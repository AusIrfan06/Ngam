import 'package:flutter_dotenv/flutter_dotenv.dart';

// ============================================================
// Ngam App — Constants & Configuration
// ============================================================

// ─── Supabase Credentials ────────────────────────────────────
String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

// ─── Task Categories ─────────────────────────────────────────
class TaskCategory {
  static const String food = 'Food';
  static const String shopping = 'Shopping';
  static const String print = 'Print';
  static const String heavy = 'Heavy';
  static const String parcel = 'Parcel';

  static const List<String> all = [food, shopping, print, heavy, parcel];

  /// Returns an icon for each category
  static String icon(String category) {
    switch (category) {
      case food:
        return '🍔';
      case shopping:
        return '🛒';
      case print:
        return '🖨️';
      case heavy:
        return '📦';
      case parcel:
        return '📮';
      default:
        return '📋';
    }
  }
}

// ─── Gig Status ──────────────────────────────────────────────
class GigStatus {
  static const String open = 'OPEN';
  static const String locked = 'LOCKED';
  static const String inProgress = 'IN-PROGRESS';
  static const String completed = 'COMPLETED';
  static const String cancelled = 'CANCELLED';
  static const String service = 'SERVICE';
}

// ─── User Roles ──────────────────────────────────────────────
class UserRole {
  static const String pemesan = 'pemesan';
  static const String runner = 'runner';
}

// ─── SLA Durations (in minutes) per category ─────────────────
class SlaDuration {
  static int forCategory(String category) {
    switch (category) {
      case TaskCategory.food:
        return 30;
      case TaskCategory.shopping:
        return 60;
      case TaskCategory.print:
        return 20;
      case TaskCategory.heavy:
        return 90;
      case TaskCategory.parcel:
        return 45;
      default:
        return 30;
    }
  }
}

// ─── Table Names ─────────────────────────────────────────────
class DbTable {
  static const String users = 'users';
  static const String gigs = 'gigs';
  static const String statusLogs = 'status_logs';
  static const String reviews = 'reviews';
}
