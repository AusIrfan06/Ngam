import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

// ============================================================
// Ngam App — Glass Toast / Snackbar Utility
// Customizable glassmorphic popup with icon, color, text
// Usage:
//   showGlassToast(context, 'Berjaya!');
//   showGlassToast(context, 'Ralat', isError: true);
//   showGlassToast(context, 'Info', color: Colors.blue, icon: HugeIcons.strokeRoundedInformationCircle);
// ============================================================

enum GlassToastType { success, error, warning, info }

void showGlassToast(
  BuildContext context,
  String message, {
  bool isError = false,
  GlassToastType? type,
  Color? color,
  dynamic icon, // HugeIcons icon data or IconData
  Duration duration = const Duration(seconds: 4),
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  // Resolve type — explicit 'type' wins, then 'isError' fallback
  final resolvedType = type ?? (isError ? GlassToastType.error : GlassToastType.success);

  // Resolve color
  final resolvedColor = color ?? _colorForType(resolvedType);

  // Resolve icon
  final resolvedIcon = icon ?? _iconForType(resolvedType);

  // Clean error messages
  final displayMessage = resolvedType == GlassToastType.error
      ? _cleanErrorMessage(message)
      : message;

  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      duration: duration,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      content: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: isDark
                  ? resolvedColor.withValues(alpha: 0.15)
                  : resolvedColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: resolvedColor.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: resolvedColor.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon — supports both HugeIcon and regular Icon
                _ToastIcon(icon: resolvedIcon, color: resolvedColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayMessage,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Dismiss tap
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                  child: Icon(
                    Icons.close_rounded,
                    color: resolvedColor.withValues(alpha: 0.7),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// ─── Icon Widget (handles both HugeIcon + IconData) ──────────
class _ToastIcon extends StatelessWidget {
  final dynamic icon;
  final Color color;

  const _ToastIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    if (icon is IconData) {
      return Icon(icon as IconData, color: color, size: 20);
    }
    // Assume HugeIcons path data
    try {
      return HugeIcon(icon: icon, color: color, size: 20);
    } catch (_) {
      return Icon(Icons.info_outline_rounded, color: color, size: 20);
    }
  }
}

// ─── Color for type ───────────────────────────────────────────
Color _colorForType(GlassToastType type) {
  switch (type) {
    case GlassToastType.success:
      return const Color(0xFF2ECC71);
    case GlassToastType.error:
      return Colors.redAccent;
    case GlassToastType.warning:
      return const Color(0xFFF39C12);
    case GlassToastType.info:
      return const Color(0xFF3498DB);
  }
}

// ─── Icon for type ────────────────────────────────────────────
dynamic _iconForType(GlassToastType type) {
  switch (type) {
    case GlassToastType.success:
      return HugeIcons.strokeRoundedTick01;
    case GlassToastType.error:
      return HugeIcons.strokeRoundedCancel01;
    case GlassToastType.warning:
      return HugeIcons.strokeRoundedAlert01;
    case GlassToastType.info:
      return HugeIcons.strokeRoundedInformationCircle;
  }
}

// ─── Error message cleaner ────────────────────────────────────
String _cleanErrorMessage(String rawMessage) {
  String msg = rawMessage
      .replaceAll(
        RegExp(
          r'^(Ralat|Exception|AuthException|PostgrestException|Ralat daftar|Ralat masuk sebagai tetamu):',
          caseSensitive: false,
        ),
        '',
      )
      .trim();

  final lowMsg = msg.toLowerCase();

  if (lowMsg.contains('invalid login credentials')) {
    return 'E-mel atau kata laluan salah. Sila cuba lagi.';
  }
  if (lowMsg.contains('email not confirmed')) {
    return 'E-mel anda belum disahkan. Sila semak peti masuk anda.';
  }
  if (lowMsg.contains('user already registered') || lowMsg.contains('already exists')) {
    return 'Akaun sudah wujud. Sila log masuk atau gunakan e-mel lain.';
  }
  if (lowMsg.contains('failed host lookup') ||
      lowMsg.contains('network_error') ||
      lowMsg.contains('socketexception') ||
      lowMsg.contains('connection failed')) {
    return 'Tiada sambungan internet. Sila periksa rangkaian anda.';
  }
  if (lowMsg.contains('weak password')) {
    return 'Kata laluan terlalu lemah. Gunakan sekurang-kurangnya 6 aksara.';
  }
  if (lowMsg.contains('user not found')) {
    return 'Pengguna tidak ditemui. Sila daftar akaun baru.';
  }
  if (lowMsg.contains('invalid email')) {
    return 'Format e-mel tidak sah.';
  }
  if (lowMsg.contains('timeout')) {
    return 'Sambungan terputus (Timeout). Sila cuba sebentar lagi.';
  }
  if (lowMsg.contains('rate limit')) {
    return 'Terlalu banyak percubaan. Sila tunggu sebentar.';
  }
  if (lowMsg.contains('unexpected end of stream')) {
    return 'Masalah rangkaian. Sila cuba lagi.';
  }

  if (msg.isNotEmpty) {
    return msg[0].toUpperCase() + msg.substring(1);
  }
  return 'Berlaku ralat. Sila cuba lagi.';
}
