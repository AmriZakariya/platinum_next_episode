import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:platinum_next_episode/constants/app_theme.dart';
import 'package:platinum_next_episode/models/models.dart';
import 'package:platinum_next_episode/services/ApiService.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../providers/user_profile_provider.dart';

// ─────────────────────────────────────────────
//  EPISODE SCROLLER SCREEN
// ─────────────────────────────────────────────
class EpisodeScrollerScreen extends StatefulWidget {
  final String seriesId;
  final String seriesTitle;
  final int startIndex;

  const EpisodeScrollerScreen({
    Key? key,
    required this.seriesId,
    required this.seriesTitle,
    this.startIndex = 0,
  }) : super(key: key);

  @override
  State<EpisodeScrollerScreen> createState() => _EpisodeScrollerScreenState();
}

class _EpisodeScrollerScreenState extends State<EpisodeScrollerScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  // ── API ────────────────────────────────
  late Future<List<Episode>> _episodesFuture;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;
    _pageController = PageController(initialPage: widget.startIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _episodesFuture = ApiService.instance.fetchEpisodes(widget.seriesId);
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<List<Episode>>(
        future: _episodesFuture,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2));
          }
          if (snap.hasError || snap.data == null || snap.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.textSecondary, size: 48),
                  const SizedBox(height: 12),
                  const Text('Could not load episodes', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => setState(() => _episodesFuture = ApiService.instance.fetchEpisodes(widget.seriesId)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(12)),
                      child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            );
          }

          final episodes = snap.data!;
          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: episodes.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  if (index % 3 == 0 && index != 0) {
                    Provider.of<UserProfileProvider>(context, listen: false)
                        .showInterstitialIfReady();
                  }
                },
                itemBuilder: (_, index) => _EpisodePlayerPage(
                  key: ValueKey('episode_$index'),
                  episode: episodes[index],
                  seriesTitle: widget.seriesTitle,
                  isActive: index == _currentIndex,
                  onOutOfPoints: () => _showOutOfPointsSheet(context),
                  onShowComments: () => _showCommentsSheet(context),
                  onShowEpisodeList: () => _showEpisodeListSheet(context, episodes),
                ),
              ),
              Positioned(
                right: 6, top: 0, bottom: 0,
                child: Center(
                  child: _ScrollDots(total: episodes.length, current: _currentIndex),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showOutOfPointsSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _OutOfPointsSheet(
        onWatchAd: () async {
          Navigator.pop(ctx);
          await Provider.of<UserProfileProvider>(ctx, listen: false).watchAdForPoints();
        },
      ),
    );
  }

  void _showCommentsSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _CommentsSheet(),
    );
  }

  void _showEpisodeListSheet(BuildContext ctx, List<Episode> episodes) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EpisodeListSheet(
        episodes: episodes,
        currentIndex: _currentIndex,
        onSelect: (i) {
          Navigator.pop(ctx);
          _pageController.animateToPage(i, duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SINGLE EPISODE PLAYER PAGE
// ─────────────────────────────────────────────
class _EpisodePlayerPage extends StatefulWidget {
  final Episode episode;
  final String seriesTitle;
  final bool isActive;
  final VoidCallback onOutOfPoints;
  final VoidCallback onShowComments;
  final VoidCallback onShowEpisodeList;

  const _EpisodePlayerPage({
    Key? key,
    required this.episode,
    required this.seriesTitle,
    required this.isActive,
    required this.onOutOfPoints,
    required this.onShowComments,
    required this.onShowEpisodeList,
  }) : super(key: key);

  @override
  State<_EpisodePlayerPage> createState() => _EpisodePlayerPageState();
}

class _EpisodePlayerPageState extends State<_EpisodePlayerPage>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _vpc;
  bool _initialized = false;
  bool _isLocked = true;
  bool _showControls = true;
  bool _liked = false;
  bool _muted = false;
  Timer? _hideTimer;
  late AnimationController _heartAnim;

  @override
  void initState() {
    super.initState();
    _heartAnim = AnimationController(vsync: this, lowerBound: 0.8, upperBound: 1.3, duration: const Duration(milliseconds: 350));
    _initVideo();
  }

  Future<void> _initVideo() async {
    _vpc = VideoPlayerController.networkUrl(Uri.parse(widget.episode.videoUrl));
    try {
      await _vpc.initialize();
      _vpc.addListener(_videoListener);
      if (mounted) setState(() => _initialized = true);
      if (widget.isActive && !_isLocked && mounted) { _vpc.play(); _scheduleHide(); }
    } catch (e) {
      debugPrint('Video init error: $e');
    }
  }

  void _videoListener() {
    if (!mounted) return;
    setState(() {});
    if (_initialized && _vpc.value.position >= _vpc.value.duration && _vpc.value.duration > Duration.zero) {
      _vpc.seekTo(Duration.zero);
      _vpc.play();
    }
  }

  @override
  void didUpdateWidget(_EpisodePlayerPage old) {
    super.didUpdateWidget(old);
    if (!widget.isActive && _initialized && _vpc.value.isPlaying) _vpc.pause();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    if (_initialized) { _vpc.removeListener(_videoListener); _vpc.dispose(); }
    _heartAnim.dispose();
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _initialized && _vpc.value.isPlaying) setState(() => _showControls = false);
    });
  }

  void _onTapVideo() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHide();
  }

  void _togglePlayPause() {
    if (_isLocked) { _tryUnlock(); return; }
    if (!_initialized) return;
    if (_vpc.value.isPlaying) {
      _vpc.pause(); _hideTimer?.cancel(); setState(() => _showControls = true);
    } else {
      _vpc.play(); _scheduleHide();
    }
  }

  void _seekBy(int seconds) {
    if (!_initialized) return;
    final target  = _vpc.value.position + Duration(seconds: seconds);
    final clamped = Duration(milliseconds: target.inMilliseconds.clamp(0, _vpc.value.duration.inMilliseconds));
    _vpc.seekTo(clamped);
    _scheduleHide();
  }

  void _seekTo(double fraction) {
    if (!_initialized) return;
    _vpc.seekTo(Duration(milliseconds: (fraction * _vpc.value.duration.inMilliseconds).round()));
    _scheduleHide();
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _vpc.setVolume(_muted ? 0.0 : 1.0);
  }

  void _tryUnlock() {
    final profile = Provider.of<UserProfileProvider>(context, listen: false);
    final result  = profile.consumePoint();
    if (result == EpisodeUnlockResult.success) {
      setState(() => _isLocked = false);
      if (_initialized) { _vpc.play(); _scheduleHide(); }
      profile.recordWatched(
        seriesId: widget.episode.id,
        seriesTitle: widget.seriesTitle,
        episodeNumber: widget.episode.number,
        season: widget.episode.season,
      );
    } else {
      widget.onOutOfPoints();
    }
  }

  void _toggleLike() {
    setState(() => _liked = !_liked);
    if (_liked) _heartAnim.forward().then((_) => _heartAnim.reverse());
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final pos      = _initialized ? _vpc.value.position : Duration.zero;
    final dur      = _initialized ? _vpc.value.duration : Duration.zero;
    final progress = dur.inMilliseconds > 0
        ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: _onTapVideo,
          onDoubleTap: _toggleLike,
          child: Container(
            color: Colors.black,
            child: _initialized
                ? Center(child: AspectRatio(aspectRatio: _vpc.value.aspectRatio, child: VideoPlayer(_vpc)))
                : Container(
              decoration: BoxDecoration(gradient: LinearGradient(colors: [widget.episode.bgColor, Colors.black], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
              child: const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2)),
            ),
          ),
        ),
        _gradient(top: true),
        _gradient(top: false),
        AnimatedOpacity(
          opacity: _showControls ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: IgnorePointer(
            ignoring: !_showControls,
            child: Stack(children: [
              _buildTopBar(),
              _buildCenterControls(),
              _buildBottomPanel(pos, dur, progress),
            ]),
          ),
        ),
        _buildActionRail(),
        if (_isLocked) _buildLockOverlay(),
      ],
    );
  }

  Widget _gradient({required bool top}) => Positioned(
    top: top ? 0 : null, bottom: top ? null : 0, left: 0, right: 0,
    child: IgnorePointer(
      child: Container(
        height: top ? 160 : 300,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: top ? Alignment.topCenter : Alignment.bottomCenter,
            end:   top ? Alignment.bottomCenter : Alignment.topCenter,
            colors: top
                ? [const Color(0xCC000000), Colors.transparent]
                : [const Color(0xF0000000), const Color(0x80000000), Colors.transparent],
            stops: top ? null : [0, 0.55, 1],
          ),
        ),
      ),
    ),
  );

  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              _GlassBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.pop(context)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.seriesTitle.isEmpty ? 'SeriesFlix' : widget.seriesTitle,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    Text('S${widget.episode.season} · Episode ${widget.episode.number}',
                        style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: widget.onShowEpisodeList,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.list_rounded, color: Colors.white70, size: 18),
                    SizedBox(width: 6),
                    Text('Episodes', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    return Positioned.fill(
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SeekBtn(icon: Icons.replay_10_rounded, onTap: () => _seekBy(-10)),
            const SizedBox(width: 32),
            GestureDetector(
              onTap: _togglePlayPause,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 68, height: 68,
                decoration: BoxDecoration(
                  color: _initialized && _vpc.value.isPlaying ? Colors.white.withOpacity(0.15) : AppColors.accent,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: (_initialized && _vpc.value.isPlaying ? Colors.white : AppColors.accent).withOpacity(0.25), blurRadius: 20)],
                ),
                child: _initialized
                    ? Icon(_vpc.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 36)
                    : const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 32),
            _SeekBtn(icon: Icons.forward_10_rounded, onTap: () => _seekBy(10)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel(Duration pos, Duration dur, double progress) {
    return Positioned(
      bottom: 0, left: 0, right: 70,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _Pill(text: 'EP ${widget.episode.number}', color: AppColors.accent),
                const SizedBox(width: 8),
                _Pill(text: widget.episode.duration, color: Colors.white24),
                const SizedBox(width: 8),
                Row(children: [
                  const Icon(Icons.remove_red_eye_outlined, size: 12, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(widget.episode.views, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ]),
              ]),
              const SizedBox(height: 6),
              Text(widget.episode.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
              const SizedBox(height: 14),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  activeTrackColor: AppColors.accent,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                  overlayColor: AppColors.accentSoft,
                  trackShape: const RectangularSliderTrackShape(),
                ),
                child: Slider(
                  value: progress,
                  onChanged: _isLocked ? null : _seekTo,
                  onChangeStart: (_) => _hideTimer?.cancel(),
                  onChangeEnd: (_) => _scheduleHide(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(pos), style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    Text(_fmt(dur), style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(children: [
                _GlassBtn(icon: _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, onTap: _toggleMute),
                const SizedBox(width: 10),
                _Pill(text: 'HD', color: Colors.white24),
                const Spacer(),
                _GlassBtn(icon: Icons.speed_rounded, onTap: () => _showSpeedSheet(context)),
                const SizedBox(width: 8),
                _GlassBtn(icon: Icons.fit_screen_rounded, onTap: () {}),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRail() {
    return Positioned(
      right: 12,
      bottom: MediaQuery.of(context).padding.bottom + 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _heartAnim,
            child: _RailBtn(
              icon: _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              label: '48K',
              color: _liked ? AppColors.accent : Colors.white,
              onTap: _toggleLike,
            ),
          ),
          const SizedBox(height: 20),
          _RailBtn(icon: Icons.comment_rounded,       label: '1.2K',  color: Colors.white, onTap: widget.onShowComments),
          const SizedBox(height: 20),
          _RailBtn(icon: Icons.share_rounded,         label: 'Share', color: Colors.white, onTap: () {}),
          const SizedBox(height: 20),
          _RailBtn(icon: Icons.bookmark_border_rounded, label: 'Save', color: Colors.white, onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildLockOverlay() {
    return GestureDetector(
      onTap: _tryUnlock,
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent.withOpacity(0.4)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle, border: Border.all(color: AppColors.accent.withOpacity(0.5))),
                  child: const Icon(Icons.lock_rounded, color: AppColors.accent, size: 28),
                ),
                const SizedBox(height: 14),
                const Text('Unlock Episode', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('Costs 1 point', style: TextStyle(color: Colors.white60, fontSize: 13)),
                const SizedBox(height: 16),
                Consumer<UserProfileProvider>(
                  builder: (_, p, __) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                    decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text('Watch  (${p.points} pts left)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSpeedSheet(BuildContext ctx) {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.divider)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(),
            const Text('Playback Speed', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10, runSpacing: 10,
              alignment: WrapAlignment.center,
              children: speeds.map((s) {
                final active = _initialized && (_vpc.value.playbackSpeed - s).abs() < 0.01;
                return GestureDetector(
                  onTap: () { _vpc.setPlaybackSpeed(s); Navigator.pop(ctx); setState(() {}); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? AppColors.accent : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: active ? AppColors.accent : AppColors.divider),
                    ),
                    child: Text('${s}x', style: TextStyle(color: active ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w700)),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SCROLL DOTS
// ─────────────────────────────────────────────
class _ScrollDots extends StatelessWidget {
  final int total;
  final int current;
  const _ScrollDots({required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    final visible = total.clamp(0, 8);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(visible, (i) {
        final active = i == current % visible;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 3, height: active ? 20 : 5,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(color: active ? AppColors.accent : Colors.white24, borderRadius: BorderRadius.circular(3)),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────
//  REUSABLE SMALL WIDGETS
// ─────────────────────────────────────────────
class _GlassBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback? onTap;
  const _GlassBtn({required this.icon, this.size = 18, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.15))),
      child: Icon(icon, color: Colors.white70, size: size),
    ),
  );
}

class _SeekBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SeekBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 52, height: 52,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white70, size: 30),
    ),
  );
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.18), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.4))),
    child: Text(text, style: TextStyle(color: color == Colors.white24 ? Colors.white70 : color, fontSize: 11, fontWeight: FontWeight.w700)),
  );
}

class _RailBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _RailBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.1))),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────
//  BOTTOM SHEETS
// ─────────────────────────────────────────────
Widget _sheetHandle() => Container(
  margin: const EdgeInsets.only(bottom: 16),
  width: 40, height: 4,
  decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
);

class _OutOfPointsSheet extends StatelessWidget {
  final VoidCallback onWatchAd;
  const _OutOfPointsSheet({required this.onWatchAd});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.divider)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sheetHandle(),
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle, border: Border.all(color: AppColors.accent.withOpacity(0.3))),
            child: const Icon(Icons.bolt_rounded, color: AppColors.gold, size: 36),
          ),
          const SizedBox(height: 14),
          const Text("You're out of points!", style: TextStyle(color: AppColors.textPrimary, fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('You need 1 point to unlock this episode.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              _SheetOption(icon: Icons.ondemand_video_rounded, iconColor: AppColors.accent, bgColor: AppColors.accentSoft, title: 'Watch a Short Ad', subtitle: 'Earn 1 point instantly  •  ~30 sec', trailingLabel: 'FREE', trailingColor: AppColors.accent, onTap: onWatchAd),
              const SizedBox(height: 10),
              _SheetOption(icon: Icons.add_circle_outline_rounded, iconColor: AppColors.gold, bgColor: AppColors.goldSoft, title: 'Buy 10 Points', subtitle: 'Watch 10 more episodes', trailingLabel: r'$0.99', trailingColor: AppColors.gold, onTap: () => Navigator.pop(context)),
              const SizedBox(height: 10),
              _SheetOption(icon: Icons.workspace_premium_rounded, iconColor: Colors.white, bgColor: AppColors.purpleSoft, title: 'Go Premium', subtitle: 'Unlimited episodes, no ads', trailingLabel: r'$4.99/mo', trailingColor: AppColors.purple, onTap: () => Navigator.pop(context)),
            ]),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor, bgColor, trailingColor;
  final String title, subtitle, trailingLabel;
  final VoidCallback onTap;
  const _SheetOption({required this.icon, required this.iconColor, required this.bgColor, required this.title, required this.subtitle, required this.trailingLabel, required this.trailingColor, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: trailingColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: trailingColor.withOpacity(0.35))),
          child: Text(trailingLabel, style: TextStyle(color: trailingColor, fontSize: 12, fontWeight: FontWeight.w800)),
        ),
      ]),
    ),
  );
}

