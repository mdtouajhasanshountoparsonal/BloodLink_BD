import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'donate_screen.dart';
import 'home_screen.dart';
import 'nearby_screen.dart';
import 'profile_screen.dart';
import 'requests_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _pages = [
    HomeScreen(),
    RequestsScreen(),
    DonateScreen(),
    NearbyScreen(),
    ProfileScreen(),
  ];

  void _select(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          IndexedStack(index: _index, children: _pages),
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: _NavBar(index: _index, onSelect: _select),
          ),
        ],
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _NavItem(
              icon: Icons.home_rounded,
              label: 'হোম',
              selected: index == 0,
              onTap: () => onSelect(0),
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.notifications_rounded,
              label: 'রিকোয়েস্ট',
              selected: index == 1,
              onTap: () => onSelect(1),
            ),
          ),
          _DonateFab(selected: index == 2, onTap: () => onSelect(2)),
          Expanded(
            child: _NavItem(
              icon: Icons.explore_rounded,
              label: 'কাছাকাছি',
              selected: index == 3,
              onTap: () => onSelect(3),
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.person_rounded,
              label: 'প্রোফাইল',
              selected: index == 4,
              onTap: () => onSelect(4),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 23, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonateFab extends StatelessWidget {
  const _DonateFab({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Transform.translate(
        offset: const Offset(0, -12),
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.primarySoft, AppColors.primaryDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppColors.border, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.5),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.water_drop, color: Colors.white, size: 22),
              Text(
                'ডোনেট',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
