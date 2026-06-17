import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/glass_toast.dart';

// ============================================================
// Ngam App — Runner Verification Screen
// Form to collect KYC details before becoming a runner
// ============================================================

class RunnerVerificationScreen extends StatefulWidget {
  const RunnerVerificationScreen({super.key});

  @override
  State<RunnerVerificationScreen> createState() => _RunnerVerificationScreenState();
}

class _RunnerVerificationScreenState extends State<RunnerVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  final TextEditingController _icController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();

  String _selectedVehicle = 'Motorcycle';
  final List<String> _vehicleTypes = ['Car', 'Motorcycle', 'Bicycle', 'Walking'];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _icController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  bool get _requiresPlate => _selectedVehicle == 'Car' || _selectedVehicle == 'Motorcycle';

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().submitRunnerVerification(
        fullName: _nameController.text.trim(),
        icNumber: _icController.text.trim(),
        vehicleType: _selectedVehicle,
        plateNumber: _requiresPlate ? _plateController.text.trim() : null,
      );

      if (mounted) {
        showGlassToast(context, 'Verification successful! Welcome to the team.');
        // Automatically switch to runner role and go to runner home
        await context.read<AuthProvider>().setRole('runner');
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/runner-home', (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        showGlassToast(context, e.toString(), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  LiquidGlassSettings _glassSettings(bool isDark) {
    return LiquidGlassSettings(
      thickness: 0.1,
      blur: 15,
      refractiveIndex: 1.0,
      glassColor: Colors.transparent,
      lightAngle: 45.0,
      lightIntensity: isDark ? 0.1 : 0.2,
      ambientStrength: 1.0,
      saturation: 1.0,
      chromaticAberration: 0.0,
    );
  }

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
        title: Text(
          'Runner Verification',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: isDark ? Colors.white70 : Colors.black54,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Before you can accept tasks, we need a few details to keep our community safe.',
                  style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
                ),
                const SizedBox(height: 24),
                
                GlassContainer(
                  useOwnLayer: true,
                  quality: GlassQuality.standard,
                  shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
                  settings: _glassSettings(isDark),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.6),
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputField(
                          isDark: isDark,
                          label: 'auth.full_name'.tr(),
                          controller: _nameController,
                          icon: HugeIcons.strokeRoundedUser,
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          isDark: isDark,
                          label: 'IC / Passport Number',
                          controller: _icController,
                          icon: Icons.credit_card_outlined,
                        ),
                        const SizedBox(height: 16),
                        
                        Text(
                          'MODE OF TRANSPORT',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedVehicle,
                              isExpanded: true,
                              dropdownColor: isDark ? Colors.grey[900] : Colors.white,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                fontFamily: GoogleFonts.outfit().fontFamily,
                              ),
                              items: _vehicleTypes.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedVehicle = val;
                                    if (!_requiresPlate) {
                                      _plateController.clear();
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        
                        if (_requiresPlate) ...[
                          const SizedBox(height: 16),
                          _buildInputField(
                            isDark: isDark,
                            label: 'Vehicle Plate Number',
                            controller: _plateController,
                            icon: HugeIcons.strokeRoundedCar01,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                GestureDetector(
                  onTap: _isLoading ? null : _submitVerification,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Verify & Apply',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

  Widget _buildInputField({
    required bool isDark,
    required String label,
    required TextEditingController controller,
    required dynamic icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextFormField(
            controller: controller,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
            decoration: InputDecoration(
              filled: false,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: icon is IconData
                    ? Icon(icon, color: Colors.grey, size: 20)
                    : HugeIcon(
                        icon: icon,
                        color: Colors.grey,
                        size: 20,
                      ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              border: InputBorder.none,
              errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }
}
