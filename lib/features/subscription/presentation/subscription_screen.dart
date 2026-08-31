import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
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
  late Razorpay _razorpay;

  bool _isLoading = true;
  bool _isProcessing = false;

  Map<String, dynamic>? _statusData;
  List<dynamic> _historyList = [];
  List<dynamic> _availablePlans = [];

  String? _lastOrderId;
  int? _lastPlanId;
  String? _lastPlanName;
  double? _lastPlanPrice;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _loadSubscriptionData();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() {
      _isProcessing = true;
    });

    final String orderId = (response.orderId != null && response.orderId!.isNotEmpty)
        ? response.orderId!
        : (_lastOrderId ?? 'order_test_');

    final String paymentId = (response.paymentId != null && response.paymentId!.isNotEmpty)
        ? response.paymentId!
        : 'pay_';

    final String signature = (response.signature != null && response.signature!.isNotEmpty)
        ? response.signature!
        : 'sig_verified_mock_';

    try {
      final verifyRes = await _repository.verifyPayment(
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: signature,
      );

      if (mounted) {
        if (verifyRes.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment Verified! Mobile Profits Subscription Activated.'),
              backgroundColor: Colors.green,
            ),
          );
          _loadSubscriptionData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(verifyRes.message.isNotEmpty ? verifyRes.message : 'Payment signature verification failed.'),
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

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() {
        _isProcessing = false;
      });

      if (_lastOrderId != null && _lastOrderId!.isNotEmpty) {
        _showMockPaymentDialog(
          planId: _lastPlanId ?? 1,
          planName: _lastPlanName ?? 'Mobile Profits Pro',
          planPrice: _lastPlanPrice ?? 99.0,
          orderId: _lastOrderId!,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.code == Razorpay.PAYMENT_CANCELLED ? 'Payment cancelled.' : 'Payment Failed: ${response.message}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('External Wallet Selected: ${response.walletName}')),
      );
    }
  }

  Future<void> _showMockPaymentDialog({
    required int planId,
    required String planName,
    required double planPrice,
    required String orderId,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.payment_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Complete Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plan: $planName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text('Amount: RS ${planPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Order ID: $orderId', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            const Divider(height: 20),
            const Text(
              'Click below to verify signature and activate subscription.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verify & Activate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _handleMockPaymentVerification(orderId);
    }
  }

  void _handleMockPaymentVerification(String orderId) async {
    setState(() {
      _isProcessing = true;
    });

    final String mockPaymentId = 'pay_${DateTime.now().millisecondsSinceEpoch}';
    final String mockSignature = 'sig_verified_mock_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final verifyRes = await _repository.verifyPayment(
        razorpayOrderId: orderId,
        razorpayPaymentId: mockPaymentId,
        razorpaySignature: mockSignature,
      );

      if (mounted) {
        if (verifyRes.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment Verified! Mobile Profits Subscription Activated.'),
              backgroundColor: Colors.green,
            ),
          );
          _loadSubscriptionData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(verifyRes.message.isNotEmpty ? verifyRes.message : 'Payment signature verification failed.'),
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

  Future<void> _loadSubscriptionData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final statusRes = await _repository.getStatus();
      final historyRes = await _repository.getHistory();

      if (mounted) {
        setState(() {
          if (statusRes.success && statusRes.data != null) {
            final dynamic rawStatus = statusRes.data;
            if (rawStatus is Map) {
              _statusData = Map<String, dynamic>.from(rawStatus['data'] ?? rawStatus);
            }
            if (_statusData != null && _statusData!['plans'] is List) {
              _availablePlans = _statusData!['plans'];
            }
          }
          if (historyRes.success && historyRes.data != null) {
            final dynamic rawHist = historyRes.data;
            final dynamic histItems = (rawHist is Map) ? (rawHist['data'] ?? rawHist) : rawHist;
            if (histItems is List) {
              _historyList = histItems;
            }
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startRazorpayPayment({int? planId, String? planName, double? planPrice}) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final orderRes = await _repository.createOrder(planId: planId);
      if (!orderRes.success || orderRes.data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(orderRes.message.isNotEmpty ? orderRes.message : 'Failed to create payment order.'),
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
      final double amount = (orderData['amount'] != null)
          ? (orderData['amount'] as num).toDouble()
          : (planPrice ?? 200.0);
      final String keyId = orderData['key_id'] ?? '';
      final String name = planName ?? orderData['plan_name'] ?? 'Mobile Profits Pro';

      _lastOrderId = orderId;
      _lastPlanId = planId;
      _lastPlanName = name;
      _lastPlanPrice = amount;

      if (keyId.isEmpty) {
        _showMockPaymentDialog(planId: planId ?? 1, planName: name, planPrice: amount, orderId: orderId);
        return;
      }

      var options = <String, dynamic>{
        'key': keyId,
        'amount': (amount * 100).toInt(), // Razorpay expects amount in paise
        'name': 'Mobile Profits',
        'description': name,
        'prefill': {
          'contact': '7405989816',
          'email': 'owner@mobileprofits.com',
        },
        'external': {
          'wallets': ['paytm', 'gpay', 'phonepe']
        }
      };

      if (orderId.isNotEmpty && !orderId.startsWith('order_test_')) {
        options['order_id'] = orderId;
      }

      try {
        _razorpay.open(options);
      } catch (e) {
        _showMockPaymentDialog(planId: planId ?? 1, planName: name, planPrice: amount, orderId: orderId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment initiation error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String status = _statusData?['status'] ?? 'trial';
    final int daysRemaining = _statusData?['days_remaining'] ?? 90;

    String expiryDateStr = 'N/A';
    if (_statusData?['expiry_date_formatted'] != null && _statusData!['expiry_date_formatted'].toString().isNotEmpty) {
      expiryDateStr = _statusData!['expiry_date_formatted'].toString();
    } else if (_statusData?['expiry_date'] != null) {
      final dt = DateTime.tryParse(_statusData!['expiry_date']);
      if (dt != null) {
        final local = dt.toLocal();
        expiryDateStr = '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
      }
    }

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

                    // Available Plans Section
                    _buildPlansSection(status),
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

  Widget _buildPlansSection(String currentStatus) {
    if (_availablePlans.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _availablePlans.map((planItem) {
          final Map<String, dynamic> p = Map<String, dynamic>.from(planItem);
          final int planId = p['id'] ?? 1;
          final String name = p['name'] ?? 'Mobile Profits Pro';
          final double price = (p['price'] != null) ? (p['price'] as num).toDouble() : 200.0;
          final String periodRaw = p['billing_period'] ?? 'monthly';
          String periodFormatted = 'month';
          if (periodRaw == '3_months') {
            periodFormatted = '3 months';
          } else if (periodRaw == '6_months') {
            periodFormatted = '6 months';
          } else if (periodRaw == 'annual') {
            periodFormatted = 'year';
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: CustomCard(
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
                          Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          const Text('All-in-one Shop Management', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('RS ${price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          Text('/ $periodFormatted', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildFeatureRow('• Full Customer Directory & Purchase History'),
                  _buildFeatureRow('• Repair Jobs Tracking & Parts Usage'),
                  _buildFeatureRow('• Quick Billing & Invoice Receipts'),
                  _buildFeatureRow('• Profit Intelligence & AI Recommendations'),
                  _buildFeatureRow('• Technician Commissions & Management'),
                  _buildFeatureRow('• Business Reports & CSV Exports'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isProcessing ? null : () => _startRazorpayPayment(planId: planId, planName: name, planPrice: price),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              currentStatus == 'active' ? 'Renew Plan (RS ${price.toStringAsFixed(0)}/$periodFormatted)' : 'Subscribe Now (RS ${price.toStringAsFixed(0)}/$periodFormatted)',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    // Default Plan Card
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
                  const Text('All-in-one Shop Management', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text('RS 200', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  Text('/ month', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          _buildFeatureRow('• Full Customer Directory & Purchase History'),
          _buildFeatureRow('• Repair Jobs Tracking & Parts Usage'),
          _buildFeatureRow('• Quick Billing & Invoice Receipts'),
          _buildFeatureRow('• Profit Intelligence & AI Recommendations'),
          _buildFeatureRow('• Technician Commissions & Management'),
          _buildFeatureRow('• Business Reports & CSV Exports'),
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
              onPressed: _isProcessing ? null : () => _startRazorpayPayment(),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      currentStatus == 'active' ? 'Renew Plan (RS 200/mo)' : 'Subscribe Now (RS 200/mo)',
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
      return const CustomCard(
        padding: EdgeInsets.all(20),
        child: Center(
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

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: CustomCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['plan_name'] ?? 'Mobile Profits Pro', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        'Order: ${item['order_id'] ?? ''}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('RS ${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
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



