import 'package:flutter/material.dart';
import '../models/course.dart';

class CourseBadge extends StatelessWidget {
  final String code;
  final CourseTone tone;
  final bool isSolid;

  const CourseBadge({
    super.key,
    required this.code,
    required this.tone,
    this.isSolid = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color text;

    if (isSolid) {
      switch (tone) {
        case CourseTone.amber:
          bg = const Color(0xFFD97706);
          text = Colors.white;
          break;
        case CourseTone.blue:
          bg = const Color(0xFF2563EB);
          text = Colors.white;
          break;
        case CourseTone.emerald:
          bg = const Color(0xFF059669);
          text = Colors.white;
          break;
        case CourseTone.purple:
          bg = const Color(0xFF7C3AED);
          text = Colors.white;
          break;
        case CourseTone.zinc:
          bg = isDark ? const Color(0xFFE4E4E7) : const Color(0xFF27272A);
          text = isDark ? const Color(0xFF18181B) : Colors.white;
          break;
      }
    } else {
      switch (tone) {
        case CourseTone.amber:
          bg = isDark ? const Color(0xFF38230D) : const Color(0xFFFEF3C7);
          text = isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E);
          break;
        case CourseTone.blue:
          bg = isDark ? const Color(0xFF162548) : const Color(0xFFDBEAFE);
          text = isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF);
          break;
        case CourseTone.emerald:
          bg = isDark ? const Color(0xFF0D3326) : const Color(0xFFD1FAE5);
          text = isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46);
          break;
        case CourseTone.purple:
          bg = isDark ? const Color(0xFF2E1A47) : const Color(0xFFEDE9FE);
          text = isDark ? const Color(0xFFDDD6FE) : const Color(0xFF5B21B6);
          break;
        case CourseTone.zinc:
          bg = isDark ? const Color(0xFF27272A) : const Color(0xFFF4F5F7);
          text = isDark ? const Color(0xFFE4E4E7) : const Color(0xFF3F3F46);
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        code,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}
