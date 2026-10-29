import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'schedule_slot.dart';

enum CourseTone { amber, blue, emerald, purple, zinc }

class Course {
  final String id;
  final String code;
  final String name;
  final String lecturer;
  final int sks;
  final CourseTone tone;
  final List<ScheduleSlot> slots;

  const Course({
    required this.id,
    required this.code,
    required this.name,
    required this.lecturer,
    required this.sks,
    required this.tone,
    this.slots = const [],
  });

  Color get accentColor {
    switch (tone) {
      case CourseTone.amber:
        return AppColors.amberAccent;
      case CourseTone.blue:
        return AppColors.blueAccent;
      case CourseTone.emerald:
        return AppColors.emeraldAccent;
      case CourseTone.purple:
        return AppColors.purpleAccent;
      case CourseTone.zinc:
        return const Color(0xFF27272A);
    }
  }

  Color lightBadgeBg(BuildContext context) {
    switch (tone) {
      case CourseTone.amber:
        return const Color(0xFFFEF3C7);
      case CourseTone.blue:
        return const Color(0xFFDBEAFE);
      case CourseTone.emerald:
        return const Color(0xFFD1FAE5);
      case CourseTone.purple:
        return const Color(0xFFEDE9FE);
      case CourseTone.zinc:
        return const Color(0xFFF4F5F7);
    }
  }

  Color darkBadgeBg(BuildContext context) {
    switch (tone) {
      case CourseTone.amber:
        return const Color(0xFF451A03);
      case CourseTone.blue:
        return const Color(0xFF1E3A8A);
      case CourseTone.emerald:
        return const Color(0xFF064E3B);
      case CourseTone.purple:
        return const Color(0xFF3B0764);
      case CourseTone.zinc:
        return const Color(0xFF27272A);
    }
  }

  Color badgeTextColor(bool isDark) {
    if (isDark) {
      switch (tone) {
        case CourseTone.amber:
          return const Color(0xFFFDE68A);
        case CourseTone.blue:
          return const Color(0xFFBFDBFE);
        case CourseTone.emerald:
          return const Color(0xFFA7F3D0);
        case CourseTone.purple:
          return const Color(0xFFDDD6FE);
        case CourseTone.zinc:
          return const Color(0xFFE4E4E7);
      }
    } else {
      switch (tone) {
        case CourseTone.amber:
          return const Color(0xFF92400E);
        case CourseTone.blue:
          return const Color(0xFF1E40AF);
        case CourseTone.emerald:
          return const Color(0xFF065F46);
        case CourseTone.purple:
          return const Color(0xFF5B21B6);
        case CourseTone.zinc:
          return const Color(0xFF27272A);
      }
    }
  }

  Course copyWith({
    String? id,
    String? code,
    String? name,
    String? lecturer,
    int? sks,
    CourseTone? tone,
    List<ScheduleSlot>? slots,
  }) {
    return Course(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      lecturer: lecturer ?? this.lecturer,
      sks: sks ?? this.sks,
      tone: tone ?? this.tone,
      slots: slots ?? this.slots,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'lecturer': lecturer,
        'sks': sks,
        'tone': tone.name,
        'slots': slots.map((s) => s.toJson()).toList(),
      };
}
