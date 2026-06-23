import 'package:flutter/material.dart';
import '../models/gig_model.dart';
import 'category_chip.dart';

// ============================================================
// Ngam App — Task Card Widget (Rezrv Inspired)
// Displays a gig/task in a premium vertical card format
// ============================================================

class TaskCard extends StatefulWidget {
  final GigModel gig;
  final VoidCallback? onTap;
  final bool showStatus;
  final Widget? actionWidget;

  const TaskCard({
    super.key,
    required this.gig,
    this.onTap,
    this.showStatus = false,
    this.actionWidget,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (widget.gig.status) {
      case 'OPEN':
        return const Color(0xFF2ECC71);
      case 'LOCKED':
        return const Color(0xFFF39C12);
      case 'IN-PROGRESS':
        return const Color(0xFF3498DB);
      case 'COMPLETED':
        return const Color(0xFF27AE60);
      case 'CANCELLED':
        return const Color(0xFFE74C3C);
      default:
        return Colors.grey;
    }
  }

  List<Color> _getCategoryGradient() {
    switch (widget.gig.category) {
      case 'Delivery': return [const Color(0xFFFF9A9E), const Color(0xFFFECFEF)];
      case 'Cleaning': return [const Color(0xFF4FACFE), const Color(0xFF00F2FE)];
      case 'Assembly': return [const Color(0xFFFCCB90), const Color(0xFFD57EEB)];
      case 'Shopping': return [const Color(0xFFE0C3FC), const Color(0xFF8EC5FC)];
      case 'Moving': return [const Color(0xFF84FAB0), const Color(0xFF8FD3F4)];
      default: return [const Color(0xFF43E97B), const Color(0xFF38F9D7)];
    }
  }

  IconData _getCategoryIcon() {
    switch (widget.gig.category) {
      case 'Delivery': return Icons.local_shipping_rounded;
      case 'Cleaning': return Icons.cleaning_services_rounded;
      case 'Assembly': return Icons.build_circle_rounded;
      case 'Shopping': return Icons.shopping_cart_rounded;
      case 'Moving': return Icons.inventory_2_rounded;
      default: return Icons.task_alt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        if (widget.onTap != null) widget.onTap!();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cover Image / Gradient Header
              Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getCategoryGradient(),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        _getCategoryIcon(),
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    if (widget.showStatus)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              )
                            ],
                          ),
                          child: Text(
                            widget.gig.status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _getStatusColor(),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Content Area
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Price Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.gig.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
                    const SizedBox(height: 12),

                    // Location
                    if (widget.gig.location.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.gig.location,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Category Chip
                    CategoryChip(
                      label: widget.gig.category,
                      showIcon: false,
                    ),

                    if (widget.actionWidget != null) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: widget.actionWidget,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
