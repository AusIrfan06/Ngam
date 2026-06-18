import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/gig_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gig_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/category_chip.dart';

// ============================================================
// Ngam App — Confirm Acceptance Screen (Runner)
// Confirmation dialog before locking a task
// ============================================================

class ConfirmAcceptanceScreen extends StatelessWidget {
  const ConfirmAcceptanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gig = ModalRoute.of(context)?.settings.arguments as GigModel;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'runner.confirm_acceptance'.tr(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ─── Header ──────────────────────────────
            Text(
              'runner.about_to_accept'.tr(),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            // ─── Task Summary Card ───────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gig.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  CategoryChip(label: gig.category),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        gig.location,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      gig.formattedBounty,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── Warning Banner ──────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.error.withValues(alpha: 0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppTheme.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'runner.warning_locked'.tr(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'runner.status_in_progress'.tr(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            // ─── Action Buttons ──────────────────────
            Row(
              children: [
                // Cancel
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: Text('runner.cancel'.tr()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Confirm
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: Consumer<GigProvider>(
                      builder: (context, gigProvider, _) {
                        return ElevatedButton.icon(
                          onPressed: gigProvider.isLoading
                              ? null
                              : () async {
                                  final userId =
                                      context.read<AuthProvider>().user!.id;
                                  final success = await gigProvider.acceptGig(
                                    gig.id,
                                    userId,
                                  );

                                  if (success && context.mounted) {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/active-job',
                                      (route) => false,
                                      arguments: gig.copyWith(
                                        status: 'LOCKED',
                                        gigWorkerId: userId,
                                      ),
                                    );
                                  }
                                },
                          icon: gigProvider.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: Text('runner.confirm'.tr()),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
