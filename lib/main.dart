import 'package:flutter/material.dart';
import 'package:platinum_next_episode/constants/app_theme.dart';
import 'package:platinum_next_episode/screens/MainShell.dart';
import 'package:provider/provider.dart';
import 'providers/user_profile_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        // Add more providers here as your app grows:
        // ChangeNotifierProvider(create: (_) => SeriesProvider()),
        // ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'SeriesFlix',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.bg,
          colorScheme: const ColorScheme.dark(
            primary:   AppColors.accent,
            secondary: AppColors.purple,
            surface:   AppColors.surface,
          ),
          fontFamily: 'SF Pro Display', // falls back to system font on device
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: CupertinoPageTransitionsBuilder(),
              TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
            },
          ),
        ),
        home: const MainShell(),
      ),
    );
  }
}