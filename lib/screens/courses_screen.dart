import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/schedule_slot.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/course_badge.dart';

class CoursesScreen extends StatelessWidget {
  final AppState appState;

  const CoursesScreen({
    super.key,
    required this.appState,
  });

  void _showAddCourseSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final lecturerController = TextEditingController();
    int sks = 3;
    CourseTone selectedTone = CourseTone.blue;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
            final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
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
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E8EC),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tambah Mata Kuliah',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Isi data mata kuliah untuk jadwal dan tugas terhubung',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    const SizedBox(height: 16),

                    // Kode Mata Kuliah (Paling atas)
                    Text('Kode Mata Kuliah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(12)),
                      child: TextField(
                        controller: codeController,
                        style: TextStyle(fontSize: 13, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Contoh: 111500 atau IF1101',
                          hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Nama Matkul
                    Text('Nama Mata Kuliah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(12)),
                      child: TextField(
                        controller: nameController,
                        style: TextStyle(fontSize: 13, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Contoh: Basis Data Lanjut',
                          hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Dosen Pengampu
                    Text('Dosen Pengampu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(12)),
                      child: TextField(
                        controller: lecturerController,
                        style: TextStyle(fontSize: 13, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Contoh: Dr. Budi Santoso, M.Kom.',
                          hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // SKS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Beban SKS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                        Row(
                          children: [1, 2, 3, 4, 6].map((val) {
                            final isSel = sks == val;
                            return GestureDetector(
                              onTap: () => setSheetState(() => sks = val),
                              child: Container(
                                margin: const EdgeInsets.only(left: 6),
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isSel ? (isDark ? Colors.white : const Color(0xFF090A0C)) : inputBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$val',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSel ? (isDark ? const Color(0xFF090A0C) : Colors.white) : textPrimary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Warna / Tone
                    Text('Identitas Warna', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                    const SizedBox(height: 8),
                    Row(
                      children: CourseTone.values.map((tone) {
                        final isSel = selectedTone == tone;
                        Color c;
                        switch (tone) {
                          case CourseTone.amber:
                            c = AppColors.amberAccent;
                            break;
                          case CourseTone.blue:
                            c = AppColors.blueAccent;
                            break;
                          case CourseTone.emerald:
                            c = AppColors.emeraldAccent;
                            break;
                          case CourseTone.purple:
                            c = AppColors.purpleAccent;
                            break;
                          case CourseTone.zinc:
                            c = const Color(0xFF52525B);
                            break;
                        }
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedTone = tone),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: isSel ? Border.all(color: textPrimary, width: 2.5) : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    GestureDetector(
                      onTap: () {
                        final code = codeController.text.trim();
                        final name = nameController.text.trim();
                        final lecturer = lecturerController.text.trim();

                        if (name.isEmpty) return;

                        final courseCode = code.isNotEmpty ? code : 'MK';

                        final newCourse = Course(
                          id: 'course-${DateTime.now().millisecondsSinceEpoch}',
                          code: courseCode,
                          name: name,
                          lecturer: lecturer.isEmpty ? 'Dosen Belum Ditentukan' : lecturer,
                          sks: sks,
                          tone: selectedTone,
                          slots: const [],
                        );

                        appState.addCourse(newCourse);
                        Navigator.pop(ctx);
                        appState.showToast('Mata kuliah $name ($courseCode) berhasil ditambahkan');
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : const Color(0xFF090A0C),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Simpan Mata Kuliah',
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

  void _showManageCourseSheet(BuildContext context, Course course) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
        final insetTone = isDark ? AppColors.darkSurfaceStep : AppColors.lightSurfaceStep;

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
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E8EC),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CourseBadge(code: '${course.code} • ${course.sks} SKS', tone: course.tone),
                      const SizedBox(height: 4),
                      Text(
                        course.name,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Dosen: ${course.lecturer}',
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
              const SizedBox(height: 16),

              Text('Jadwal Pertemuan (${course.slots.length} Sesi)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary)),
              const SizedBox(height: 8),

              if (course.slots.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: insetTone, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    'Mata kuliah ini belum punya jadwal, jadi tenggat belum bisa dihitung.',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                )
              else
                ...course.slots.map((slot) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: insetTone, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${slot.dayName}, ${slot.startTime} – ${slot.endTime}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                        Text(
                          slot.room,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 16),

              // Add slot button
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddSlotSheet(context, course);
                },
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: insetTone,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 16, color: textPrimary),
                      const SizedBox(width: 6),
                      Text('Tambah Slot Jadwal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Delete course button (PRD Section 4.3)
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteCourse(context, course);
                },
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.roseDarkBg : AppColors.roseLightBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Hapus Mata Kuliah',
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

  void _showAddSlotSheet(BuildContext context, Course course) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int selectedDay = 1; // 1 = Senin
    final startController = TextEditingController(text: '08:00');
    final endController = TextEditingController(text: '10:30');
    final roomController = TextEditingController(text: 'Lab 1');

    final dayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Tambah Slot Jadwal: ${course.code}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary)),
                  const SizedBox(height: 14),

                  Text('Pilih Hari', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(7, (i) {
                        final d = i + 1;
                        final isSel = selectedDay == d;
                        return GestureDetector(
                          onTap: () => setSlotState(() => selectedDay = d),
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

                  Text('Ruang Kuliah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
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
                      final newSlot = ScheduleSlot(
                        id: 'slot-${DateTime.now().millisecondsSinceEpoch}',
                        courseId: course.id,
                        courseCode: course.code,
                        courseName: course.name,
                        day: selectedDay,
                        dayName: dayNames[selectedDay - 1],
                        startTime: startController.text.trim(),
                        endTime: endController.text.trim(),
                        room: roomController.text.trim(),
                        durationMinutes: 100,
                      );
                      appState.addSlot(course.id, newSlot);
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
                        'Simpan Jadwal',
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
            );
          },
        );
      },
    );
  }

  void _confirmDeleteCourse(BuildContext context, Course course) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Mata Kuliah?'),
        content: Text('Mata kuliah "${course.name}" (${course.code}) akan dihapus. Tugas yang terhubung akan dialihkan ke kategori Mandiri.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              appState.deleteCourse(course.id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgCard = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final insetTone = isDark ? AppColors.darkSurfaceStep : AppColors.lightSurfaceStep;

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
                        'Mata Kuliah',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${appState.totalCourses} Terdaftar • ${appState.totalSks} SKS Total',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _showAddCourseSheet(context),
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
                          Icon(
                            Icons.add,
                            size: 16,
                            color: isDark ? const Color(0xFF090A0C) : Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tambah Matkul',
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

            // Main Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                children: [
                  // Academic Study Load Summary
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
                            Text(
                              'Ringkasan Beban Studi',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              '${appState.totalCourses} / 30 Matkul Terisi',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Visual progress bar
                        Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: insetTone,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (appState.totalSks / 24).clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.blueAccent,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Beban Semester Ini',
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                            Text(
                              '${appState.totalSks} dari Max 24 SKS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Course Cards
                  if (appState.courses.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        children: [
                          Icon(Icons.school_outlined, size: 48, color: textSecondary),
                          const SizedBox(height: 12),
                          Text('Belum Ada Mata Kuliah', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
                          const SizedBox(height: 4),
                          Text('Tekan Tambah Matkul untuk mengisi jadwal dan tugas.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: textSecondary)),
                        ],
                      ),
                    )
                  else
                    ...appState.courses.map((course) {
                      return _buildCourseCard(
                        context: context,
                        course: course,
                        isDark: isDark,
                        bgCard: bgCard,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        insetTone: insetTone,
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard({
    required BuildContext context,
    required Course course,
    required bool isDark,
    required Color bgCard,
    required Color textPrimary,
    required Color textSecondary,
    required Color insetTone,
  }) {
    Color slotBadgeBg;
    Color slotBadgeText;

    switch (course.tone) {
      case CourseTone.blue:
        slotBadgeBg = isDark ? AppColors.blueDarkBg : AppColors.blueLightBg;
        slotBadgeText = isDark ? AppColors.blueTextDark : AppColors.blueText;
        break;
      case CourseTone.emerald:
        slotBadgeBg = isDark ? AppColors.emeraldDarkBg : AppColors.emeraldLightBg;
        slotBadgeText = isDark ? AppColors.emeraldTextDark : AppColors.emeraldText;
        break;
      case CourseTone.amber:
        slotBadgeBg = isDark ? AppColors.amberDarkBg : AppColors.amberLightBg;
        slotBadgeText = isDark ? AppColors.amberTextDark : AppColors.amberText;
        break;
      case CourseTone.purple:
        slotBadgeBg = isDark ? AppColors.purpleDarkBg : AppColors.purpleLightBg;
        slotBadgeText = isDark ? AppColors.purpleTextDark : AppColors.purpleText;
        break;
      default:
        slotBadgeBg = insetTone;
        slotBadgeText = textPrimary;
    }

    final activeTasks = appState.tasks.where((t) => t.courseId == course.id && !t.isCompleted).length;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CourseBadge(code: '${course.code} • ${course.sks} SKS', tone: course.tone),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    course.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    course.lecturer,
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: slotBadgeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${course.slots.length} Slot',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: slotBadgeText,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Slots details
          ...course.slots.map((slot) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: insetTone,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${slot.dayName}: ${slot.startTime} – ${slot.endTime} WITA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    slot.room,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 6),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$activeTasks tugas aktif',
                style: TextStyle(fontSize: 11, color: textSecondary),
              ),
              GestureDetector(
                onTap: () => _showManageCourseSheet(context, course),
                child: Text(
                  'Kelola Matkul →',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: slotBadgeText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
