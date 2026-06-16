import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/gig_service.dart';
import '../../services/review_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

// ============================================================
// Ngam App — Profile Screen (Shared)
// User profile with role toggle, stats, and settings
// ============================================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _tasksPosted = 0;
  int _tasksCompleted = 0;
  double _rating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    try {
      final posted = await GigService.getPostedCount(user.id);
      final completed = await GigService.getCompletedCount(user.id);
      final rating = await ReviewService.getAverageRating(user.id);

      if (mounted) {
        setState(() {
          _tasksPosted = posted;
          _tasksCompleted = completed;
          _rating = rating;
        });
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = authProvider.user;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ─── Avatar ──────────────────────────────
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── Name & Email ────────────────────────
            Text(
              user.name,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 20),

            // ─── Role Toggle ─────────────────────────
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  _RoleToggle(
                    label: 'Pemesan',
                    isSelected: user.role == UserRole.pemesan,
                    onTap: () => authProvider.setRole(UserRole.pemesan),
                  ),
                  _RoleToggle(
                    label: 'Runner',
                    isSelected: user.role == UserRole.runner,
                    onTap: () => authProvider.setRole(UserRole.runner),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── Stats Row ───────────────────────────
            Row(
              children: [
                _StatCard(
                  label: 'Tasks Posted',
                  value: '$_tasksPosted',
                  icon: Icons.upload_rounded,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Completed',
                  value: '$_tasksCompleted',
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Rating',
                  value: _rating > 0 ? _rating.toStringAsFixed(1) : '-',
                  icon: Icons.star_rounded,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ─── Settings ────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // Dark Mode Toggle
                  ListTile(
                    leading: Icon(
                      themeProvider.isDarkMode
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: AppTheme.primary,
                    ),
                    title: const Text(
                      'Dark Mode',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: Switch(
                      value: themeProvider.isDarkMode,
                      activeColor: AppTheme.primary,
                      onChanged: (_) => themeProvider.toggleTheme(),
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey.shade200),

                  // Phone
                  ListTile(
                    leading: const Icon(Icons.phone_outlined,
                        color: AppTheme.primary),
                    title: const Text(
                      'Phone',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: Text(
                      user.phone,
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey.shade200),

                  // About
                  ListTile(
                    leading: const Icon(Icons.info_outline,
                        color: AppTheme.primary),
                    title: const Text(
                      'About Ngam',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                    ),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Ngam',
                        applicationVersion: '1.0.0',
                        applicationLegalese:
                            'Local Errands, Powered by Community\nCSC264 Individual Project',
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── Logout Button ───────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await authProvider.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: const BorderSide(color: AppTheme.error),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─── Role Toggle Button ──────────────────────────────────────
class _RoleToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleToggle({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Stats Card ──────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppTheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
