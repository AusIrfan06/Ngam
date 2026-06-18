import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/gig_model.dart';
import '../../services/gig_service.dart';
import '../../services/review_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/sla_countdown.dart';
import '../../widgets/status_timeline.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../shared/chat_screen.dart';

// ============================================================
// Ngam App — Order Status Screen (Customer)
// Real-time task tracking with SLA countdown
// ============================================================

class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({super.key});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  GigModel? _gig;
  StreamSubscription? _subscription;
  bool _hasReview = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gig = ModalRoute.of(context)?.settings.arguments as GigModel?;
      if (gig != null) {
        setState(() => _gig = gig);
        _subscribeToUpdates(gig.id);
        _checkReview(gig.id);
      }
    });
  }

  void _subscribeToUpdates(String gigId) {
    _subscription = GigService.subscribeToGig(gigId).listen((updatedGig) {
      if (mounted) {
        setState(() => _gig = updatedGig);
      }
    });
  }

  Future<void> _checkReview(String gigId) async {
    final has = await ReviewService.hasReview(gigId);
    if (mounted) {
      setState(() => _hasReview = has);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gig == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final gig = _gig!;
    final gigIdShort = gig.id.substring(0, 8).toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'order_status.title'.tr(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Task Header Card ────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gig.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'order_status.task_id'.tr(args: [gigIdShort]),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CategoryChip(label: gig.category),
                      const Spacer(),
                      Text(
                        gig.formattedBounty,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── Status Timeline ─────────────────────
            Text(
              'order_status.status_label'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            StatusTimeline(
              currentStatus: gig.status,
              runnerName: gig.runnerName,
            ),
            const SizedBox(height: 16),

            // ─── SLA Countdown (when task is locked/in-progress) ─
            if (gig.isActive) ...[
              SlaCountdown(
                category: gig.category,
                startTime: gig.createdAt,
                onExpired: () {
                  // SLA expired notification
                },
              ),
              const SizedBox(height: 20),
            ],

            // ─── Runner Info (when assigned) ─────────
            if (gig.gigWorkerId != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    // Runner avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'order_status.runner_assigned'.tr(args: [gig.runnerName ?? 'order_status.assigned'.tr()]),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  size: 14, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                gig.runnerRating?.toStringAsFixed(1) ?? '4.8',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Chat button
                    if (gig.gigWorkerId != null && gig.gigWorkerId != context.read<AuthProvider>().user?.id)
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      child: IconButton(
                        onPressed: () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(child: CircularProgressIndicator()),
                          );
                          try {
                            final auth = context.read<AuthProvider>();
                            if (auth.user == null) return;
                            final conversation = await ChatService.createOrGetConversation(
                              auth.user!.id,
                              gig.gigWorkerId!,
                              gigId: gig.id,
                            );
                            if (context.mounted) {
                              Navigator.pop(context); // Close loading dialog
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatThreadScreen(conversation: conversation),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('order_status.err_chat'.tr(args: [e.toString()]))));
                            }
                          }
                        },
                        icon: const Icon(
                          Icons.chat_bubble_outline,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ─── Review Button (when completed) ─────
            if (gig.isCompleted && !_hasReview) ...[
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      '/review',
                      arguments: gig,
                    );
                    if (result == true) {
                      setState(() => _hasReview = true);
                    }
                  },
                  icon: const Icon(Icons.star_rounded),
                  label: Text('order_status.rate_review'.tr()),
                ),
              ),
            ],

            if (_hasReview) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppTheme.success, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'order_status.review_submitted'.tr(),
                      style: const TextStyle(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
