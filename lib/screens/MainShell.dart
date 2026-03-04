import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:platinum_next_episode/constants/app_theme.dart';
import 'package:platinum_next_episode/screens/ExploreScreen.dart';
import 'package:platinum_next_episode/screens/HomeScreen.dart';
import 'package:platinum_next_episode/screens/ProfileScreen.dart';
import 'package:platinum_next_episode/screens/WatchlistScreen.dart';

// ─────────────────────────────────────────────
//  MAIN SHELL  —  owns the bottom navigation
//  and lazily builds each tab.
// ─────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({Key? key}) : super(key: key);

  @override
  State<MainShell> createState() => MainShellState();

  /// Allow child screens to jump to a tab without a Navigator push.
  static MainShellState of(BuildContext context) =>
      context.findAncestorStateOfType<MainShellState>()!;
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void jumpToTab(int index) => setState(() => _currentIndex = index);

  static const _navItems = [
    _NavItem(icon: Icons.home_rounded,     label: 'Home'),
    _NavItem(icon: Icons.explore_rounded,  label: 'Explore'),
    _NavItem(icon: Icons.bookmark_rounded, label: 'Watchlist'),
    _NavItem(icon: Icons.person_rounded,   label: 'Profile'),
  ];

  // Keep all pages alive while switching tabs.
  static final _pages = [
    const HomeScreen(),
    const ExploreScreen(),
    const WatchlistScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppColors.bg,
      // IndexedStack keeps every tab's state alive.
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BOTTOM NAV WIDGET
// ─────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final selected = i == currentIndex;
          final item = items[i];
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.accentSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    color: selected ? AppColors.accent : AppColors.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: selected ? AppColors.accent : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}