import 'package:flutter/material.dart';
import '../core/time/time_service.dart';
import '../models/course.dart';
import '../models/schedule_slot.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'course_badge.dart';

class SlotFormSheet extends StatefulWidget {
  final AppState appState;
  final Course? course;
  final ScheduleSlot? slotToEdit;
  final int? defaultDay;

  const SlotFormSheet({
    super.key,
    required this.appState,
    this.course,
    this.slotToEdit,
    this.defaultDay,
  });

  static Future<void> show(
    BuildContext context, {
    required AppState appState,
    Course? course,
    ScheduleSlot? slotToEdit,
    int? defaultDay,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SlotFormSheet(
        appState: appState,
        course: course,
        slotToEdit: slotToEdit,
        defaultDay: defaultDay,
      ),
    );
  }

  @override
  State<SlotFormSheet> createState() => _SlotFormSheetState();
}

class _SlotFormSheetState extends State<SlotFormSheet> {
  static const List<String> _dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  late Course? _selectedCourse;
  late int _selectedDay;
  late String _startTime;
  late String _endTime;
  late TextEditingController _roomController;

  @override
  void initState() {
    super.initState();
    final slot = widget.slotToEdit;

    if (slot != null) {
      _selectedCourse = widget.course ?? widget.appState.getCourse(slot.courseId);
      _selectedDay = slot.day;
      _startTime = slot.startTime;
      _endTime = slot.endTime;
      _roomController = TextEditingController(text: slot.room);
    } else {
      _selectedCourse = widget.course ?? (widget.appState.courses.isNotEmpty ? widget.appState.courses.first : null);
      _selectedDay = widget.defaultDay ?? widget.appState.liveNow.weekday;
      _startTime = '13:00';
      _endTime = '15:30';
      _roomController = TextEditingController(text: 'Lab 1');
    }
  }

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final currentTime = isStart ? _startTime : _endTime;
    final currentMin = TimeService.timeToMinutes(currentTime);
    final initialHour = currentMin >= 1440 ? 23 : (currentMin ~/ 60).clamp(0, 23);
    final initialMinute = currentMin >= 1440 ? 59 : currentMin % 60;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      helpText: isStart ? 'PILIH JAM MULAI' : 'PILIH JAM SELESAI (MAKS 24:00)',
      cancelText: 'BATAL',
      confirmText: 'PILIH',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      final formatted = '$h:$m';

