import 'package:flutter/material.dart';
import 'custom_bottom_nav.dart';

// ============================================================
// Ngam App — Customer Bottom Navigation
// Home, Post, My Tasks, Profile
// ============================================================

class BottomNavCustomer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavCustomer({
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
          icon: Icons.home_rounded,
          title: 'Home',
        ),
        NavItem(
          icon: Icons.add_circle_outline,
          title: 'Post',
        ),
        NavItem(
          icon: Icons.receipt_long_rounded,
          title: 'My Tasks',
        ),
        NavItem(
          icon: Icons.person_rounded,
          title: 'Profile',
        ),
      ],
    );
  }
}
