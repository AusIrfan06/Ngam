import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'custom_bottom_nav.dart';

// ============================================================
// Ngam App — Runner Bottom Navigation
// Home, My Jobs, Chat, Profile
// ============================================================

class BottomNavRunner extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavRunner({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomBottomNav(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        NavItem(
          icon: HugeIcons.strokeRoundedCompass,
          title: 'Home',
        ),
        NavItem(
          icon: HugeIcons.strokeRoundedBriefcase02,
          title: 'Jobs',
        ),
        NavItem(
          icon: HugeIcons.strokeRoundedBubbleChat,
          title: 'Chat',
        ),
        NavItem(
          icon: HugeIcons.strokeRoundedChartHistogram, // Fixed inverted icon
          title: 'Stats',
        ),
        NavItem(
          icon: HugeIcons.strokeRoundedUser,
          title: 'Profile',
        ),
      ],
    );
  }
}
