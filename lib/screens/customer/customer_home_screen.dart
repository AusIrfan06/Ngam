import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gig_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/task_card.dart';
import '../../widgets/bottom_nav_customer.dart';
import 'post_task_screen.dart';
import 'my_tasks_screen.dart';
import '../shared/profile_screen.dart';

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
      gigProvider.subscribeToOpenGigs();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pages for bottom navigation
    final pages = [
      _CustomerHomeFeed(),
      const PostTaskScreen(),
      const MyTasksScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavCustomer(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // ─── Greeting ────────────────────────────
            Text(
              '👋 Hi, $userName',
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),

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
            const SizedBox(height: 20),

            // ─── Available Tasks Header ──────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Tasks (${gigProvider.filteredGigs.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(Icons.sort_rounded, color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 12),

            // ─── Task List ───────────────────────────
            Expanded(
              child: gigProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : gigProvider.filteredGigs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_rounded,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tasks available',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Post a new task to get started!',
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
                                    '/order-status',
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
