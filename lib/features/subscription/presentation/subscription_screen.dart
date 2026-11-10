import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
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
  bool _isPurchasingAddon = false;
  int _staffAddonCount = 1;

  Map<String, dynamic>? _statusData;
  List<dynamic> _historyList = [];
  List<dynamic> _availablePlans = [];
  String _planFilter = 'all'; // 'all', 'staff', 'solo'

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
          final String successMsg = (verifyRes.message.isNotEmpty)
              ? verifyRes.message
              : 'Payment Verified Successfully!';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMsg),
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
          _isPurchasingAddon = false;
        });
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _isPurchasingAddon = false;
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

  Future<void> _startRazorpayPayment({
    int? planId,
    String? planName,
    double? planPrice,
    bool isUpgrade = false,
  }) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final orderRes = await _repository.createOrder(planId: planId, isUpgrade: isUpgrade);
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

                    // Add Staff / Technician Add-on Card
                    if (daysRemaining > 0 && status != 'expired') ...[
                      _buildStaffAddonCard(status, daysRemaining, expiryDateStr),
                      const SizedBox(height: 18),
                    ],

                    // Available Plans Section
                    _buildPlansSection(status, daysRemaining, expiryDateStr),
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
    final int effectiveMaxStaff = _statusData?['effective_max_staff'] ?? 0;
    final int staffDaysRemaining = _statusData?['staff_days_remaining'] ?? 0;
    final String staffValidUntilStr = _statusData?['staff_valid_until_formatted']?.toString() ?? '';
    final bool isStaffExpired = _statusData?['is_staff_expired'] == true;

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
          // Staff Logins Validity Indicator
          if (effectiveMaxStaff > 0 || isStaffExpired || staffValidUntilStr.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isStaffExpired
                    ? AppColors.error.withOpacity(0.08)
                    : const Color(0xFF4F46E5).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isStaffExpired
                      ? AppColors.error.withOpacity(0.25)
                      : const Color(0xFF4F46E5).withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isStaffExpired
                          ? AppColors.error.withOpacity(0.15)
                          : const Color(0xFF4F46E5).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.people_alt_rounded,
                      size: 18,
                      color: isStaffExpired ? AppColors.error : const Color(0xFF4F46E5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isStaffExpired ? 'Staff Login Access Expired' : 'Staff Login Validity',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isStaffExpired ? AppColors.error : textColor,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isStaffExpired ? AppColors.error : const Color(0xFF4F46E5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isStaffExpired
                                    ? 'EXPIRED'
                                    : '$staffDaysRemaining Days Left',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isStaffExpired
                              ? 'Technician login is locked. Renew staff plan or add-on to re-enable.'
                              : '$effectiveMaxStaff Staff Login(s) active until $staffValidUntilStr',
                          style: TextStyle(
                            fontSize: 11,
                            color: isStaffExpired ? AppColors.error : textMutedColor,
                          ),
                        ),
                      ],
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

  Widget _buildStaffAddonCard(String status, int daysRemaining, String expiryDateStr) {
    if (status == 'expired' || daysRemaining <= 0) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double dailyRate = (_statusData?['staff_price_per_day'] != null)
        ? (_statusData!['staff_price_per_day'] as num).toDouble()
        : 2.00;
    final int currentStaffLimit = (_statusData?['effective_max_staff'] != null)
        ? int.tryParse(_statusData!['effective_max_staff'].toString()) ?? 0
        : 0;
    final int activeStaffCount = (_statusData?['active_staff_count'] != null)
        ? int.tryParse(_statusData!['active_staff_count'].toString()) ?? 0
        : 0;

    final double totalAmount = (daysRemaining * dailyRate * _staffAddonCount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.people_alt_rounded, color: Color(0xFF4F46E5), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Staff Member Logins',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Valid for remaining $daysRemaining days (until $expiryDateStr)',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  '₹${dailyRate.toStringAsFixed(0)}/day',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Current Limit & Stepper Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Staff to Add:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Limit: $currentStaffLimit ($activeStaffCount active)',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded, size: 24, color: Color(0xFF4F46E5)),
                      onPressed: _staffAddonCount > 1
                          ? () => setState(() => _staffAddonCount--)
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.3)),
                      ),
                      child: Text(
                        '+$_staffAddonCount Staff',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 24, color: Color(0xFF4F46E5)),
                      onPressed: _staffAddonCount < 10
                          ? () => setState(() => _staffAddonCount++)
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Transparent Formula Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Formula ($daysRemaining d):',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF4338CA)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$daysRemaining d × ₹${dailyRate.toStringAsFixed(0)} × $_staffAddonCount',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3730A3)),
                    ),
                  ],
                ),
                const Divider(height: 12, color: Color(0xFFC7D2FE)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Add-on Cost:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                    Text(
                      '₹${totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF4338CA)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Add Staff Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isPurchasingAddon ? null : () => _confirmAndPurchaseStaffAddon(totalAmount, daysRemaining, expiryDateStr),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
              ),
              icon: _isPurchasingAddon
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.bolt_rounded, size: 20),
              label: Text(
                _isPurchasingAddon
                    ? 'Processing...'
                    : 'Add $_staffAddonCount Staff (Pay ₹${totalAmount.toStringAsFixed(0)})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndPurchaseStaffAddon(double totalAmount, int daysRemaining, String expiryDateStr) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.group_add_rounded, color: Color(0xFF4F46E5), size: 22),
            ),
            const SizedBox(width: 10),
            const Text('Confirm Staff Add-on', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add $_staffAddonCount staff login account(s) for your current plan.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Staff Added:', style: TextStyle(fontSize: 12)),
                      Text('+$_staffAddonCount Staff', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Validity:', style: TextStyle(fontSize: 12)),
                      Text('$daysRemaining Days (until $expiryDateStr)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Payable:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      Text(
                        '₹${totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm & Pay', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _startStaffAddonRazorpayPayment(totalAmount);
  }

  Future<void> _startStaffAddonRazorpayPayment(double totalAmount) async {
    setState(() {
      _isPurchasingAddon = true;
      _isProcessing = true;
    });

    try {
      final orderRes = await _repository.createStaffAddonOrder(
        staffCount: _staffAddonCount,
      );

      if (!orderRes.success || orderRes.data == null) {
        if (mounted) {
          AppFeedback.showError(
            context,
            error: orderRes.message.isNotEmpty
                ? orderRes.message
                : 'Failed to create staff add-on payment order.',
          );
        }
        setState(() {
          _isPurchasingAddon = false;
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
          : totalAmount;
      final String keyId = orderData['key_id'] ?? '';
      final String shopName = orderData['shop_name'] ?? 'Mobile Profits';
      final String planName = orderData['plan_name'] ?? 'Staff Logins Add-on (+$_staffAddonCount Staff)';

      _lastOrderId = orderId;

      if (keyId.isEmpty) {
        if (mounted) {
          AppFeedback.showError(
            context,
            error: 'Razorpay Key ID is missing. Please configure Key ID in Admin Panel.',
          );
        }
        setState(() {
          _isPurchasingAddon = false;
          _isProcessing = false;
        });
        return;
      }

      var options = <String, dynamic>{
        'key': keyId,
        'amount': (amount * 100).toInt(),
        'name': shopName,
        'description': planName,
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
          AppFeedback.showError(context, error: 'Failed to open Razorpay SDK: $e');
        }
        setState(() {
          _isPurchasingAddon = false;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, error: 'Payment initiation error: $e');
      }
      setState(() {
        _isPurchasingAddon = false;
        _isProcessing = false;
      });
    }
  }

  Widget _buildPlansSection(String currentStatus, int daysRemaining, String expiryDateStr) {
    if (_availablePlans.isNotEmpty) {
      final List<Map<String, dynamic>> parsedPlans = _availablePlans.map((item) {
        return Map<String, dynamic>.from(item);
      }).toList();

      // Base plans: Solo Owner plans (staff logins are added via ₹2/day add-on)
      final List<Map<String, dynamic>> filteredPlans = parsedPlans.where((p) {
        final staff = int.tryParse(p['max_staff_accounts']?.toString() ?? '0') ?? 0;
        return staff == 0;
      }).toList();

      final bool hasCustomDiscount = _statusData?['has_custom_discount'] == true;
      final bool isOneTimeDiscount = _statusData?['custom_discount_is_one_time'] == true;
      final int? customDiscountPercent = _statusData?['custom_discount_percent'] != null
          ? int.tryParse(_statusData!['custom_discount_percent'].toString())
          : null;
      final String? customDiscountNote = _statusData?['custom_discount_note']?.toString();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom Shop Discount Banner (if active)
          if (hasCustomDiscount)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.stars_rounded, color: Color(0xFF059669), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                customDiscountPercent != null && customDiscountPercent > 0
                                    ? (isOneTimeDiscount
                                        ? '🎉 Special $customDiscountPercent% One-Time Discount!'
                                        : '🎉 Special $customDiscountPercent% Discount applied!')
                                    : '🎉 Exclusive Custom Pricing applied!',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF065F46)),
                              ),
                            ),
                            if (isOneTimeDiscount)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '1-TIME',
                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (customDiscountNote != null && customDiscountNote.isNotEmpty)
                              ? (isOneTimeDiscount ? '$customDiscountNote • Valid for next purchase' : customDiscountNote)
                              : (isOneTimeDiscount ? 'Discount applies once to your next plan purchase.' : 'Special pricing active for your shop.'),
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF047857)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const Text(
            'Choose Subscription Plan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),

          ...filteredPlans.map((p) {
            final dynamic rawId = p['id'];
            final int planId = (rawId != null) ? (int.tryParse(rawId.toString()) ?? 1) : 1;
            final String name = p['name'] ?? 'Mobile Profits Plan';
            final double price = (p['price'] != null) ? (p['price'] as num).toDouble() : 99.0;
            final bool isDiscounted = p['is_discounted'] == true;
            final double? originalPrice = (p['original_price'] != null) ? (p['original_price'] as num).toDouble() : null;
            final int? discountPercent = (p['discount_percent'] != null) ? int.tryParse(p['discount_percent'].toString()) : null;
            final String periodRaw = p['billing_period'] ?? 'monthly';
            final int maxStaff = (p['max_staff_accounts'] != null)
                ? (int.tryParse(p['max_staff_accounts'].toString()) ?? 0)
                : 0;

            String periodFormatted = 'month';
            if (periodRaw == '3_months') {
              periodFormatted = '3 months';
            } else if (periodRaw == '6_months') {
              periodFormatted = '6 months';
            } else if (periodRaw == 'annual') {
              periodFormatted = 'year';
            }

            final bool isActivePlan = _checkIsActivePlan(p, currentStatus);
            final bool canUpgrade = p['can_upgrade'] == true;
            final double? upgradePrice = (p['upgrade_price'] != null)
                ? (p['upgrade_price'] as num).toDouble()
                : null;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14.0),
              child: _buildSinglePlanCard(
                planId: planId,
                name: name,
                price: price,
                isDiscounted: isDiscounted,
                isOneTimeDiscount: isOneTimeDiscount,
                originalPrice: originalPrice,
                discountPercent: discountPercent,
                periodFormatted: periodFormatted,
                periodRaw: periodRaw,
                maxStaff: maxStaff,
                currentStatus: currentStatus,
                isActivePlan: isActivePlan,
                canUpgrade: canUpgrade,
                upgradePrice: upgradePrice,
                daysRemaining: daysRemaining,
                expiryDateStr: expiryDateStr,
              ),
            );
          }),
        ],
      );
    }

    // Default Plan Card
    final Map<String, dynamic> defaultPlan = {
      'id': 1,
      'name': 'Solo Owner (1 Month)',
      'billing_period': 'monthly',
      'max_staff_accounts': 0,
    };
    final bool isActivePlan = _checkIsActivePlan(defaultPlan, currentStatus);

    return _buildSinglePlanCard(
      planId: 1,
      name: 'Solo Owner (1 Month)',
      price: 99.0,
      periodFormatted: 'month',
      periodRaw: 'monthly',
      maxStaff: 0,
      currentStatus: currentStatus,
      isActivePlan: isActivePlan,
      canUpgrade: false,
      upgradePrice: null,
      daysRemaining: daysRemaining,
      expiryDateStr: expiryDateStr,
    );
  }

  Widget _buildPlanFilterChip({required String label, required String key}) {
    final isSelected = _planFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _planFilter = key);
      },
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.grey.shade300,
        width: 1.2,
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildSinglePlanCard({
    required int planId,
    required String name,
    required double price,
    bool isDiscounted = false,
    bool isOneTimeDiscount = false,
    double? originalPrice,
    int? discountPercent,
    required String periodFormatted,
    required String periodRaw,
    required int maxStaff,
    required String currentStatus,
    required bool isActivePlan,
    bool canUpgrade = false,
    double? upgradePrice,
    int daysRemaining = 0,
    String expiryDateStr = 'N/A',
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
    } else if (isDiscounted) {
      topBadgeText = discountPercent != null
          ? (isOneTimeDiscount ? '$discountPercent% 1-TIME DISCOUNT' : '$discountPercent% SPECIAL DISCOUNT')
          : (isOneTimeDiscount ? '1-TIME SPECIAL PRICE' : 'SPECIAL PRICE');
      topBadgeColor = const Color(0xFF059669);
      topBadgeIcon = Icons.local_offer_rounded;
    } else if (maxStaff == 1 || maxStaff == 2) {
      topBadgeText = 'POPULAR WITH STAFF';
      topBadgeColor = const Color(0xFFFF9800);
      topBadgeIcon = Icons.local_fire_department_rounded;
    } else if (maxStaff >= 5) {
      topBadgeText = 'BEST FOR TEAMS';
      topBadgeColor = const Color(0xFF7C3AED);
      topBadgeIcon = Icons.stars_rounded;
    }

    final String buttonText;
    if (isActivePlan) {
      buttonText = 'Renew Plan (₹${price.toStringAsFixed(0)}/$periodFormatted)';
    } else if (currentStatus == 'active') {
      buttonText = 'Switch Plan (₹${price.toStringAsFixed(0)}/$periodFormatted)';
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
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textColor),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: maxStaff > 0 ? AppColors.primary.withOpacity(0.08) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: maxStaff > 0 ? AppColors.primary.withOpacity(0.25) : Colors.grey.shade300,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                maxStaff > 0 ? Icons.people_alt_rounded : Icons.person_rounded,
                                size: 12,
                                color: maxStaff > 0 ? AppColors.primary : Colors.grey.shade700,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                maxStaff == 0
                                    ? '0 Staff (Owner Only)'
                                    : maxStaff == 1
                                        ? '1 Staff Account Included'
                                        : maxStaff == 2
                                            ? '2 Staff Accounts Included'
                                            : 'Up to $maxStaff Staff Accounts',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: maxStaff > 0 ? AppColors.primary : Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isDiscounted && originalPrice != null && originalPrice > price) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹${originalPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 13,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.red.shade400,
                                decorationThickness: 2,
                                color: textMutedColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (discountPercent != null && discountPercent > 0) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '$discountPercent% OFF',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text('₹${price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary)),
                      Text('/ $periodFormatted', style: TextStyle(fontSize: 11, color: textMutedColor)),
                    ],
                  ),
                ],
              ),
              Divider(height: 24, color: isDark ? AppColors.darkBorder : AppColors.border),
              if (maxStaff > 0) ...[
                _buildFeatureRow('✔ 1 Shop Owner + $maxStaff Staff App Logins'),
                _buildFeatureRow('✔ Role-Based Permissions (Repairs, Sales, Stock)'),
                _buildFeatureRow('✔ Financial Privacy (Profits & Costs hidden from staff)'),
              ] else ...[
                _buildFeatureRow('✔ 1 Shop Owner Full Access (Solo Operation)'),
              ],
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
                  onPressed: _isProcessing
                      ? null
                      : () {
                          _startRazorpayPayment(
                            planId: planId,
                            planName: name,
                            planPrice: price,
                            isUpgrade: false,
                          );
                        },
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
