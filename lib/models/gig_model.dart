// ============================================================
// Ngam App — Gig Model
// ============================================================

class GigModel {
  final String id;
  final String customerId;
  final String? gigWorkerId;
  final String title;
  final String description;
  final String category;
  final double bountyAmount;
  final String status; // OPEN, LOCKED, IN-PROGRESS, COMPLETED, CANCELLED
  final String location;
  final DateTime createdAt;

  // Joined fields (from related tables)
  final String? customerName;
  final String? runnerName;
  final double? runnerRating;

  GigModel({
    required this.id,
    required this.customerId,
    this.gigWorkerId,
    required this.title,
    required this.description,
    required this.category,
    required this.bountyAmount,
    required this.status,
    required this.location,
    required this.createdAt,
    this.customerName,
    this.runnerName,
    this.runnerRating,
  });

  /// Create from Supabase JSON row
  factory GigModel.fromJson(Map<String, dynamic> json) {
    return GigModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      gigWorkerId: json['gig_worker_id'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      bountyAmount: (json['bounty_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'OPEN',
      location: json['location'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      customerName: json['customer_name'] as String?,
      runnerName: json['runner_name'] as String?,
    );
  }

  /// Convert to JSON for Supabase insert
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'gig_worker_id': gigWorkerId,
      'title': title,
      'description': description,
      'category': category,
      'bounty_amount': bountyAmount,
      'status': status,
      'location': location,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  GigModel copyWith({
    String? id,
    String? customerId,
    String? gigWorkerId,
    String? title,
    String? description,
    String? category,
    double? bountyAmount,
    String? status,
    String? location,
    DateTime? createdAt,
    String? customerName,
    String? runnerName,
    double? runnerRating,
  }) {
    return GigModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      gigWorkerId: gigWorkerId ?? this.gigWorkerId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      bountyAmount: bountyAmount ?? this.bountyAmount,
      status: status ?? this.status,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      customerName: customerName ?? this.customerName,
      runnerName: runnerName ?? this.runnerName,
      runnerRating: runnerRating ?? this.runnerRating,
    );
  }

  /// Whether this gig is available for runners to accept
  bool get isOpen => status == 'OPEN';

  /// Whether this gig is currently being worked on
  bool get isActive => status == 'LOCKED' || status == 'IN-PROGRESS';

  /// Whether this gig has been completed
  bool get isCompleted => status == 'COMPLETED';

  /// Formatted bounty string
  String get formattedBounty => 'RM ${bountyAmount.toStringAsFixed(2)}';

  /// Short time ago string
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
