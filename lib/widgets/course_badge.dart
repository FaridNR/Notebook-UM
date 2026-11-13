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

    final bg = isDark
        ? (isSolid ? const Color(0xFF27272A) : const Color(0xFF18191E))
        : (isSolid ? const Color(0xFFE5E7EB) : const Color(0xFFF4F5F7));
    final border = isDark ? const Color(0xFF2E313A) : const Color(0xFFE5E7EB);
    final text = isDark ? const Color(0xFFE4E4E7) : const Color(0xFF27272A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Text(
        code,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
