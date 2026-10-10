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
        : (_lastOrderId ?? 'order_test_${DateTime.now().millisecondsSinceEpoch}');

    final String paymentId = (response.paymentId != null && response.paymentId!.isNotEmpty)
        ? response.paymentId!
        : 'pay_${DateTime.now().millisecondsSinceEpoch}';

    final String signature = (response.signature != null && response.signature!.isNotEmpty)
        ? response.signature!
        : 'sig_verified_mock_${DateTime.now().millisecondsSinceEpoch}';

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
              backgroundColor: AppColors.accent,
            ),
          );
          _loadSubscriptionData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(verifyRes.message.isNotEmpty ? verifyRes.message : 'Payment signature verification failed.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification error: $e'),
            backgroundColor: AppColors.error,
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

      final String msg = (response.code == Razorpay.PAYMENT_CANCELLED)
          ? 'Payment cancelled.'
          : (response.message != null && response.message!.isNotEmpty
              ? 'Payment Failed: ${response.message}'
              : 'Payment Failed (Code ${response.code})');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: response.code == Razorpay.PAYMENT_CANCELLED ? AppColors.warning : AppColors.error,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('External Wallet Selected: ${response.walletName}')),
      );
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
              backgroundColor: AppColors.error,
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

      if (keyId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Razorpay Key ID is missing. Please configure Key ID in Admin Panel.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        setState(() {
          _isProcessing = false;
        });
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to open Razorpay SDK: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment initiation error: $e'),
            backgroundColor: AppColors.error,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
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
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Subscription & Payments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                    Text(
                      'Payment History',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMutedColor = isDark ? AppColors.darkTextSecondary : AppColors.textMuted;
    Color badgeColor;
    String statusText;
    IconData statusIcon;
    String badgeTagText = status.toUpperCase();

    final bool isExpiringSoon = (daysRemaining <= 10);

    if (status == 'active') {
      if (isExpiringSoon) {
        badgeColor = AppColors.warning;
        statusText = 'Active (Expiring Soon)';
        statusIcon = Icons.timer_outlined;
        badgeTagText = 'EXPIRING SOON';
      } else {
        badgeColor = AppColors.accent;
        statusText = 'Active Subscription';
        statusIcon = Icons.verified_rounded;
      }
    } else if (status == 'expired') {
      badgeColor = AppColors.error;
      statusText = 'Subscription Expired';
      statusIcon = Icons.error_rounded;
      badgeTagText = 'EXPIRED';
    } else {
      if (isExpiringSoon) {
        badgeColor = AppColors.warning;
        statusText = 'Trial Expiring Soon';
        statusIcon = Icons.hourglass_bottom_rounded;
        badgeTagText = 'EXPIRING SOON';
      } else {
        badgeColor = AppColors.warning;
        statusText = 'Free Trial Active';
        statusIcon = Icons.hourglass_top_rounded;
      }
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: badgeColor),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: isExpiringSoon ? Border.all(color: badgeColor.withOpacity(0.5)) : null,
                ),
                child: Text(
                  badgeTagText,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                ),
              ),
            ],
          ),
          Divider(height: 24, color: isDark ? AppColors.darkBorder : AppColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Days Remaining',
                    style: TextStyle(fontSize: 12, color: isExpiringSoon ? AppColors.warning : textMutedColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$daysRemaining Days',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isExpiringSoon ? AppColors.warning : textColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Valid Until', style: TextStyle(fontSize: 12, color: textMutedColor)),
                  const SizedBox(height: 2),
                  Text(
                    expiryDate,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isExpiringSoon ? AppColors.warning : textColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (isExpiringSoon) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '⏰ Only $daysRemaining days remaining! Renew your plan below to continue uninterrupted access.',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _checkIsActivePlan(Map<String, dynamic> planItem, String currentStatus) {
    if (currentStatus != 'active' || _statusData == null) {
      return false;
    }

    final dynamic rawPlanId = _statusData!['plan_id'] ??
        _statusData!['active_plan_id'] ??
        _statusData!['plan']?['id'];

    final dynamic rawBillingPeriod = _statusData!['billing_period'] ??
        _statusData!['active_billing_period'] ??
        _statusData!['plan']?['billing_period'];

    final dynamic rawPlanName = _statusData!['plan_name'] ??
        _statusData!['name'] ??
        _statusData!['plan']?['name'];

    final dynamic planId = planItem['id'];
    final String periodRaw = (planItem['billing_period'] ?? '').toString().toLowerCase();
    final String nameRaw = (planItem['name'] ?? '').toString().toLowerCase();

    // 1. Direct plan_id match (highest precedence)
    if (rawPlanId != null && planId != null) {
      return rawPlanId.toString() == planId.toString();
    }

    // 2. Billing period match
    if (rawBillingPeriod != null && periodRaw.isNotEmpty) {
      final String activeBp = rawBillingPeriod.toString().toLowerCase();
      if (activeBp == periodRaw) return true;
      if ((activeBp == 'monthly' || activeBp == 'month') && (periodRaw == 'monthly' || periodRaw == 'month')) return true;
      if ((activeBp == '3_months' || activeBp == '3_month') && (periodRaw == '3_months' || periodRaw == '3_month')) return true;
      if ((activeBp == '6_months' || activeBp == '6_month') && (periodRaw == '6_months' || periodRaw == '6_month')) return true;
      if ((activeBp == 'annual' || activeBp == 'yearly') && (periodRaw == 'annual' || periodRaw == 'yearly')) return true;
      return false;
    }

    // 3. Plan name match
    if (rawPlanName != null && nameRaw.isNotEmpty) {
      final String activeName = rawPlanName.toString().toLowerCase();
      return activeName == nameRaw;
    }

    return false;
  }

  Widget _buildPlansSection(String currentStatus) {
    if (_availablePlans.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _availablePlans.map((planItem) {
          final Map<String, dynamic> p = Map<String, dynamic>.from(planItem);
          final dynamic rawId = p['id'];
          final int planId = (rawId != null) ? (int.tryParse(rawId.toString()) ?? 1) : 1;
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

          final bool isActivePlan = _checkIsActivePlan(p, currentStatus);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildSinglePlanCard(
              planId: planId,
              name: name,
              price: price,
              periodFormatted: periodFormatted,
              periodRaw: periodRaw,
              currentStatus: currentStatus,
              isActivePlan: isActivePlan,
            ),
          );
        }).toList(),
      );
    }

    // Default Plan Card
    final Map<String, dynamic> defaultPlan = {
      'id': 1,
      'name': 'Mobile Profits Pro',
      'billing_period': 'monthly',
    };
    final bool isActivePlan = _checkIsActivePlan(defaultPlan, currentStatus);

    return _buildSinglePlanCard(
      planId: 1,
      name: 'Mobile Profits Pro',
      price: 200.0,
      periodFormatted: 'month',
      periodRaw: 'monthly',
      currentStatus: currentStatus,
      isActivePlan: isActivePlan,
    );
  }

  Widget _buildSinglePlanCard({
    required int planId,
    required String name,
    required double price,
    required String periodFormatted,
    required String periodRaw,
    required String currentStatus,
    required bool isActivePlan,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMutedColor = isDark ? AppColors.darkTextSecondary : AppColors.textMuted;

    // Single clean top-right badge tag
    String? topBadgeText;
    Color topBadgeColor = AppColors.accent;
    IconData? topBadgeIcon;

    if (isActivePlan) {
      topBadgeText = 'CURRENT PLAN';
      topBadgeColor = AppColors.accent;
      topBadgeIcon = Icons.check_circle_rounded;
    } else if (periodRaw == '3_months' || periodRaw == '6_months') {
      topBadgeText = 'MOST POPULAR';
      topBadgeColor = const Color(0xFFFF9800);
      topBadgeIcon = Icons.local_fire_department_rounded;
    }

    final String buttonText;
    if (isActivePlan) {
      buttonText = 'Renew Plan (₹${price.toStringAsFixed(0)}/$periodFormatted)';
    } else if (currentStatus == 'active') {
      buttonText = 'Upgrade Plan (₹${price.toStringAsFixed(0)}/$periodFormatted)';
    } else {
      buttonText = 'Subscribe Now (₹${price.toStringAsFixed(0)}/$periodFormatted)';
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CustomCard(
          padding: const EdgeInsets.all(20),
          border: isActivePlan
              ? Border.all(color: AppColors.accent, width: 2)
              : Border.all(color: isDark ? AppColors.darkBorder : AppColors.border, width: 1),
          backgroundColor: isActivePlan
              ? (isDark ? AppColors.accent.withOpacity(0.08) : AppColors.accent.withOpacity(0.03))
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
                        ),
                        const SizedBox(height: 2),
                        Text('All-in-one Shop Management', style: TextStyle(fontSize: 12, color: textMutedColor)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary)),
                      Text('/ $periodFormatted', style: TextStyle(fontSize: 11, color: textMutedColor)),
                    ],
                  ),
                ],
              ),
              Divider(height: 24, color: isDark ? AppColors.darkBorder : AppColors.border),
              _buildFeatureRow('✔ Full Customer Directory & Purchase History'),
              _buildFeatureRow('✔ Repair Jobs Tracking & Parts Usage'),
              _buildFeatureRow('✔ Quick Billing & Invoice Receipts'),
              _buildFeatureRow('✔ Profit Intelligence & AI Recommendations'),
              _buildFeatureRow('✔ Technician Commissions & Management'),
              _buildFeatureRow('✔ Business Reports & CSV Exports'),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: isActivePlan
                      ? const LinearGradient(colors: [AppColors.accent, Color(0xFF009688)])
                      : AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (isActivePlan ? AppColors.accent : AppColors.primary).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isProcessing ? null : () => _startRazorpayPayment(planId: planId, planName: name, planPrice: price),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          buttonText,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
        if (topBadgeText != null)
          Positioned(
            top: -1,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: topBadgeColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: topBadgeColor.withOpacity(0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (topBadgeIcon != null) ...[
                    Icon(topBadgeIcon, color: Colors.white, size: 13),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    topBadgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFeatureRow(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildHistoryList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMutedColor = isDark ? AppColors.darkTextSecondary : AppColors.textMuted;

    if (_historyList.isEmpty) {
      return CustomCard(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text('No previous payment transactions found.', style: TextStyle(color: textMutedColor, fontSize: 13)),
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
                      Text(item['plan_name'] ?? 'Mobile Profits Pro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                      const SizedBox(height: 2),
                      Text(
                        'Order: ${item['order_id'] ?? ''}',
                        style: TextStyle(fontSize: 11, color: textMutedColor),
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
                    Text('₹${amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                    const SizedBox(height: 2),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: status == 'successful' ? AppColors.accent : (status == 'pending' ? AppColors.warning : AppColors.error),
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
