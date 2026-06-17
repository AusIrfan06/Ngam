import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gig_provider.dart';
import '../../widgets/task_card.dart';
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

class _MyJobsScreenState extends State<MyJobsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        context.read<GigProvider>().loadRunnerGigs(userId);
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
                      'Jobs',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${gigProvider.myGigs.length} jobs',
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
                  label: const Text('Post Job'),
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
                                Icons.work_off_outlined,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No jobs yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Accept your first gig to get started!',
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
                              await gigProvider.loadRunnerGigs(userId);
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
                                  if (gig.status == 'SERVICE') return; // Don't navigate for service listings
                                  final currentUserId = context.read<AuthProvider>().user?.id;
                                  if (gig.customerId == currentUserId) {
                                    Navigator.pushNamed(
                                      context,
                                      '/order-status',
                                      arguments: gig,
                                    );
                                  } else {
                                    if (gig.isActive) {
                                      Navigator.pushNamed(
                                        context,
                                        '/active-job',
                                        arguments: gig,
                                      );
                                    }
                                  }
                                },
                                actionWidget: gig.status == 'SERVICE'
                                    ? TextButton(
                                        onPressed: () async {
                                          final success = await context.read<GigProvider>().takeDownService(gig.id);
                                          if (success && context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Service taken down')),
                                            );
                                          }
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text('Take Down', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
    );
  }
}
