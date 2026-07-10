import 'dart:math';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gig_provider.dart';
import '../../utils/constants.dart';
import '../../models/gig_model.dart';
import '../../widgets/category_chip.dart';
import '../../services/gig_service.dart';
import 'task_detail_screen.dart';
import '../customer/post_task_screen.dart';

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
          child: DefaultTabController(
            length: 2,
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
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'runner.my_jobs_title'.tr(),
                              style: GoogleFonts.outfit(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        
                        // Action Button
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/post-service');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const HugeIcon(icon: HugeIcons.strokeRoundedPlusSign, color: Colors.white, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  'Tawar Servis',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TabBar(
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    labelColor: isDark ? Colors.white : Theme.of(context).primaryColor,
                    unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    tabs: [
                      Tab(text: 'runner.customer_tasks'.tr()),
                      Tab(text: 'runner.my_services'.tr()),
                    ],
                  ),
                ),
                const SizedBox(height: 12),                
                Expanded(
                  child: gigProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          children: [
                            // Tab 1: Customer Tasks (Tasks assigned to me, customerId != currentUserId)
                            _buildJobList(
                              gigs: gigProvider.myGigs.where((g) => g.customerId != context.read<AuthProvider>().user?.id).toList(),
                              emptyMessage: 'runner.no_jobs_yet'.tr(),
                              emptySubMessage: 'runner.accept_first_gig'.tr(),
                              isDark: isDark,
                              gigProvider: gigProvider,
                            ),
                            // Tab 2: My Services (Services posted by me, customerId == currentUserId AND status is SERVICE/DISABLED_SERVICE)
                            _buildJobList(
                              gigs: gigProvider.myGigs.where((g) => 
                                g.customerId == context.read<AuthProvider>().user?.id && 
                                (g.status == 'SERVICE' || g.status == 'DISABLED_SERVICE')
                              ).toList(),
                              emptyMessage: "No services posted",
                              emptySubMessage: "Tap + Post Job to post your first service.",
                              isDark: isDark,
                              gigProvider: gigProvider,
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
        ),
      ],
    );
  }

  Widget _buildJobList({
    required List<GigModel> gigs,
    required String emptyMessage,
    required String emptySubMessage,
    required bool isDark,
    required GigProvider gigProvider,
  }) {
    if (gigs.isEmpty) {
      return Center(
        child: _buildSystemGlass(
          borderRadius: 32,
          isDark: isDark,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedWorkHistory, size: 64, color: isDark ? Colors.white54 : Colors.black45),
                const SizedBox(height: 16),
                Text(emptyMessage, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
                const SizedBox(height: 8),
                Text(emptySubMessage, style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final userId = context.read<AuthProvider>().user?.id;
        if (userId != null) {
          await gigProvider.loadRunnerGigs(userId);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: gigs.length,
        itemBuilder: (context, index) {
          final gig = gigs[index];
          return _GlassTaskCard(
            gig: gig,
            isDark: isDark,
            onTap: () {
              final currentUserId = context.read<AuthProvider>().user?.id;
              if (gig.status.contains('SERVICE')) {
                Navigator.pushNamed(context, '/task-detail', arguments: gig);
                return;
              }
              if (gig.customerId == currentUserId) {
                Navigator.pushNamed(context, '/order-status', arguments: gig);
              } else {
                if (gig.isActive) {
                  Navigator.pushNamed(context, '/active-job', arguments: gig);
                } else if (gig.status == GigStatus.pending && currentUserId != null) {
                  _showPendingOptions(context, gig, currentUserId, isDark);
                } else {
                  Navigator.pushNamed(context, '/task-detail', arguments: gig);
                }
              }
            },
            actionWidget: null,
          );
        },
      ),
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
  bool _isExpanded = false;
  
  List<GigModel>? _bookings;
  bool _isLoadingBookings = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }
  
  Future<void> _fetchBookings() async {
    if (widget.gig.status != 'SERVICE' && widget.gig.status != 'DISABLED_SERVICE') return;
    if (_bookings != null) return;
    
    setState(() => _isLoadingBookings = true);
    try {
      final fetched = await GigService.fetchBookingsForService(widget.gig.id);
      if (mounted) {
        setState(() {
          _bookings = fetched;
          _isLoadingBookings = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBookings = false);
      }
    }
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
      case 'SERVICE': return const Color(0xFF9B59B6);
      case 'DISABLED_SERVICE': return Colors.grey;
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

  Widget _buildQuickAction({
    required dynamic icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(icon: icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
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
        if (widget.gig.status == 'SERVICE' || widget.gig.status == 'DISABLED_SERVICE') {
          setState(() {
            _isExpanded = !_isExpanded;
          });
          if (_isExpanded) {
            _fetchBookings();
          }
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TaskDetailScreen(),
              settings: RouteSettings(arguments: widget.gig),
            ),
          );
        }
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
                                  HugeIcon(icon: HugeIcons.strokeRoundedLocation01, size: 14, color: widget.isDark ? Colors.white54 : Colors.black54),
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
                                CategoryChip(label: widget.gig.category, showIcon: false, isSelected: true),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor().withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _getStatusColor().withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    widget.gig.status,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            widget.gig.formattedBounty,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (widget.gig.status == 'SERVICE' || widget.gig.status == 'DISABLED_SERVICE')
                            HugeIcon(
                              icon: _isExpanded ? HugeIcons.strokeRoundedArrowUp01 : HugeIcons.strokeRoundedArrowDown01,
                              color: widget.isDark ? Colors.white54 : Colors.black54,
                              size: 20,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _isExpanded
                      ? Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Divider(color: widget.isDark ? Colors.white24 : Colors.black12, height: 1),
                            ),
                            // Quick Actions for Services
                            if (widget.gig.status == 'SERVICE' || widget.gig.status == 'DISABLED_SERVICE') ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildQuickAction(
                                      icon: HugeIcons.strokeRoundedView,
                                      label: "Details",
                                      color: Colors.blue,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const TaskDetailScreen(),
                                            settings: RouteSettings(arguments: widget.gig),
                                          ),
                                        );
                                      },
                                    ),
                                    _buildQuickAction(
                                      icon: widget.gig.status == 'DISABLED_SERVICE' ? HugeIcons.strokeRoundedPlay : HugeIcons.strokeRoundedPause,
                                      label: widget.gig.status == 'DISABLED_SERVICE' ? "Resume" : "Pause",
                                      color: Colors.orange,
                                      onTap: () async {
                                        final provider = context.read<GigProvider>();
                                        await provider.toggleGigStatus(widget.gig.id, widget.gig.status);
                                      },
                                    ),
                                    _buildQuickAction(
                                      icon: HugeIcons.strokeRoundedDelete01,
                                      label: "Delete",
                                      color: Colors.red,
                                      onTap: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (c) => AlertDialog(
                                            title: const Text('Delete Service?'),
                                            content: const Text('Are you sure you want to delete this service?'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          if (!mounted) return;
                                          final provider = context.read<GigProvider>();
                                          await provider.deleteGig(widget.gig.id);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            
                            // Bookings Section
                            if ((widget.gig.status == 'SERVICE' || widget.gig.status == 'DISABLED_SERVICE') && _isExpanded) ...[
                               Padding(
                                 padding: const EdgeInsets.symmetric(horizontal: 16),
                                 child: Divider(color: widget.isDark ? Colors.white24 : Colors.black12, height: 1),
                               ),
                               const SizedBox(height: 8),
                               Padding(
                                 padding: const EdgeInsets.symmetric(horizontal: 16),
                                 child: Row(
                                   children: [
                                      HugeIcon(icon: HugeIcons.strokeRoundedUserGroup, size: 16, color: widget.isDark ? Colors.white70 : Colors.black87),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Customer Bookings", 
                                        style: TextStyle(
                                          fontSize: 13, 
                                          fontWeight: FontWeight.w700, 
                                          color: widget.isDark ? Colors.white70 : Colors.black87,
                                        ),
                                      ),
                                   ]
                                 ),
                               ),
                               const SizedBox(height: 8),
                               if (_isLoadingBookings)
                                 const Padding(
                                   padding: EdgeInsets.all(16.0),
                                   child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                                 )
                               else if (_bookings != null && _bookings!.isEmpty)
                                 Padding(
                                   padding: const EdgeInsets.all(16.0),
                                   child: Center(
                                     child: Text(
                                       "No bookings yet.", 
                                       style: TextStyle(fontSize: 13, color: widget.isDark ? Colors.white54 : Colors.black54),
                                     ),
                                   ),
                                 )
                               else if (_bookings != null)
                                 Padding(
                                   padding: const EdgeInsets.symmetric(horizontal: 12),
                                   child: Column(
                                     children: _bookings!.map((booking) => Container(
                                       margin: const EdgeInsets.only(bottom: 8),
                                       padding: const EdgeInsets.all(12),
                                       decoration: BoxDecoration(
                                         color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
                                         borderRadius: BorderRadius.circular(12),
                                       ),
                                       child: Row(
                                         children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                                              child: Text(
                                                (booking.customerName?.isNotEmpty ?? false) ? booking.customerName![0].toUpperCase() : 'C',
                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    booking.customerName ?? 'Unknown Customer',
                                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    booking.status,
                                                    style: TextStyle(
                                                      fontSize: 11, 
                                                      fontWeight: FontWeight.w700, 
                                                      color: booking.status == 'PENDING' ? Colors.orange : (booking.status == 'COMPLETED' ? Colors.green : Colors.blue),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Action Buttons for booking
                                            if (booking.status == 'PENDING') ...[
                                              IconButton(
                                                icon: const HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkBadge01, size: 20, color: Colors.green),
                                                onPressed: () async {
                                                   final provider = context.read<GigProvider>();
                                                   await provider.acceptPendingGig(booking.id, widget.gig.gigWorkerId!);
                                                   _fetchBookings(); // Refresh
                                                },
                                              ),
                                              IconButton(
                                                icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 20, color: Colors.red),
                                                onPressed: () async {
                                                   final provider = context.read<GigProvider>();
                                                   await provider.rejectPendingGig(booking.id, widget.gig.gigWorkerId!);
                                                   _fetchBookings(); // Refresh
                                                },
                                              ),
                                            ] else if (booking.status == 'IN-PROGRESS' || booking.status == 'LOCKED') ...[
                                              IconButton(
                                                icon: const HugeIcon(icon: HugeIcons.strokeRoundedTaskDone01, size: 20, color: Colors.blue),
                                                onPressed: () async {
                                                   final provider = context.read<GigProvider>();
                                                   await provider.completeGig(booking.id);
                                                   _fetchBookings(); // Refresh
                                                },
                                              ),
                                            ]
                                         ],
                                       ),
                                     )).toList(),
                                   ),
                                 ),
                               const SizedBox(height: 8),
                            ],
                          ],
                        )
                      : const SizedBox.shrink(),
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

