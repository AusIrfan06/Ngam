import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';

// ============================================================
// Ngam App — Supabase Service
// Central Supabase client accessor
// ============================================================

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  /// Initialize Supabase — call this in main.dart before runApp
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  }

  /// Update the current user's password
  /// Returns an error string on failure, null on success
  static Future<String?> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Re-authenticate first (Supabase requires valid session — just update)
      await client.auth.updateUser(UserAttributes(password: newPassword));
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Update display name and phone in the profiles table
  static Future<String?> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? avatarUrl,
    String? bio,
    String? gender,
    DateTime? birthDate,
    String? address,
    String? fcmToken,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (bio != null) updates['bio'] = bio;
      if (gender != null) updates['gender'] = gender;
      if (birthDate != null) updates['birth_date'] = "${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}";
      if (address != null) updates['address'] = address;
      if (fcmToken != null) updates['fcm_token'] = fcmToken;
      if (updates.isEmpty) return null;

      await client.from('users').update(updates).eq('id', userId);
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }
}
