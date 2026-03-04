import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:platinum_next_episode/constants/app_theme.dart';
import 'package:platinum_next_episode/screens/EpisodeScrollerScreen.dart';
import 'package:platinum_next_episode/screens/MainShell.dart';
import 'package:platinum_next_episode/services/ApiService.dart';

import '../models/models.dart';

// ─────────────────────────────────────────────
//  CATEGORY DEFINITIONS
// ─────────────────────────────────────────────
final _categories = [
  {'label': 'All',     'icon': Icons.apps_rounded},
  {'label': 'Action',  'icon': Icons.local_fire_department_rounded},
  {'label': 'Drama',   'icon': Icons.theater_comedy_rounded},
  {'label': 'Thriller','icon': Icons.remove_red_eye_rounded},
  {'label': 'Sci-Fi',  'icon': Icons.rocket_launch_rounded},
  {'label': 'Romance', 'icon': Icons.favorite_rounded},
  {'label': 'Horror',  'icon': Icons.nightlight_rounded},
  {'label': 'Comedy',  'icon': Icons.sentiment_very_satisfied_rounded},
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
  // ── State ────────────────────────────────
  int _selectedCategory = 0;
  final _searchController = TextEditingController();
  bool _searchFocused = false;

  // ── API data futures ───────────────────
  late Future<Series>                   _featuredFuture;
  late Future<List<Series>>             _top10Future;
  late Future<List<Series>>             _newReleasesFuture;
  late Future<List<ContinueWatchingItem>> _continueFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final api = ApiService.instance;
    _featuredFuture      = api.fetchFeaturedSeries();
    _top10Future         = api.fetchTop10();
    _newReleasesFuture   = api.fetchNewReleases();
    _continueFuture      = api.fetchContinueWatching();
  }

  void _onCategoryChanged(int index) {
    setState(() {
      _selectedCategory = index;
      final cat = _categories[index]['label'] as String;
      _top10Future       = cat == 'All'
          ? ApiService.instance.fetchTop10()
          : ApiService.instance.fetchByCategory(cat);
      _newReleasesFuture = cat == 'All'
          ? ApiService.instance.fetchNewReleases()
          : ApiService.instance.fetchByCategory(cat);
    });
  }

  // ── Navigation helpers ────────────────
  void _openSeries(Series series, {int startIndex = 0}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EpisodeScrollerScreen(
        seriesId:    series.id,
        seriesTitle: series.title,
        startIndex:  startIndex,
      ),
    ));
  }

  void _goToProfile() => MainShell.of(context).jumpToTab(3);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            setState(() => _loadData());
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: _buildCategoryRow()),
              // Featured banner
              SliverToBoxAdapter(
                child: FutureBuilder<Series>(
                  future: _featuredFuture,
                  builder: (_, snap) {
                    if (snap.hasData) return _buildFeaturedBanner(snap.data!);
                    if (snap.hasError) return _errorTile('Could not load featured');
                    return _buildFeaturedSkeleton();
                  },
                ),
              ),
              // Continue watching
              SliverToBoxAdapter(child: _buildSectionHeader('Continue Watching', 'See all', onTap: () {})),
              SliverToBoxAdapter(
                child: FutureBuilder<List<ContinueWatchingItem>>(
                  future: _continueFuture,
                  builder: (_, snap) {
                    if (snap.hasData) return _buildContinueWatching(snap.data!);
                    if (snap.hasError) return _errorTile('Could not load history');
                    return _buildHorizontalSkeleton(height: 120, width: 240);
                  },
                ),
              ),
              // Top 10
              SliverToBoxAdapter(child: _buildSectionHeader('Top 10 Today', 'Rankings', onTap: () {})),
              SliverToBoxAdapter(
                child: FutureBuilder<List<Series>>(
                  future: _top10Future,
                  builder: (_, snap) {
                    if (snap.hasData) return _buildTop10(snap.data!);
                    if (snap.hasError) return _errorTile('Could not load top 10');
                    return _buildHorizontalSkeleton(height: 220, width: 150);
                  },
                ),
              ),
              // New releases
              SliverToBoxAdapter(child: _buildSectionHeader('New Releases', 'See all', onTap: () {})),
              SliverToBoxAdapter(
                child: FutureBuilder<List<Series>>(
                  future: _newReleasesFuture,
                  builder: (_, snap) {
                    if (snap.hasData) return _buildNewReleases(snap.data!);
                    if (snap.hasError) return _errorTile('Could not load new releases');
                    return _buildListSkeleton(count: 3);
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
      child: Row(
        children: [
          // Logo
          Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(children: [
                TextSpan(text: 'Series', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                TextSpan(text: 'Flix',   style: TextStyle(color: AppColors.accent,      fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              ]),
            ),
          ]),
          const Spacer(),
          // Points pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withOpacity(0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.bolt_rounded, color: AppColors.gold, size: 16),
              SizedBox(width: 4),
              Text('42 pts', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          ),
          const SizedBox(width: 10),
          // Avatar → Profile tab
          GestureDetector(
            onTap: _goToProfile,
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent, width: 2),
                gradient: const LinearGradient(colors: [Color(0xFF6C3DD8), Color(0xFFE63946)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: const Center(child: Text('JD', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Search bar ───────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _searchFocused ? AppColors.accent : AppColors.divider, width: 1.5),
          boxShadow: _searchFocused ? [const BoxShadow(color: AppColors.accentSoft, blurRadius: 12)] : [],
        ),
        child: Focus(
          onFocusChange: (f) => setState(() => _searchFocused = f),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            onSubmitted: (q) {
              if (q.trim().isNotEmpty) {
                // TODO: navigate to a SearchResultsScreen(query: q)
                ApiService.instance.search(q);
              }
            },
            decoration: InputDecoration(
              hintText: 'Search series, genres...',
              hintStyle: AppText.caption.copyWith(fontSize: 15),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 22),
              suffixIcon: const Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Categories ───────────────────────────
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
          itemBuilder: (_, i) {
            final selected = i == _selectedCategory;
            return GestureDetector(
              onTap: () => _onCategoryChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.accent : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? AppColors.accent : AppColors.divider),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_categories[i]['icon'] as IconData, size: 14, color: selected ? Colors.white : AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(_categories[i]['label'] as String, style: AppText.chip.copyWith(color: selected ? Colors.white : AppColors.textSecondary)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Featured banner ─────────────────────
  Widget _buildFeaturedBanner(Series series) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GestureDetector(
        onTap: () => _openSeries(series),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [series.bgColor, const Color(0xFF0D0A1E), const Color(0xFF1A0010)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
              ),
              // Decorative circles
              Positioned(right: -30, top: -30,
                  child: Container(width: 160, height: 160, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent.withOpacity(0.15)))),
              Positioned(right: 20, top: 10,
                  child: Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.purple.withOpacity(0.2)))),
              // Content
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.accent.withOpacity(0.5))),
                      child: const Text('🔥 FEATURED', style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    ),
                    const SizedBox(height: 12),
                    Text(series.title, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.star_rounded, color: AppColors.gold, size: 15),
                      const SizedBox(width: 4),
                      Text(series.rating.toString(), style: const TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 12),
                      Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.textSecondary)),
                      const SizedBox(width: 12),
                      Text('${series.genre} · ${series.episodeCount} Episodes', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ]),
                    const SizedBox(height: 18),
                    Row(children: [
                      _accentBtn(Icons.play_arrow_rounded, 'Watch Now', () => _openSeries(series)),
                      const SizedBox(width: 10),
                      _outlineBtn(Icons.add_rounded, 'Watchlist', () => ApiService.instance.addToWatchlist(series.id)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedSkeleton() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
    child: _skeleton(height: 200, radius: 20),
  );

  // ─── Section header ───────────────────────
  Widget _buildSectionHeader(String title, String action, {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
      child: Row(children: [
        Container(width: 3, height: 18, decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title, style: AppText.sectionTitle),
        const Spacer(),
        GestureDetector(
          onTap: onTap,
          child: Text(action, style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  // ─── Continue Watching ────────────────────
  Widget _buildContinueWatching(List<ContinueWatchingItem> items) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final item = items[i];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => EpisodeScrollerScreen(
                seriesId:    item.seriesId,
                seriesTitle: item.seriesTitle,
                startIndex:  item.episodeIndex,
              ),
            )),
            child: Container(
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
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [item.bgColor, AppColors.surface], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(child: Text(item.seriesTitle, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(6)),
                              child: Text(item.episodeLabel, style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ]),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${(item.progress * 100).toInt()}% watched', style: AppText.caption),
                                  const Icon(Icons.play_circle_filled_rounded, color: AppColors.accent, size: 28),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: item.progress,
                                  backgroundColor: AppColors.divider,
                                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
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
            ),
          );
        },
      ),
    );
  }

  // ─── Top 10 ───────────────────────────────
  Widget _buildTop10(List<Series> items) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final series = items[i];
          return Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () => _openSeries(series),
                child: Container(
                  width: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(colors: [series.bgColor, AppColors.surface], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        Positioned(top: -20, right: -20, child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.04)))),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.gold.withOpacity(0.4))),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.star_rounded, size: 12, color: AppColors.gold),
                                  const SizedBox(width: 4),
                                  Text(series.rating.toString(), style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w700)),
                                ]),
                              ),
                              const Spacer(),
                              Text(series.title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text('${series.genre} · ${series.episodeCount} eps', style: AppText.caption),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () => _openSeries(series),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                                      SizedBox(width: 4),
                                      Text('Watch', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Rank badge
              Positioned(
                top: -8, left: -8,
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: i == 0 ? AppColors.gold : AppColors.surfaceElevated,
                    shape: BoxShape.circle,
                    border: Border.all(color: i == 0 ? AppColors.gold : AppColors.divider, width: 2),
                  ),
                  child: Center(child: Text('#${i + 1}', style: TextStyle(color: i == 0 ? AppColors.bg : AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w800))),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── New Releases ─────────────────────────
  Widget _buildNewReleases(List<Series> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: items.take(5).map((series) {
          return GestureDetector(
            onTap: () => _openSeries(series),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(colors: [series.bgColor, AppColors.surfaceElevated], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                    child: const Icon(Icons.play_circle_outline_rounded, color: Colors.white54, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(series.title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('${series.genre} · ${series.episodeCount} Episodes', style: AppText.caption),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.star_rounded, size: 13, color: AppColors.gold),
                          const SizedBox(width: 3),
                          Text(series.rating.toString(), style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(4)),
                            child: const Text('NEW', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Skeleton loaders ─────────────────────
  Widget _buildHorizontalSkeleton({required double height, required double width}) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => _skeleton(height: height, width: width, radius: 16),
      ),
    );
  }

  Widget _buildListSkeleton({required int count}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(count, (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _skeleton(height: 90, radius: 16),
        )),
      ),
    );
  }

  Widget _skeleton({required double height, double? width, double radius = 12}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _errorTile(String msg) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: Text(msg, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
  );

  // ─── Button helpers ───────────────────────
  Widget _accentBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _outlineBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.2))),
        child: Row(children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
    );
  }
}