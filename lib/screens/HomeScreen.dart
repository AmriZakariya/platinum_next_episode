import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
class AppColors {
  static const bg = Color(0xFF0A0A0F);
  static const surface = Color(0xFF13131A);
  static const surfaceElevated = Color(0xFF1C1C27);
  static const accent = Color(0xFFE63946);
  static const accentSoft = Color(0x33E63946);
  static const gold = Color(0xFFFFB703);
  static const textPrimary = Color(0xFFF1F1F5);
  static const textSecondary = Color(0xFF8A8A9A);
  static const divider = Color(0xFF2A2A38);
}

class AppText {
  static const headline = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
  static const sectionTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );
  static const caption = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
  static const chip = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
}

// ─────────────────────────────────────────────
//  MOCK DATA
// ─────────────────────────────────────────────
final List<Map<String, dynamic>> _categories = [
  {'label': 'All', 'icon': Icons.apps_rounded},
  {'label': 'Action', 'icon': Icons.local_fire_department_rounded},
  {'label': 'Drama', 'icon': Icons.theater_comedy_rounded},
  {'label': 'Thriller', 'icon': Icons.remove_red_eye_rounded},
  {'label': 'Sci-Fi', 'icon': Icons.rocket_launch_rounded},
  {'label': 'Romance', 'icon': Icons.favorite_rounded},
  {'label': 'Horror', 'icon': Icons.nightlight_rounded},
  {'label': 'Comedy', 'icon': Icons.sentiment_very_satisfied_rounded},
];

final List<Map<String, String>> _top10 = [
  {'title': 'Neon Abyss', 'genre': 'Sci-Fi', 'rating': '9.4', 'episodes': '24', 'color': '0xFF1A0533'},
  {'title': 'Iron Veil', 'genre': 'Action', 'rating': '9.1', 'episodes': '18', 'color': '0xFF1A1500'},
  {'title': 'Crimson Hour', 'genre': 'Thriller', 'rating': '8.9', 'episodes': '12', 'color': '0xFF1A0000'},
  {'title': 'Silent Shore', 'genre': 'Drama', 'rating': '8.7', 'episodes': '30', 'color': '0xFF001A1A'},
  {'title': 'Phantom Gate', 'genre': 'Horror', 'rating': '8.5', 'episodes': '10', 'color': '0xFF0D001A'},
];

final List<Map<String, String>> _continueWatching = [
  {'title': 'Neon Abyss', 'episode': 'S2 E7', 'progress': '0.65', 'color': '0xFF1A0533'},
  {'title': 'Iron Veil', 'episode': 'S1 E4', 'progress': '0.3', 'color': '0xFF1A1500'},
  {'title': 'Crimson Hour', 'episode': 'S1 E11', 'progress': '0.85', 'color': '0xFF1A0000'},
];

