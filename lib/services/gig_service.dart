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
    String? customerName,
    String? runnerName,
    double? latitude,
    double? longitude,
    String? gigWorkerId,
    String? status,
  }) async {
    final gigId = _uuid.v4();
    final now = DateTime.now();

    final dbPayload = {
      'id': gigId,
      'customer_id': customerId,
      'gig_worker_id': gigWorkerId,
      'title': title,
      'description': description,
      'category': category,
      'bounty_amount': bountyAmount,
      'status': status ?? GigStatus.open,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': now.toIso8601String(),
    };

    final gigDataForModel = {
      ...dbPayload,
      if (customerName != null) 'customer_name': customerName,
      if (runnerName != null) 'runner_name': runnerName,
    };

    if (status != GigStatus.service) {
      // Use RPC for payment deduction when a customer creates a gig
      final response = await _client.rpc('create_gig_with_payment', params: {
        'p_id': gigId,
        'p_customer_id': customerId,
        'p_gig_worker_id': gigWorkerId,
        'p_title': title,
        'p_description': description,
        'p_category': category,
        'p_bounty_amount': bountyAmount,
        'p_status': status ?? GigStatus.open,
        'p_location': location,
        'p_latitude': latitude,
        'p_longitude': longitude,
      });
      // Assuming response['success'] == true, otherwise it would throw
    } else {
      // Runner posting a service (free)
      await _client.from(DbTable.gigs).insert(dbPayload);
      await _logStatus(gigId, status ?? GigStatus.open);
    }

    return GigModel.fromJson(gigDataForModel);
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

  /// Fetch all runner service postings
  static Future<List<GigModel>> fetchServices({String? category}) async {
    var query = _client
        .from(DbTable.gigs)
        .select()
        .eq('status', GigStatus.service);

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

  static Future<List<GigModel>> fetchRunnerGigs(String runnerId) async {
    final response = await _client
        .from(DbTable.gigs)
        .select()
        .or('gig_worker_id.eq.$runnerId,customer_id.eq.$runnerId')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => GigModel.fromJson(json))
        .where((gig) => gig.serviceId == null) // Filter out bookings here if they shouldn't show as top-level tasks
        .toList();
  }

  /// Fetch bookings for a specific service advertisement
  static Future<List<GigModel>> fetchBookingsForService(String serviceId) async {
    final response = await _client
        .from(DbTable.gigs)
        .select()
        .eq('service_id', serviceId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => GigModel.fromJson(json))
        .toList();
  }

  /// Customer books a service advertisement
  static Future<GigModel> bookService({
    required String serviceId,
    required String customerId,
    required String runnerId,
    required String title,
    required String description,
    required String category,
    required double bountyAmount,
    required String location,
    double? latitude,
    double? longitude,
  }) async {
    final gig = GigModel(
      id: const Uuid().v4(),
      customerId: customerId,
      gigWorkerId: runnerId,
      serviceId: serviceId,
      title: title,
      description: description,
      category: category,
      bountyAmount: bountyAmount,
      status: 'PENDING',
      location: location,
      latitude: latitude,
      longitude: longitude,
      createdAt: DateTime.now(),
    );

    // Use RPC to deduct balance from customer when booking
    await _client.rpc('create_gig_with_payment', params: {
        'p_id': gig.id,
        'p_customer_id': customerId,
        'p_gig_worker_id': runnerId,
        'p_title': title,
        'p_description': description,
        'p_category': category,
        'p_bounty_amount': bountyAmount,
        'p_status': 'PENDING',
        'p_location': location,
        'p_latitude': latitude,
        'p_longitude': longitude,
    });

    return gig;
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

  /// Fetch gigs shared between two users (e.g. for unified chat task switcher)
  static Future<List<GigModel>> fetchSharedGigs(String userA, String userB) async {
    final response = await _client
        .from(DbTable.gigs)
        .select()
        .or('and(customer_id.eq.$userA,gig_worker_id.eq.$userB),and(customer_id.eq.$userB,gig_worker_id.eq.$userA)')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => GigModel.fromJson(json))
        .toList();
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
        .eq('status', GigStatus.open) // Only lock if still OPEN
        .select()
        .single();

    await _logStatus(gigId, GigStatus.locked);
  }

  /// Runner accepts a pending service order
  static Future<void> acceptPendingGig(String gigId, String runnerId) async {
    await _client
        .from(DbTable.gigs)
        .update({
          'status': GigStatus.locked,
        })
        .eq('id', gigId)
        .eq('status', GigStatus.pending)
        .eq('gig_worker_id', runnerId) // Security check
        .select()
        .single();

    await _logStatus(gigId, GigStatus.locked);
  }

  /// Runner rejects a pending service order
  static Future<void> rejectPendingGig(String gigId, String runnerId) async {
    await _client
        .from(DbTable.gigs)
        .update({
          'status': GigStatus.cancelled,
        })
        .eq('id', gigId)
        .eq('status', GigStatus.pending)
        .eq('gig_worker_id', runnerId) // Security check
        .select()
        .single();

    await _logStatus(gigId, GigStatus.cancelled);
  }

  /// Runner starts working on the gig
  static Future<void> startGig(String gigId) async {
    await _client
        .from(DbTable.gigs)
        .update({'status': GigStatus.inProgress})
        .eq('id', gigId);

    await _logStatus(gigId, GigStatus.inProgress);
  }

  /// Runner marks the gig as delivered (awaiting confirmation)
  static Future<void> deliverGig(String gigId) async {
    await _client
        .from(DbTable.gigs)
        .update({'status': GigStatus.delivered})
        .eq('id', gigId);

    await _logStatus(gigId, GigStatus.delivered);
  }

  /// Customer confirms completion (also credits runner balance)
  static Future<void> completeGig(String gigId, String runnerId) async {
    await _client.rpc('complete_gig_and_pay', params: {
      'p_gig_id': gigId,
      'p_runner_id': runnerId,
    });
  }

  /// Cancel a gig (by customer) - Refunds customer
  static Future<void> cancelGigAndRefund(String gigId, String customerId) async {
    await _client.rpc('cancel_gig_and_refund', params: {
      'p_gig_id': gigId,
      'p_user_id': customerId,
    });
  }

  /// Cancel a gig (no refund, e.g. runner taking down service)
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

  // ─── TASK MANAGEMENT ─────────────────────────────────────────

  /// Update the bounty amount of a gig
  static Future<void> updateBounty(String gigId, double newAmount) async {
    await _client
        .from(DbTable.gigs)
        .update({'bounty_amount': newAmount})
        .eq('id', gigId);
  }

  /// Delete a gig permanently
  static Future<void> deleteGig(String gigId) async {
    await _client.from(DbTable.gigs).delete().eq('id', gigId);
  }

  /// Toggle a gig between active and disabled
  static Future<String> toggleGigStatus(String gigId, String currentStatus) async {
    String newStatus;
    if (currentStatus == GigStatus.open) {
      newStatus = GigStatus.disabled;
    } else if (currentStatus == GigStatus.disabled) {
      newStatus = GigStatus.open;
    } else if (currentStatus == GigStatus.service) {
      newStatus = GigStatus.disabledService;
    } else if (currentStatus == GigStatus.disabledService) {
      newStatus = GigStatus.service;
    } else {
      return currentStatus;
    }

    await _client
        .from(DbTable.gigs)
        .update({'status': newStatus})
        .eq('id', gigId);

    await _logStatus(gigId, newStatus);
    return newStatus;
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

  /// Subscribe to all runner services (live feed for customers)
  static Stream<List<GigModel>> subscribeToServices() {
    return _client
        .from(DbTable.gigs)
        .stream(primaryKey: ['id'])
        .map((list) => list
            .map((json) => GigModel.fromJson(json))
            .where((gig) => gig.status == GigStatus.service)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  static Future<void> updateRunnerLocation(String gigId, double lat, double lng) async {
    await _client.from(DbTable.gigs).update({
      'runner_latitude': lat,
      'runner_longitude': lng,
    }).eq('id', gigId);
  }

  // ─── STATE LOGGING ───────────────────────────────────────────

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

  /// Get real-time stream of completed tasks count for a user (as runner)
  static Stream<int> streamCompletedCount(String runnerId) {
    return _client
        .from(DbTable.gigs)
        .stream(primaryKey: ['id'])
        .map((list) => list.where((gig) => gig['gig_worker_id'] == runnerId && gig['status'] == GigStatus.completed).length);
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
