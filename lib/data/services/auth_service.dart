import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentication service - handles all Supabase auth operations
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  /// Check if user is logged in
  bool get isLoggedIn => currentSession != null;

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Send OTP to phone number
  ///
  /// [phone] - Full phone number with country code (e.g., "+911234567890")
  Future<void> sendOTP(String phone) async {
    // TODO: Remove debug logs before production
    print('=== SEND OTP DEBUG ===');
    print('Phone: $phone');

    try {
      await _supabase.auth.signInWithOtp(
        phone: phone,
      );
      print('OTP sent successfully');
      print('======================');
    } on AuthException catch (e) {
      print('AuthException: ${e.message}');
      print('======================');
      throw AuthServiceException(_mapAuthError(e.message));
    } catch (e) {
      print('Unknown error: $e');
      print('Error type: ${e.runtimeType}');
      print('======================');
      throw AuthServiceException('Failed to send OTP. Please try again.');
    }
  }

  /// Verify OTP code
  ///
  /// [phone] - Full phone number with country code
  /// [token] - 6-digit OTP code
  ///
  /// Returns [AuthResponse] with user and session data
  Future<AuthResponse> verifyOTP(String phone, String token) async {
    // TODO: Remove debug logs before production
    print('=== VERIFY OTP DEBUG ===');
    print('Phone: $phone');
    print('Token: $token');

    try {
      final response = await _supabase.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
      print('OTP verified successfully');
      print('User ID: ${response.user?.id}');
      print('========================');
      return response;
    } on AuthException catch (e) {
      print('AuthException: ${e.message}');
      print('========================');
      throw AuthServiceException(_mapAuthError(e.message));
    } catch (e) {
      print('Unknown error: $e');
      print('Error type: ${e.runtimeType}');
      print('========================');
      throw AuthServiceException('Failed to verify OTP. Please try again.');
    }
  }

  /// Check if user is new (no profile exists)
  /// Note: With on_auth_user_created trigger, profile is auto-created
  /// This check is for backwards compatibility
  Future<bool> isNewUser(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      return response == null;
    } catch (e) {
      // If error, assume new user
      return true;
    }
  }

  /// Create user profile for new users
  Future<void> createUserProfile({
    required String userId,
    required String phone,
    String? name,
    String? referralCode,
  }) async {
    // TODO: Remove debug logs before production
    print('=== CREATE PROFILE DEBUG ===');
    print('User ID: $userId');
    print('Phone: $phone');
    print('Name: $name');
    print('Referral Code: $referralCode');

    try {
      // Generate unique referral code for this user
      final userReferralCode = _generateReferralCode();
      final username = 'user_${userId.substring(0, 8)}';

      print('Generated username: $username');
      print('Generated referral code: $userReferralCode');

      // Use upsert to update the auto-created profile from trigger
      // The trigger creates basic profile, we update with user-provided name
      await _supabase.from('users').upsert({
        'id': userId,
        'phone': phone,
        'full_name': name ?? 'Player',
        'username': username,
        'referral_code': userReferralCode,
        'coin_balance': 10000, // Welcome bonus
      }, onConflict: 'id');

      print('Profile created successfully');

      // If referral code provided, link to referrer (handle separately)
      if (referralCode != null && referralCode.isNotEmpty) {
        await _processReferral(userId, referralCode);
      }
      print('============================');
    } catch (e) {
      // Profile creation failed - might already exist
      print('ERROR creating profile: $e');
      print('Error type: ${e.runtimeType}');
      print('============================');
      // Re-throw so we can see the error in UI
      rethrow;
    }
  }

  /// Generate a unique referral code
  String _generateReferralCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(8, (i) => chars[(random + i * 7) % chars.length]).join();
  }

  /// Process referral code - find referrer and link
  Future<void> _processReferral(String userId, String referralCode) async {
    try {
      // Find user with this referral code
      final referrer = await _supabase
          .from('users')
          .select('id')
          .eq('referral_code', referralCode.toUpperCase())
          .maybeSingle();

      if (referrer != null) {
        // Update the new user's referred_by field
        await _supabase
            .from('users')
            .update({'referred_by': referrer['id']})
            .eq('id', userId);
      }
    } catch (e) {
      print('Error processing referral: $e');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      throw AuthServiceException(_mapAuthError(e.message));
    } catch (e) {
      throw AuthServiceException('Failed to sign out. Please try again.');
    }
  }

  /// Map Supabase auth errors to user-friendly messages
  String _mapAuthError(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('invalid phone')) {
      return 'Invalid phone number. Please check and try again.';
    }
    if (lowerMessage.contains('rate limit') || lowerMessage.contains('too many')) {
      return 'Too many attempts. Please wait a few minutes and try again.';
    }
    if (lowerMessage.contains('expired')) {
      return 'OTP has expired. Please request a new code.';
    }
    if (lowerMessage.contains('invalid') && lowerMessage.contains('otp')) {
      return 'Invalid OTP. Please check the code and try again.';
    }
    if (lowerMessage.contains('network') || lowerMessage.contains('connection')) {
      return 'Network error. Please check your connection.';
    }

    return message;
  }
}

/// Custom exception for auth errors
class AuthServiceException implements Exception {
  final String message;

  AuthServiceException(this.message);

  @override
  String toString() => message;
}
