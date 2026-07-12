import 'package:uuid/uuid.dart';
import '../models/gig_model.dart';
import '../models/status_log_model.dart';
import '../utils/constants.dart';
import 'supabase_service.dart';

// ============================================================
// Ngam App — Gig Service
// Tempat uruskan semua data gig (tambah, baca, update, buang) + sistem lock status secara live
// ============================================================

class GigService {
  static final _client = SupabaseService.client;
  static const _uuid = Uuid();

  // ─── CREATE ────────────────────────────────────────────────

  /// Buat task baru (Bila customer nak post gig)
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
    String? serviceId,
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
      'service_id': serviceId,
      'created_at': now.toIso8601String(),
    };

    final gigDataForModel = {
      ...dbPayload,
      if (customerName != null) 'customer_name': customerName,
      if (runnerName != null) 'runner_name': runnerName,
    };

    if (status != GigStatus.service) {
      // Guna RPC supaya payment terus kena tolak bila customer create gig
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
        'p_service_id': serviceId,
      });
      // Kita assume response['success'] == true, kalau tak dia automatik throw error
    } else {
      // Bila runner post service (takde kena bayar apa-apa)
      await _client.from(DbTable.gigs).insert(dbPayload);
      await _logStatus(gigId, status ?? GigStatus.open);
    }

    return GigModel.fromJson(gigDataForModel);
  }

  // ─── READ ──────────────────────────────────────────────────

  /// Ambil senarai gig yang masih open (untuk runner cari job)
  static Future<List<GigModel>> fetchOpenGigs({String? category}) async {
    var query = _client
        .from(DbTable.gigs)
        .select('*, customer:users!customer_id(name), runner:users!gig_worker_id(name)')
        .eq('status', GigStatus.open);

    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId != null) {
      query = query.neq('customer_id', currentUserId);
    }

    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.eq('category', category);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((json) => GigModel.fromJson(json))
        .toList();
  }

  /// Ambil senarai service yang runner dah post
  static Future<List<GigModel>> fetchServices({String? category}) async {
    var query = _client
        .from(DbTable.gigs)
        .select('*, customer:users!customer_id(name), runner:users!gig_worker_id(name)')
        .eq('status', GigStatus.service);

    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.eq('category', category);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((json) => GigModel.fromJson(json))
        .toList();
  }

  /// Ambil senarai gig yang customer ni post
  static Future<List<GigModel>> fetchCustomerGigs(String customerId) async {
    final response = await _client
        .from(DbTable.gigs)
        .select('*, customer:users!customer_id(name), runner:users!gig_worker_id(name)')
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => GigModel.fromJson(json))
        .toList();
  }

  static Future<List<GigModel>> fetchRunnerGigs(String runnerId) async {
    final response = await _client
        .from(DbTable.gigs)
        .select('*, customer:users!customer_id(name), runner:users!gig_worker_id(name)')
        .or('gig_worker_id.eq.$runnerId,customer_id.eq.$runnerId')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => GigModel.fromJson(json))
        .where((gig) => gig.serviceId == null) // Filter booking servis sebab taknak tunjuk sekali dengan task biasa
        .toList();
  }

  /// Ambil senarai orang booking untuk servis ni
  static Future<List<GigModel>> fetchBookingsForService(String serviceId) async {
    final response = await _client
        .from(DbTable.gigs)
        .select('*, customer:users!customer_id(name), runner:users!gig_worker_id(name)')
        .eq('service_id', serviceId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => GigModel.fromJson(json))
        .toList();
  }

  /// Bila customer nak booking servis
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

    // Pakai RPC untuk potong balance customer masa booking
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
        'p_service_id': serviceId,
    });

    return gig;
  }

  /// Cari satu gig pakai ID dia
  static Future<GigModel> fetchGigById(String gigId) async {
    final response = await _client
        .from(DbTable.gigs)
        .select()
        .eq('id', gigId)
        .single();


    return GigModel.fromJson(response);
  }

  /// Ambil gig yang ada kaitan antara dua user ni (contoh: untuk tunjuk dalam chat)
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

  /// Cari gig yang tengah jalan (locked/in-progress) untuk runner ni
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

  // ─── TUKAR STATUS (Sistem Lock Task) ───────────────────────

  /// Bila runner accept gig — terus trigger "Sistem Lock"
  /// Tukar status jadi LOCKED dan assign kat runner ni
  static Future<void> acceptGig(String gigId, String runnerId) async {
    // Update status gig serentak
    await _client
        .from(DbTable.gigs)
        .update({
          'gig_worker_id': runnerId,
          'status': GigStatus.locked,
        })
        .eq('id', gigId)
        .eq('status', GigStatus.open) // Boleh lock kalau status dia memang still OPEN je
        .select()
        .single();

    await _logStatus(gigId, GigStatus.locked);
  }

  /// Runner terima booking servis dari customer
  static Future<void> acceptPendingGig(String gigId, String runnerId) async {
    await _client
        .from(DbTable.gigs)
        .update({
          'status': GigStatus.locked,
        })
        .eq('id', gigId)
        .eq('status', GigStatus.pending)
        .eq('gig_worker_id', runnerId) // Check betul ke tak runner ni
        .select()
        .single();

    await _logStatus(gigId, GigStatus.locked);
  }

  /// Runner reject booking servis
  static Future<void> rejectPendingGig(String gigId, String runnerId) async {
    await _client
        .from(DbTable.gigs)
        .update({
          'status': GigStatus.cancelled,
        })
        .eq('id', gigId)
        .eq('status', GigStatus.pending)
        .eq('gig_worker_id', runnerId) // Check betul ke tak runner ni
        .select()
        .single();

    await _logStatus(gigId, GigStatus.cancelled);
  }

  /// Runner dah mula buat kerja
  static Future<void> startGig(String gigId) async {
    await _client
        .from(DbTable.gigs)
        .update({'status': GigStatus.inProgress})
        .eq('id', gigId);

    await _logStatus(gigId, GigStatus.inProgress);
  }

  /// Runner dah siap (tunggu customer confirm)
  static Future<void> deliverGig(String gigId) async {
    await _client
        .from(DbTable.gigs)
        .update({'status': GigStatus.delivered})
        .eq('id', gigId);

    await _logStatus(gigId, GigStatus.delivered);
  }

  /// Customer confirm dah siap (runner pun dapat duit)
  static Future<void> completeGig(String gigId, String runnerId) async {
    await _client.rpc('complete_gig_and_pay', params: {
      'p_gig_id': gigId,
      'p_runner_id': runnerId,
    });
  }

  /// Cancel gig (customer yang buat) - Duit akan refund balik
  static Future<void> cancelGigAndRefund(String gigId, String customerId) async {
    await _client.rpc('cancel_gig_and_refund', params: {
      'p_gig_id': gigId,
      'p_user_id': customerId,
    });
  }

  /// Cancel gig (takde refund, contoh runner nak buang servis dia)
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

  /// Ubah harga upah gig ni
  static Future<void> updateBounty(String gigId, double newAmount) async {
    await _client
        .from(DbTable.gigs)
        .update({'bounty_amount': newAmount})
        .eq('id', gigId);
  }

  /// Padam gig ni terus
  static Future<void> deleteGig(String gigId) async {
    await _client.from(DbTable.gigs).delete().eq('id', gigId);
  }

  /// Tukar-tukar status gig sama ada on atau off
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

  /// Langgan perubahan live untuk satu gig ni je
  static Stream<GigModel> subscribeToGig(String gigId) {
    return _client
        .from(DbTable.gigs)
        .stream(primaryKey: ['id'])
        .eq('id', gigId)
        .map((list) => GigModel.fromJson(list.first));
  }

  /// Langgan semua gig open (untuk feed runner yang sentiasa update)
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

  /// Langgan semua servis runner (untuk feed customer)
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

  /// Tengok rekod perubahan status gig (untuk trace balik)
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

  /// Fungsi dalaman: simpan rekod bila status berubah
  static Future<void> _logStatus(String gigId, String status) async {
    await _client.from(DbTable.statusLogs).insert({
      'id': _uuid.v4(),
      'gig_id': gigId,
      'status': status,
      'changed_at': DateTime.now().toIso8601String(),
    });
  }

  // ─── STATS ─────────────────────────────────────────────────

  /// Kira berapa task runner ni dah siapkan
  static Future<int> getCompletedCount(String runnerId) async {
    final response = await _client
        .from(DbTable.gigs)
        .select('id')
        .eq('gig_worker_id', runnerId)
        .eq('status', GigStatus.completed);

    return (response as List).length;
  }

  /// Dapat jumlah task runner yang siap secara live
  static Stream<int> streamCompletedCount(String runnerId) {
    return _client
        .from(DbTable.gigs)
        .stream(primaryKey: ['id'])
        .map((list) => list.where((gig) => gig['gig_worker_id'] == runnerId && gig['status'] == GigStatus.completed).length);
  }

  /// Kira berapa task customer ni dah pernah post
  static Future<int> getPostedCount(String customerId) async {
    final response = await _client
        .from(DbTable.gigs)
        .select('id')
        .eq('customer_id', customerId);

    return (response as List).length;
  }
}
