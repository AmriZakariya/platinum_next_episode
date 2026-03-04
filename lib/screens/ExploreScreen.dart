import 'package:flutter/material.dart';
import 'package:platinum_next_episode/constants/app_theme.dart';
import 'package:platinum_next_episode/models/models.dart';
import 'package:platinum_next_episode/screens/EpisodeScrollerScreen.dart';
import 'package:platinum_next_episode/services/ApiService.dart';

// ─────────────────────────────────────────────
//  EXPLORE SCREEN
// ─────────────────────────────────────────────
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _ctrl = TextEditingController();
  bool _searching = false;
  List<Series>? _results;
  String _query = '';

  static const _genres = [
    {'label': 'Action',   'icon': Icons.local_fire_department_rounded, 'color': 0xFFE63946},
    {'label': 'Drama',    'icon': Icons.theater_comedy_rounded,         'color': 0xFF6C3DD8},
    {'label': 'Thriller', 'icon': Icons.remove_red_eye_rounded,         'color': 0xFFFFB703},
    {'label': 'Sci-Fi',   'icon': Icons.rocket_launch_rounded,          'color': 0xFF06D6A0},
    {'label': 'Romance',  'icon': Icons.favorite_rounded,               'color': 0xFFFF6B9D},
    {'label': 'Horror',   'icon': Icons.nightlight_rounded,             'color': 0xFF9B2335},
    {'label': 'Comedy',   'icon': Icons.sentiment_very_satisfied_rounded,'color': 0xFFFFB703},
    {'label': 'Crime',    'icon': Icons.gavel_rounded,                   'color': 0xFF4A4A6A},
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() { _results = null; _query = ''; });
      return;
    }
    setState(() { _searching = true; _query = q; });
    try {
      final res = await ApiService.instance.search(q);
      if (mounted) setState(() { _results = res; _searching = false; });
    } catch (_) {
      if (mounted) setState(() { _searching = false; });
    }
  }

  Future<void> _browseGenre(String genre) async {
    setState(() { _searching = true; _query = genre; _ctrl.text = genre; });
    try {
      final res = await ApiService.instance.fetchByCategory(genre);
      if (mounted) setState(() { _results = res; _searching = false; });
    } catch (_) {
      if (mounted) setState(() { _searching = false; });
    }
  }

  void _open(Series s) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EpisodeScrollerScreen(seriesId: s.id, seriesTitle: s.title),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─ header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: const Text('Explore', style: TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            ),
            // ─ search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider, width: 1.5),
                ),
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                  onSubmitted: _search,
                  onChanged: (v) { if (v.isEmpty) setState(() { _results = null; _query = ''; }); },
                  decoration: InputDecoration(
                    hintText: 'Search for series or genres...',
                    hintStyle: AppText.caption.copyWith(fontSize: 15),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 22),
                    suffixIcon: _ctrl.text.isNotEmpty
                        ? GestureDetector(
                      onTap: () { _ctrl.clear(); setState(() { _results = null; _query = ''; }); },
                      child: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                    )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // ─ body
            Expanded(
              child: _searching
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2))
                  : _results != null
                  ? _buildResults()
                  : _buildGenreGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Browse by Genre', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.8,
              ),
              itemCount: _genres.length,
              itemBuilder: (_, i) {
                final g = _genres[i];
                final color = Color(g['color'] as int);
                return GestureDetector(
                  onTap: () => _browseGenre(g['label'] as String),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(g['icon'] as IconData, color: color, size: 22),
                        const SizedBox(width: 8),
                        Text(g['label'] as String, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_results!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, color: AppColors.textSecondary, size: 48),
            const SizedBox(height: 12),
            Text('No results for "$_query"', style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: _results!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final s = _results![i];
        return GestureDetector(
          onTap: () => _open(s),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: [s.bgColor, AppColors.surfaceElevated], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                  child: const Icon(Icons.play_circle_outline_rounded, color: Colors.white54, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('${s.genre} · ${s.episodeCount} Episodes', style: AppText.caption),
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.star_rounded, size: 12, color: AppColors.gold),
                        const SizedBox(width: 3),
                        Text(s.rating.toString(), style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w700)),
                      ]),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        );
      },
    );
  }
}