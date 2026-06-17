import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gig_provider.dart';
import '../../widgets/task_card.dart';
import 'post_task_screen.dart';

// ============================================================
// Ngam App — My Tasks Screen (Customer)
// List of tasks posted by the customer
// ============================================================

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        context.read<GigProvider>().loadCustomerGigs(userId);
      }
    });
  }

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'nav.my_tasks'.tr(),
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${gigProvider.myGigs.length} tasks posted',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PostTaskScreen()));
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Post Task'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Expanded(
              child: gigProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : gigProvider.myGigs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tasks yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Post your first task to get started!',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            final userId =
                                context.read<AuthProvider>().user?.id;
                            if (userId != null) {
                              await gigProvider.loadCustomerGigs(userId);
                            }
                          },
                          child: ListView.builder(
                            itemCount: gigProvider.myGigs.length,
                            itemBuilder: (context, index) {
                              final gig = gigProvider.myGigs[index];
                              return TaskCard(
                                gig: gig,
                                showStatus: true,
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
