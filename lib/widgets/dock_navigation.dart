import 'dart:math' as math;
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
    final borderColor = isDark ? const Color(0xFF1E2433) : const Color(0xFFE2E8F0);
    final activeTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final inactiveTextColor = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    final isCenterActive = selectedIndex == 2;
    // Warna tombol tengah diselaraskan dengan palet utama aplikasi (obsidian / ivory)
    final centerButtonBg = isDark ? const Color(0xFFF4F4F5) : const Color(0xFF090A0C);
    final centerButtonFg = isDark ? const Color(0xFF090A0C) : Colors.white;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Navigation Bar berlekuk halus (notched curve) yang melengkung mengikuti lingkaran ikon Tugas
        CustomPaint(
          painter: NotchedDockPainter(
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            isDark: isDark,
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
                  // Ruang di tengah khusus untuk lengkungan tombol Tugas
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

        // Tombol Tengah Tugas dengan warna yang serasi dengan identitas aplikasi NoteBook UM
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
                color: centerButtonBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCenterActive
                      ? (isDark ? Colors.white : const Color(0xFF2563EB))
                      : surfaceColor,
                  width: 3.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : const Color(0xFF090A0C)).withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.task_alt_rounded,
                    size: 21,
                    color: centerButtonFg,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Tugas',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: centerButtonFg,
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

/// CustomPainter untuk menggambar garis tepi dan permukaan dock yang melengkung
/// mengikuti kontur lingkaran tombol Tugas di tengah secara presisi dan mulus.
class NotchedDockPainter extends CustomPainter {
  final Color surfaceColor;
  final Color borderColor;
  final bool isDark;

  const NotchedDockPainter({
    required this.surfaceColor,
    required this.borderColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final host = Rect.fromLTWH(0, 0, size.width, size.height);
    final guestCenter = Offset(size.width / 2, 11);
    const r = 35.0; // Radius lekukan (radius tombol 29 + margin lekukan 6)
    const s1 = 14.0;
    const s2 = 2.0;

    final double a = -r - s2;
    final double b = host.top - guestCenter.dy;

    final double n2 = math.sqrt(b * b * r * r * (a * a + b * b - r * r));
    final double p2xA = ((a * r * r) - n2) / (a * a + b * b);
    final double p2xB = ((a * r * r) + n2) / (a * a + b * b);
    final double p2yA = math.sqrt(r * r - p2xA * p2xA);
    final double p2yB = math.sqrt(r * r - p2xB * p2xB);

    final p = List<Offset>.filled(6, Offset.zero);
    p[0] = Offset(a - s1, b);
    p[1] = Offset(a, b);
    final cmp = b < 0 ? -1.0 : 1.0;
    p[2] = cmp * p2yA > cmp * p2yB ? Offset(p2xA, p2yA) : Offset(p2xB, p2yB);

    p[3] = Offset(-1.0 * p[2].dx, p[2].dy);
    p[4] = Offset(-1.0 * p[1].dx, p[1].dy);
    p[5] = Offset(-1.0 * p[0].dx, p[0].dy);

    for (var i = 0; i < p.length; i += 1) {
      p[i] += guestCenter;
    }

    // Path permukaan yang diisi warna background dock
    final fillPath = Path()
      ..moveTo(host.left, host.top)
      ..lineTo(p[0].dx, p[0].dy)
      ..quadraticBezierTo(p[1].dx, p[1].dy, p[2].dx, p[2].dy)
      ..arcToPoint(p[3], radius: const Radius.circular(r), clockwise: false)
      ..quadraticBezierTo(p[4].dx, p[4].dy, p[5].dx, p[5].dy)
      ..lineTo(host.right, host.top)
      ..lineTo(host.right, host.bottom)
      ..lineTo(host.left, host.bottom)
      ..close();

    // Path garis atas dock yang melengkung mengikuti lekukan
    final borderPath = Path()
      ..moveTo(host.left, host.top)
      ..lineTo(p[0].dx, p[0].dy)
      ..quadraticBezierTo(p[1].dx, p[1].dy, p[2].dx, p[2].dy)
      ..arcToPoint(p[3], radius: const Radius.circular(r), clockwise: false)
      ..quadraticBezierTo(p[4].dx, p[4].dy, p[5].dx, p[5].dy)
      ..lineTo(host.right, host.top);

    // Efek bayangan halus dock
    canvas.drawShadow(
      fillPath,
      Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
      6.0,
      false,
    );

    // Gambar background permukaan
    final fillPaint = Paint()
      ..color = surfaceColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Gambar garis batas atas yang melengkung
    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant NotchedDockPainter oldDelegate) {
    return oldDelegate.surfaceColor != surfaceColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.isDark != isDark;
  }
}
