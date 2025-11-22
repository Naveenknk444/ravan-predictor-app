import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_routes.dart';

// Placeholder screens - will be replaced with actual screens
import '../presentation/screens/placeholder_screens.dart';

/// App router configuration using GoRouter
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,

    // Redirect logic for auth
    redirect: (context, state) {
      final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup ||
          state.matchedLocation == AppRoutes.otp ||
          state.matchedLocation == AppRoutes.splash ||
          state.matchedLocation == AppRoutes.forgotPassword;

      // If not logged in and trying to access protected route
      if (!isLoggedIn && !isAuthRoute) {
        return AppRoutes.login;
      }

      // If logged in and trying to access auth route (except splash)
      if (isLoggedIn && isAuthRoute && state.matchedLocation != AppRoutes.splash) {
        return AppRoutes.dashboard;
      }

      return null;
    },

    routes: [
      // Splash screen
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const PlaceholderScreen(title: 'Splash'),
      ),

      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const PlaceholderScreen(title: 'Login'),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const PlaceholderScreen(title: 'Sign Up'),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) => const PlaceholderScreen(title: 'OTP Verification'),
      ),
      GoRoute(
        path: AppRoutes.welcomeBonus,
        builder: (context, state) => const PlaceholderScreen(title: 'Welcome Bonus'),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const PlaceholderScreen(title: 'Forgot Password'),
      ),

      // Main app shell with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          // Dashboard
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const PlaceholderScreen(title: 'Dashboard'),
          ),
          // Predictions tab
          GoRoute(
            path: AppRoutes.predictions,
            builder: (context, state) => const PlaceholderScreen(title: 'Predictions'),
          ),
          // Wallet tab
          GoRoute(
            path: AppRoutes.wallet,
            builder: (context, state) => const PlaceholderScreen(title: 'Wallet'),
          ),
          // Profile tab
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const PlaceholderScreen(title: 'Profile'),
          ),
        ],
      ),

      // Match predictions (full screen, no bottom nav)
      GoRoute(
        path: '/match/:matchId/predictions',
        builder: (context, state) {
          final matchId = state.pathParameters['matchId']!;
          return PlaceholderScreen(title: 'Match $matchId Predictions');
        },
      ),

      // Prediction confirmation
      GoRoute(
        path: AppRoutes.predictionConfirmation,
        builder: (context, state) => const PlaceholderScreen(title: 'Prediction Confirmation'),
      ),

      // My predictions
      GoRoute(
        path: AppRoutes.myPredictions,
        builder: (context, state) => const PlaceholderScreen(title: 'My Predictions'),
      ),

      // Prediction result
      GoRoute(
        path: '/prediction/:predictionId/result',
        builder: (context, state) {
          final predictionId = state.pathParameters['predictionId']!;
          return PlaceholderScreen(title: 'Prediction $predictionId Result');
        },
      ),

      // Wallet sub-routes
      GoRoute(
        path: AppRoutes.addCoins,
        builder: (context, state) => const PlaceholderScreen(title: 'Add Coins'),
      ),
      GoRoute(
        path: AppRoutes.dailyRewards,
        builder: (context, state) => const PlaceholderScreen(title: 'Daily Rewards'),
      ),
      GoRoute(
        path: AppRoutes.rewardsStore,
        builder: (context, state) => const PlaceholderScreen(title: 'Rewards Store'),
      ),

      // Profile sub-routes
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const PlaceholderScreen(title: 'Edit Profile'),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const PlaceholderScreen(title: 'Settings'),
      ),
      GoRoute(
        path: AppRoutes.achievements,
        builder: (context, state) => const PlaceholderScreen(title: 'Achievements'),
      ),
      GoRoute(
        path: AppRoutes.leaderboard,
        builder: (context, state) => const PlaceholderScreen(title: 'Leaderboard'),
      ),
      GoRoute(
        path: AppRoutes.referral,
        builder: (context, state) => const PlaceholderScreen(title: 'Referral'),
      ),
      GoRoute(
        path: AppRoutes.helpSupport,
        builder: (context, state) => const PlaceholderScreen(title: 'Help & Support'),
      ),
    ],

    // Error page
    errorBuilder: (context, state) => PlaceholderScreen(
      title: 'Error',
      subtitle: state.error?.message ?? 'Page not found',
    ),
  );
}

/// Main shell with bottom navigation
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const MainBottomNav(),
    );
  }
}

/// Bottom navigation bar
class MainBottomNav extends StatelessWidget {
  const MainBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF333333), width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _getSelectedIndex(location),
        onTap: (index) => _onItemTapped(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_cricket_outlined),
            activeIcon: Icon(Icons.sports_cricket),
            label: 'Predict',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  int _getSelectedIndex(String location) {
    if (location.startsWith(AppRoutes.dashboard)) return 0;
    if (location.startsWith(AppRoutes.predictions)) return 1;
    if (location.startsWith(AppRoutes.wallet)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
        break;
      case 1:
        context.go(AppRoutes.predictions);
        break;
      case 2:
        context.go(AppRoutes.wallet);
        break;
      case 3:
        context.go(AppRoutes.profile);
        break;
    }
  }
}
