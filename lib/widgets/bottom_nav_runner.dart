import 'package:flutter/material.dart';
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
      items: const [
        NavItem(
          icon: Icons.explore_rounded,
          title: 'Home',
        ),
        NavItem(
          icon: Icons.work_rounded,
          title: 'My Jobs',
        ),
        NavItem(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Chat',
        ),
        NavItem(
          icon: Icons.person_rounded,
          title: 'Profile',
        ),
      ],
    );
  }
}
