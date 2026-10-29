import 'package:flutter_test/flutter_test.dart';
import 'package:notebook_um/core/time/time_service.dart';
import 'package:notebook_um/models/schedule_slot.dart';
import 'package:notebook_um/models/task.dart';
import 'package:notebook_um/state/app_state.dart';

void main() {
  group('TimeService - getClassStatus (PRD Section 1.7)', () {
    const slot = ScheduleSlot(
      id: 'slot-test-1',
      courseId: 'IF1203',
      courseCode: 'IF1203',
      courseName: 'Basis Data',
      day: 3, // Wednesday
      dayName: 'Rabu',
      startTime: '13:00',
      endTime: '15:30',
      room: 'Lab Basis Data',
      durationMinutes: 150,
    );

    test('sekarang < mulai -> akan_datang', () {
      // Wednesday at 12:45 (15 minutes before class)
      final now = DateTime(2026, 10, 28, 12, 45); // 2026-10-28 is Wednesday
      expect(now.weekday, 3);

      final result = TimeService.getClassStatus(now, slot);
      expect(result.status, ClassStatus.akanDatang);
      expect(result.progress, 0.0);
      expect(result.remainingText, contains('15 menit lagi'));
    });

    test('batas menit: persis jam mulai -> berlangsung', () {
      // Wednesday at exactly 13:00
      final now = DateTime(2026, 10, 28, 13, 0);
      final result = TimeService.getClassStatus(now, slot);
      expect(result.status, ClassStatus.berlangsung);
      expect(result.progress, 0.0);
    });

    test('mulai <= sekarang < selesai -> berlangsung with progress', () {
      // Wednesday at 14:15 (75 min of 150 min elapsed = 50%)
      final now = DateTime(2026, 10, 28, 14, 15);
      final result = TimeService.getClassStatus(now, slot);
      expect(result.status, ClassStatus.berlangsung);
      expect(result.progress, closeTo(0.5, 0.01));
      expect(result.remainingText, contains('50% Berjalan'));
      expect(result.remainingText, contains('Sisa 1j 15m'));
    });

    test('batas menit: persis jam selesai -> selesai', () {
      // Wednesday at exactly 15:30
      final now = DateTime(2026, 10, 28, 15, 30);
      final result = TimeService.getClassStatus(now, slot);
      expect(result.status, ClassStatus.selesai);
      expect(result.progress, 1.0);
    });

    test('sekarang >= selesai -> selesai', () {
      // Wednesday at 16:00
      final now = DateTime(2026, 10, 28, 16, 0);
      final result = TimeService.getClassStatus(now, slot);
      expect(result.status, ClassStatus.selesai);
    });

    test('hari berbeda -> tidakAktifHariIni', () {
      // Tuesday at 13:00
      final now = DateTime(2026, 10, 27, 13, 0); // Tuesday (weekday 2)
      final result = TimeService.getClassStatus(now, slot);
      expect(result.status, ClassStatus.tidakAktifHariIni);
    });
  });

  group('TimeService - calculateNextSession (PRD Section 1.7)', () {
    final List<ScheduleSlot> slots = [
      const ScheduleSlot(
        id: 'slot-mon',
        courseId: 'IF1101',
        courseCode: 'IF1101',
        courseName: 'Algoritma & Pemrograman',
        day: 1, // Monday
        dayName: 'Senin',
        startTime: '08:00',
        endTime: '10:30',
        room: 'Lab 2',
        durationMinutes: 150,
      ),
      const ScheduleSlot(
        id: 'slot-thu',
        courseId: 'IF1101',
        courseCode: 'IF1101',
        courseName: 'Algoritma & Pemrograman',
        day: 4, // Thursday
        dayName: 'Kamis',
        startTime: '13:00',
        endTime: '14:40',
        room: 'R.301',
        durationMinutes: 100,
      ),
    ];

    test('Tugas dibuat Rabu -> next session adalah Kamis 13:00', () {
      // Wednesday, 2026-10-28 at 14:00
      final createdAt = DateTime(2026, 10, 28, 14, 0);
      final nextSession = TimeService.calculateNextSession(
        createdAt: createdAt,
        slots: slots,
      );

      expect(nextSession, isNotNull);
      expect(nextSession!.weekday, 4); // Thursday
      expect(nextSession.hour, 13);
      expect(nextSession.minute, 0);
      expect(nextSession.day, 29);
    });

    test('Tugas dibuat Jumat -> next session adalah Senin depan 08:00', () {
      // Friday, 2026-10-30 at 16:00
      final createdAt = DateTime(2026, 10, 30, 16, 0);
      final nextSession = TimeService.calculateNextSession(
        createdAt: createdAt,
        slots: slots,
      );

      expect(nextSession, isNotNull);
      expect(nextSession!.weekday, 1); // Monday
      expect(nextSession.hour, 8);
      expect(nextSession.minute, 0);
      expect(nextSession.day, 2); // 2 November 2026
    });

    test('Mata kuliah tanpa jadwal -> return null (kriteria peringatan UI)', () {
      final createdAt = DateTime(2026, 10, 28, 14, 0);
      final nextSession = TimeService.calculateNextSession(
        createdAt: createdAt,
        slots: [],
      );

      expect(nextSession, isNull);
    });
  });

  group('TimeService - Live Clock & Formatting', () {
    test('formatLiveClock menghasilkan string format yang benar', () {
      final dt = DateTime(2026, 10, 28, 14, 15);
      final text = TimeService.formatLiveClock(dt);
      expect(text, 'Rabu, 28 Okt • 14:15 WITA');
    });

    test('getCountdownText menghitung sisa waktu dan keterlambatan', () {
      final now = DateTime(2026, 10, 28, 10, 0);
      final dueSoon = DateTime(2026, 10, 28, 12, 30);
      expect(TimeService.getCountdownText(now: now, dueAt: dueSoon, isCompleted: false), 'Sisa 2j 30m');

      final overdue = DateTime(2026, 10, 27, 10, 0);
      expect(TimeService.getCountdownText(now: now, dueAt: overdue, isCompleted: false), 'Terlambat 1 hari');

      expect(TimeService.getCountdownText(now: now, dueAt: overdue, isCompleted: true), 'Selesai');
    });
  });

  group('AppState - Real-time Schedule & Undo Toast Fixes', () {
    test('AppState awal tidak menampilkan undo toast', () {
      final state = AppState();
      expect(state.showUndoToast, isFalse);
      expect(state.undoCountdown, 5);
      state.dispose();
    });

    test('Toggle tugas mengaktifkan undo toast dengan countdown 5 detik', () {
      final state = AppState();
      expect(state.showUndoToast, isFalse);

      state.addTask(CourseTask(
        id: 'task-test-toggle',
        title: 'Tugas Uji Coba',
        courseCode: '111500',
        courseName: 'Sistem Manajemen Basis Data',
        priority: TaskPriority.high,
        dueCategory: TaskDueCategory.urgent,
        dueText: 'Besok',
      ));

      final taskId = state.tasks.first.id;
      final initialStatus = state.tasks.first.isCompleted;

      state.toggleTaskCompletion(taskId);
      expect(state.showUndoToast, isTrue);
      expect(state.undoToastMessage, contains('1 tugas ditandai selesai'));
      expect(state.undoCountdown, 5);
      expect(state.tasks.first.isCompleted, !initialStatus);

      // Urungkan aksi
      state.undoLastAction();
      expect(state.showUndoToast, isFalse);
      expect(state.tasks.first.isCompleted, initialStatus);
      state.dispose();
    });

    test('TimeService.nowInWita dan timeToDateTime sinkron tanpa selisih UTC', () {
      // Slot Kamis 09:00 - 10:40
      const slot = ScheduleSlot(
        id: 'slot-kamis',
        courseId: 'UM1101',
        courseCode: 'UM1101',
        courseName: 'Bahasa Inggris Teknik',
        day: 4, // Kamis
        dayName: 'Kamis',
        startTime: '09:00',
        endTime: '10:40',
        room: 'R.101',
        durationMinutes: 100,
      );

      // Simulasi waktu Kamis jam 09:15 WITA (sedang berlangsung)
      final nowDuringClass = DateTime(2026, 10, 29, 9, 15);
      final statusResult = TimeService.getClassStatus(nowDuringClass, slot);
      expect(statusResult.status, ClassStatus.berlangsung);
      expect(statusResult.statusLabel, 'Kuliah Sedang Berlangsung');
      expect(statusResult.progress, closeTo(0.15, 0.01));

      // Simulasi sebelum kelas jam 08:30 WITA (akan datang)
      final nowBeforeClass = DateTime(2026, 10, 29, 8, 30);
      final statusBefore = TimeService.getClassStatus(nowBeforeClass, slot);
      expect(statusBefore.status, ClassStatus.akanDatang);
      expect(statusBefore.statusLabel, 'Akan Datang');

      // Simulasi setelah kelas jam 11:00 WITA (selesai)
      final nowAfterClass = DateTime(2026, 10, 29, 11, 0);
      final statusAfter = TimeService.getClassStatus(nowAfterClass, slot);
      expect(statusAfter.status, ClassStatus.selesai);
      expect(statusAfter.statusLabel, 'Selesai');
    });
  });
}
