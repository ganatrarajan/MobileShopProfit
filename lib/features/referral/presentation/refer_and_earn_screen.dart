import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
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
                                    height: 300,
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

  Widget _buildReferralsTab(List<dynamic> referrals) {
    if (referrals.isEmpty) {
      return const Center(
        child: Text(
          'No shops referred yet.\nShare your link to start earning points!',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: referrals.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, idx) {
        final item = Map<String, dynamic>.from(referrals[idx]);
        final earned = _toDouble(item['points_earned']);
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 18),
          ),
          title: Text(item['shop_name'] ?? 'Shop', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('Joined: ${item['joined_at'] ?? ''}', style: const TextStyle(fontSize: 12)),
          trailing: Text(
            '+${earned.toStringAsFixed(2)} pts',
            style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13),
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

