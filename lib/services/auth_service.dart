import '../models/user_model.dart';
import '../utils/constants.dart';
import 'supabase_service.dart';

// ============================================================
// Ngam App — Auth Service
// Handles registration, login, logout, and user profile
// ============================================================

class AuthService {
  static final _client = SupabaseService.client;

  /// Sign up a new user with email/password and insert profile into users table
  static Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    // 1. Create auth account
    final authResponse = await _client.auth.signUp(
      email: email,
      password: password,
    );

    if (authResponse.user == null) {
      throw Exception('Registration failed. Please try again.');
    }

    final userId = authResponse.user!.id;

    // 2. Insert user profile into users table
    final userData = {
      'id': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'created_at': DateTime.now().toIso8601String(),
    };

    await _client.from(DbTable.users).insert(userData);

    return UserModel.fromJson(userData);
  }

  /// Sign in with email and password
  static Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final authResponse = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (authResponse.user == null) {
      throw Exception('Login failed. Invalid credentials.');
    }

    // Fetch user profile from users table
    final userId = authResponse.user!.id;
    final response = await _client
        .from(DbTable.users)
        .select()
        .eq('id', userId)
        .single();

    return UserModel.fromJson(response);
  }

  /// Sign out current user
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Get current logged-in user profile
  static Future<UserModel?> getCurrentUser() async {
    final session = _client.auth.currentSession;
    if (session == null) return null;

    final userId = session.user.id;
    try {
      final response = await _client
          .from(DbTable.users)
          .select()
          .eq('id', userId)
          .single();
      return UserModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Update user role (for role switching)
  static Future<void> updateRole(String userId, String newRole) async {
    await _client
        .from(DbTable.users)
        .update({'role': newRole})
        .eq('id', userId);
  }

  /// Check if user is currently logged in
  static bool get isLoggedIn => _client.auth.currentSession != null;
}
