import 'dart:math';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gig_provider.dart';
import '../../utils/constants.dart';
import '../customer/post_task_screen.dart';
import '../../models/gig_model.dart';
import '../../widgets/category_chip.dart';

// ============================================================
// Ngam App — My Jobs Screen (Runner)
// List of accepted/completed jobs for the runner
// ============================================================

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _bgAnimationController;

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        context.read<GigProvider>().loadRunnerGigs(userId);
      }
    });
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    super.dispose();
  }

  Widget _buildSystemGlass({
    required Widget child,
    required double borderRadius,
    required bool isDark,
    Color? customColor,
    double blur = 20.0,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: customColor ?? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.4),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gigProvider = context.watch<GigProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Animated Abstract Background
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _bgAnimationController,
            builder: (context, child) {
              return Stack(
                children: [
                  Container(
                    color: isDark ? const Color(0xFF151515) : const Color(0xFFE5E7EB),
                  ),
                  Positioned(
                    top: -100 + 50 * sin(_bgAnimationController.value * 2 * pi),
                    left: -50 + 30 * cos(_bgAnimationController.value * 2 * pi),
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withValues(alpha: 0.3),
                        boxShadow: [
                          BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 100, spreadRadius: 50)
                        ]
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -50 + 40 * cos(_bgAnimationController.value * 2 * pi),
                    right: -50 + 60 * sin(_bgAnimationController.value * 2 * pi),
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.purple.withValues(alpha: 0.3),
                        boxShadow: [
                          BoxShadow(color: Colors.purple.withValues(alpha: 0.3), blurRadius: 100, spreadRadius: 50)
                        ]
                      ),
                    ),
                  ),
                ],
              );
            }
          ),
        ),
        
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Glass Header
                _buildSystemGlass(
                  borderRadius: 24,
                  isDark: isDark,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'runner.my_jobs_title'.tr(),
                              style: GoogleFonts.outfit(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'runner.jobs_count'.tr(args: [gigProvider.myGigs.length.toString()]),
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        _buildSystemGlass(
                          borderRadius: 16,
                          isDark: isDark,
                          blur: 15,
                          customColor: Theme.of(context).primaryColor.withValues(alpha: 0.8),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const PostTaskScreen()));
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.add, size: 18, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'runner.post_job'.tr(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: gigProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : gigProvider.myGigs.isEmpty
                          ? Center(
                              child: _buildSystemGlass(
                                borderRadius: 32,
                                isDark: isDark,
                                child: Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.work_off_outlined,
                                        size: 64,
                                        color: isDark ? Colors.white54 : Colors.black45,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'runner.no_jobs_yet'.tr(),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white70 : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'runner.accept_first_gig'.tr(),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? Colors.white54 : Colors.black54,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                final userId = context.read<AuthProvider>().user?.id;
                                if (userId != null) {
                                  await gigProvider.loadRunnerGigs(userId);
                                }
                              },
                              child: ListView.builder(
                                padding: const EdgeInsets.only(bottom: 100), // padding for bottom nav
                                itemCount: gigProvider.myGigs.length,
                                itemBuilder: (context, index) {
                                  final gig = gigProvider.myGigs[index];
                                  return _GlassTaskCard(
                                    gig: gig,
                                    isDark: isDark,
                                    onTap: () {
                                      if (gig.status == 'SERVICE') return;
                                      final currentUserId = context.read<AuthProvider>().user?.id;
                                      if (gig.customerId == currentUserId) {
                                        Navigator.pushNamed(context, '/order-status', arguments: gig);
                                      } else {
                                        if (gig.isActive) {
                                          Navigator.pushNamed(context, '/active-job', arguments: gig);
                                        } else if (gig.status == GigStatus.pending && currentUserId != null) {
                                          _showPendingOptions(context, gig, currentUserId, isDark);
                                        }
                                      }
                                    },
                                    actionWidget: gig.status == 'SERVICE'
                                        ? TextButton(
                                            onPressed: () async {
                                              final success = await context.read<GigProvider>().takeDownService(gig.id);
                                              if (success && context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('runner.service_taken_down'.tr())),
                                                );
                                              }
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.redAccent,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: Text('runner.take_down'.tr(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                          )
                                        : null,
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPendingOptions(BuildContext context, GigModel gig, String runnerId, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return _buildSystemGlass(
          borderRadius: 32,
          isDark: isDark,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Order Request',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'A customer wants to hire you for:\n"${gig.title}"\n\nDo you want to accept this order?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  _buildSystemGlass(
                    borderRadius: 16,
                    isDark: isDark,
                    customColor: Theme.of(context).primaryColor.withValues(alpha: 0.8),
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(bottomSheetContext);
                        final gigProvider = context.read<GigProvider>();
                        final success = await gigProvider.acceptPendingGig(gig.id, runnerId);
                        if (success && context.mounted) {
                          Navigator.pushNamed(context, '/active-job', arguments: gig);
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: Text('Accept Order', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(bottomSheetContext);
                      final gigProvider = context.read<GigProvider>();
                      await gigProvider.rejectPendingGig(gig.id, runnerId);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Reject Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GlassTaskCard extends StatefulWidget {
  final GigModel gig;
  final VoidCallback? onTap;
  final Widget? actionWidget;
  final bool isDark;

  const _GlassTaskCard({
    required this.gig,
    this.onTap,
    this.actionWidget,
    required this.isDark,
  });

  @override
  State<_GlassTaskCard> createState() => _GlassTaskCardState();
}

class _GlassTaskCardState extends State<_GlassTaskCard> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (widget.gig.status) {
      case 'OPEN': return const Color(0xFF2ECC71);
      case 'LOCKED': return const Color(0xFFF39C12);
      case 'IN-PROGRESS': return const Color(0xFF3498DB);
      case 'COMPLETED': return const Color(0xFF27AE60);
      case 'CANCELLED': return const Color(0xFFE74C3C);
      default: return Colors.grey;
    }
  }

  IconData _getCategoryIcon() {
    switch (widget.gig.category) {
      case 'Food': return Icons.fastfood_rounded;
      case 'Shopping': return Icons.shopping_cart_rounded;
      case 'Print': return Icons.print_rounded;
      case 'Heavy': return Icons.fitness_center_rounded;
      case 'Parcel': return Icons.local_shipping_rounded;
      case 'Cleaning': return Icons.cleaning_services_rounded;
      case 'Pet Care': return Icons.pets_rounded;
      case 'Errands': return Icons.directions_run_rounded;
      case 'Automotive': return Icons.directions_car_rounded;
      case 'Others': return Icons.category_rounded;
      default: return Icons.task_alt_rounded;
    }
  }

  Widget _buildSystemGlass({
    required Widget child,
    required double borderRadius,
    Color? customColor,
    double blur = 20.0,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: customColor ?? (widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: widget.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.4),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        if (widget.onTap != null) widget.onTap!();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(scale: _scaleAnimation.value, child: child),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildSystemGlass(
            borderRadius: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSystemGlass(
                        borderRadius: 16,
                        blur: 10,
                        customColor: widget.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.4),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: Icon(_getCategoryIcon(), size: 28, color: widget.isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.gig.title,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.2),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            if (widget.gig.location.isNotEmpty) ...[
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded, size: 14, color: widget.isDark ? Colors.white54 : Colors.black54),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      widget.gig.location,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: widget.isDark ? Colors.white70 : Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                CategoryChip(label: widget.gig.category, showIcon: false),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor().withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _getStatusColor().withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    widget.gig.status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: _getStatusColor(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.gig.formattedBounty,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.actionWidget != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: widget.actionWidget,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

