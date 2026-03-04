import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:platinum_next_episode/constants/app_theme.dart';
import 'package:platinum_next_episode/providers/user_profile_provider.dart';
import 'package:platinum_next_episode/screens/MainShell.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────
//  PROFILE SCREEN
// ─────────────────────────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Consumer<UserProfileProvider>(
        builder: (context, profile, _) => CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, profile)),
            SliverToBoxAdapter(child: _buildPointsCard(context, profile)),
            SliverToBoxAdapter(child: _buildEarnSection(context, profile)),
            SliverToBoxAdapter(child: _buildStoreSection(context, profile)),
            SliverToBoxAdapter(child: _buildStatsRow(profile)),
            SliverToBoxAdapter(child: _buildSettingsSection(context, profile)),
            SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.bottom + 32)),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────
  Widget _buildHeader(BuildContext context, UserProfileProvider profile) {
    return Stack(
      children: [
        Container(
          height: 220,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF1A0533), Color(0xFF0A0A0F)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
        ),
        Positioned(top: -40, right: -40, child: _circle(200, AppColors.purple, 0.1)),
        Positioned(top: 20,  left: -60, child: _circle(160, AppColors.accent,  0.07)),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              children: [
                Row(
                  children: [
                    // Back → Home tab (no push/pop, just tab switch)
                    _iconBtn(Icons.arrow_back_ios_new_rounded, () => MainShell.of(context).jumpToTab(0)),
                    const Spacer(),
                    if (profile.isPremium) _premiumBadge(),
                    const SizedBox(width: 10),
                    _iconBtn(Icons.settings_rounded, () {}),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(colors: [AppColors.purple, AppColors.accent]),
                            border: Border.all(color: AppColors.accent, width: 2.5),
                          ),
                          child: const Center(child: Text('JD', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800))),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(width: 22, height: 22, decoration: BoxDecoration(color: AppColors.green, shape: BoxShape.circle, border: Border.all(color: AppColors.bg, width: 2))),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('John Doe', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          const Text('john.doe@email.com', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          const SizedBox(height: 8),
                          Row(children: [
                            _miniStat('${profile.watchHistory.length}', 'Watched'),
                            const SizedBox(width: 16),
                            _miniStat('${profile.totalPointsEarned}', 'Earned'),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _circle(double size, Color color, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(opacity)),
  );

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.12))),
      child: Icon(icon, color: Colors.white70, size: 18),
    ),
  );

  Widget _premiumBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.purple, AppColors.accent]), borderRadius: BorderRadius.circular(20)),
    child: const Row(children: [
      Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 14),
      SizedBox(width: 5),
      Text('PREMIUM', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    ]),
  );

  Widget _miniStat(String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
    ],
  );

  // ── Points card ───────────────────────────
  Widget _buildPointsCard(BuildContext context, UserProfileProvider profile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(width: 36, height: 36, decoration: const BoxDecoration(color: AppColors.goldSoft, shape: BoxShape.circle), child: const Icon(Icons.bolt_rounded, color: AppColors.gold, size: 20)),
                    const SizedBox(width: 10),
                    const Text('Your Balance', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ]),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${profile.points}', style: const TextStyle(color: AppColors.gold, fontSize: 52, fontWeight: FontWeight.w900, height: 1)),
                      const Padding(padding: EdgeInsets.only(bottom: 8, left: 6), child: Text('pts', style: TextStyle(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.w700))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profile.isPremium ? 'Unlimited access active ✓' : '${profile.points} episode${profile.points == 1 ? "" : "s"} available',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 80, height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: (profile.adsWatchedToday / UserProfileProvider.kMaxAdsPerDay).clamp(0.0, 1.0),
                    strokeWidth: 5,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${profile.adsWatchedToday}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                      const Text('ads today', style: TextStyle(color: AppColors.textSecondary, fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Earn section ──────────────────────────
  Widget _buildEarnSection(BuildContext context, UserProfileProvider profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Earn Points'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            _EarnCard(
              icon: Icons.ondemand_video_rounded, iconColor: AppColors.accent, bgColor: AppColors.accentSoft,
              title: 'Watch a Short Ad',
              subtitle: profile.canWatchAd ? 'Tap to earn 1 point instantly' : profile.dailyAdLimitReached ? 'Daily limit reached — come back tomorrow' : 'Loading ad...',
              badge: '+1 pt', badgeColor: AppColors.accent,
              isEnabled: profile.canWatchAd, isLoading: profile.isAdLoading,
              onTap: () => _onWatchAd(context, profile),
            ),
            const SizedBox(height: 10),
            _EarnCard(icon: Icons.calendar_today_rounded, iconColor: AppColors.green, bgColor: AppColors.greenSoft, title: 'Daily Check-In', subtitle: 'Claim 2 free points every day', badge: '+2 pts', badgeColor: AppColors.green, isEnabled: true, onTap: () {}),
            const SizedBox(height: 10),
            _EarnCard(icon: Icons.group_add_rounded, iconColor: AppColors.purple, bgColor: AppColors.purpleSoft, title: 'Invite a Friend', subtitle: 'Both of you get 5 bonus points', badge: '+5 pts', badgeColor: AppColors.purple, isEnabled: true, onTap: () {}),
          ]),
        ),
      ],
    );
  }

  // ── Store section ─────────────────────────
  Widget _buildStoreSection(BuildContext context, UserProfileProvider profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Buy Points'),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: kPointsPackages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _PointsPackageCard(package: kPointsPackages[i]),
          ),
        ),
        if (!profile.isPremium) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(colors: [Color(0xFF1A0533), Color(0xFF0D0020)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  border: Border.all(color: AppColors.purple.withOpacity(0.4)),
                ),
                child: Row(children: [
                  Container(width: 52, height: 52, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.purple, AppColors.accent]), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 26)),
                  const SizedBox(width: 14),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Go Premium', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                    SizedBox(height: 3),
                    Text(r'Unlimited episodes · No ads · $4.99/mo', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.purple, AppColors.accent]), borderRadius: BorderRadius.circular(10)),
                    child: const Text('Upgrade', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Stats row ─────────────────────────────
  Widget _buildStatsRow(UserProfileProvider profile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Row(children: [
        _StatTile(icon: Icons.bolt_rounded,             iconColor: AppColors.gold,          bgColor: AppColors.goldSoft,         label: 'Total Earned', value: '${profile.totalPointsEarned} pts'),
        const SizedBox(width: 10),
        _StatTile(icon: Icons.play_circle_outline_rounded, iconColor: AppColors.accent,     bgColor: AppColors.accentSoft,       label: 'Episodes',     value: '${profile.watchHistory.length}'),
        const SizedBox(width: 10),
        _StatTile(icon: Icons.ondemand_video_rounded,   iconColor: AppColors.textSecondary, bgColor: AppColors.surfaceElevated,  label: 'Ads Today',    value: '${profile.adsWatchedToday}/${UserProfileProvider.kMaxAdsPerDay}'),
      ]),
    );
  }

  // ── Settings ──────────────────────────────
  Widget _buildSettingsSection(BuildContext context, UserProfileProvider profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Account'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.divider)),
            child: Column(children: [
              _SettingsRow(icon: Icons.history_rounded,               label: 'Watch History',   onTap: () {}),
              const Divider(color: AppColors.divider, height: 1, indent: 56),
              _SettingsRow(icon: Icons.notifications_none_rounded,    label: 'Notifications',   onTap: () {}),
              const Divider(color: AppColors.divider, height: 1, indent: 56),
              _SettingsRow(icon: Icons.privacy_tip_outlined,          label: 'Privacy Policy',  onTap: () {}),
              const Divider(color: AppColors.divider, height: 1, indent: 56),
              _SettingsRow(icon: Icons.help_outline_rounded,          label: 'Help & Support',  onTap: () {}),
              const Divider(color: AppColors.divider, height: 1, indent: 56),
              _SettingsRow(icon: Icons.logout_rounded, label: 'Sign Out', labelColor: AppColors.accent, iconColor: AppColors.accent, showChevron: false, onTap: () => _showSignOutDialog(context)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
    child: Row(children: [
      Container(width: 3, height: 18, decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
    ]),
  );

  Future<void> _onWatchAd(BuildContext context, UserProfileProvider profile) async {
    final result = await profile.watchAdForPoints();
    if (!context.mounted) return;
    final msgs = {
      AdWatchResult.success:           ('🎉 +1 Point earned!',                        AppColors.green),
      AdWatchResult.skipped:           ('Ad skipped — no points awarded.',            AppColors.textSecondary),
      AdWatchResult.notReady:          ('Ad not ready yet. Try again shortly.',       AppColors.textSecondary),
      AdWatchResult.dailyLimitReached: ('Daily limit reached. Come back tomorrow!',  AppColors.gold),
      AdWatchResult.premiumUser:       ('You have unlimited access!',                 AppColors.purple),
    };
    final (msg, color) = msgs[result]!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to sign out?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Sign Out', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  EARN CARD
// ─────────────────────────────────────────────
class _EarnCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor, bgColor, badgeColor;
  final String title, subtitle, badge;
  final bool isEnabled, isLoading;
  final VoidCallback onTap;
  const _EarnCard({required this.icon, required this.iconColor, required this.bgColor, required this.title, required this.subtitle, required this.badge, required this.badgeColor, required this.isEnabled, required this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: isEnabled ? onTap : null,
    child: AnimatedOpacity(
      opacity: isEnabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isEnabled ? badgeColor.withOpacity(0.25) : AppColors.divider),
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: isLoading
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)))
                : Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 3),
            Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: badgeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: badgeColor.withOpacity(0.35))),
            child: Text(badge, style: TextStyle(color: badgeColor, fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ]),
      ),
    ),
  );
}

