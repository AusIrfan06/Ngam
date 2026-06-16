import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/gig_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/task_card.dart';
import '../../widgets/bottom_nav_runner.dart';
import 'my_jobs_screen.dart';
import '../shared/profile_screen.dart';

// ============================================================
// Ngam App — Runner Home Screen
// Discovery feed with filter chips for available gigs
// ============================================================

class RunnerHomeScreen extends StatefulWidget {
  const RunnerHomeScreen({super.key});

  @override
  State<RunnerHomeScreen> createState() => _RunnerHomeScreenState();
}

class _RunnerHomeScreenState extends State<RunnerHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gigProvider = context.read<GigProvider>();
      gigProvider.loadOpenGigs();
      gigProvider.subscribeToOpenGigs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _RunnerFeed(),
      const MyJobsScreen(),
      _ChatPlaceholder(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavRunner(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}

// ─── Runner Discovery Feed ──────────────────────────────────
class _RunnerFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gigProvider = context.watch<GigProvider>();

    return RefreshIndicator(
      onRefresh: () => gigProvider.loadOpenGigs(),
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
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Find Gigs',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2ECC71),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
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

                  // ─── Filter Chips ────────────────────────
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
                  const SizedBox(height: 12),

                  // ─── Search Bar ──────────────────────────
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search tasks...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardTheme.color,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── Nearby Count ────────────────────────
                  Text(
                    'Nearby (${gigProvider.filteredGigs.length} tasks)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // ─── Gig List ───────────────────────────
          if (gigProvider.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (gigProvider.filteredGigs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No gigs available',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later for new tasks',
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
                    final gig = gigProvider.filteredGigs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TaskCard(
                        gig: gig,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/task-detail',
                            arguments: gig,
                          );
                        },
                      ),
                    );
                  },
                  childCount: gigProvider.filteredGigs.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Chat Placeholder ────────────────────────────────────────
class _ChatPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Chat',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
