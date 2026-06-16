import 'package:uuid/uuid.dart';
import '../models/review_model.dart';
import '../utils/constants.dart';
import 'supabase_service.dart';

// ============================================================
// Ngam App — Review Service
// Handles review/rating submission and retrieval
// ============================================================

class ReviewService {
  static final _client = SupabaseService.client;
  static const _uuid = Uuid();

  /// Submit a review for a completed gig
  static Future<ReviewModel> submitReview({
    required String gigId,
    required String reviewerId,
    required int rating,
    required String comment,
  }) async {
    final reviewData = {
      'id': _uuid.v4(),
      'gig_id': gigId,
      'reviewer_id': reviewerId,
      'rating': rating,
      'comment': comment,
      'created_at': DateTime.now().toIso8601String(),
    };

    await _client.from(DbTable.reviews).insert(reviewData);

    return ReviewModel.fromJson(reviewData);
  }

  /// Fetch all reviews for gigs completed by a specific runner
  static Future<List<ReviewModel>> fetchRunnerReviews(String runnerId) async {
    // Get all gig IDs completed by this runner
    final gigsResponse = await _client
        .from(DbTable.gigs)
        .select('id')
        .eq('gig_worker_id', runnerId)
        .eq('status', 'COMPLETED');

    final gigIds = (gigsResponse as List).map((g) => g['id'] as String).toList();

    if (gigIds.isEmpty) return [];

    final response = await _client
        .from(DbTable.reviews)
        .select()
        .inFilter('gig_id', gigIds)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ReviewModel.fromJson(json))
        .toList();
  }

  /// Get the average rating for a runner
  static Future<double> getAverageRating(String runnerId) async {
    final reviews = await fetchRunnerReviews(runnerId);
    if (reviews.isEmpty) return 0.0;

    final total = reviews.fold<int>(0, (sum, r) => sum + r.rating);
    return total / reviews.length;
  }

  /// Check if a review already exists for a gig
  static Future<bool> hasReview(String gigId) async {
    final response = await _client
        .from(DbTable.reviews)
        .select('id')
        .eq('gig_id', gigId);

    return (response as List).isNotEmpty;
  }
}