// ─────────────────────────────────────────────
//  POINTS PACKAGE CARD
// ─────────────────────────────────────────────
class _PointsPackageCard extends StatelessWidget {
  final PointsPackage package;
  const _PointsPackageCard({required this.package});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {},
    child: Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: package.isBestValue ? AppColors.gold.withOpacity(0.5) : AppColors.divider, width: package.isBestValue ? 1.5 : 1),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.goldSoft, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.bolt_rounded, color: AppColors.gold, size: 22)),
              const SizedBox(height: 12),
              Text('${package.points}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w900, height: 1)),
              const Text('points', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: package.isBestValue ? AppColors.gold : AppColors.accent, borderRadius: BorderRadius.circular(10)),
                child: Text(package.price, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          if (package.isBestValue)
            Positioned(
              top: -20, right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(8)),
                child: const Text('BEST', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
            ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────
//  STAT TILE
// ─────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor, bgColor;
  final String label, value;
  const _StatTile({required this.icon, required this.iconColor, required this.bgColor, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
      child: Column(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor, size: 18)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────
//  SETTINGS ROW
// ─────────────────────────────────────────────
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor, labelColor;
  final bool showChevron;
  final VoidCallback onTap;
  const _SettingsRow({required this.icon, required this.label, required this.onTap, this.iconColor = AppColors.textSecondary, this.labelColor = AppColors.textPrimary, this.showChevron = true});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: iconColor, size: 17)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(color: labelColor, fontSize: 14, fontWeight: FontWeight.w600))),
        if (showChevron) const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
      ]),
    ),
  );
}