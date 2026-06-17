import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/glass_toast.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
// Ngam App — Account Details Screen
// Edit profile info and change password
// ============================================================

class AccountDetailsScreen extends StatefulWidget {
  const AccountDetailsScreen({super.key});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;

  bool _isLoading = false;
  bool _obscureCurrentPass = true;
  bool _obscureNewPass = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        final profileError = await context.read<AuthProvider>().updateProfile(
          _nameController.text.trim(),
          _phoneController.text.trim(),
        );
        if (profileError != null && mounted) {
          showGlassToast(context, profileError, isError: true);
          setState(() => _isLoading = false);
          return;
        }
      }

      final currentPass = _currentPasswordController.text.trim();
      final newPass = _newPasswordController.text.trim();

      if (newPass.isNotEmpty && currentPass.isNotEmpty) {
        final passError = await SupabaseService.updatePassword(
          currentPassword: currentPass,
          newPassword: newPass,
        );
        if (passError != null && mounted) {
          showGlassToast(context, passError, isError: true);
          setState(() => _isLoading = false);
          return;
        }
      }

      if (mounted) {
        showGlassToast(context, 'Akaun berjaya dikemas kini!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showGlassToast(context, e.toString(), isError: true);
    }

    setState(() => _isLoading = false);
  }

  String? _validateCurrentPassword(String? value) {
    if (_newPasswordController.text.isNotEmpty && (value == null || value.isEmpty)) {
      return 'Diperlukan untuk tukar kata laluan';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (_currentPasswordController.text.isNotEmpty && (value == null || value.isEmpty)) {
      return 'Diperlukan untuk tukar kata laluan';
    }
    if (value == null || value.isEmpty) return null;
    final regex = RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[\d\W]).{8,}$');
    if (!regex.hasMatch(value)) return '8+ aksara, huruf besar, kecil & nombor/simbol';
    return null;
  }

  LiquidGlassSettings _glassSettings(bool isDark) => LiquidGlassSettings(
        thickness: 0.1, blur: 15, refractiveIndex: 1.0, glassColor: Colors.transparent,
        lightAngle: 45.0, lightIntensity: isDark ? 0.1 : 0.2, ambientStrength: 1.0,
        saturation: 1.0, chromaticAberration: 0.0,
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Butiran Akaun', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
        leading: IconButton(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: isDark ? Colors.white70 : Colors.black54, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('PROFIL AWAM'),
                const SizedBox(height: 12),
                _glassCard(isDark, Column(children: [
                  _premiumInput(isDark: isDark, label: 'Nama Penuh', controller: _nameController, icon: HugeIcons.strokeRoundedUser),
                  const SizedBox(height: 16),
                  _premiumInput(isDark: isDark, label: 'E-mel (Tidak boleh ditukar)', controller: _emailController, icon: HugeIcons.strokeRoundedMail01, readOnly: true),
                  const SizedBox(height: 16),
                  _premiumInput(isDark: isDark, label: 'No. Telefon', controller: _phoneController, icon: HugeIcons.strokeRoundedCall02, keyboardType: TextInputType.phone),
                ])),
                const SizedBox(height: 32),

                _sectionLabel('KESELAMATAN'),
                const SizedBox(height: 12),
                _glassCard(isDark, Column(children: [
                  _premiumInput(
                    isDark: isDark, label: 'Kata Laluan Semasa', controller: _currentPasswordController,
                    icon: HugeIcons.strokeRoundedLockPassword, isPassword: true, obscureText: _obscureCurrentPass,
                    onToggleObscure: () => setState(() => _obscureCurrentPass = !_obscureCurrentPass),
                    validator: _validateCurrentPassword,
                  ),
                  const SizedBox(height: 16),
                  _premiumInput(
                    isDark: isDark, label: 'Kata Laluan Baru', controller: _newPasswordController,
                    icon: HugeIcons.strokeRoundedLockKey, isPassword: true, obscureText: _obscureNewPass,
                    onToggleObscure: () => setState(() => _obscureNewPass = !_obscureNewPass),
                    validator: _validateNewPassword,
                  ),
                ])),
                const SizedBox(height: 40),

                GestureDetector(
                  onTap: _isLoading ? null : _saveChanges,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2));

  Widget _glassCard(bool isDark, Widget child) => GlassContainer(
    useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: 24.0), settings: _glassSettings(isDark),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(24.0), border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.6), width: 1.0)),
      child: child,
    ),
  );

  Widget _premiumInput({
    required bool isDark, required String label, required TextEditingController controller, required dynamic icon,
    TextInputType keyboardType = TextInputType.text, bool isPassword = false, bool obscureText = false,
    VoidCallback? onToggleObscure, String? Function(String?)? validator, bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(14)),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            readOnly: readOnly,
            style: TextStyle(color: isDark ? (readOnly ? Colors.white54 : Colors.white) : (readOnly ? Colors.black54 : Colors.black87), fontWeight: FontWeight.w600, fontSize: 14),
            validator: validator ?? (value) => value == null || (value.isEmpty && !readOnly) ? 'Wajib diisi' : null,
            decoration: InputDecoration(
              filled: false,
              prefixIcon: Padding(padding: const EdgeInsets.only(right: 14), child: HugeIcon(icon: icon, color: Colors.grey, size: 20)),
              prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              border: InputBorder.none,
              errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
              suffixIcon: isPassword ? IconButton(
                icon: HugeIcon(icon: obscureText ? HugeIcons.strokeRoundedViewOff : HugeIcons.strokeRoundedView, color: Colors.grey, size: 20),
                onPressed: onToggleObscure,
              ) : null,
            ),
          ),
        ),
      ],
    );
  }
}
