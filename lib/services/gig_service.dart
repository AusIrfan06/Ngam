import 'package:uuid/uuid.dart';
import '../models/gig_model.dart';
import '../models/status_log_model.dart';
import '../utils/constants.dart';
import 'supabase_service.dart';

// ============================================================
// Ngam App — Gig Service
// CRUD operations for gigs + Real-Time Task-State Locker
// ============================================================

class GigService {
  static final _client = SupabaseService.client;
  static const _uuid = Uuid();

  // ─── CREATE ────────────────────────────────────────────────

  /// Create a new gig task (Customer posts a task)
  static Future<GigModel> createGig({
    required String customerId,
    required String title,
    required String description,
    required String category,
    required double bountyAmount,
    required String location,
  }) async {
    final gigId = _uuid.v4();
    final now = DateTime.now();

    final gigData = {
      'id': gigId,
      'customer_id': customerId,
      'gig_worker_id': null,
      'title': title,
      'description': description,
      'category': category,
      'bounty_amount': bountyAmount,
      'status': GigStatus.open,
      'location': location,
      'created_at': now.toIso8601String(),
    };

    await _client.from(DbTable.gigs).insert(gigData);

    // Log the initial status
    await _logStatus(gigId, GigStatus.open);

    return GigModel.fromJson(gigData);
  }

  // ─── READ ──────────────────────────────────────────────────

  /// Fetch all open gigs (for runner discovery feed)
  static Future<List<GigModel>> fetchOpenGigs({String? category}) async {
    var query = _client
        .from(DbTable.gigs)
        .select()
        .eq('status', GigStatus.open);

    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.eq('category', category);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((json) => GigModel.fromJson(json))
        .toList();
  }

  /// Fetch gigs posted by a specific customer
  static Future<List<GigModel>> fetchCustomerGigs(String customerId) async {
    final response = await _client
        .from(DbTable.gigs)
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => GigModel.fromJson(json))
        .toList();
  }

  /// Fetch gigs accepted by a specific runner
  static Future<List<GigModel>> fetchRunnerGigs(String runnerId) async {
    final response = await _client
        .from(DbTable.gigs)
        .select()
        .eq('gig_worker_id', runnerId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => GigModel.fromJson(json))
        .toList();
  }

  /// Fetch a single gig by ID
  static Future<GigModel> fetchGigById(String gigId) async {
    final response = await _client
        .from(DbTable.gigs)
        .select()
        .eq('id', gigId)
        .single();

    return GigModel.fromJson(response);
  }

  /// Fetch the active (locked/in-progress) job for a runner
  static Future<GigModel?> fetchActiveJob(String runnerId) async {
    try {
      final response = await _client
          .from(DbTable.gigs)
          .select()
          .eq('gig_worker_id', runnerId)
          .inFilter('status', [GigStatus.locked, GigStatus.inProgress])
          .limit(1)
          .single();

      return GigModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // ─── STATE MUTATIONS (Task-State Locker) ───────────────────

  /// Runner accepts a gig — triggers the "State Locker"
  /// Sets status to LOCKED and assigns the runner
  static Future<void> acceptGig(String gigId, String runnerId) async {
    // Atomically update the gig status
    await _client
        .from(DbTable.gigs)
        .update({
          'gig_worker_id': runnerId,
          'status': GigStatus.locked,
        })
        .eq('id', gigId)
        .eq('status', GigStatus.open); // Only lock if still OPEN

    await _logStatus(gigId, GigStatus.locked);
  }

  /// Runner starts working on the gig
  static Future<void> startGig(String gigId) async {
    await _client
        .from(DbTable.gigs)
        .update({'status': GigStatus.inProgress})
        .eq('id', gigId);

    await _logStatus(gigId, GigStatus.inProgress);
  }

  /// Runner completes the gig
  static Future<void> completeGig(String gigId) async {
    await _client
        .from(DbTable.gigs)
        .update({'status': GigStatus.completed})
        .eq('id', gigId);

    await _logStatus(gigId, GigStatus.completed);
  }

  /// Cancel a gig (by customer or system)
  static Future<void> cancelGig(String gigId) async {
    await _client
        .from(DbTable.gigs)
        .update({
          'status': GigStatus.cancelled,
          'gig_worker_id': null,
        })
        .eq('id', gigId);

    await _logStatus(gigId, GigStatus.cancelled);
  }

  // ─── REAL-TIME STREAMS ─────────────────────────────────────

  /// Subscribe to real-time changes for a specific gig
  static Stream<GigModel> subscribeToGig(String gigId) {
    return _client
        .from(DbTable.gigs)
        .stream(primaryKey: ['id'])
        .eq('id', gigId)
        .map((list) => GigModel.fromJson(list.first));
  }

  /// Subscribe to all open gigs (live feed for runners)
  static Stream<List<GigModel>> subscribeToOpenGigs() {
    return _client
        .from(DbTable.gigs)
        .stream(primaryKey: ['id'])
        .map((list) => list
            .map((json) => GigModel.fromJson(json))
            .where((gig) => gig.status == GigStatus.open)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  // ─── STATUS LOGS ───────────────────────────────────────────

  /// Fetch status logs for a gig (audit trail)
  static Future<List<StatusLogModel>> fetchStatusLogs(String gigId) async {
    final response = await _client
        .from(DbTable.statusLogs)
        .select()
        .eq('gig_id', gigId)
        .order('changed_at', ascending: true);

    return (response as List)
        .map((json) => StatusLogModel.fromJson(json))
        .toList();
  }

  /// Internal: log a status change
  static Future<void> _logStatus(String gigId, String status) async {
    await _client.from(DbTable.statusLogs).insert({
      'id': _uuid.v4(),
      'gig_id': gigId,
      'status': status,
      'changed_at': DateTime.now().toIso8601String(),
    });
  }

  // ─── STATS ─────────────────────────────────────────────────

  /// Get count of completed tasks for a user (as runner)
  static Future<int> getCompletedCount(String runnerId) async {
    final response = await _client
        .from(DbTable.gigs)
        .select('id')
        .eq('gig_worker_id', runnerId)
        .eq('status', GigStatus.completed);

    return (response as List).length;
  }

  /// Get count of posted tasks for a user (as customer)
  static Future<int> getPostedCount(String customerId) async {
    final response = await _client
        .from(DbTable.gigs)
        .select('id')
        .eq('customer_id', customerId);

    return (response as List).length;
  }
}
