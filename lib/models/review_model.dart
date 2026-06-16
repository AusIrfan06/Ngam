// ============================================================
// Ngam App — Review Model
// ============================================================

class ReviewModel {
  final String id;
  final String gigId;
  final String reviewerId;
  final int rating;
  final String comment;
  final DateTime createdAt;

  // Joined field
  final String? reviewerName;

  ReviewModel({
    required this.id,
    required this.gigId,
    required this.reviewerId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.reviewerName,
  });

  /// Create from Supabase JSON row
  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      gigId: json['gig_id'] as String,
      reviewerId: json['reviewer_id'] as String,
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      reviewerName: json['reviewer_name'] as String?,
    );
  }

  /// Convert to JSON for Supabase insert
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gig_id': gigId,
      'reviewer_id': reviewerId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
