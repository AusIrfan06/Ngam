import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/gig_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/review_service.dart';
import '../../utils/app_theme.dart';

// ============================================================
// Ngam App — Review Screen
// Customer rates and reviews a runner after task completion
// ============================================================

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final gig = ModalRoute.of(context)?.settings.arguments as GigModel;
    final userId = context.read<AuthProvider>().user!.id;

    try {
      await ReviewService.submitReview(
        gigId: gig.id,
        reviewerId: userId,
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit review')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Rate & Review',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ─── Runner Avatar ───────────────────────
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'How was your experience?',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your feedback helps improve the community',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 32),

            // ─── Star Rating ─────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _rating = index + 1);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 44,
                      color: index < _rating
                          ? Colors.amber.shade600
                          : Colors.grey.shade300,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _rating == 0
                  ? 'Tap to rate'
                  : _rating <= 2
                      ? 'Could be better'
                      : _rating <= 3
                          ? 'Good'
                          : _rating <= 4
                              ? 'Great!'
                              : 'Excellent! 🎉',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _rating > 0 ? Colors.amber.shade700 : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 32),

            // ─── Comment Field ───────────────────────
            TextFormField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Leave a comment (optional)',
                hintText: 'Tell us about your experience...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            // ─── Submit Button ───────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
