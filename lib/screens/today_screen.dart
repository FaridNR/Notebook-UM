import 'package:flutter/material.dart';
import '../core/time/time_service.dart';
import '../models/course.dart';
import '../models/schedule_slot.dart';
import '../models/task.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/course_badge.dart';

class TodayScreen extends StatelessWidget {
  final AppState appState;

  const TodayScreen({
    super.key,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgCard = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final insetTone = isDark ? AppColors.darkSurfaceStep : AppColors.lightSurfaceStep;

    final todaySlots = appState.getTodaySlots();
    final activeSlot = appState.getActiveSlotToday();
    final activeCourse = activeSlot != null ? appState.getCourse(activeSlot.courseId) : null;
    final now = appState.liveNow;

    // Filter urgent tasks (< 24 jam / urgent)
    final urgentTasks = appState.tasks.where((t) => !t.isCompleted).take(3).toList();

    // Related task for current active slot
    final relatedTask = activeSlot != null
        ? appState.tasks.cast<CourseTask?>().firstWhere(
            (t) => t != null && t.courseId == activeSlot.courseId && !t.isCompleted,
            orElse: () => null,
          )
        : null;

    // Avatar initials
    final initials = appState.displayName
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .take(2)
        .join();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top App Header
            Container(
              color: bgCard,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF1F3F7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        clipBehavior: Clip.antiAlias,
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/images/logo_um.png',
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white : const Color(0xFF090A0C),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'UM',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF090A0C) : Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'NoteBook UM',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            TimeService.formatLiveClock(now),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceStep2 : AppColors.lightBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Sinkron ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                            const Text(
                              'Aktif',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF272A34) : const Color(0xFFE5E8EC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials.isNotEmpty ? initials : 'UM',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main Content Feed
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                children: [
                  // Hero: Live Active Lecture (or Empty State)
                  if (activeSlot != null && activeCourse != null) ...[
                    _buildHeroActiveLecture(
                      context: context,
                      slot: activeSlot,
                      course: activeCourse,
                      relatedTask: relatedTask,
                      now: now,
                      bgCard: bgCard,
                      insetTone: insetTone,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDark: isDark,
                    ),
                  ] else ...[
                    // PRD Section 4.4 & 1.5 Empty state: "Belum ada kelas hari ini. Santai dulu, atau cicil tugasmu."
                    Container(
                      decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.event_available_outlined, size: 44, color: AppColors.emeraldAccent),
                          const SizedBox(height: 12),
                          Text(
                            'Hari Ini Santai',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Belum ada kelas hari ini. Santai dulu, atau cicil tugasmu.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => AddTaskSheet.show(context, appState),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white : const Color(0xFF090A0C),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Tambah Tugas Baru',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFF090A0C) : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Schedule Feed for Today
                  Container(
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E2430) : const Color(0xFFE5E8EC),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Jadwal Hari Ini',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              '${todaySlots.length} Sesi Terjadwal',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (todaySlots.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Tidak ada jadwal kuliah hari ini.',
                              style: TextStyle(fontSize: 12, color: textSecondary),
                            ),
                          )
                        else
                          ...todaySlots.map((slot) {
                            final c = appState.getCourse(slot.courseId);
                            final statusRes = TimeService.getClassStatus(now, slot);
                            final isOngoing = statusRes.status == ClassStatus.berlangsung;
                            final isCompleted = statusRes.status == ClassStatus.selesai;

                            return Opacity(
                              opacity: isCompleted ? 0.55 : 1.0,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isOngoing
                                      ? (isDark ? AppColors.amberDarkBg : AppColors.amberLightBg)
                                      : insetTone,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: c?.accentColor ?? AppColors.amberAccent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CourseBadge(code: slot.courseCode, tone: c?.tone ?? CourseTone.zinc),
                                              const SizedBox(width: 6),
                                              Text(
                                                slot.courseName,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${slot.room} • ${c?.lecturer ?? "-"}',
                                            style: TextStyle(fontSize: 11, color: textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${slot.startTime} – ${slot.endTime}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: isOngoing ? FontWeight.w700 : FontWeight.w500,
                                            color: isOngoing
                                                ? (isDark ? AppColors.amberTextDark : AppColors.amberText)
                                                : textSecondary,
                                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isOngoing
                                              ? 'Aktif Sekarang'
                                              : (isCompleted ? 'Selesai' : 'Akan Datang'),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: isOngoing
                                                ? (isDark ? AppColors.amberTextDark : AppColors.amberText)
                                                : (isCompleted ? const Color(0xFF10B981) : textSecondary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Relevant Tasks Section
                  Container(
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E2430) : const Color(0xFFE5E8EC),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Tugas Mendesak',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: insetTone,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${urgentTasks.length}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => appState.setTabIndex(2), // Switch to Tugas tab
                              child: Text(
                                'Semua Tugas →',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (urgentTasks.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF10B981)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tidak ada tugas mendesak',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        'Semua tugas telah beres atau belum ada tugas baru.',
                                        style: TextStyle(fontSize: 11, color: textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...urgentTasks.map((task) {
                            final c = appState.getCourse(task.courseId);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: insetTone,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => appState.toggleTaskCompletion(task.id),
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 6, bottom: 6),
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        margin: const EdgeInsets.only(top: 2),
                                        decoration: BoxDecoration(
                                          color: task.isCompleted
                                              ? const Color(0xFF10B981)
                                              : (isDark ? const Color(0xFF272A34) : const Color(0xFFE5E8EC)),
                                          borderRadius: BorderRadius.circular(6),
                                          border: task.isCompleted
                                              ? null
                                              : Border.all(color: textSecondary.withValues(alpha: 0.3), width: 1.2),
                                        ),
                                        child: task.isCompleted
                                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                                            : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CourseBadge(code: task.courseCode, tone: c?.tone ?? CourseTone.zinc),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                task.title,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: textPrimary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (task.notes.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            task.notes,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 11, color: textSecondary),
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        Text(
                                          task.dueText,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFF43F5E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroActiveLecture({
    required BuildContext context,
    required ScheduleSlot slot,
    required Course course,
    required CourseTask? relatedTask,
    required DateTime now,
    required Color bgCard,
    required Color insetTone,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    final statusResult = TimeService.getClassStatus(now, slot);
    final isOngoing = statusResult.status == ClassStatus.berlangsung;

    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOngoing
              ? (isDark ? AppColors.amberAccent.withValues(alpha: 0.35) : AppColors.amberAccent.withValues(alpha: 0.45))
              : (isDark ? const Color(0xFF1E2430) : const Color(0xFFE5E8EC)),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isOngoing
                ? (isDark ? AppColors.amberAccent.withValues(alpha: 0.1) : AppColors.amberAccent.withValues(alpha: 0.08))
                : Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isOngoing ? AppColors.amberAccent : const Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusResult.statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isOngoing
                                ? (isDark ? AppColors.amberTextDark : AppColors.amberText)
                                : textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      course.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${course.code} • ${course.lecturer}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: insetTone,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      slot.room,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${slot.startTime} – ${slot.endTime}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Duration Progress Track
          Column(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: insetTone,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: statusResult.progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isOngoing ? AppColors.amberAccent : const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mulai ${slot.startTime}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: textSecondary),
                  ),
                  Text(
                    statusResult.remainingText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isOngoing
                          ? (isDark ? AppColors.amberTextDark : AppColors.amberText)
                          : textSecondary,
                    ),
                  ),
                  Text(
                    'Selesai ${slot.endTime}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: textSecondary),
                  ),
                ],
              ),
            ],
          ),

          if (relatedTask != null) ...[
            const SizedBox(height: 16),
            // Connected Assignment (Tone Step Inset)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: insetTone,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tugas Terkait Sesi Ini',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                      Text(
                        'Prioritas ${relatedTask.priority.name.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF43F5E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => appState.toggleTaskCompletion(relatedTask.id),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6, bottom: 6),
                          child: Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: relatedTask.isCompleted
                                  ? const Color(0xFF10B981)
                                  : (isDark ? const Color(0xFF272A34) : const Color(0xFFE5E8EC)),
                              borderRadius: BorderRadius.circular(6),
                              border: relatedTask.isCompleted
                                  ? null
                                  : Border.all(color: textSecondary.withValues(alpha: 0.3), width: 1.2),
                            ),
                            child: relatedTask.isCompleted
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              relatedTask.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${relatedTask.dueText} • ${relatedTask.notes}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
