import 'package:flutter/material.dart';
import '../core/time/time_service.dart';
import '../models/course.dart';
import '../models/schedule_slot.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/course_badge.dart';

class ScheduleScreen extends StatefulWidget {
  final AppState appState;

  const ScheduleScreen({
    super.key,
    required this.appState,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedDay = 3; // 1 = Senin ... 7 = Minggu
  int _viewMode = 0; // 0: Hari Ini/Pilihan, 1: Pekan Ini

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.appState.liveNow.weekday;
  }

  void _showAddSlotDialog(BuildContext context) {
    if (widget.appState.courses.isEmpty) {
      widget.appState.showToast('Tambahkan mata kuliah terlebih dahulu di tab Matkul');
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    Course selectedCourse = widget.appState.courses.first;
    int day = _selectedDay;
    final startController = TextEditingController(text: '13:00');
    final endController = TextEditingController(text: '15:30');
    final roomController = TextEditingController(text: 'Lab 1');
    final dayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSlotState) {
            final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
            final inputBg = isDark ? AppColors.darkSurfaceStep : AppColors.lightSurfaceStep;

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
                    Text('Tambah Slot Jadwal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary)),
                    const SizedBox(height: 12),

                    Text('Mata Kuliah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(10)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCourse.id,
                          isExpanded: true,
                          dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          items: widget.appState.courses.map((c) {
                            return DropdownMenuItem(
                              value: c.id,
                              child: Text('${c.code} • ${c.name}', style: TextStyle(fontSize: 13, color: textPrimary)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setSlotState(() {
                                selectedCourse = widget.appState.courses.firstWhere((c) => c.id == val);
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text('Pilih Hari', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(7, (i) {
                          final d = i + 1;
                          final isSel = day == d;
                          return GestureDetector(
                            onTap: () => setSlotState(() => day = d),
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSel ? (isDark ? Colors.white : const Color(0xFF090A0C)) : inputBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                dayNames[i],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSel ? (isDark ? const Color(0xFF090A0C) : Colors.white) : textPrimary,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Jam Mulai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                              const SizedBox(height: 6),
                              Container(
                                decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(10)),
                                child: TextField(
                                  controller: startController,
                                  style: TextStyle(fontSize: 13, color: textPrimary),
                                  decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
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
                              Text('Jam Selesai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                              const SizedBox(height: 6),
                              Container(
                                decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(10)),
                                child: TextField(
                                  controller: endController,
                                  style: TextStyle(fontSize: 13, color: textPrimary),
                                  decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text('Ruangan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(10)),
                      child: TextField(
                        controller: roomController,
                        style: TextStyle(fontSize: 13, color: textPrimary),
                        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: () {
                        final slot = ScheduleSlot(
                          id: 'slot-${DateTime.now().millisecondsSinceEpoch}',
                          courseId: selectedCourse.id,
                          courseCode: selectedCourse.code,
                          courseName: selectedCourse.name,
                          day: day,
                          dayName: dayNames[day - 1],
                          startTime: startController.text.trim(),
                          endTime: endController.text.trim(),
                          room: roomController.text.trim(),
                          durationMinutes: 100,
                        );
                        widget.appState.addSlot(selectedCourse.id, slot);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : const Color(0xFF090A0C),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Simpan Slot',
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
          },
        );
      },
    );
  }

  void _showSlotDetailsModal(BuildContext context, ScheduleSlot slot, Course? course) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CourseBadge(code: slot.courseCode, tone: course?.tone ?? CourseTone.zinc),
                      const SizedBox(height: 4),
                      Text(slot.courseName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              Text('${slot.dayName} • ${slot.startTime} – ${slot.endTime} WITA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
              Text('Ruang: ${slot.room} • Dosen: ${course?.lecturer ?? "-"}', style: TextStyle(fontSize: 12, color: textSecondary)),
              const SizedBox(height: 24),

              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  widget.appState.deleteSlot(slot.courseId, slot.id);
                },
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.roseDarkBg : AppColors.roseLightBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Hapus Slot Jadwal',
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

    final now = widget.appState.liveNow;
    final dayNames = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

    // Get slots for the selected day
    final selectedDaySlots = <ScheduleSlot>[];
    for (final course in widget.appState.courses) {
      for (final slot in course.slots) {
        if (slot.day == _selectedDay) {
          selectedDaySlots.add(slot);
        }
      }
    }
    selectedDaySlots.sort((a, b) => a.startTime.compareTo(b.startTime));

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
                        'Jadwal Kuliah',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.appState.totalSlots} Slot Terjadwal • Zona WITA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _showAddSlotDialog(context),
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
                            'Tambah Slot',
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

            // 7-Day Calendar Strip
            Container(
              color: bgCard,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceStep : const Color(0xFFF4F5F7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildDayTab(day: 1, label: 'Sen', isToday: now.weekday == 1),
                    _buildDayTab(day: 2, label: 'Sel', isToday: now.weekday == 2),
                    _buildDayTab(day: 3, label: 'Rab', isToday: now.weekday == 3),
                    _buildDayTab(day: 4, label: 'Kam', isToday: now.weekday == 4),
                    _buildDayTab(day: 5, label: 'Jum', isToday: now.weekday == 5),
                    _buildDayTab(day: 6, label: 'Sab', isToday: now.weekday == 6),
                    _buildDayTab(day: 7, label: 'Min', isToday: now.weekday == 7),
                  ],
                ),
              ),
            ),

            // View Mode Segmented Tone Bar
            Container(
              color: bgCard,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceStep2 : AppColors.lightBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _viewMode = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _viewMode == 0 ? (isDark ? AppColors.darkSurface : Colors.white) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              dayNames[_selectedDay],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: _viewMode == 0 ? FontWeight.w700 : FontWeight.w500,
                                color: _viewMode == 0 ? textPrimary : textSecondary,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _viewMode = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _viewMode == 1 ? (isDark ? AppColors.darkSurface : Colors.white) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Pekan Ini',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: _viewMode == 1 ? FontWeight.w700 : FontWeight.w500,
                                color: _viewMode == 1 ? textPrimary : textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WITA',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Agenda Content Area
            Expanded(
              child: _viewMode == 0
                  ? _buildDayAgenda(selectedDaySlots, bgCard, insetTone, textPrimary, textSecondary, isDark)
                  : _buildWeekOverview(bgCard, insetTone, textPrimary, textSecondary, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayAgenda(
    List<ScheduleSlot> slots,
    Color bgCard,
    Color insetTone,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    if (slots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy, size: 48, color: textSecondary),
              const SizedBox(height: 12),
              Text('Tidak Ada Kuliah', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
              const SizedBox(height: 4),
              Text('Santai dulu, atau gunakan waktu untuk mencicil tugas.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: textSecondary)),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      children: slots.map((slot) {
        final course = widget.appState.getCourse(slot.courseId);
        final statusResult = TimeService.getClassStatus(widget.appState.liveNow, slot);

        return GestureDetector(
          onTap: () => _showSlotDetailsModal(context, slot, course),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 5,
                  height: 110,
                  decoration: BoxDecoration(
                    color: course?.accentColor ?? AppColors.amberAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CourseBadge(code: slot.courseCode, tone: course?.tone ?? CourseTone.zinc, isSolid: true),
                              const SizedBox(width: 8),
                              Text(
                                statusResult.statusLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: statusResult.status == ClassStatus.berlangsung
                                      ? AppColors.amberAccent
                                      : textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: insetTone, borderRadius: BorderRadius.circular(8)),
                            child: Text(slot.room, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textPrimary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(slot.courseName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
                      const SizedBox(height: 2),
                      Text('${course?.lecturer ?? "-"} • ${course?.sks ?? 0} SKS', style: TextStyle(fontSize: 11, color: textSecondary)),
                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(color: insetTone, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${slot.startTime} – ${slot.endTime} WITA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary)),
                            Text(statusResult.remainingText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary)),
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
      }).toList(),
    );
  }

  Widget _buildWeekOverview(
    Color bgCard,
    Color insetTone,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    final dayNames = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      children: List.generate(7, (i) {
        final d = i + 1;
        final daySlots = <ScheduleSlot>[];
        for (final c in widget.appState.courses) {
          for (final s in c.slots) {
            if (s.day == d) daySlots.add(s);
          }
        }
        daySlots.sort((a, b) => a.startTime.compareTo(b.startTime));

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dayNames[d], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary)),
                  Text('${daySlots.length} Sesi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary)),
                ],
              ),
              const SizedBox(height: 8),
              if (daySlots.isEmpty)
                Text('Tidak ada jadwal kuliah', style: TextStyle(fontSize: 11, color: textSecondary))
              else
                ...daySlots.map((s) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: insetTone, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${s.courseCode} (${s.startTime} – ${s.endTime})', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary)),
                        Text(s.room, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textPrimary)),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDayTab({
    required int day,
    required String label,
    bool isToday = false,
  }) {
    final isSelected = _selectedDay == day;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color textColor;

    if (isSelected) {
      bg = isDark ? Colors.white : const Color(0xFF090A0C);
      textColor = isDark ? const Color(0xFF090A0C) : Colors.white;
    } else {
      bg = Colors.transparent;
      textColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDay = day),
        child: Container(
          height: 48,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
              if (isToday)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isSelected ? (isDark ? Colors.black : Colors.white) : AppColors.amberAccent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
