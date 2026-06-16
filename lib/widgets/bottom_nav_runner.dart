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
        BottomNavigationBarItem(
          icon: Icon(Icons.explore_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.work_rounded),
          label: 'My Jobs',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline_rounded),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}
