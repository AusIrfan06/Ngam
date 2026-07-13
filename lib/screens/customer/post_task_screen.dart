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
import 'package:latlong2/latlong.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../widgets/map_picker.dart';
import '../shared/wallet_screen.dart';
import '../../services/supabase_service.dart';

// ============================================================
// Ngam App — Skrin Post Task
// Customer buat dan broadcast task baru
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
  LatLng? _selectedLocation;
  String _selectedPaymentMethod = 'wallet';

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
  }

  Future<void> _loadSavedLocation() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    
    if (user.address != null && user.addressLat != null && user.addressLng != null) {
      if (mounted) {
        setState(() {
          _locationController.text = user.address!;
          _selectedLocation = LatLng(user.addressLat!, user.addressLng!);
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _bountyController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please tap on the map to pin the exact location'),
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final gigProvider = context.read<GigProvider>();
    final userId = authProvider.user!.id;
    final balance = authProvider.user!.balance;
    final amount = double.parse(_bountyController.text);

    if (!authProvider.isRunner && _selectedPaymentMethod == 'wallet' && balance < amount) {
      if (mounted) {
        final topUp = await showDialog<bool>(
          context: context,
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: GlassContainer(
                useOwnLayer: true,
                quality: GlassQuality.standard,
                shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
                settings: LiquidGlassSettings(
                  blur: 16.0,
                  lightIntensity: isDark ? 0.1 : 0.2,
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(icon: HugeIcons.strokeRoundedWallet02, size: 48, color: Colors.orange),
                      const SizedBox(height: 16),
                      const Text('Baki Tidak Mencukupi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        'Baki dompet anda (RM ${balance.toStringAsFixed(2)}) tidak mencukupi untuk membayar tugasan ini (RM ${amount.toStringAsFixed(2)}).',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                            child: const Text('Tambah Nilai'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );

        if (topUp == true && mounted) {
          final proceed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => WalletScreen(requiredAmountForPendingTask: amount)));
          if (proceed == true && mounted) {
            _handleSubmit();
          }
        }
      }
      return;
    }

    if (!authProvider.isRunner && _selectedPaymentMethod == 'wallet') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: GlassContainer(
              useOwnLayer: true,
              quality: GlassQuality.standard,
              shape: LiquidRoundedSuperellipse(borderRadius: 24.0),
              settings: LiquidGlassSettings(
                blur: 16.0,
                lightIntensity: isDark ? 0.1 : 0.2,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedInformationCircle, size: 48, color: Colors.blueAccent),
                    const SizedBox(height: 16),
                    const Text('Sahkan Pembayaran', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'RM ${amount.toStringAsFixed(2)} akan ditolak daripada baki dompet anda. Teruskan?',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                          child: const Text('Bayar & Hantar'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        },
      );
      if (confirmed != true) return;
    }

    GigModel? gig;
    if (authProvider.isRunner) {
      gig = await gigProvider.createServiceListing(
        runnerId: userId,
        runnerName: authProvider.user!.name,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        price: amount,
        location: _locationController.text.trim(),
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
      );
    } else {
      gig = await gigProvider.createGig(
        customerId: userId,
        customerName: authProvider.user!.name,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        bountyAmount: amount,
        location: _locationController.text.trim(),
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        paymentMethod: _selectedPaymentMethod,
      );
    }

    // Refresh wallet balance lepas bayar
    if (!authProvider.isRunner && _selectedPaymentMethod == 'wallet' && mounted) {
      authProvider.refreshBalance();
    }

    if (gig != null && mounted) {
      // Save lokasi ni terus ke profil user
      final userId = authProvider.user?.id;
      if (userId != null) {
        await SupabaseService.updateProfile(
          userId: userId,
          address: _locationController.text.trim(),
          addressLat: _selectedLocation!.latitude,
          addressLng: _selectedLocation!.longitude,
        );
        // Refresh auth supaya dapat address yang latest
        await authProvider.initialize();
      }

      if (!mounted) return;

      if (authProvider.isRunner) {
        Navigator.pop(context);
      } else {
        Navigator.pushNamed(context, '/task-posted', arguments: gig);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            gigProvider.error ?? 'Failed to post task. Check logs.',
          ),
        ),
      );
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
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              title: Text(
                isRunner
                    ? 'post_task.title_runner'.tr()
                    : 'post_task.title_customer'.tr(),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
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
                      // ─── Tajuk Task ──────────────────────────
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: isRunner
                              ? 'post_task.service_title_label'.tr()
                              : 'customer.task_title'.tr(),
                          hintText: isRunner
                              ? 'post_task.service_title_hint'.tr()
                              : 'post_task.task_title_hint'.tr(),
                          prefixIcon: const Icon(Icons.title_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'post_task.err_title'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ─── Penerangan Task ─────────────────────
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: isRunner
                              ? 'post_task.service_desc_label'.tr()
                              : 'post_task.task_desc_label'.tr(),
                          hintText: isRunner
                              ? 'post_task.service_desc_hint'.tr()
                              : 'customer.task_desc'.tr(),
                          alignLabelWithHint: true,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 60),
                            child: Icon(Icons.description_outlined),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'post_task.err_desc'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ─── Dropdown Kategori ───────────────────
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'post_task.category'.tr(),
                          prefixIcon: const Icon(Icons.category_outlined),
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
                            // Update harga anggaran bounty
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // ─── Lokasi ──────────────────────────────
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'post_task.location_label'.tr(),
                          hintText: 'post_task.location_hint'.tr(),
                          prefixIcon: const Icon(Icons.location_on_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'post_task.err_location'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'post_task.pin_location'.tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      MapPicker(
                        initialCenter: const LatLng(3.140853, 101.693207),
                        onLocationSelected: (point) {
                          setState(() {
                            _selectedLocation = point;
                          });
                        },
                      ),
                      if (_selectedLocation != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'post_task.location_pinned'.tr(
                              args: [
                                _selectedLocation!.latitude.toStringAsFixed(4),
                                _selectedLocation!.longitude.toStringAsFixed(4),
                              ],
                            ),
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // ─── Harga Upah (Bounty) ─────────────────
                      TextFormField(
                        controller: _bountyController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isRunner
                              ? 'post_task.price_runner'.tr()
                              : 'customer.bounty'.tr(),
                          hintText: 'post_task.min_rm'.tr(
                            args: [
                              BountyCalculator.getMinimum(
                                _selectedCategory,
                              ).toStringAsFixed(2),
                            ],
                          ),
                          prefixIcon: const Icon(Icons.payments_outlined),
                          prefixText: 'RM ',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'post_task.err_bounty'.tr();
                          }
                          final amount = double.tryParse(value);
                          if (amount == null) {
                            return 'post_task.err_valid_number'.tr();
                          }
                          final error = BountyCalculator.validate(
                            _selectedCategory,
                            amount,
                          );
                          return error;
                        },
                      ),
                      const SizedBox(height: 8),

                      // ─── Info Matrik Bounty ──────────────────
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
                            const Icon(
                              Icons.info_outline,
                              color: AppTheme.info,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'post_task.min_bounty_info'.tr(
                                  args: [
                                    _selectedCategory,
                                    BountyCalculator.getMinimum(
                                      _selectedCategory,
                                    ).toStringAsFixed(2),
                                  ],
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.info,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ─── Payment Method ──────────────────────
                      if (!isRunner) ...[
                        DropdownButtonFormField<String>(
                          value: _selectedPaymentMethod,
                          decoration: InputDecoration(
                            labelText: 'Payment Method',
                            prefixIcon: const Icon(Icons.payment_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'wallet',
                              child: Row(
                                children: [
                                  Icon(Icons.account_balance_wallet_outlined, size: 20),
                                  SizedBox(width: 8),
                                  Text('Pay from Wallet (Escrow)'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'qr',
                              child: Row(
                                children: [
                                  Icon(Icons.qr_code_2_outlined, size: 20),
                                  SizedBox(width: 8),
                                  Text('Pay via QR directly to Runner'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedPaymentMethod = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 32),
                      ],

                      // ─── Butang Submit ───────────────────────
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
                                gig.isLoading
                                    ? 'post_task.posting'.tr()
                                    : (isRunner
                                          ? 'post_task.submit_service'.tr()
                                          : 'post_task.submit_task'.tr()),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          isRunner
                              ? 'post_task.service_visible'.tr()
                              : 'post_task.task_visible'.tr(),
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
