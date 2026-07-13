import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
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
import '../../providers/gig_provider.dart';
import '../../services/chat_service.dart';
import '../shared/chat_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// Ngam App — Skrin Status Order (Customer)
// Track task secara live siap dengan SLA countdown
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
  RealtimeChannel? _trackingChannel;
  LatLng? _runnerLocation;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gig = ModalRoute.of(context)?.settings.arguments as GigModel?;
      if (gig != null) {
        setState(() => _gig = gig);
        _subscribeToUpdates(gig.id);
        _checkReview(gig.id);
        if (gig.status == 'IN-PROGRESS') {
          _subscribeToLocation(gig.id);
        }
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

  void _subscribeToLocation(String gigId) {
    _trackingChannel = Supabase.instance.client.channel(
      'public:gig_location:$gigId',
    );
    _trackingChannel!
        .onBroadcast(
          event: 'location_update',
          callback: (payload) {
            if (mounted) {
              final lat = payload['lat'];
              final lng = payload['lng'];
              if (lat != null && lng != null) {
                final newPos = LatLng(
                  lat is int ? lat.toDouble() : lat as double,
                  lng is int ? lng.toDouble() : lng as double,
                );
                setState(() {
                  _runnerLocation = newPos;
                });
                // Cuba alih map sikit supaya nampak dua-dua lokasi
                if (_gig != null &&
                    _gig!.latitude != null &&
                    _gig!.longitude != null) {
                  final dest = LatLng(_gig!.latitude!, _gig!.longitude!);
                  final bounds = LatLngBounds.fromPoints([newPos, dest]);
                  try {
                    _mapController.fitCamera(
                      CameraFit.bounds(
                        bounds: bounds,
                        padding: const EdgeInsets.all(40),
                      ),
                    );
                  } catch (_) {}
                }
              }
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _trackingChannel?.unsubscribe();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gig == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final gig = _gig!;
    final gigIdShort = gig.id.substring(0, 8).toUpperCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'order_status.title'.tr(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (gig.status == 'OPEN' || gig.status == 'DISABLED')
            IconButton(
              icon: HugeIcon(icon: HugeIcons.strokeRoundedSettings01),
              onPressed: _showManageTaskMenu,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Kad Task Header ─────────────────────
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

            // ─── Timeline Status ─────────────────────
            Text(
              'order_status.status_label'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            StatusTimeline(
              currentStatus: gig.status,
              runnerName: gig.runnerName,
            ),
            const SizedBox(height: 16),

            // ─── SLA Countdown (bila task tengah jalan) ─
            if (gig.isActive) ...[
              SlaCountdown(
                category: gig.category,
                startTime: gig.createdAt,
                onExpired: () {
                  // SLA dah habis masa (expired)
                },
              ),
              const SizedBox(height: 20),
            ],

            // ─── Map Live Tracking ───────────────────
            if (gig.status == 'IN-PROGRESS' &&
                gig.latitude != null &&
                gig.longitude != null) ...[
              Text(
                'Live Location',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                clipBehavior: Clip.antiAlias,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(gig.latitude!, gig.longitude!),
                    initialZoom: 14.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          Theme.of(context).brightness == Brightness.dark
                          ? 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                          : 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.ngam',
                      errorTileCallback: (tile, error, stackTrace) {},
                    ),
                    MarkerLayer(
                      markers: [
                        // Marker destinasi
                        Marker(
                          point: LatLng(gig.latitude!, gig.longitude!),
                          width: 40,
                          height: 40,
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedLocation01,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                        // Marker si runner
                        if (_runnerLocation != null)
                          Marker(
                            point: _runnerLocation!,
                            width: 50,
                            height: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedDeliveryTruck01,
                                color: AppTheme.primary,
                                size: 30,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ─── Info Runner (lepas dah assign) ──────
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
                    // Avatar runner
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                      backgroundImage: NetworkImage(
                        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(gig.runnerName ?? 'Runner')}&background=random&color=fff',
                      ),
                      onBackgroundImageError: (e, s) {},
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'order_status.runner_assigned'.tr(
                              args: [
                                gig.runnerName ?? 'order_status.assigned'.tr(),
                              ],
                            ),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedStar,
                                size: 14,
                                color: Colors.amber,
                              ),
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
                    // Butang chat
                    if (gig.gigWorkerId != null &&
                        gig.gigWorkerId !=
                            context.read<AuthProvider>().user?.id)
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
                              builder: (_) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                            try {
                              final auth = context.read<AuthProvider>();
                              if (auth.user == null) return;
                              final conversation =
                                  await ChatService.createOrGetConversation(
                                    auth.user!.id,
                                    gig.gigWorkerId!,
                                    gigId: gig.id,
                                  );
                              if (context.mounted) {
                                Navigator.pop(context); // Tutup loading tu
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatThreadScreen(
                                      conversation: conversation,
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'order_status.err_chat'.tr(
                                        args: [e.toString()],
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedChatting01,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ─── Butang Confirm Siap (bila dah delivered) ─────
            if (gig.status == 'DELIVERED') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Task Delivered',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.info,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      gig.paymentMethod == 'qr'
                          ? 'The runner has marked this task as delivered. Please pay via QR code below and confirm.'
                          : 'The runner has marked this task as delivered. Please confirm to release the payment.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (gig.proofImageUrl != null) ...[
                      Text(
                        'Bukti Penghantaran',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          gig.proofImageUrl!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (gig.paymentMethod == 'qr') ...[
                      if (gig.runnerQrCodeUrl != null) ...[
                        Text(
                          'Sila imbas QR Code di bawah untuk membayar runner',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              gig.runnerQrCodeUrl!,
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        Text(
                          'Runner tidak mempunyai QR code, sila hubungi runner untuk bayaran manual.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Confirm Payment?'),
                                content: const Text(
                                  'Are you sure you have paid the runner via QR code?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.success,
                                    ),
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text(
                                      'Yes, I Have Paid',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true && context.mounted) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                              final success = await context
                                  .read<GigProvider>()
                                  .customerConfirmQrPayment(gig.id);
                              if (context.mounted) {
                                Navigator.pop(context); // tutup loader
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Payment marked as done! Waiting for runner confirmation.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.qr_code_2),
                          label: const Text('I Have Paid via QR'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Confirm Completion?'),
                                content: const Text(
                                  'Are you sure the task is completed satisfactorily? The payment will be released to the runner immediately.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.success,
                                    ),
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text(
                                      'Confirm & Pay',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true && context.mounted) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                              final success = await context
                                  .read<GigProvider>()
                                  .completeGig(gig.id, gig.gigWorkerId!);
                              if (context.mounted) {
                                Navigator.pop(context); // tutup loader
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Payment released successfully!',
                                      ),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Confirm & Release Payment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (gig.status == 'PENDING_PAYMENT_CONFIRMATION') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Menunggu Pengesahan Runner',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.warning,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sila tunggu runner semak dan sahkan pembayaran yang telah dibuat.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ─── Butang Review (lepas siap semua) ───
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
                  icon: HugeIcon(icon: HugeIcons.strokeRoundedStar),
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
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                      color: AppTheme.success,
                      size: 20,
                    ),
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

  void _showManageTaskMenu() {
    final gig = _gig!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Manage Task',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedMoney03,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                title: Text(
                  'Adjust Bounty',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showAdjustBountyDialog();
                },
              ),
              ListTile(
                leading: HugeIcon(
                  icon: gig.status.startsWith('DISABLED')
                      ? HugeIcons.strokeRoundedPlay
                      : HugeIcons.strokeRoundedPause,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                title: Text(
                  gig.status.startsWith('DISABLED')
                      ? 'Resume Task'
                      : 'Pause Task',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final isPausing = !gig.status.startsWith('DISABLED');
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: Text(isPausing ? 'Pause Task?' : 'Resume Task?'),
                      content: Text(
                        isPausing
                            ? 'Are you sure you want to pause this task? It will not be visible to runners.'
                            : 'Are you sure you want to resume this task?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: Text(
                            isPausing ? 'Pause' : 'Resume',
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    if (!mounted) return;
                    await context.read<GigProvider>().toggleGigStatus(
                      gig.id,
                      gig.status,
                    );

                    final newStatus = gig.status == 'DISABLED'
                        ? 'OPEN'
                        : gig.status == 'DISABLED'
                        ? 'SERVICE'
                        : gig.status == 'SERVICE'
                        ? 'DISABLED'
                        : 'DISABLED';

                    setState(() {
                      _gig = _gig!.copyWith(status: newStatus);
                    });
                  }
                },
              ),
              ListTile(
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedCancel01,
                  color: Colors.red,
                ),
                title: const Text(
                  'Cancel Task & Refund',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Cancel Task?'),
                      content: const Text(
                        'Are you sure you want to cancel this task? Your payment will be refunded to your wallet.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text(
                            'Cancel Task',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    if (!mounted) return;
                    final authProvider = context.read<AuthProvider>();
                    await context.read<GigProvider>().cancelGigAndRefund(
                      gig.id,
                      authProvider.user!.id,
                    );
                    await authProvider.refreshBalance();
                    if (mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAdjustBountyDialog() {
    final TextEditingController controller = TextEditingController(
      text: _gig!.bountyAmount.toStringAsFixed(2),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adjust Bounty'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'New Amount (RM)',
            prefixText: 'RM ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                await context.read<GigProvider>().updateGigBounty(
                  _gig!.id,
                  val,
                );
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