      setState(() {
        if (isStart) {
          _startTime = formatted;
        } else {
          // Jika memilih 00:00 untuk jam selesai dan jam mulai > 00:00,
          // user memaksudkan akhir hari (jam 24:00)
          if (formatted == '00:00' && TimeService.timeToMinutes(_startTime) > 0) {
            _endTime = '24:00';
          } else {
            _endTime = formatted;
          }
        }
      });
    }
  }

  void _showCollisionDialog(ScheduleSlot collision) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF271B1E) : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Jadwal Tabrakan!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Input jadwal tidak dapat dilakukan karena jam yang dipilih bertabrakan dengan jadwal kuliah lain:',
              style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceStep : AppColors.lightSurfaceStep,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collision.courseName,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${collision.dayName} • ${collision.startTime} – ${collision.endTime} WITA',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE11D48)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ruang: ${collision.room}',
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Silakan sesuaikan jam mulai atau jam selesai agar tidak saling beririsan.',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Tutup & Perbaiki Jam',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF090A0C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveSlot() {
    if (_selectedCourse == null) {
      widget.appState.showToast('Pilih mata kuliah terlebih dahulu');
      return;
    }

    final start = _startTime.trim();
    final end = _endTime.trim();
    final room = _roomController.text.trim();

    if (room.isEmpty) {
      widget.appState.showToast('Ruangan kuliah harus diisi');
      return;
    }

    final startMin = TimeService.timeToMinutes(start);
    final endMin = TimeService.timeToMinutes(end);

    // 1. Validasi batas maksimal 24:00 (1440 menit)
    if (endMin > 1440) {
      widget.appState.showToast('Batas waktu slot maksimal adalah jam 24:00');
      return;
    }

    // 2. Validasi jam mulai < jam selesai
    if (startMin >= endMin) {
      widget.appState.showToast('Jam mulai harus lebih awal dari jam selesai (Maks 24:00)');
      return;
    }

    // 3. Validasi tabrakan jadwal (Collision Check)
    final collision = widget.appState.checkSlotCollision(
      day: _selectedDay,
      startTime: start,
      endTime: end,
      excludeSlotId: widget.slotToEdit?.id,
    );

    if (collision != null) {
      _showCollisionDialog(collision);
      return;
    }

    // 4. Simpan / Perbarui
    final duration = endMin - startMin;
    final dayName = _dayNames[_selectedDay - 1];

    if (widget.slotToEdit != null) {
      final updated = widget.slotToEdit!.copyWith(
        courseId: _selectedCourse!.id,
        courseCode: _selectedCourse!.code,
        courseName: _selectedCourse!.name,
        day: _selectedDay,
        dayName: dayName,
        startTime: start,
        endTime: end,
        room: room,
        durationMinutes: duration,
      );
      widget.appState.updateSlot(_selectedCourse!.id, updated);
      Navigator.pop(context);
      widget.appState.showToast('Slot jadwal "${_selectedCourse!.name}" berhasil diperbarui');
    } else {
      final newSlot = ScheduleSlot(
        id: 'slot-${DateTime.now().millisecondsSinceEpoch}',
        courseId: _selectedCourse!.id,
        courseCode: _selectedCourse!.code,
        courseName: _selectedCourse!.name,
        day: _selectedDay,
        dayName: dayName,
        startTime: start,
        endTime: end,
        room: room,
        durationMinutes: duration,
      );
      widget.appState.addSlot(_selectedCourse!.id, newSlot);
      Navigator.pop(context);
      widget.appState.showToast('Slot jadwal "${_selectedCourse!.name}" berhasil ditambahkan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final inputBg = isDark ? AppColors.darkSurfaceStep : AppColors.lightSurfaceStep;

    final isEditing = widget.slotToEdit != null;
    final title = isEditing ? 'Edit Slot Jadwal' : 'Tambah Slot Jadwal';

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tentukan hari, rentang jam pertemuan, dan ruangan kuliah',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
            const SizedBox(height: 16),

            // Pilih Mata Kuliah
            Text('Mata Kuliah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
            const SizedBox(height: 6),
            if (widget.course != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  children: [
                    CourseBadge(code: widget.course!.code, tone: widget.course!.tone),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.course!.name,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCourse?.id,
                    isExpanded: true,
                    dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    items: widget.appState.courses.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text(
                          '${c.code} • ${c.name}',
                          style: TextStyle(fontSize: 13, color: textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCourse = widget.appState.courses.firstWhere((c) => c.id == val);
                        });
                      }
                    },
                  ),
                ),
              ),
            const SizedBox(height: 14),

            // Pilih Hari
            Text('Pilih Hari', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(7, (i) {
                  final d = i + 1;
                  final isSel = _selectedDay == d;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = d),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? (isDark ? Colors.white : const Color(0xFF090A0C)) : inputBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _dayNames[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSel ? (isDark ? const Color(0xFF090A0C) : Colors.white) : textPrimary,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 14),

            // Jam Mulai & Jam Selesai (Interaktif Tap Bukan Ketik)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Jam Mulai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _pickTime(isStart: true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _startTime,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              Icon(Icons.access_time_rounded, size: 16, color: textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Jam Selesai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                          GestureDetector(
                            onTap: () {
                              setState(() => _endTime = '24:00');
                            },
                            child: Text(
                              'Set 24:00',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _pickTime(isStart: false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _endTime,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              Icon(Icons.access_time_rounded, size: 16, color: textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Maksimal batas waktu slot jam 24:00',
                style: TextStyle(fontSize: 10.5, color: textSecondary),
              ),
            ),
            const SizedBox(height: 12),

            // Ruang Kuliah
            Text('Ruang Kuliah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB),
                ),
              ),
              child: TextField(
                controller: _roomController,
                style: TextStyle(fontSize: 13, color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Contoh: Lab 1, R.302, Daring',
                  hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Tombol Simpan / Perbarui
            GestureDetector(
              onTap: _saveSlot,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : const Color(0xFF090A0C),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  isEditing ? 'Perbarui Slot Jadwal' : 'Simpan Slot Jadwal',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF090A0C) : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
