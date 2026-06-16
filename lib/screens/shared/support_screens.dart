import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
// Ngam App — Support Screens
// Help Center + Contact Us
// ============================================================

LiquidGlassSettings _glassSettings(bool isDark) => LiquidGlassSettings(
  thickness: 0.1, blur: 15, refractiveIndex: 1.0, glassColor: Colors.transparent,
  lightAngle: 45.0, lightIntensity: isDark ? 0.1 : 0.2, ambientStrength: 1.0,
  saturation: 1.0, chromaticAberration: 0.0,
);

// ─── Help Center ──────────────────────────────────────────────
class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final List<Map<String, String>> _faqs = [
    {'q': 'Bagaimana cara posting task?', 'a': 'Tekan butang "+" di bawah, isi butiran task seperti kategori, lokasi, dan tawaran harga. Kemudian submit dan tunggu runner ambil task anda.'},
    {'q': 'Bagaimana cara menjadi Runner?', 'a': 'Tukar peranan anda kepada "Runner" dari profil. Anda kemudian boleh cari task yang tersedia dalam feed dan menerima task yang bersesuaian.'},
    {'q': 'Bagaimana pembayaran berfungsi?', 'a': 'Pembayaran dibuat terus antara Pemesan dan Runner selepas task selesai. Kami cadangkan menggunakan DuitNow atau pemindahan bank.'},
    {'q': 'Bolehkah saya batalkan task?', 'a': 'Ya, anda boleh batalkan task dari halaman "My Tasks" selagi task belum diterima oleh runner.'},
    {'q': 'Apa yang berlaku jika runner tidak hadir?', 'a': 'Hubungi kami melalui "Hubungi Kami" dan kami akan bantu selesaikan isu tersebut dalam masa 24 jam.'},
  ];

  int? _expandedIndex;

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
        title: Text('Pusat Bantuan', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
        leading: IconButton(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: isDark ? Colors.white70 : Colors.black54, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hi 👋\nBagaimana kami boleh bantu?', style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, height: 1.2)),
              const SizedBox(height: 24),

              // Search bar
              GlassContainer(
                useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: 16.0), settings: _glassSettings(isDark),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.6))),
                  child: TextField(
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      filled: false,
                      hintText: 'Cari soalan...', hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black26),
                      icon: const HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: Colors.grey, size: 20),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Text('SOALAN LAZIM', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 12),

              ...List.generate(_faqs.length, (index) {
                final isExpanded = _expandedIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _expandedIndex = isExpanded ? null : index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: isExpanded ? 0.08 : 0.03) : Colors.white.withValues(alpha: isExpanded ? 0.7 : 0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isExpanded ? const Color(0xFFFF8C00).withValues(alpha: 0.6) : Colors.white.withValues(alpha: isDark ? 0.05 : 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(_faqs[index]['q']!, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87))),
                            Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                          ],
                        ),
                        if (isExpanded) ...[
                          const SizedBox(height: 12),
                          Text(_faqs[index]['a']!, style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54, height: 1.5)),
                        ]
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Contact Us ───────────────────────────────────────────────
class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

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
        title: Text('Hubungi Kami', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
        leading: IconButton(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: isDark ? Colors.white70 : Colors.black54, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hubungi Kami', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 8),
              Text('Pasukan kami sedia membantu anda.', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
              const SizedBox(height: 32),

              _contactCard(isDark, HugeIcons.strokeRoundedBubbleChat, 'Chat Sokongan', 'Kami di sini untuk membantu.', 'Mula Chat'),
              const SizedBox(height: 16),
              _contactCard(isDark, HugeIcons.strokeRoundedMail01, 'E-mel Kami', 'Hantar e-mel bila-bila masa.', 'support@ngam.my'),
              const SizedBox(height: 16),
              _contactCard(isDark, HugeIcons.strokeRoundedCall02, 'Hubungi Kami', 'Isnin-Jumaat, 9am–5pm.', '+60 12-345 6789'),
              const SizedBox(height: 32),

              Text('IKUTI KAMI', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _socialButton(isDark, 'Instagram', const Color(0xFFE91E63)),
                  const SizedBox(width: 12),
                  _socialButton(isDark, 'Facebook', const Color(0xFF1976D2)),
                  const SizedBox(width: 12),
                  _socialButton(isDark, 'Twitter/X', Colors.black),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contactCard(bool isDark, dynamic icon, String title, String subtitle, String action) {
    return GlassContainer(
      useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: 20.0), settings: _glassSettings(isDark),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.6))),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFF8C00).withValues(alpha: 0.1), shape: BoxShape.circle),
              child: HugeIcon(icon: icon, color: const Color(0xFFFF8C00), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                  const SizedBox(height: 6),
                  Text(action, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFFF8C00))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialButton(bool isDark, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Center(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color))),
      ),
    );
  }
}
