import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gig_provider.dart';
import '../../models/gig_model.dart';
import '../../utils/constants.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/task_card.dart';
import '../../widgets/bottom_nav_customer.dart';
import 'my_tasks_screen.dart';
import '../shared/profile_screen.dart';
import '../shared/chat_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:hugeicons/hugeicons.dart';

// ============================================================
// Ngam App — Customer Home Screen (Rezrv Inspired)
// Dashboard with visual feeds, trending tasks, and categories
// ============================================================

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final gigProvider = context.read<GigProvider>();
      await gigProvider.loadServices();
      FlutterNativeSplash.remove();
    });
  }

  LiquidGlassSettings _getGlassSettings(bool isDark, {double blur = 2.0}) {
    return isDark
        ? LiquidGlassSettings(
      thickness: 0.1,
      blur: blur,
      refractiveIndex: 1.0,
      glassColor: Colors.transparent,
      lightAngle: 45.0,
      lightIntensity: 0.1,
      ambientStrength: 1.0,
      saturation: 1.0,
      chromaticAberration: 0.0,
    )
        : LiquidGlassSettings(
      thickness: 0.1,
      blur: blur,
      refractiveIndex: 1.0,
      glassColor: Colors.transparent,
      lightAngle: 45.0,
      lightIntensity: 0.2,
      ambientStrength: 1.0,
      saturation: 1.0,
      chromaticAberration: 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _CustomerHomeFeed(),
      const MyTasksScreen(),
      const ChatScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          pages[_currentIndex],
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: BottomNavCustomer(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() => _currentIndex = index);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Home Feed Page ──────────────────────────────────────────
class _CustomerHomeFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final gigProvider = context.watch<GigProvider>();
    final userName = authProvider.user?.name ?? 'User';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color lightModeGray = const Color(0xFF3A3A3C);

    final trendingTasks = gigProvider.filteredServices.take(3).toList();
    final moreTasks = gigProvider.filteredServices.skip(3).toList();

    return RefreshIndicator(
      onRefresh: () => gigProvider.loadServices(),
      child: CustomScrollView(
        slivers: [
          // ─── Modern App Bar & Search ────────────────────────────
          SliverAppBar(
            expandedHeight: 240,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        '👋 ${'customer.greeting'.tr(args: [userName])}',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        "What do you need help with today?",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Search Bar Mockup
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: GlassContainer(
                        useOwnLayer: true,
                        quality: GlassQuality.standard,
                        shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
                        settings: context.findAncestorStateOfType<_CustomerHomeScreenState>()!._getGlassSettings(isDark),
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.4),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedSearch01,
                                  color: isDark ? Colors.white70 : lightModeGray.withValues(alpha: 0.6),
                                  size: 20,
                                  strokeWidth: 2.0,
                                )
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Search services, tasks, or runners...",
                                  style: TextStyle(
                                    color: isDark ? Colors.white38 : lightModeGray.withValues(alpha: 0.4),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
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
          ),

          // ─── Categories ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Explore Categories',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        CategoryChip(
                          label: 'customer.view_all'.tr(),
                          isSelected: gigProvider.selectedCategory == 'All',
                          onTap: () => gigProvider.setCategory('All'),
                          showIcon: false,
                        ),
                        const SizedBox(width: 8),
                        ...TaskCategory.all.map((cat) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: CategoryChip(
                                label: cat,
                                isSelected: gigProvider.selectedCategory == cat,
                                onTap: () => gigProvider.setCategory(cat),
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Loading / Empty State ───────────────────────────
          if (gigProvider.isLoading)
            SliverFillRemaining(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: List.generate(3, (index) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Shimmer.fromColors(
                        baseColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade300,
                        highlightColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade100,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    )
                  ),
                ),
              ),
            )
          else if (gigProvider.filteredServices.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'customer.no_services'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // ─── Trending Horizontal List ─────────────────────
            if (trendingTasks.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Featured Services',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'See all',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 360, // Height to fit vertical card
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: trendingTasks.length,
                        itemBuilder: (context, index) {
                          final gig = trendingTasks[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 16, bottom: 20), // Bottom padding for shadow
                            child: SizedBox(
                              width: 280,
                              child: TaskCard(
                                gig: gig,
                                onTap: () {},
                                actionWidget: _buildOrderButton(context, gigProvider, gig),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // ─── More Services Vertical List ──────────────────
            if (moreTasks.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Text(
                    'More to Explore',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final gig = moreTasks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: TaskCard(
                          gig: gig,
                          onTap: () {},
                          actionWidget: _buildOrderButton(context, gigProvider, gig),
                        ),
                      );
                    },
                    childCount: moreTasks.length,
                  ),
                ),
              ),
            ] else
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderButton(BuildContext context, GigProvider gigProvider, GigModel gig) {
    return ElevatedButton(
      onPressed: () async {
        final auth = context.read<AuthProvider>();
        if (auth.user == null) return;
        final newGig = await gigProvider.orderService(
          customerId: auth.user!.id,
          customerName: auth.user!.name,
          serviceListing: gig,
        );
        if (newGig != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('customer.service_ordered'.tr())),
          );
          Navigator.pushNamed(context, '/order-status', arguments: newGig);
        } else if (gigProvider.error != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(gigProvider.error!)),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        'customer.order_service'.tr(),
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }
}
