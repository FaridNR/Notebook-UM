import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/time/time_service.dart';
import '../models/course.dart';
import '../models/task.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class AddTaskSheet extends StatefulWidget {
  final AppState appState;

  const AddTaskSheet({
    super.key,
    required this.appState,
  });

  static void show(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddTaskSheet(appState: appState),
    );
  }

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;

  Course? _selectedCourse;
  int _dueModeIndex = 0; // 0: Next Session, 1: Pilih Tanggal, 2: Tanpa Tenggat
  TaskPriority _selectedPriority = TaskPriority.medium;
  bool _reminderEnabled = true;
  DateTime _customDate = DateTime.now().add(const Duration(days: 2));

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _notesController = TextEditingController();

    // PRD Section 1.5 Flow B: Mata kuliah terisi otomatis bila ada kelas berlangsung atau kelas terdekat
    final activeSlot = widget.appState.getActiveSlotToday();
    if (activeSlot != null) {
      _selectedCourse = widget.appState.getCourse(activeSlot.courseId);
    } else if (widget.appState.courses.isNotEmpty) {
      _selectedCourse = widget.appState.courses.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _pickCustomDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _customDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: _customDate.hour, minute: _customDate.minute),
      );

      if (pickedTime != null && mounted) {
        setState(() {
          _customDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _saveTask() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      widget.appState.showToast('Judul tugas tidak boleh kosong');
      return;
    }

    final String courseCode = _selectedCourse?.code ?? 'MANDIRI';
    final String courseName = _selectedCourse?.name ?? 'Kemahasiswaan';
    final String? courseId = _selectedCourse?.id;

    TaskDueCategory dueCategory;
    DueMode dueMode;
    DateTime? dueAt;
    String dueText;
    String? secondaryMeta;
    final now = widget.appState.liveNow;

    if (_dueModeIndex == 0) {
      // PRD Section 1.7 next_session logic
      dueMode = DueMode.nextSession;
      if (_selectedCourse != null && _selectedCourse!.slots.isNotEmpty) {
        dueAt = TimeService.calculateNextSession(
          createdAt: now,
          slots: _selectedCourse!.slots,
        );

        if (dueAt != null) {
          dueCategory = TaskDueCategory.nextSession;
          dueText = TimeService.formatNextSessionText(dueAt);
          final daysDiff = dueAt.difference(now).inDays;
          secondaryMeta = daysDiff > 0 ? '+$daysDiff Hari' : 'Hari Ini';
        } else {
          dueCategory = TaskDueCategory.upcoming;
          dueText = 'Peringatan: Belum ada jadwal';
          secondaryMeta = 'Tanpa Jadwal';
        }
      } else {
        dueCategory = TaskDueCategory.upcoming;
        dueText = 'Peringatan: Mata kuliah belum ada jadwal';
        secondaryMeta = 'Perlu Jadwal';
      }
    } else if (_dueModeIndex == 1) {
      dueMode = DueMode.fixed;
      dueAt = _customDate;
      final diff = _customDate.difference(now);
      if (diff.inHours < 24 && !diff.isNegative) {
        dueCategory = TaskDueCategory.urgent;
        dueText = 'Besok, ${_customDate.hour.toString().padLeft(2, '0')}:${_customDate.minute.toString().padLeft(2, '0')} WITA';
        secondaryMeta = 'Batas Pengumpulan';
      } else {
        dueCategory = TaskDueCategory.upcoming;
        dueText = '${_customDate.day}/${_customDate.month}/${_customDate.year} • ${_customDate.hour.toString().padLeft(2, '0')}:${_customDate.minute.toString().padLeft(2, '0')} WITA';
        secondaryMeta = 'Kalender';
      }
    } else {
      dueMode = DueMode.none;
      dueCategory = TaskDueCategory.upcoming;
      dueText = 'Fleksibel (Tanpa Tenggat)';
      secondaryMeta = 'Fleksibel';
    }

    final newTask = CourseTask(
      id: 'task-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      notes: _notesController.text.trim(),
      courseId: courseId,
      courseCode: courseCode,
      courseName: courseName,
      priority: _selectedPriority,
      dueCategory: dueCategory,
      dueMode: dueMode,
      dueAt: dueAt,
      createdAt: now,
      dueText: dueText,
      secondaryMeta: secondaryMeta,
      reminderEnabled: _reminderEnabled,
    );

    widget.appState.addTask(newTask);
    Navigator.of(context).pop();
    widget.appState.showToast('Tugas "$title" berhasil ditambahkan');
  }

  void _showCoursePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pilih Mata Kuliah',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...widget.appState.courses.map((course) {
                  final isSelected = _selectedCourse?.id == course.id;
                  return ListTile(
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: course.accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      '${course.code} • ${course.name}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      course.lecturer,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: isSelected ? const Icon(Icons.check, size: 20) : null,
                    onTap: () {
                      setState(() {
                        _selectedCourse = course;
                      });
                      Navigator.pop(ctx);
                    },
                  );
                }),
                ListTile(
                  leading: const Icon(Icons.person_outline, size: 20),
                  title: const Text('Tugas Mandiri (Non-Kuliah)'),
                  onTap: () {
                    setState(() {
                      _selectedCourse = null;
                    });
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
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
    final inputBg = isDark ? AppColors.darkSurfaceStep : AppColors.lightSurfaceStep;

    // Calculate preview for next session
    DateTime? nextSessionDue;
    if (_selectedCourse != null && _selectedCourse!.slots.isNotEmpty) {
      nextSessionDue = TimeService.calculateNextSession(
        createdAt: widget.appState.liveNow,
        slots: _selectedCourse!.slots,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E8EC),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Modal Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tambah Tugas',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pencatatan Cepat & Terhubung Sesi Kuliah',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Course Context Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedCourse != null
                        ? (isDark ? AppColors.amberDarkBg : AppColors.amberLightBg)
                        : inputBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _selectedCourse?.accentColor ?? Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedCourse != null
                                ? '${_selectedCourse!.code} • ${_selectedCourse!.name}'
                                : 'Tugas Mandiri (Non-Kuliah)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _showCoursePicker,
                        child: Text(
                          'Ganti',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blueAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Title Input
                Text('Judul Tugas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(12)),
                  child: TextField(
                    controller: _titleController,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Nama tugas kuliah...',
                      hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Notes Input
                Text('Catatan Tambahan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(12)),
                  child: TextField(
                    controller: _notesController,
                    maxLines: 2,
                    style: TextStyle(fontSize: 13, color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Format pengerjaan, instruksi dosen, dll...',
                      hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // 3-Way Segmented Due Date Mode (PRD Section 1.3 & Canvas Node 4)
                Text('Tenggat Waktu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      _buildDueModeOption(0, 'Next Session', 'Otomatis', isDark, textPrimary, textSecondary),
                      _buildDueModeOption(1, 'Pilih Tanggal', 'Kalender', isDark, textPrimary, textSecondary),
                      _buildDueModeOption(2, 'Tanpa Tenggat', 'Fleksibel', isDark, textPrimary, textSecondary),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Due mode description banner
                if (_dueModeIndex == 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.blueDarkBg : AppColors.blueLightBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jadwal Sesi Berikutnya',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.blueTextDark : AppColors.blueText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                nextSessionDue != null
                                    ? TimeService.formatNextSessionText(nextSessionDue)
                                    : 'Mata kuliah ini belum punya jadwal, jadi tenggat belum bisa dihitung.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (nextSessionDue != null)
                          Text(
                            '+${nextSessionDue.difference(widget.appState.liveNow).inDays} Hari',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.blueTextDark : AppColors.blueText,
                            ),
                          ),
                      ],
                    ),
                  )
                else if (_dueModeIndex == 1)
                  GestureDetector(
                    onTap: _pickCustomDateTime,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_month_outlined, size: 18, color: textPrimary),
                              const SizedBox(width: 8),
                              Text(
                                '${_customDate.day}/${_customDate.month}/${_customDate.year} • ${_customDate.hour.toString().padLeft(2, '0')}:${_customDate.minute.toString().padLeft(2, '0')} WITA',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                              ),
                            ],
                          ),
                          Text('Ubah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.blueAccent)),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 14),

                // Priority Selection
                Text('Prioritas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildPriorityButton(TaskPriority.low, 'Rendah', isDark, textPrimary, textSecondary),
                    const SizedBox(width: 8),
                    _buildPriorityButton(TaskPriority.medium, 'Sedang', isDark, textPrimary, textSecondary),
                    const SizedBox(width: 8),
                    _buildPriorityButton(TaskPriority.high, 'Tinggi', isDark, textPrimary, textSecondary),
                  ],
                ),

                const SizedBox(height: 14),

                // Local Reminder Toggle
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pengingat Lokal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
                          Text('Notifikasi 24j & 1j sebelum tenggat', style: TextStyle(fontSize: 11, color: textSecondary)),
                        ],
                      ),
                      CupertinoSwitch(
                        value: _reminderEnabled,
                        activeTrackColor: const Color(0xFF10B981),
                        onChanged: (val) => setState(() => _reminderEnabled = val),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Save Button
                GestureDetector(
                  onTap: _saveTask,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : const Color(0xFF090A0C),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, size: 18, color: isDark ? const Color(0xFF090A0C) : Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'Simpan Tugas',
                          style: TextStyle(
                            fontSize: 13,
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
        ),
      ),
    );
  }

  Widget _buildDueModeOption(
    int index,
    String title,
    String subtitle,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final isSelected = _dueModeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _dueModeIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? AppColors.darkSurface : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? textPrimary : textSecondary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.blueAccent : textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityButton(
    TaskPriority priority,
    String label,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final isSelected = _selectedPriority == priority;
    Color activeColor;
    switch (priority) {
      case TaskPriority.high:
        activeColor = const Color(0xFFF43F5E);
        break;
      case TaskPriority.medium:
        activeColor = const Color(0xFFD97706);
        break;
      case TaskPriority.low:
        activeColor = const Color(0xFF10B981);
        break;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPriority = priority),
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? activeColor.withValues(alpha: 0.2) : activeColor.withValues(alpha: 0.1))
                : (isDark ? AppColors.darkSurfaceStep : AppColors.lightSurfaceStep),
            borderRadius: BorderRadius.circular(10),
            border: isSelected ? Border.all(color: activeColor, width: 1.5) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? activeColor : textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
