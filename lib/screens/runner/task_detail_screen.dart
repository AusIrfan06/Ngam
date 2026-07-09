import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/gig_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/category_chip.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../providers/gig_provider.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/chat_service.dart';
import '../shared/chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================
// Ngam App — Task Detail Screen (Runner)
// Detailed view of a gig before accepting
// ============================================================

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  GigModel? _gig;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_gig == null) {
      _gig = ModalRoute.of(context)?.settings.arguments as GigModel?;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().user?.id;
    final gig = _gig;
    
    if (gig == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            actions: [
              if (gig.customerId == currentUserId)
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: _showManageServiceMenu,
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                'runner.task_detail'.tr(),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Task Title ──────────────────────────
                    Text(
                      gig.title,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ─── Category Tag ────────────────────────
                    CategoryChip(label: gig.category),
                    const SizedBox(height: 20),

                    // ─── Location ────────────────────────────
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 20,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            gig.location,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ─── Mini Map ────────────────────────────
                    if (gig.latitude != null && gig.longitude != null)
                      Container(
                        height: 180,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(gig.latitude!, gig.longitude!),
                            initialZoom: 15.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: Theme.of(context).brightness == Brightness.dark
                                  ? 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                                  : 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.ngam',
                              errorTileCallback: (tile, error, stackTrace) {},
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(gig.latitude!, gig.longitude!),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    // ─── Navigate Button ─────────────────────
                    if (gig.latitude != null && gig.longitude != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${gig.latitude},${gig.longitude}');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                            icon: const Icon(Icons.navigation_rounded),
                            label: Text('task_detail.navigate'.tr()),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: AppTheme.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // ─── Posted Time ─────────────────────────
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 20,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'runner.posted_time'.tr(args: [gig.timeAgo]),
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ─── Description ─────────────────────────
                    _buildGlassSection(
                      isDark: Theme.of(context).brightness == Brightness.dark,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          gig.description,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ─── Customer Info ───────────────────────
                    _buildGlassSection(
                      isDark: Theme.of(context).brightness == Brightness.dark,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppTheme.info.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: AppTheme.info,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gig.customerName ?? 'Customer',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Row(
                                  children: [
                                    Icon(Icons.star, size: 16, color: Colors.amber),
                                    SizedBox(width: 6),
                                    Text(
                                      '4.8 (12 tasks)',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Chat Button
                          if (gig.customerId != currentUserId)
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: () async {
                                  if (currentUserId == null) return;
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => const Center(child: CircularProgressIndicator()),
                                  );
                                  try {
                                    final conversation = await ChatService.createOrGetConversation(
                                      currentUserId,
                                      gig.customerId,
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
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error starting chat: $e')));
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
                    ),
                    const SizedBox(height: 40),

                    // ─── Bounty Amount ───────────────────────
                    Center(
                      child: Column(
                        children: [
                          Text(
                            gig.formattedBounty,
                            style: GoogleFonts.outfit(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'runner.bounty_offered'.tr(),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ─── Accept Button ───────────────────────
                    if (gig.customerId != currentUserId)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: _buildGlassButton(
                          isDark: Theme.of(context).brightness == Brightness.dark,
                          icon: Icons.check_circle_outline,
                          label: 'runner.accept_task'.tr(),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/confirm-acceptance',
                              arguments: gig,
                            );
                          },
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: _buildGlassButton(
                          isDark: Theme.of(context).brightness == Brightness.dark,
                          icon: Icons.settings_outlined,
                          label: 'Manage Service',
                          onTap: _showManageServiceMenu,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  LiquidGlassSettings _getGlassSettings(bool isDark) {
    return LiquidGlassSettings(
      thickness: 0.1,
      blur: 15,
      refractiveIndex: 1.0,
      glassColor: Colors.transparent,
      lightAngle: 45.0,
      lightIntensity: isDark ? 0.1 : 0.2,
      ambientStrength: 1.0,
      saturation: 1.0,
      chromaticAberration: 0.0,
    );
  }

  Widget _buildGlassSection({required bool isDark, required Widget child}) {
    return GlassContainer(
      useOwnLayer: true,
      quality: GlassQuality.standard,
      shape: LiquidRoundedSuperellipse(borderRadius: 16.0),
      settings: _getGlassSettings(isDark),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildGlassButton(
      {required bool isDark,
      required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: GlassContainer(
        quality: GlassQuality.standard,
        shape: LiquidRoundedSuperellipse(borderRadius: 16.0),
        settings: _getGlassSettings(isDark),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showManageServiceMenu() {
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
              Text('task_detail.manage_service'.tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.attach_money, color: isDark ? Colors.white70 : Colors.black87),
                title: Text('task_detail.adjust_bounty'.tr(), style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showAdjustBountyDialog();
                },
              ),
              ListTile(
                leading: Icon(gig.status == 'DISABLED_SERVICE' ? Icons.play_arrow : Icons.pause, color: isDark ? Colors.white70 : Colors.black87),
                title: Text(gig.status == 'DISABLED_SERVICE' ? 'Resume Service' : 'Pause Service', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final isPausing = gig.status != 'DISABLED_SERVICE';
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: Text(isPausing ? 'Pause Service?' : 'Resume Service?'),
                      content: Text(isPausing ? 'Are you sure you want to pause this service? It will not be visible to customers.' : 'Are you sure you want to resume this service?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(c, true), child: Text(isPausing ? 'Pause' : 'Resume', style: const TextStyle(color: Colors.blue))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    if (!mounted) return;
                    await context.read<GigProvider>().toggleGigStatus(gig.id, gig.status);
                    if (!mounted) return;
                    setState(() {
                      _gig = _gig!.copyWith(status: gig.status == 'DISABLED_SERVICE' ? 'SERVICE' : 'DISABLED_SERVICE');
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text('task_detail.delete_service'.tr(), style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: Text('task_detail.delete_service_title'.tr()),
                      content: Text('task_detail.delete_service_desc'.tr()),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: Text('task_detail.cancel'.tr())),
                        TextButton(onPressed: () => Navigator.pop(c, true), child: Text('task_detail.delete'.tr(), style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    if (!mounted) return;
                    await context.read<GigProvider>().deleteGig(gig.id);
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
    final TextEditingController controller = TextEditingController(text: _gig!.bountyAmount.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('task_detail.adjust_bounty'.tr()),
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
            child: Text('task_detail.cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                await context.read<GigProvider>().updateGigBounty(_gig!.id, val);
                setState(() {
                  _gig = _gig!.copyWith(bountyAmount: val);
                });
                if (mounted) Navigator.pop(context);
              }
            },
            child: Text('task_detail.save'.tr()),
          ),
        ],
      ),
    );
  }
}
