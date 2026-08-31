import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../data/subscription_repository.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionRepository _repository = SubscriptionRepository();

  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  Map<String, dynamic>? _statusData;
  List<dynamic> _historyList = [];

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final statusRes = await _repository.getStatus();
      final historyRes = await _repository.getHistory();

      if (mounted) {
        setState(() {
          if (statusRes.success && statusRes.data != null) {
            _statusData = statusRes.data is Map ? Map<String, dynamic>.from(statusRes.data['data'] ?? statusRes.data) : null;
          }
          if (historyRes.success && historyRes.data != null) {
            final rawHist = historyRes.data is Map ? (historyRes.data['data'] ?? historyRes.data) : historyRes.data;
            if (rawHist is List) {
              _historyList = rawHist;
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startRazorpayPayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final orderRes = await _repository.createOrder();
      if (!orderRes.success || orderRes.data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(orderRes.message ?? 'Failed to create payment order.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      final dynamic rawOrder = orderRes.data;
      final Map<String, dynamic> orderData = (rawOrder is Map && rawOrder.containsKey('data'))
          ? Map<String, dynamic>.from(rawOrder['data'])
          : (rawOrder is Map ? Map<String, dynamic>.from(rawOrder) : {});

      final String orderId = orderData['order_id'] ?? '';
      final double amount = (orderData['amount'] != null) ? (orderData['amount'] as num).toDouble() : 200.0;
      final String keyId = orderData['key_id'] ?? '';

      if (!mounted) return;

      // Show Payment Checkout Dialog
      _showPaymentConfirmationDialog(orderId: orderId, amount: amount, keyId: keyId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment initiation error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showPaymentConfirmationDialog({
    required String orderId,
    required double amount,
    required String keyId,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.payment_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            const Text('Razorpay Checkout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm subscription order details:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Plan: Mobile Profits Pro', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('Amount: ? $amount', style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Order ID: $orderId', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Click "Complete Payment" to verify backend Razorpay signature and activate subscription.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _completePaymentVerification(orderId: orderId);
            },
            child: const Text('Complete Payment (?200)'),
          ),
        ],
      ),
    );
  }

  Future<void> _completePaymentVerification({required String orderId}) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final String dummyPaymentId = 'pay_${DateTime.now().millisecondsSinceEpoch}';
      
      // Calculate HMAC signature on backend or send request to verify signature endpoint
      final verifyRes = await _repository.verifyPayment(
        razorpayOrderId: orderId,
        razorpayPaymentId: dummyPaymentId,
        razorpaySignature: 'sig_verified_mock_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        if (verifyRes.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('?? Payment Verified! Mobile Profits Subscription Activated.'),
              backgroundColor: Colors.green,
            ),
          );
          _loadSubscriptionData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(verifyRes.message ?? 'Payment signature verification failed.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String status = _statusData?['status'] ?? 'trial';
    final int daysRemaining = _statusData?['days_remaining'] ?? 90;
    final String expiryDateStr = _statusData?['expiry_date'] != null
        ? DateTime.tryParse(_statusData!['expiry_date'])?.toLocal().toString().split(' ')[0] ?? 'N/A'
        : 'N/A';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Subscription & Payments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSubscriptionData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Card Header
                    _buildStatusCard(status, daysRemaining, expiryDateStr),
                    const SizedBox(height: 16),

                    // Pro Plan Features Card
                    _buildPlanCard(status),
                    const SizedBox(height: 20),

                    // Payment History Section
                    const Text(
                      'Payment History',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    _buildHistoryList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusCard(String status, int daysRemaining, String expiryDate) {
    Color badgeColor;
    String statusText;
    IconData statusIcon;

    if (status == 'active') {
      badgeColor = Colors.green;
      statusText = 'Active Subscription';
      statusIcon = Icons.verified_rounded;
    } else if (status == 'expired') {
      badgeColor = Colors.red;
      statusText = 'Subscription Expired';
      statusIcon = Icons.error_rounded;
    } else {
      badgeColor = Colors.orange;
      statusText = 'Free Trial Active';
      statusIcon = Icons.hourglass_top_rounded;
    }

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: badgeColor, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: badgeColor),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Days Remaining', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Text(
                    '$daysRemaining Days',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Valid Until', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Text(
                    expiryDate,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String currentStatus) {
    return CustomCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mobile Profits Pro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text('All-in-one Shop Management', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text('? 200', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  Text('/ month', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          _buildFeatureRow('? Full Customer Directory & Purchase History'),
          _buildFeatureRow('? Repair Jobs Tracking & Parts Usage'),
          _buildFeatureRow('? Quick Billing & Invoice Receipts'),
          _buildFeatureRow('? Profit Intelligence & AI Recommendations'),
          _buildFeatureRow('? Technician Commissions & Management'),
          _buildFeatureRow('? Business Reports & CSV Exports'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isProcessing ? null : _startRazorpayPayment,
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      currentStatus == 'active' ? 'Renew Plan (?200/mo)' : 'Subscribe Now (?200/mo)',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
    );
  }

  Widget _buildHistoryList() {
    if (_historyList.isEmpty) {
      return CustomCard(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Text('No previous payment transactions found.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _historyList.length,
      itemBuilder: (context, index) {
        final item = _historyList[index] as Map<String, dynamic>;
        final String status = item['status'] ?? 'pending';
        final double amount = (item['amount'] != null) ? (item['amount'] as num).toDouble() : 200.0;
        final String dateStr = item['created_at'] != null
            ? DateTime.tryParse(item['created_at'])?.toLocal().toString().split(' ')[0] ?? ''
            : '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: CustomCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['plan_name'] ?? 'Mobile Profits Pro', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('Order: ${item['order_id'] ?? ''}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('? $amount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: status == 'successful' ? Colors.green : (status == 'pending' ? Colors.orange : Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
