import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/task.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/course_badge.dart';

class TasksScreen extends StatefulWidget {
  final AppState appState;

  const TasksScreen({
    super.key,
    required this.appState,
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.appState.taskSearchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showTaskDetailSheet(BuildContext context, CourseTask task) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final insetTone = isDark ? AppColors.darkSurfaceStep : AppColors.lightSurfaceStep;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final c = widget.appState.getCourse(task.courseId);

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE5E8EC), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CourseBadge(code: task.courseCode, tone: c?.tone ?? CourseTone.zinc),
                      const SizedBox(width: 8),
                      Text(task.courseName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 8),
              Text(task.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary)),
              if (task.notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: insetTone, borderRadius: BorderRadius.circular(12)),
                  child: Text(task.notes, style: TextStyle(fontSize: 13, color: textPrimary)),
                ),
              ],
              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tenggat Waktu:', style: TextStyle(fontSize: 12, color: textSecondary)),
                  Text(task.dueText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Prioritas:', style: TextStyle(fontSize: 12, color: textSecondary)),
                  Text(task.priority.name.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFF43F5E))),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        widget.appState.toggleTaskCompletion(task.id);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : const Color(0xFF090A0C),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          task.isCompleted ? 'Buka Kembali' : 'Tandai Selesai',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF090A0C) : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      widget.appState.deleteTask(task.id);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.roseDarkBg : AppColors.roseLightBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Hapus',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.roseTextDark : AppColors.roseText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgCard = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final insetTone = isDark ? AppColors.darkSurfaceStep : AppColors.lightSurfaceStep;

    // Filter logic
    final query = widget.appState.taskSearchQuery.toLowerCase();
    final statusTab = widget.appState.selectedStatusTab;
    final courseFilter = widget.appState.selectedCourseFilter;

    final allTasks = widget.appState.tasks;

    final filteredTasks = allTasks.where((t) {
      if (query.isNotEmpty) {
        final matchesTitle = t.title.toLowerCase().contains(query);
        final matchesNotes = t.notes.toLowerCase().contains(query);
        final matchesCourse = t.courseName.toLowerCase().contains(query) ||
            t.courseCode.toLowerCase().contains(query);
        if (!matchesTitle && !matchesNotes && !matchesCourse) return false;
      }

      if (courseFilter != null) {
        if (t.courseCode != courseFilter && t.courseName != courseFilter) return false;
      }

      if (statusTab == 'Mendesak') {
        return t.dueCategory == TaskDueCategory.urgent && !t.isCompleted;
      } else if (statusTab == 'Next Session') {
        return t.dueCategory == TaskDueCategory.nextSession && !t.isCompleted;
      } else if (statusTab == 'Mendatang') {
        return t.dueCategory == TaskDueCategory.upcoming && !t.isCompleted;
      } else if (statusTab == 'Selesai') {
        return t.isCompleted;
      }
      return true;
    }).toList();

    final urgentTasks = filteredTasks.where((t) => t.dueCategory == TaskDueCategory.urgent && !t.isCompleted).toList();
    final nextSessionTasks = filteredTasks.where((t) => t.dueCategory == TaskDueCategory.nextSession && !t.isCompleted).toList();
    final upcomingTasks = filteredTasks.where((t) => t.dueCategory == TaskDueCategory.upcoming && !t.isCompleted).toList();
    final completedTasks = filteredTasks.where((t) => t.isCompleted).toList();

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daftar Tugas',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.appState.activeTasksCount} Tugas Aktif • ${widget.appState.completedTasksCount} Selesai',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => AddTaskSheet.show(context, widget.appState),
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFFF4F4F5) : const Color(0xFF090A0C),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 16, color: isDark ? const Color(0xFF090A0C) : Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Tugas Baru',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF090A0C) : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar & Filter Strip
            Container(
              color: bgCard,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  // Search Input
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceStep : const Color(0xFFF4F5F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, size: 18, color: textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => widget.appState.setTaskSearchQuery(val),
                            style: TextStyle(fontSize: 13, color: textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Cari tugas atau mata kuliah...',
                              hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              widget.appState.setTaskSearchQuery('');
                            },
                            child: Icon(Icons.clear, size: 16, color: textSecondary),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Segmented Status Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceStep : const Color(0xFFF4F5F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildStatusTab('Semua', 'Semua (${allTasks.length})', isDark, textPrimary, textSecondary),
                          _buildStatusTab('Mendesak', 'Mendesak (${allTasks.where((t) => t.dueCategory == TaskDueCategory.urgent && !t.isCompleted).length})', isDark, textPrimary, textSecondary),
                          _buildStatusTab('Next Session', 'Next Session (${allTasks.where((t) => t.dueCategory == TaskDueCategory.nextSession && !t.isCompleted).length})', isDark, textPrimary, textSecondary),
                          _buildStatusTab('Mendatang', 'Mendatang (${allTasks.where((t) => t.dueCategory == TaskDueCategory.upcoming && !t.isCompleted).length})', isDark, textPrimary, textSecondary),
                          _buildStatusTab('Selesai', 'Selesai (${widget.appState.completedTasksCount})', isDark, textPrimary, textSecondary),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Dynamic Course Filter Rail
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCourseFilterChip(
                          label: 'Semua Matkul',
                          isSelected: courseFilter == null,
                          isDark: isDark,
                          onTap: () => widget.appState.setCourseFilter(null),
                        ),
                        ...widget.appState.courses.map((course) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _buildCourseFilterChip(
                              label: course.name,
                              dotColor: course.accentColor,
                              isSelected: courseFilter == course.code || courseFilter == course.name,
                              isDark: isDark,
                              onTap: () => widget.appState.setCourseFilter(course.code),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Task Content List
            Expanded(
              child: filteredTasks.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.assignment_turned_in_outlined, size: 48, color: textSecondary),
                            const SizedBox(height: 12),
                            Text('Belum Ada Tugas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
                            const SizedBox(height: 4),
                            Text('Daftar tugas kosong. Ketuk tombol Upload di bawah untuk menambahkan tugas baru.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: textSecondary)),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => AddTaskSheet.show(context, widget.appState),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF118EEA),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(CupertinoIcons.cloud_upload_fill, size: 16, color: Colors.white),
                                    SizedBox(width: 6),
                                    Text(
                                      'Upload Tugas Baru',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                      children: [
                        // Section 1: Mendesak (< 24 Jam)
                        if (urgentTasks.isNotEmpty) ...[
                          _buildSectionHeader(
                            title: 'Mendesak (< 24 Jam)',
                            dotColor: const Color(0xFFF43F5E),
                            countText: '${urgentTasks.length} Tugas Prioritas',
                            isDark: isDark,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                          const SizedBox(height: 8),
                          ...urgentTasks.map((task) => _buildTaskCard(task, isDark, bgCard, textPrimary, textSecondary, insetTone)),
                          const SizedBox(height: 16),
                        ],

                        // Section 2: Pertemuan Berikutnya
                        if (nextSessionTasks.isNotEmpty) ...[
                          _buildSectionHeader(
                            title: 'Pertemuan Berikutnya',
                            dotColor: const Color(0xFF3B82F6),
                            countText: '${nextSessionTasks.length} Tugas',
                            badge: 'Otomatis',
                            isDark: isDark,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                          const SizedBox(height: 8),
                          ...nextSessionTasks.map((task) => _buildTaskCard(task, isDark, bgCard, textPrimary, textSecondary, insetTone)),
                          const SizedBox(height: 16),
                        ],

                        // Section 3: Jadwal Mendatang & Mandiri
                        if (upcomingTasks.isNotEmpty) ...[
                          _buildSectionHeader(
                            title: 'Jadwal Mendatang & Mandiri',
                            countText: '${upcomingTasks.length} Tugas',
                            isDark: isDark,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                          const SizedBox(height: 8),
                          ...upcomingTasks.map((task) => _buildTaskCard(task, isDark, bgCard, textPrimary, textSecondary, insetTone)),
                          const SizedBox(height: 16),
                        ],

                        // Section 4: Selesai
                        if (completedTasks.isNotEmpty) ...[
                          _buildSectionHeader(
                            title: 'Selesai (${completedTasks.length})',
                            countText: 'Arsip Tugas',
                            isDark: isDark,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                          const SizedBox(height: 8),
                          ...completedTasks.map((task) => _buildTaskCard(task, isDark, bgCard, textPrimary, textSecondary, insetTone)),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTab(
    String key,
    String label,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final isSelected = widget.appState.selectedStatusTab == key;
    return GestureDetector(
      onTap: () => widget.appState.setStatusTab(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? AppColors.darkSurface : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? textPrimary : textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCourseFilterChip({
    required String label,
    Color? dotColor,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : const Color(0xFF090A0C))
              : (isDark ? AppColors.darkSurfaceStep : const Color(0xFFF4F5F7)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? const Color(0xFF090A0C) : Colors.white)
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    Color? dotColor,
    required String countText,
    String? badge,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (dotColor != null) ...[
                Container(width: 7, height: 7, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                const SizedBox(width: 6),
              ],
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: isDark ? AppColors.blueDarkBg : AppColors.blueLightBg, borderRadius: BorderRadius.circular(4)),
                  child: Text(badge, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: isDark ? AppColors.blueTextDark : AppColors.blueText)),
                ),
              ],
            ],
          ),
          Text(countText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary)),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
    CourseTask task,
    bool isDark,
    Color bgCard,
    Color textPrimary,
    Color textSecondary,
    Color insetTone,
  ) {
    final c = widget.appState.getCourse(task.courseId);

    return GestureDetector(
      onTap: () => _showTaskDetailSheet(context, task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF1E2430) : const Color(0xFFE5E8EC),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.appState.toggleTaskCompletion(task.id),
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
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        task.dueText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: task.isCompleted
                              ? const Color(0xFF10B981)
                              : (task.dueCategory == TaskDueCategory.urgent
                                  ? const Color(0xFFF43F5E)
                                  : (isDark ? AppColors.blueTextDark : AppColors.blueText)),
                        ),
                      ),
                      if (task.secondaryMeta != null)
                        Text(
                          task.secondaryMeta!,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textSecondary),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
