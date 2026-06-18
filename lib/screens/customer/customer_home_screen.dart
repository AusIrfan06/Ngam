import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gig_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/task_card.dart';
import '../../widgets/bottom_nav_customer.dart';
import 'my_tasks_screen.dart';
import '../shared/profile_screen.dart';
import '../shared/chat_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

// ============================================================
// Ngam App — Customer Home Screen
// Dashboard with category filters and available tasks feed
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
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final gigProvider = context.read<GigProvider>();
      await gigProvider.loadServices();
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pages for bottom navigation
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

    return RefreshIndicator(
      onRefresh: () => gigProvider.loadServices(),
      child: CustomScrollView(
        slivers: [
          // ─── Hero Header ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              title: Text(
                '👋 Hi, $userName',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
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

          // ─── Categories & List ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // ─── Category Filters ────────────────────
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
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
                  const SizedBox(height: 24),

                  // ─── List Header ──────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'customer.available_services'.tr(args: ['${gigProvider.filteredServices.length}']),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.sort_rounded, color: Colors.grey.shade400),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ─── Services List ────────────────────────────────────
          if (gigProvider.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
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
                    const SizedBox(height: 8),
                    Text(
                      'customer.runners_will_post'.tr(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), // padding for bottom nav
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final gig = gigProvider.filteredServices[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TaskCard(
                        gig: gig,
                        onTap: () {},
                        actionWidget: ElevatedButton(
                          onPressed: () async {
                            final auth = context.read<AuthProvider>();
                            if (auth.user == null) return;
                            final newGig = await gigProvider.orderService(
                              customerId: auth.user!.id,
                              serviceListing: gig,
                            );
                            if (newGig != null && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('customer.service_ordered'.tr())),
                              );
                              Navigator.pushNamed(context, '/order-status', arguments: newGig);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('customer.order_service'.tr()),
                        ),
                      ),
                    );
                  },
                  childCount: gigProvider.filteredServices.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

