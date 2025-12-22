import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/intro_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';

class ConfessionApp extends StatelessWidget {
  const ConfessionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Confession',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppNavigator(),
    );
  }
}

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator>
    with WidgetsBindingObserver {

  bool _isLocked = true;

  late Future<bool> _firstLaunchFuture;
  late Future<void> _authFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final authService =
        Provider.of<AuthService>(context, listen: false);

    // Initialize Futures once
    _firstLaunchFuture = authService.isFirstLaunch();
    _authFuture = authService.signInAnonymously();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (mounted) {
        setState(() {
          _isLocked = true;
        });
      }
    }
  }

  void _onUnlocked() {
    setState(() {
      _isLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      return LockScreen(onUnlocked: _onUnlocked);
    }

    return FutureBuilder<bool>(
      future: _firstLaunchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final isFirstLaunch = snapshot.data ?? true;

        if (isFirstLaunch) {
          return const IntroScreen();
        }

        return FutureBuilder(
          future: _authFuture,
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            return const HomeScreen();
          },
        );
      },
    );
  }
}
