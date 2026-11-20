import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/whatsapp_icon.dart';
import '../data/referral_repository.dart';

class ReferAndEarnScreen extends StatefulWidget {
  const ReferAndEarnScreen({super.key});

  @override
  State<ReferAndEarnScreen> createState() => _ReferAndEarnScreenState();
}

class _ReferAndEarnScreenState extends State<ReferAndEarnScreen> with SingleTickerProviderStateMixin {
  final ReferralRepository _referralRepo = ReferralRepository();
  late TabController _tabController;

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSummary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final res = await _referralRepo.getReferralSummary();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res.success && res.data != null) {
          _data = res.data!;
        } else {
          _error = res.message.isNotEmpty ? res.message : 'Failed to load referral details.';
        }
      });
    }
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Referral code "$code" copied!'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareViaWhatsApp(String message) async {
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await Share.share(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _data['config'] is Map ? Map<String, dynamic>.from(_data['config']) : <String, dynamic>{};
    final bool isEnabled = config['enabled'] != false;
    final String rewardMode = (config['reward_mode'] ?? 'signup_and_recharge').toString();
    final double signupPoints = _toDouble(config['signup_points']);
    final double rechargePercent = _toDouble(config['recharge_percent']);
    final double maxRedeemPercent = _toDouble(config['max_redeem_percent']);

    final String referralCode = (_data['referral_code'] ?? '').toString();
    final String shareMessage = (_data['share_message'] ?? '').toString();
    final double pointsBalance = _toDouble(_data['points_balance']);
    final double totalEarned = _toDouble(_data['total_earned']);
    final double totalRedeemed = _toDouble(_data['total_redeemed']);
    final int referralsCount = (_data['referrals_count'] is int) ? _data['referrals_count'] : 0;
    final List<dynamic> referrals = _data['referrals'] is List ? _data['referrals'] : [];
    final List<dynamic> transactions = _data['transactions'] is List ? _data['transactions'] : [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Refer & Earn Points'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 44, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadSummary, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : !isEnabled
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Referral program is currently disabled for your shop.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: AppColors.textMuted),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSummary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Points Wallet Hero Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.25),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Shop Points Wallet',
                                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.end,
                                    spacing: 8,
                                    children: [
                                      Text(
                                        '${pointsBalance.toStringAsFixed(2)} pts',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          '(₹${pointsBalance.toStringAsFixed(2)} plan discount)',
                                          style: const TextStyle(color: Color(0xFFBFDBFE), fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Use points on your shop plan recharge (up to ${maxRedeemPercent.toStringAsFixed(0)}% per recharge). Points cannot be withdrawn.',
                                      style: const TextStyle(color: Colors.white, fontSize: 11.5),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _miniStat('Earned', '${totalEarned.toStringAsFixed(2)} pts'),
                                      ),
                                      Expanded(
                                        child: _miniStat('Used', '${totalRedeemed.toStringAsFixed(2)} pts'),
                                      ),
                                      Expanded(
                                        child: _miniStat('Shops Joined', '$referralsCount'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 2. Dynamic Reward Rules Card (only shows what applies to THIS shop)
                            CustomCard(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.stars_rounded, color: AppColors.primary, size: 18),
                                      SizedBox(width: 6),
                                      Text(
                                        'Your Referral Rewards',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if (rewardMode == 'signup_and_recharge' && signupPoints > 0) ...[
                                    _ruleRow(
                                      Icons.person_add_alt_1_rounded,
                                      'When a shop downloads & creates an account: +${signupPoints.toStringAsFixed(0)} pts',
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  if (rechargePercent > 0) ...[
                                    _ruleRow(
                                      Icons.autorenew_rounded,
                                      'On every plan recharge by your referred shop: ${rechargePercent.toStringAsFixed(0)}% commission in points',
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  _ruleRow(
                                    Icons.discount_outlined,
                                    'Redeem up to ${maxRedeemPercent.toStringAsFixed(0)}% of plan price on your own shop recharge',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 3. Share Code & Link Card
                            CustomCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Your Referral Code',
                                    style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            referralCode,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                              color: AppColors.primary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        TextButton.icon(
                                          onPressed: () => _copyCode(referralCode),
                                          icon: const Icon(Icons.copy_rounded, size: 18),
                                          label: const Text('Copy', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF16A34A),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          onPressed: () => _shareViaWhatsApp(shareMessage),
                                          icon: const Icon(Icons.chat_rounded, size: 18),
                                          label: const Text('WhatsApp Invite', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: () => Share.share(shareMessage),
                                        icon: const Icon(Icons.share_rounded, size: 18),
                                        label: const Text('Share'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 4. Tabs: My Referrals & Points Passbook
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  TabBar(
                                    controller: _tabController,
                                    labelColor: AppColors.primary,
                                    unselectedLabelColor: AppColors.textMuted,
                                    indicatorColor: AppColors.primary,
                                    tabs: const [
                                      Tab(text: 'My Referrals'),
                                      Tab(text: 'Points Passbook'),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 480,
                                    child: TabBarView(
                                      controller: _tabController,
                                      children: [
                                        _buildReferralsTab(referrals),
                                        _buildTransactionsTab(transactions),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _ruleRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF10B981)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.3)),
        ),
      ],
    );
  }

  Future<void> _callPhone(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return;
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _chatShopWhatsApp(String phone, String shopName) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return;
    final formatted = clean.length == 10 ? '91$clean' : clean;
    final msg = Uri.encodeComponent('Hello $shopName, greeting from Mobile Repair Hub!');
    final uri = Uri.parse('https://wa.me/$formatted?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showShopPaymentsSheet(BuildContext context, Map<String, dynamic> shop) {
    final payments = shop['payments'] is List ? (shop['payments'] as List) : [];
    final totalComm = _toDouble(shop['total_commission_earned'] ?? shop['points_earned']);
    final planStatus = (shop['plan_status'] ?? 'Active').toString();
    final phone = (shop['phone'] ?? '').toString();
    final city = (shop['city'] ?? 'Not Specified').toString();
    final ownerName = (shop['owner_name'] ?? 'Shop Owner').toString();
    final shopName = (shop['shop_name'] ?? 'Shop').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header with Shop Details
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primary.withOpacity(0.12),
                              child: Text(
                                shopName.isNotEmpty ? shopName[0].toUpperCase() : 'S',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shopName,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Owner: $ownerName • $city',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Contact Buttons & Status Badges
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: planStatus.toLowerCase().contains('active')
                                    ? const Color(0xFF10B981).withOpacity(0.12)
                                    : Colors.orange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: planStatus.toLowerCase().contains('active')
                                      ? const Color(0xFF10B981).withOpacity(0.3)
                                      : Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                planStatus,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: planStatus.toLowerCase().contains('active')
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFD97706),
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (phone.isNotEmpty) ...[
                              InkWell(
                                onTap: () => _callPhone(phone),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.phone, size: 14, color: AppColors.primary),
                                      SizedBox(width: 4),
                                      Text('Call', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _chatShopWhatsApp(phone, shopName),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.chat_bubble_outline, size: 14, color: Color(0xFF16A34A)),
                                      SizedBox(width: 4),
                                      Text('WhatsApp', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // KPI Summary Banner
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Commission Earned',
                              style: TextStyle(fontSize: 11, color: Color(0xFF15803D), fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '+${totalComm.toStringAsFixed(2)} pts (₹${totalComm.toStringAsFixed(2)})',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Text(
                            '${payments.length} Payments',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Divider(height: 1),

                  // Payments List
                  Expanded(
                    child: payments.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'No payments made by this shop yet.',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'When this shop recharges their subscription plan, all payment details and your commission will appear here.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: payments.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final p = Map<String, dynamic>.from(payments[i]);
                              final pAmount = _toDouble(p['amount']);
                              final pComm = _toDouble(p['commission_earned']);
                              final pPercent = p['commission_percent'] != null ? _toDouble(p['commission_percent']) : null;
                              final pTitle = (p['title'] ?? 'Subscription').toString();
                              final pDate = (p['date'] ?? '').toString();
                              final pMethod = (p['payment_method'] ?? 'Online').toString();

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            pTitle,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                          ),
                                        ),
                                        Text(
                                          pAmount > 0 ? '₹${pAmount.toStringAsFixed(2)}' : 'Free Reward',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '$pDate • $pMethod',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Success',
                                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Commission Ribbon
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0FDF4),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFDCFCE7)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            pPercent != null
                                                ? 'Referral Commission (${pPercent.toStringAsFixed(0)}%)'
                                                : 'Referral Bonus',
                                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                                          ),
                                          Text(
                                            '+${pComm.toStringAsFixed(2)} pts Credited',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReferralsTab(List<dynamic> referrals) {
    if (referrals.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storefront_outlined, size: 40, color: AppColors.textMuted),
              SizedBox(height: 8),
              Text(
                'No shops referred yet.\nShare your code to start earning points!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: referrals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, idx) {
        final item = Map<String, dynamic>.from(referrals[idx]);
        final totalEarned = _toDouble(item['total_commission_earned'] ?? item['points_earned']);
        final shopName = (item['shop_name'] ?? 'Shop').toString();
        final ownerName = (item['owner_name'] ?? 'Shop Owner').toString();
        final city = (item['city'] ?? '').toString();
        final hasCity = city.isNotEmpty && city.toLowerCase() != 'not specified';
        final phone = (item['phone'] ?? '').toString();
        final planStatus = (item['plan_status'] ?? 'Active').toString();
        final joinedAt = (item['joined_at'] ?? '').toString();
        final lastPayment = item['last_payment'] is Map ? Map<String, dynamic>.from(item['last_payment']) : null;
        final payments = item['payments'] is List ? (item['payments'] as List) : [];

        final isPlanActive = planStatus.toLowerCase().contains('active');
        final isSignupOnly = lastPayment != null && (lastPayment['type'] == 'signup_bonus' || _toDouble(lastPayment['amount']) == 0);
        final hasRecharge = lastPayment != null && !isSignupOnly && _toDouble(lastPayment['amount']) > 0;

        return InkWell(
          onTap: () => _showShopPaymentsSheet(context, item),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Shop Avatar, Shop Name, Owner & Plan Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFEEF2FF),
                      child: Text(
                        shopName.isNotEmpty ? shopName[0].toUpperCase() : 'S',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF4F46E5), fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shopName,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                'Owner: $ownerName',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                              ),
                              if (hasCity) ...[
                                Text(' • ', style: TextStyle(color: Colors.grey.shade400)),
                                Flexible(
                                  child: Text(
                                    city,
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isPlanActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isPlanActive ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPlanActive ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            planStatus,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isPlanActive ? const Color(0xFF166534) : const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Contact Strip (Phone + Call + WhatsApp)
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.phone_iphone_rounded, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        phone,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      // Call button
                      InkWell(
                        onTap: () => _callPhone(phone),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.phone, size: 12, color: Color(0xFF2563EB)),
                              SizedBox(width: 4),
                              Text('Call', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // WhatsApp button
                      InkWell(
                        onTap: () => _chatShopWhatsApp(phone, shopName),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              WhatsAppIcon(size: 13),
                              SizedBox(width: 4),
                              Text('WhatsApp', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 10),

                // Highlights / Commission Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                  decoration: BoxDecoration(
                    color: hasRecharge
                        ? const Color(0xFFF0FDF4)
                        : (isSignupOnly ? const Color(0xFFFEFCE8) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasRecharge
                          ? const Color(0xFFDCFCE7)
                          : (isSignupOnly ? const Color(0xFFFEF08A) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: hasRecharge
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.bolt_rounded, size: 15, color: Color(0xFF16A34A)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Last Recharge: ₹${_toDouble(lastPayment['amount']).toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF166534)),
                                    ),
                                  ],
                                ),
                                Text(
                                  (lastPayment['date'] ?? '').toString(),
                                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Plan: ${lastPayment['plan_name']}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                ),
                                if (_toDouble(lastPayment['commission_earned']) > 0) ...[
                                  Builder(builder: (_) {
                                    final commVal = _toDouble(lastPayment['commission_earned']);
                                    final pVal = lastPayment['commission_percent'];
                                    final hasP = pVal != null && pVal.toString().toLowerCase() != 'null' && (num.tryParse(pVal.toString()) ?? 0) > 0;
                                    return Text(
                                      '+₹${commVal.toStringAsFixed(2)}${hasP ? ' ($pVal%)' : ''} Commission',
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                                    );
                                  }),
                                ],
                              ],
                            ),
                          ],
                        )
                      : (isSignupOnly
                          ? Row(
                              children: [
                                const Text('🎁', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '+${_toDouble(lastPayment['commission_earned']).toStringAsFixed(0)} Points Signup Reward Credited!',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF854D0E)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Joined ${lastPayment['date'] ?? joinedAt} • Awaiting subscription recharge',
                                        style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Icon(Icons.info_outline_rounded, size: 15, color: Colors.grey.shade500),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Joined ${joinedAt.isNotEmpty ? joinedAt : 'recently'} • Awaiting first subscription recharge',
                                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                                  ),
                                ),
                              ],
                            )),
                ),

                const SizedBox(height: 10),

                // Footer Row: Total Commission + View Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars_rounded, size: 14, color: Color(0xFF16A34A)),
                          const SizedBox(width: 4),
                          Text(
                            'Total: +${totalEarned.toStringAsFixed(0)} pts (₹${totalEarned.toStringAsFixed(0)})',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          payments.isNotEmpty ? 'View Payments (${payments.length})' : 'View Payments',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.primary),
                      ],
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

  Widget _buildTransactionsTab(List<dynamic> transactions) {
    if (transactions.isEmpty) {
      return const Center(
        child: Text(
          'No points transactions yet.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, idx) {
        final tx = Map<String, dynamic>.from(transactions[idx]);
        final isCredit = tx['type'] == 'credit';
        final pts = _toDouble(tx['points']);
        final bal = _toDouble(tx['balance_after']);
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            backgroundColor: (isCredit ? AppColors.success : AppColors.error).withOpacity(0.1),
            child: Icon(
              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isCredit ? AppColors.success : AppColors.error,
              size: 18,
            ),
          ),
          title: Text(tx['description'] ?? '', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          subtitle: Text('${tx['date'] ?? ''} • Bal: ${bal.toStringAsFixed(2)} pts', style: const TextStyle(fontSize: 11)),
          trailing: Text(
            '${isCredit ? '+' : '-'}${pts.toStringAsFixed(2)}',
            style: TextStyle(
              color: isCredit ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.bold,
              fontSize: 13.5,
            ),
          ),
        );
      },
    );
  }
}

