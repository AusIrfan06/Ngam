// ============================================================
// Ngam App — Status Log Model
// ============================================================

class StatusLogModel {
  final String id;
  final String gigId;
  final String status;
  final DateTime changedAt;

  StatusLogModel({
    required this.id,
    required this.gigId,
    required this.status,
    required this.changedAt,
  });

  /// Create from Supabase JSON row
  factory StatusLogModel.fromJson(Map<String, dynamic> json) {
    return StatusLogModel(
      id: json['id'] as String,
      gigId: json['gig_id'] as String,
      status: json['status'] as String? ?? '',
      changedAt: DateTime.parse(json['changed_at'] as String),
    );
  }

  /// Convert to JSON for Supabase insert
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gig_id': gigId,
      'status': status,
      'changed_at': changedAt.toIso8601String(),
    };
  }
}
