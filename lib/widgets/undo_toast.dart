import 'package:flutter/material.dart';

class UndoToast extends StatelessWidget {
  final String message;
  final int countdown;
  final VoidCallback? onUndo;
  final VoidCallback onDismiss;

  const UndoToast({
    super.key,
    required this.message,
    this.countdown = 5,
    this.onUndo,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFFF4F4F5) : const Color(0xFF0F172A);
    final textColor = isDark ? const Color(0xFF090A0C) : Colors.white;
    final undoTextColor = isDark ? const Color(0xFFB45309) : const Color(0xFFFBBF24);
    final undoPillBg = isDark ? const Color(0xFFFEF3C7) : const Color(0xFF1E293B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFFE4E4E7) : const Color(0xFF1E293B),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 13,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onUndo != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onUndo,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: undoPillBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Urungkan (${countdown}d)',
                  style: TextStyle(
                    color: undoTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close,
                size: 16,
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
