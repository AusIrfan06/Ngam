import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/gig_model.dart';
import '../../providers/gig_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/gig_service.dart';
import '../../services/chat_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/category_chip.dart';
import 'package:hugeicons/hugeicons.dart';
import '../shared/chat_screen.dart';
import '../../services/location_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================
// Ngam App — Skrin Active Job (Runner)
// View untuk job tengah jalan dengan control untuk siapkan task
// ============================================================

class ActiveJobScreen extends StatefulWidget {
  const ActiveJobScreen({super.key});

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  final _notesController = TextEditingController();
  GigModel? _gig;
  File? _proofImage;
  bool _isUploadingProof = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gig = ModalRoute.of(context)?.settings.arguments as GigModel?;
      if (gig != null) {
        setState(() => _gig = gig);
        
        // Start hantar location kalau gig tu IN-PROGRESS
        if (gig.status == 'IN-PROGRESS' && gig.gigWorkerId != null) {
          LocationService.instance.startTracking(gig.id, gig.gigWorkerId!);
        }
      }
    });
  }

  Future<void> _pickAndUploadProof() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      imageQuality: 80,
    );

    if (pickedFile != null && _gig != null && mounted) {
      setState(() {
        _proofImage = File(pickedFile.path);
        _isUploadingProof = true;
      });

      final url = await GigService.uploadProofImage(_gig!.id, _proofImage!);
      
      if (mounted) {
        setState(() {
          _isUploadingProof = false;
        });
        
        if (url != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gambar bukti berjaya dimuat naik!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal muat naik gambar.')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    LocationService.instance.stopTracking();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'runner.runner_view'.tr(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              final isRunner = context.read<AuthProvider>().isRunner;
              Navigator.pushNamedAndRemoveUntil(
                context,
                isRunner ? '/runner-home' : '/customer-home',
                (route) => false,
              );
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header Active Job ───────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.08),
                    AppTheme.accent.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.work_rounded,
                          color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'runner.active_job'.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    gig.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CategoryChip(label: gig.category),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        gig.location,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Badge status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.info.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'runner.in_progress'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── Butang Navigate & Map ───────────────
            if (gig.latitude != null && gig.longitude != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(gig.latitude!, gig.longitude!),
                            initialZoom: 15.0,
                            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.ngam',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(gig.latitude!, gig.longitude!),
                                  width: 40,
                                  height: 40,
                                  child: const HugeIcon(
                                    icon: HugeIcons.strokeRoundedLocation01,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${gig.latitude},${gig.longitude}');
                          try {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          } catch (e) {
                            debugPrint("Could not launch maps: $e");
                          }
                        },
                        icon: const HugeIcon(icon: HugeIcons.strokeRoundedNavigation01, color: AppTheme.primary, size: 20),
                        label: Text('task_detail.navigate'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppTheme.primary, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ─── Upload Bukti (Optional) ─────────────
            Text(
              'runner.upload_proof'.tr(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _isUploadingProof ? null : _pickAndUploadProof,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                  ),
                  image: _proofImage != null 
                      ? DecorationImage(
                          image: FileImage(_proofImage!),
                          fit: BoxFit.cover,
                        ) 
                      : (_gig?.proofImageUrl != null 
                          ? DecorationImage(
                              image: NetworkImage(_gig!.proofImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null),
                ),
                child: (_proofImage == null && _gig?.proofImageUrl == null && !_isUploadingProof)
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedCamera01,
                            color: Colors.grey.shade400,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'runner.tap_upload'.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      )
                    : (_isUploadingProof
                        ? const Center(child: CircularProgressIndicator())
                        : null),
              ),
            ),
            const SizedBox(height: 24),

            // ─── Nota untuk Customer ─────────────────
            Text(
              'runner.notes_requester'.tr(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'runner.notes_hint'.tr(),
              ),
            ),
            const SizedBox(height: 24),
            // ─── Butang Chat Customer ────────────────
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (auth.user?.id == gig.customerId) {
                  return const SizedBox.shrink();
                }
                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      if (auth.user == null) return;
                      // Keluarkan loading spinner jap
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const Center(child: CircularProgressIndicator()),
                      );
                      
                      try {
                        // Make sure ChatService dah import kat atas!
                        final conversation = await ChatService.createOrGetConversation(
                          auth.user!.id,
                          gig.customerId, // Orang seberang tu adalah customer
                          gigId: gig.id,
                        );
                        if (context.mounted) {
                          Navigator.pop(context); // Tutup loading tu
                          // Gerak pi ChatThreadScreen
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
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error opening chat: $e')));
                        }
                      }
                    },
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedChatting01,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                    label: Text('runner.chat_customer'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary, width: 2),
                      textStyle: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }
            ),
            const SizedBox(height: 16),

            // ─── Butang Tanda Delivered ──────────────
            Consumer<GigProvider>(
              builder: (context, gigProvider, _) {
                if (gig.status == 'PENDING_PAYMENT_CONFIRMATION') {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        HugeIcon(icon: HugeIcons.strokeRoundedBank, color: AppTheme.warning, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          'Sahkan Pembayaran QR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.warning,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pelanggan mendakwa telah membuat bayaran ke akaun anda melalui QR Code. Sila semak bank anda dan sahkan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.warning.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: gigProvider.isLoading
                                    ? null
                                    : () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (c) => AlertDialog(
                                            title: const Text('Tolak Pembayaran?'),
                                            content: const Text(
                                              'Anda pasti ingin menolak pembayaran ini? Status akan dikembalikan kepada DELIVERED.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(c, false),
                                                child: const Text('Batal'),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                ),
                                                onPressed: () => Navigator.pop(c, true),
                                                child: const Text(
                                                  'Ya, Tolak',
                                                  style: TextStyle(color: Colors.white),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true && context.mounted) {
                                          final success = await gigProvider.runnerDeclineQrPayment(gig.id);
                                          if (success && context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Pembayaran ditolak.')),
                                            );
                                          }
                                        }
                                      },
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('Tolak'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: gigProvider.isLoading
                                    ? null
                                    : () async {
                                        final success = await gigProvider.runnerAcceptQrPayment(gig.id);
                                        if (success && context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Pembayaran disahkan berjaya!')),
                                          );
                                          final isRunner = context.read<AuthProvider>().isRunner;
                                          Navigator.pushNamedAndRemoveUntil(
                                            context,
                                            isRunner ? '/runner-home' : '/customer-home',
                                            (route) => false,
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, foregroundColor: Colors.white),
                                child: const Text('Terima'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }

                if (gig.status == 'DELIVERED') {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        HugeIcon(icon: HugeIcons.strokeRoundedClock01, color: AppTheme.info, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          'Awaiting Customer Confirmation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.info,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          gig.paymentMethod == 'qr'
                              ? 'You will be notified once the customer pays via QR.'
                              : 'You will receive the payment once the customer confirms.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.info.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: gigProvider.isLoading
                        ? null
                        : () async {
                            final success = await gigProvider.deliverGig(gig.id);
                            if (success && context.mounted) {
                              // Stop hantar location bila dah delivered
                              LocationService.instance.stopTracking();
                              
                              // Keluarkan dialog delivery
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 16),
                                      Container(
                                        width: 70,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          color: AppTheme.info.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.delivery_dining,
                                          size: 40,
                                          color: AppTheme.info,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Task Delivered',
                                        style: GoogleFonts.outfit(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'The customer has been notified and needs to confirm to release the funds.',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            final isRunner = ctx.read<AuthProvider>().isRunner;
                                            Navigator.pushNamedAndRemoveUntil(
                                              ctx,
                                              isRunner ? '/runner-home' : '/customer-home',
                                              (route) => false,
                                            );
                                          },
                                          child: Text('runner.done'.tr()),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                    icon: gigProvider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: const Text('Mark as Delivered'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      textStyle: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
