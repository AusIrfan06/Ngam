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
}
