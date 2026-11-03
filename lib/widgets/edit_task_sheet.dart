import 'package:flutter/material.dart';
import '../core/time/time_service.dart';
import '../models/course.dart';
import '../models/task.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'course_badge.dart';

class EditTaskSheet extends StatefulWidget {
  final AppState appState;
  final CourseTask task;

  const EditTaskSheet({
    super.key,
    required this.appState,
    required this.task,
  });

  static void show(BuildContext context, AppState appState, CourseTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditTaskSheet(appState: appState, task: task),
    );
  }

  @override
  State<EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends State<EditTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _notesController;

  Course? _selectedCourse;
  late int _dueModeIndex; // 0: Next Session, 1: Pilih Tanggal, 2: Tanpa Tenggat
  late TaskPriority _selectedPriority;
  late DateTime _customDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _notesController = TextEditingController(text: widget.task.notes);

    _selectedCourse = widget.appState.getCourse(widget.task.courseId);
    _selectedPriority = widget.task.priority;

    if (widget.task.dueMode == DueMode.nextSession) {
      _dueModeIndex = 0;
      _customDate = widget.task.dueAt ?? DateTime.now().add(const Duration(days: 2));
    } else if (widget.task.dueMode == DueMode.none) {
      _dueModeIndex = 2;
      _customDate = DateTime.now().add(const Duration(days: 2));
    } else {
      _dueModeIndex = 1;
      _customDate = widget.task.dueAt ?? DateTime.now().add(const Duration(days: 2));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _customDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
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
          _dueModeIndex = 1;
        });
      }
    }
  }

  void _saveChanges() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newTitle = _titleController.text.trim();
    final newNotes = _notesController.text.trim();
    final now = widget.appState.liveNow;

    TaskDueCategory dueCategory;
    DueMode dueMode;
    DateTime? dueAt;
    String dueText;
    String? secondaryMeta;

    if (_dueModeIndex == 0) {
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

    final updatedTask = widget.task.copyWith(
      title: newTitle,
      notes: newNotes,
      priority: _selectedPriority,
      dueCategory: dueCategory,
      dueMode: dueMode,
      dueAt: dueAt,
      dueText: dueText,
      secondaryMeta: secondaryMeta,
    );

    final messenger = ScaffoldMessenger.of(context);
    widget.appState.updateTask(updatedTask);

    Navigator.pop(context);

    messenger.showSnackBar(
      SnackBar(
        content: Text('Tugas "$newTitle" berhasil diperbarui!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF090A0C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final insetTone = isDark ? AppColors.darkSurfaceStep : AppColors.lightSurfaceStep;

    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF272A34) : const Color(0xFFE5E8EC),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Sheet Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CourseBadge(
                        code: widget.task.courseCode,
                        tone: _selectedCourse?.tone ?? CourseTone.zinc,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ubah Tugas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.3,
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

              // Field 1: Judul Tugas (Wajib diisi & Tolak Spasi Kosong)
              Text(
                'Judul Tugas / Catatan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Contoh: Makalah Sistem Basis Data',
                  filled: true,
                  fillColor: insetTone,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF1E2430) : const Color(0xFFE5E8EC),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF1E2430) : const Color(0xFFE5E8EC),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE11D48), width: 1.2),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Judul tugas wajib diisi dan tidak boleh hanya spasi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Field 2: Deskripsi / Catatan
              Text(
                'Deskripsi / Catatan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tambahkan instruksi dosen atau catatan pengerjaan...',
                  filled: true,
                  fillColor: insetTone,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF1E2430) : const Color(0xFFE5E8EC),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF1E2430) : const Color(0xFFE5E8EC),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Field 3: Pengaturan Tenggat Waktu
              Text(
                'Tenggat Waktu',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 6),

              // Opsi Mode Tenggat Waktu
              Row(
                children: [
                  _buildDueModeChip(
                    label: 'Next Session',
                    index: 0,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildDueModeChip(
                    label: 'Pilih Tanggal',
                    index: 1,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildDueModeChip(
                    label: 'Tanpa Tenggat',
                    index: 2,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Kotak Tampilan & Tombol Tanggal Kustom
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: insetTone,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E2430) : const Color(0xFFE5E8EC),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _dueModeIndex == 0
                            ? 'Otomatis dihitung ke sesi kuliah berikutnya'
                            : (_dueModeIndex == 1
                                ? '${_customDate.day}/${_customDate.month}/${_customDate.year} • ${_customDate.hour.toString().padLeft(2, '0')}:${_customDate.minute.toString().padLeft(2, '0')} WITA'
                                : 'Fleksibel (Tanpa batas waktu)'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    if (_dueModeIndex == 1)
                      TextButton(
                        onPressed: _pickCustomDateTime,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text(
                          'Pilih Jam/Tgl',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Prioritas Tugas
              Text(
                'Prioritas',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildPriorityChip(TaskPriority.low, 'Rendah', isDark),
                  const SizedBox(width: 8),
                  _buildPriorityChip(TaskPriority.medium, 'Sedang', isDark),
                  const SizedBox(width: 8),
                  _buildPriorityChip(TaskPriority.high, 'Tinggi', isDark),
                ],
              ),
              const SizedBox(height: 24),

              // Tombol Simpan Perubahan
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : const Color(0xFF090A0C),
                    foregroundColor: isDark ? const Color(0xFF090A0C) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Simpan Perubahan',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDueModeChip({
    required String label,
    required int index,
    required bool isDark,
  }) {
    final isSelected = _dueModeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _dueModeIndex = index;
          });
          if (index == 1) {
            _pickCustomDateTime();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF090A0C))
                : (isDark ? AppColors.darkSurfaceStep2 : AppColors.lightSurfaceStep2),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? (isDark ? const Color(0xFF090A0C) : Colors.white)
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(TaskPriority priority, String label, bool isDark) {
    final isSelected = _selectedPriority == priority;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPriority = priority),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isDark ? AppColors.darkSurfaceStep2 : AppColors.lightSurfaceStep2),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