class _CommentsSheet extends StatelessWidget {
  const _CommentsSheet();
  static const _comments = [
    {'user': 'Alex M.',  'text': 'This episode is insane!! fire',       'time': '2m ago',  'likes': '234'},
    {'user': 'Julia K.', 'text': 'The plot twist caught me off guard',  'time': '5m ago',  'likes': '189'},
    {'user': 'Ryan T.',  'text': 'Episode 7 was better but still great','time': '12m ago', 'likes': '92'},
    {'user': 'Sam W.',   'text': "Can't wait for next week!",           'time': '18m ago', 'likes': '57'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.divider)),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(children: [
            _sheetHandle(),
            const Row(children: [
              Text('Comments', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
              SizedBox(width: 8),
              Text('1,240', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ]),
            const SizedBox(height: 12),
            const Divider(color: AppColors.divider, height: 1),
          ]),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            itemCount: _comments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, i) {
              final c = _comments[i];
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.accent.withOpacity(0.7), AppColors.purple])),
                  child: Center(child: Text(c['user']![0], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(c['user']!, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(width: 8),
                    Text(c['time']!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ]),
                  const SizedBox(height: 4),
                  Text(c['text']!, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.favorite_border_rounded, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(c['likes']!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(width: 16),
                    const Text('Reply', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ])),
              ]);
            },
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
          child: Row(children: [
            Container(width: 34, height: 34, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.purple, AppColors.accent])), child: const Center(child: Text('Me', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)))),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.divider)),
                child: const Text('Add a comment...', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _EpisodeListSheet extends StatelessWidget {
  final List<Episode> episodes;
  final int currentIndex;
  final void Function(int) onSelect;
  const _EpisodeListSheet({required this.episodes, required this.currentIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.divider)),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(children: [
            _sheetHandle(),
            const Row(children: [
              Text('All Episodes', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
              SizedBox(width: 8),
              Text('Season 1', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ]),
            const SizedBox(height: 12),
            const Divider(color: AppColors.divider, height: 1),
          ]),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: episodes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final ep = episodes[i];
              final isCurrent = i == currentIndex;
              return GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCurrent ? AppColors.accentSoft : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isCurrent ? AppColors.accent.withOpacity(0.4) : Colors.transparent),
                  ),
                  child: Row(children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: LinearGradient(colors: [ep.bgColor, AppColors.bg])),
                      child: Center(child: isCurrent
                          ? const Icon(Icons.equalizer_rounded, color: AppColors.accent, size: 20)
                          : Text('${ep.number}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w700))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Ep ${ep.number}  ${ep.title}', style: TextStyle(color: isCurrent ? AppColors.accent : AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(ep.duration, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ])),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(6)),
                        child: const Text('NOW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      ),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}