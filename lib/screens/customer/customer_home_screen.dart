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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gigProvider = context.read<GigProvider>();
      gigProvider.loadOpenGigs();
      gigProvider.loadServices();
      gigProvider.subscribeToOpenGigs();
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
class _CustomerHomeFeed extends StatefulWidget {
  @override
  State<_CustomerHomeFeed> createState() => _CustomerHomeFeedState();
}

class _CustomerHomeFeedState extends State<_CustomerHomeFeed> {
  bool _showServices = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final gigProvider = context.watch<GigProvider>();
    final userName = authProvider.user?.name ?? 'User';

    return RefreshIndicator(
      onRefresh: () async {
        if (_showServices) {
          await gigProvider.loadServices();
        } else {
          await gigProvider.loadOpenGigs();
        }
      },
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
                          label: 'All',
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
                  const SizedBox(height: 32),

                  // ─── Toggle Tasks / Services ──────────────
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _showServices = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !_showServices ? Theme.of(context).cardColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: !_showServices ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ] : null,
                              ),
                              child: Center(
                                child: Text('Open Tasks', style: TextStyle(
                                  fontWeight: !_showServices ? FontWeight.w700 : FontWeight.w500,
                                  color: !_showServices ? Theme.of(context).colorScheme.primary : Colors.grey.shade600,
                                )),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _showServices = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _showServices ? Theme.of(context).cardColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _showServices ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ] : null,
                              ),
                              child: Center(
                                child: Text('Runner Services', style: TextStyle(
                                  fontWeight: _showServices ? FontWeight.w700 : FontWeight.w500,
                                  color: _showServices ? Theme.of(context).colorScheme.primary : Colors.grey.shade600,
                                )),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // ─── List Header ──────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _showServices 
                          ? 'Available Services (${gigProvider.filteredServices.length})'
                          : 'Available Tasks (${gigProvider.filteredGigs.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(Icons.sort_rounded, color: Colors.grey.shade400),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ─── Task List ────────────────────────────────────────
          if (gigProvider.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_showServices ? gigProvider.filteredServices.isEmpty : gigProvider.filteredGigs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _showServices ? Icons.design_services_outlined : Icons.inbox_rounded,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _showServices ? 'No services available' : 'No tasks available',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _showServices ? 'Check back later!' : 'Post a new task to get started!',
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
                    final gigs = _showServices ? gigProvider.filteredServices : gigProvider.filteredGigs;
                    final gig = gigs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TaskCard(
                        gig: gig,
                        onTap: () {
                          if (!_showServices) {
                            Navigator.pushNamed(
                              context,
                              '/order-status',
                              arguments: gig,
                            );
                          }
                        },
                        actionWidget: _showServices 
                            ? ElevatedButton(
                                onPressed: () async {
                                  final auth = context.read<AuthProvider>();
                                  if (auth.user == null) return;
                                  final newGig = await gigProvider.orderService(
                                    customerId: auth.user!.id,
                                    serviceListing: gig,
                                  );
                                  if (newGig != null && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Service Ordered!')),
                                    );
                                    Navigator.pushNamed(context, '/order-status', arguments: newGig);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Order Service'),
                              )
                            : null,
                      ),
                    );
                  },
                  childCount: _showServices ? gigProvider.filteredServices.length : gigProvider.filteredGigs.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
