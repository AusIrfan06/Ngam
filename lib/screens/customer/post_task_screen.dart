import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gig_provider.dart';
import '../../models/gig_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/bounty_calculator.dart';
import '../../utils/constants.dart';

// ============================================================
// Ngam App — Post Task Screen
// Customer creates and broadcasts a new task
// ============================================================

class PostTaskScreen extends StatefulWidget {
  const PostTaskScreen({super.key});

  @override
  State<PostTaskScreen> createState() => _PostTaskScreenState();
}

class _PostTaskScreenState extends State<PostTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _bountyController = TextEditingController();
  String _selectedCategory = TaskCategory.food;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _bountyController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final gigProvider = context.read<GigProvider>();
    final userId = authProvider.user!.id;

    GigModel? gig;
    if (authProvider.isRunner) {
      gig = await gigProvider.createServiceListing(
        runnerId: userId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        price: double.parse(_bountyController.text),
        location: _locationController.text.trim(),
      );
    } else {
      gig = await gigProvider.createGig(
        customerId: userId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        bountyAmount: double.parse(_bountyController.text),
        location: _locationController.text.trim(),
      );
    }

    if (gig != null && mounted) {
      if (authProvider.isRunner) {
        Navigator.pop(context);
      } else {
        Navigator.pushNamed(
          context,
          '/task-posted',
          arguments: gig,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRunner = context.watch<AuthProvider>().isRunner;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                isRunner ? 'Post a Service' : 'Post New Task',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
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
          SliverToBoxAdapter(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── Task Title ──────────────────────────
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: isRunner ? 'Service Title' : 'customer.task_title'.tr(),
                          hintText: isRunner ? 'e.g., I will print 10 pages' : 'e.g., Print assignment 10 pages',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a task title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ─── Task Description ────────────────────
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: isRunner ? 'Service Description' : 'Task Description',
                          hintText: isRunner ? 'Describe what you can do...' : 'customer.task_desc'.tr(),
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 60),
                            child: Icon(Icons.description_outlined),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ─── Category Dropdown ───────────────────
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: TaskCategory.all.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Row(
                              children: [
                                Text(TaskCategory.icon(cat)),
                                const SizedBox(width: 8),
                                Text(cat),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                            // Update bounty hint
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // ─── Location ────────────────────────────
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Location / Drop-off',
                          hintText: 'e.g., Block C, Campus Library',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a location';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ─── Bounty Amount ───────────────────────
                      TextFormField(
                        controller: _bountyController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isRunner ? 'Price (RM)' : 'customer.bounty'.tr(),
                          hintText:
                              'Min: RM ${BountyCalculator.getMinimum(_selectedCategory).toStringAsFixed(2)}',
                          prefixIcon: const Icon(Icons.payments_outlined),
                          prefixText: 'RM ',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a bounty amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null) {
                            return 'Please enter a valid number';
                          }
                          final error =
                              BountyCalculator.validate(_selectedCategory, amount);
                          return error;
                        },
                      ),
                      const SizedBox(height: 8),

                      // ─── Bounty Matrix Info ──────────────────
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.info.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.info.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: AppTheme.info, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Minimum bounty for $_selectedCategory: RM ${BountyCalculator.getMinimum(_selectedCategory).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.info,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ─── Submit Button ───────────────────────
                      Consumer<GigProvider>(
                        builder: (context, gig, _) {
                          return SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: gig.isLoading ? null : _handleSubmit,
                              icon: gig.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded),
                              label: Text(
                                gig.isLoading ? 'Posting...' : (isRunner ? 'Submit Service →' : 'Submit Task →'),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          isRunner ? 'Service will be visible to customers' : 'Task will appear in the live feed once submitted',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
