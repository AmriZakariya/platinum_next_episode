import 'package:flutter/material.dart';
import 'package:platinum_next_episode/constants/app_theme.dart';
import 'package:platinum_next_episode/screens/EpisodeScrollerScreen.dart';
import 'package:platinum_next_episode/services/ApiService.dart';
import '../models/models.dart';
// ─────────────────────────────────────────────
//  WATCHLIST SCREEN
// ─────────────────────────────────────────────
class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({Key? key}) : super(key: key);

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  late Future<List<Series>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.instance.fetchWatchlist();
  }

  Future<void> _refresh() async {
    setState(() => _future = ApiService.instance.fetchWatchlist());
  }

  void _open(Series s) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EpisodeScrollerScreen(seriesId: s.id, seriesTitle: s.title),
    ));
  }

  Future<void> _remove(String seriesId) async {
    await ApiService.instance.removeFromWatchlist(seriesId);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(children: [
                const Text('Watchlist', style: TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(10)),
                  child: const Text('Saved', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: FutureBuilder<List<Series>>(
                future: _future,
                builder: (_, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2));
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error loading watchlist', style: const TextStyle(color: AppColors.textSecondary)));
                  }
                  final list = snap.data!;
                  if (list.isEmpty) return _buildEmpty();
                  return RefreshIndicator(
                    color: AppColors.accent,
                    backgroundColor: AppColors.surface,
                    onRefresh: _refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _WatchlistTile(
                        series: list[i],
                        onTap:   () => _open(list[i]),
                        onRemove: () => _remove(list[i].id),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
            child: const Icon(Icons.bookmark_border_rounded, color: AppColors.accent, size: 38),
          ),
          const SizedBox(height: 16),
          const Text('No series saved yet', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Tap the bookmark icon on any series\nto add it here.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _WatchlistTile extends StatelessWidget {
  final Series series;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const _WatchlistTile({required this.series, required this.onTap, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.star_rounded, size: 12, color: AppColors.gold),
                    const SizedBox(width: 3),
                    Text(series.rating.toString(), style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ],
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.bookmark_remove_rounded, color: AppColors.accent, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}