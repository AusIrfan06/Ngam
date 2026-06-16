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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // ─── Header ──────────────────────────────
            Row(
              children: [
                Text(
                  'Find Gigs',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2ECC71),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
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
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // ─── Nearby Count ────────────────────────
            Text(
              'Nearby (${gigProvider.filteredGigs.length} tasks)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),

            // ─── Gig List ───────────────────────────
            Expanded(
              child: gigProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : gigProvider.filteredGigs.isEmpty
                      ? Center(
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
                        )
                      : RefreshIndicator(
                          onRefresh: () => gigProvider.loadOpenGigs(),
                          child: ListView.builder(
                            itemCount: gigProvider.filteredGigs.length,
                            itemBuilder: (context, index) {
                              final gig = gigProvider.filteredGigs[index];
                              return TaskCard(
                                gig: gig,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/task-detail',
                                    arguments: gig,
                                  );
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
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
