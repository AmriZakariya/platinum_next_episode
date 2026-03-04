import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:platinum_next_episode/providers/UserProfileProvider.dart';
import 'package:platinum_next_episode/screens/EpisodeScrollerScreen.dart';
import 'package:platinum_next_episode/screens/HomeScreen.dart';
import 'package:platinum_next_episode/screens/ProfileScreen.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────
//  ENTRY POINT
// ─────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar — baseline (screens override per-page)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF13131A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize AdMob SDK before runApp
  await MobileAds.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProfileProvider>(
          create: (_) => UserProfileProvider(
            initialPoints: 3,
            isPremium: false,
          ),
        ),
      ],
      child: const SeriesFlixApp(),
    ),
  );
}

// ─────────────────────────────────────────────
//  ROOT APP WIDGET
// ─────────────────────────────────────────────
class SeriesFlixApp extends StatelessWidget {
  const SeriesFlixApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SeriesFlix',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      initialRoute: Routes.splash,
      onGenerateRoute: Routes.onGenerateRoute,
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0A0F),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFE63946),
        secondary: Color(0xFF6C3DD8),
        surface: Color(0xFF13131A),
        onSurface: Color(0xFFF1F1F5),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A0A0F),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFFF1F1F5),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: Color(0xFFF1F1F5)),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      splashColor: Colors.white10,
      highlightColor: Colors.white10,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF13131A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _AppPageTransition(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ROUTER
// ─────────────────────────────────────────────
class Routes {
  static const splash = '/';
  static const home = '/home';
  static const episodeScroller = '/episode-scroller';
  static const profile = '/profile';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _fadeRoute(const SplashScreen(), settings);
      case home:
        return _fadeRoute(const HomeScreen(), settings);
      case episodeScroller:
        final args = settings.arguments as EpisodeScrollerArgs?;
        return _slideUpRoute(
          EpisodeScrollerScreen(
            seriesId:    args?.seriesId    ?? '',
            seriesTitle: args?.seriesTitle ?? 'SeriesFlix',
            startIndex:  args?.startIndex  ?? 0,
          ),
          settings,
        );
      case profile:
        return _fadeRoute(const ProfileScreen(), settings);
      default:
        return _fadeRoute(const HomeScreen(), settings);
    }
  }

  static PageRoute _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  static PageRoute _slideUpRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
            parent: animation, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  ROUTE ARGUMENTS
// ─────────────────────────────────────────────
class EpisodeScrollerArgs {
  final String seriesId;
  final String seriesTitle;
  final int startIndex;

  const EpisodeScrollerArgs({
    required this.seriesId,
    required this.seriesTitle,
    this.startIndex = 0,
  });
}

// ─────────────────────────────────────────────
//  CUSTOM PAGE TRANSITION  (Android)
// ─────────────────────────────────────────────
class _AppPageTransition extends PageTransitionsBuilder {
  const _AppPageTransition();

  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    final fadeAnim =
    CurvedAnimation(parent: animation, curve: Curves.easeOut);
    final slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(position: slideAnim, child: child),
    );
  }
}

// ─────────────────────────────────────────────
//  SPLASH SCREEN
// ─────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));

    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _taglineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.5, 0.9, curve: Curves.easeOut)),
    );

    _ctrl.forward().then((_) async {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.home);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _logoScale,
              child: FadeTransition(
                opacity: _logoFade,
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C3DD8), Color(0xFFE63946)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE63946).withOpacity(0.35),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 52),
                    ),
                    const SizedBox(height: 20),
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Series',
                            style: TextStyle(
                              color: Color(0xFFF1F1F5),
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          TextSpan(
                            text: 'Flix',
                            style: TextStyle(
                              color: Color(0xFFE63946),
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            FadeTransition(
              opacity: _taglineFade,
              child: const Text(
                'Watch. Earn. Binge.',
                style: TextStyle(
                  color: Color(0xFF8A8A9A),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 60),
            FadeTransition(
              opacity: _taglineFade,
              child: const _LoadingDots(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ANIMATED LOADING DOTS
// ─────────────────────────────────────────────
class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _anims = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final ctrl = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 600));
      final anim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
      );
      _controllers.add(ctrl);
      _anims.add(anim);
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(
                const Color(0xFF2A2A38),
                const Color(0xFFE63946),
                _anims[i].value,
              ),
            ),
          ),
        );
      }),
    );
  }
}