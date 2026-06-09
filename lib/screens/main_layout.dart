import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'chat_list_screen.dart';
import 'my_events_screen.dart';
import 'profile_screen.dart';
import 'create_plan_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    ExploreScreen(),
    MyEventsScreen(),
    ChatListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: ColoredBox(
        color: AppColors.bg,
        child: IndexedStack(index: _currentIndex, children: _screens),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              heroTag: 'main_fab',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePlanScreen()),
              ),
              backgroundColor: AppColors.accent,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgSecondary,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home', index: 0, current: _currentIndex, onTap: _setTab),
                _NavItem(icon: Icons.search, activeIcon: Icons.search, label: 'Explore', index: 1, current: _currentIndex, onTap: _setTab),
                _NavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Events', index: 2, current: _currentIndex, onTap: _setTab),
                _NavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Chats', index: 3, current: _currentIndex, onTap: _setTab),
                _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', index: 4, current: _currentIndex, onTap: _setTab),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setTab(int i) => setState(() => _currentIndex = i);
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 22,
              color: isActive ? AppColors.navy : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                color: isActive ? AppColors.navy : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
