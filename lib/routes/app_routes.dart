/// App route constants - all named routes in the app
class AppRoutes {
  AppRoutes._();

  // Auth routes
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String otp = '/otp';
  static const String welcomeBonus = '/welcome-bonus';
  static const String forgotPassword = '/forgot-password';

  // Main app routes (with bottom nav)
  static const String dashboard = '/dashboard';
  static const String predictions = '/predictions';
  static const String wallet = '/wallet';
  static const String profile = '/profile';

  // Prediction routes
  static const String matchPredictions = '/match/:matchId/predictions';
  static const String predictionConfirmation = '/prediction/confirmation';
  static const String myPredictions = '/my-predictions';
  static const String predictionResult = '/prediction/:predictionId/result';

  // Wallet routes
  static const String addCoins = '/wallet/add-coins';
  static const String dailyRewards = '/wallet/daily-rewards';
  static const String rewardsStore = '/wallet/rewards-store';

  // Profile routes
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';
  static const String achievements = '/achievements';
  static const String leaderboard = '/leaderboard';
  static const String referral = '/referral';
  static const String helpSupport = '/help-support';

  // Helper method to generate match prediction route
  static String matchPrediction(String matchId) => '/match/$matchId/predictions';

  // Helper method to generate prediction result route
  static String predictionResultRoute(String predictionId) => '/prediction/$predictionId/result';
}
