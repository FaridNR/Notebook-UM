import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DockNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback? onCenterAction;

  const DockNavigation({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.onCenterAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final activeTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final inactiveTextColor = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    final isCenterActive = selectedIndex == 2;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Symmetrical Flat Navigation Bar
        Container(
          decoration: BoxDecoration(
            color: surfaceColor.withValues(alpha: 0.98),
            border: Border(
              top: BorderSide(
                color: isDark ? const Color(0xFF1E2433) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 62,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    label: 'Hari Ini',
                    icon: CupertinoIcons.calendar_today,
                    activeIcon: CupertinoIcons.calendar_today,
                    isSelected: selectedIndex == 0,
                    activeColor: activeTextColor,
                    inactiveColor: inactiveTextColor,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    index: 1,
                    label: 'Jadwal',
                    icon: CupertinoIcons.time,
                    activeIcon: CupertinoIcons.time_solid,
                    isSelected: selectedIndex == 1,
                    activeColor: activeTextColor,
                    inactiveColor: inactiveTextColor,
                    isDark: isDark,
                  ),
                  // Space reserved for the protruding center DANA-style button
                  const SizedBox(width: 68),
                  _buildNavItem(
                    index: 3,
                    label: 'Matkul',
                    icon: CupertinoIcons.book,
                    activeIcon: CupertinoIcons.book_fill,
                    isSelected: selectedIndex == 3,
                    activeColor: activeTextColor,
                    inactiveColor: inactiveTextColor,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    index: 4,
                    label: 'Akun',
                    icon: CupertinoIcons.person,
                    activeIcon: CupertinoIcons.person_fill,
                    isSelected: selectedIndex == 4,
                    activeColor: activeTextColor,
                    inactiveColor: inactiveTextColor,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Prominent Center Button (DANA Style - Floating Action Button for Tugas)
        Positioned(
          top: -18,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (onCenterAction != null) {
                onCenterAction!();
              } else {
                onTabSelected(2);
              }
            },
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFF118EEA), // DANA Iconic Primary Blue
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCenterActive
                      ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF93C5FD))
                      : surfaceColor,
                  width: 3.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF118EEA).withValues(alpha: 0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.task_alt_rounded,
                    size: 21,
                    color: Colors.white,
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Tugas',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required bool isSelected,
    required Color activeColor,
    required Color inactiveColor,
    required bool isDark,
  }) {
    final activePillBg = isDark ? const Color(0xFF1E2433) : const Color(0xFFF1F4F9);

    return Expanded(
      child: InkWell(
        onTap: () => onTabSelected(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 12 : 6,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: isSelected ? activePillBg : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 20,
                  color: isSelected ? activeColor : inactiveColor,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? activeColor : inactiveColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