// ─────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategory = 0;
  int _navIndex = 0;
  final _searchController = TextEditingController();
  bool _searchFocused = false;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverHeader(),
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildCategoryRow()),
            SliverToBoxAdapter(child: _buildFeaturedBanner()),
            SliverToBoxAdapter(child: _buildSectionHeader('Continue Watching', 'See all')),
            SliverToBoxAdapter(child: _buildContinueWatching()),
            SliverToBoxAdapter(child: _buildSectionHeader('Top 10 Today', 'Rankings')),
            SliverToBoxAdapter(child: _buildTop10()),
            SliverToBoxAdapter(child: _buildSectionHeader('New Releases', 'See all')),
            SliverToBoxAdapter(child: _buildNewReleases()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Header ────────────────────────────────
  Widget _buildSliverHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
        child: Row(
          children: [
            // Logo
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 8),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Series',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: 'Flix',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Points pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: AppColors.gold, size: 16),
                  const SizedBox(width: 4),
                  const Text('42 pts',
                      style: TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Avatar
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent, width: 2),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C3DD8), Color(0xFFE63946)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Text('JD',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search Bar ────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _searchFocused ? AppColors.accent : AppColors.divider,
            width: 1.5,
          ),
          boxShadow: _searchFocused
              ? [BoxShadow(color: AppColors.accentSoft, blurRadius: 12)]
              : [],
        ),
        child: Focus(
          onFocusChange: (f) => setState(() => _searchFocused = f),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Search series, genres...',
              hintStyle: AppText.caption.copyWith(fontSize: 15),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.textSecondary, size: 22),
              suffixIcon: const Icon(Icons.tune_rounded,
                  color: AppColors.textSecondary, size: 20),
              border: InputBorder.none,
              contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            ),
          ),
        ),
      ),
    );
  }

  // ── Categories ────────────────────────────
  Widget _buildCategoryRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const BouncingScrollPhysics(),
          itemCount: _categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final selected = i == _selectedCategory;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.accent : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                    selected ? AppColors.accent : AppColors.divider,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _categories[i]['icon'] as IconData,
                      size: 14,
                      color: selected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _categories[i]['label'] as String,
                      style: AppText.chip.copyWith(
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Featured Banner ───────────────────────
  Widget _buildFeaturedBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background gradient
            Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A0030), Color(0xFF0D0A1E), Color(0xFF1A0010)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Decorative circles
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withOpacity(0.15),
                ),
              ),
            ),
            Positioned(
              right: 20,
              top: 10,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6C3DD8).withOpacity(0.2),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.accent.withOpacity(0.5)),
                    ),
                    child: const Text('🔥 FEATURED',
                        style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Neon Abyss',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.gold, size: 15),
                      const SizedBox(width: 4),
                      const Text('9.4',
                          style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(width: 12),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 12),
                      const Text('Sci-Fi · 24 Episodes',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _buildAccentButton(
                        icon: Icons.play_arrow_rounded,
                        label: 'Watch Now',
                        onTap: () {},
                      ),
                      const SizedBox(width: 10),
                      _buildOutlineButton(
                        icon: Icons.add_rounded,
                        label: 'Watchlist',
                        onTap: () {},
                      ),
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

  Widget _buildAccentButton(
      {required IconData icon,
        required String label,
        required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlineButton(
      {required IconData icon,
        required String label,
        required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ── Section Header ────────────────────────
  Widget _buildSectionHeader(String title, String action) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(title, style: AppText.sectionTitle),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: Text(action,
                style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Continue Watching ─────────────────────
  Widget _buildContinueWatching() {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: _continueWatching.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final item = _continueWatching[i];
          final progress = double.parse(item['progress']!);
          return Container(
            width: 240,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // BG
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(int.parse(item['color']!)),
                          AppColors.surface
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(item['title']!,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accentSoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(item['episode']!,
                                  style: const TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            )
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    '${(progress * 100).toInt()}% watched',
                                    style: AppText.caption),
                                const Icon(Icons.play_circle_filled_rounded,
                                    color: AppColors.accent, size: 28),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: AppColors.divider,
                                valueColor: const AlwaysStoppedAnimation(
                                    AppColors.accent),
                                minHeight: 4,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Top 10 ────────────────────────────────
  Widget _buildTop10() {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: _top10.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final item = _top10[i];
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [
                      Color(int.parse(item['color']!)),
                      AppColors.surface
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border.all(color: AppColors.divider),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      // Decorative circle
                      Positioned(
                        top: -20,
                        right: -20,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.04),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Rating badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.gold.withOpacity(0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded,
                                      size: 12, color: AppColors.gold),
                                  const SizedBox(width: 4),
                                  Text(item['rating']!,
                                      style: const TextStyle(
                                          color: AppColors.gold,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(item['title']!,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                            const SizedBox(height: 4),
                            Text(
                                '${item['genre']} · ${item['episodes']} eps',
                                style: AppText.caption),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding:
                              const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_arrow_rounded,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text('Watch',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Rank badge
              Positioned(
                top: -8,
                left: -8,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: i == 0 ? AppColors.gold : AppColors.surfaceElevated,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: i == 0
                            ? AppColors.gold
                            : AppColors.divider,
                        width: 2),
                  ),
                  child: Center(
                    child: Text('#${i + 1}',
                        style: TextStyle(
                            color:
                            i == 0 ? AppColors.bg : AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── New Releases (vertical list peek) ────
  Widget _buildNewReleases() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(3, (i) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                // Thumbnail placeholder
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        Color(int.parse(_top10[i]['color']!)),
                        AppColors.surfaceElevated
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.play_circle_outline_rounded,
                      color: Colors.white54, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_top10[i]['title']!,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(
                          '${_top10[i]['genre']} · ${_top10[i]['episodes']} Episodes',
                          style: AppText.caption),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 13, color: AppColors.gold),
                          const SizedBox(width: 3),
                          Text(_top10[i]['rating']!,
                              style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentSoft,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('NEW',
                                style: TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Bottom Nav ────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.explore_rounded, 'label': 'Explore'},
      {'icon': Icons.bookmark_rounded, 'label': 'Watchlist'},
      {'icon': Icons.person_rounded, 'label': 'Profile'},
    ];

    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 8, top: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final selected = i == _navIndex;
          return GestureDetector(
            onTap: () => setState(() => _navIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.accentSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(items[i]['icon'] as IconData,
                      color: selected
                          ? AppColors.accent
                          : AppColors.textSecondary,
                      size: 24),
                  const SizedBox(height: 4),
                  Text(items[i]['label'] as String,
                      style: TextStyle(
                          color: selected
                              ? AppColors.accent
                              : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}