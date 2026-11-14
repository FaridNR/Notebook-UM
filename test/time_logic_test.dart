import 'package:flutter_test/flutter_test.dart';
import 'package:notebook_um/core/database/database_helper.dart';
import 'package:notebook_um/core/time/time_service.dart';
import 'package:notebook_um/models/schedule_slot.dart';
import 'package:notebook_um/models/task.dart';
import 'package:notebook_um/state/app_state.dart';

void main() {
  setUpAll(() {
    DatabaseHelper.setupDatabaseFactory(noIsolate: true);
  });
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

    test('TimeService timeToMinutes dan isValidTimeSlot hingga 24:00', () {
      expect(TimeService.timeToMinutes('00:00'), 0);
      expect(TimeService.timeToMinutes('08:30'), 510);
      expect(TimeService.timeToMinutes('19:00'), 1140);
      expect(TimeService.timeToMinutes('24:00'), 1440);

      // Valid
      expect(TimeService.isValidTimeSlot('08:00', '10:00'), isTrue);
      expect(TimeService.isValidTimeSlot('19:00', '24:00'), isTrue);

      // Invalid: start >= end
      expect(TimeService.isValidTimeSlot('10:00', '08:00'), isFalse);
      expect(TimeService.isValidTimeSlot('10:00', '10:00'), isFalse);

      // Invalid: exceeds 24:00 (1440)
      expect(TimeService.isValidTimeSlot('22:00', '24:30'), isFalse);
    });

    test('TimeService findSlotCollision mendeteksi tabrakan jadwal dengan tepat', () {
      const existingSlot = ScheduleSlot(
        id: 'slot-1',
        courseId: 'C1',
        courseCode: '111500',
        courseName: 'Basis Data',
        day: 1, // Senin
        dayName: 'Senin',
        startTime: '19:00',
        endTime: '20:30',
        room: 'Lab B',
        durationMinutes: 90,
      );

      final list = [existingSlot];

      // Tabrakan persis sama di hari yang sama
      final c1 = TimeService.findSlotCollision(
        day: 1,
        startTime: '19:00',
        endTime: '20:30',
        existingSlots: list,
      );
      expect(c1, isNotNull);
      expect(c1?.id, 'slot-1');

      // Tabrakan beririsan di tengah (19:30 - 21:00)
      final c2 = TimeService.findSlotCollision(
        day: 1,
        startTime: '19:30',
        endTime: '21:00',
        existingSlots: list,
      );
      expect(c2, isNotNull);

      // Tabrakan mencakup seluruhnya (18:00 - 21:00)
      final c3 = TimeService.findSlotCollision(
        day: 1,
        startTime: '18:00',
        endTime: '21:00',
        existingSlots: list,
      );
      expect(c3, isNotNull);

      // Tidak tabrakan: setelah slot (20:30 - 22:00)
      final c4 = TimeService.findSlotCollision(
        day: 1,
        startTime: '20:30',
        endTime: '22:00',
        existingSlots: list,
      );
      expect(c4, isNull);

      // Tidak tabrakan: sebelum slot (17:00 - 19:00)
      final c5 = TimeService.findSlotCollision(
        day: 1,
        startTime: '17:00',
        endTime: '19:00',
        existingSlots: list,
      );
      expect(c5, isNull);

      // Tidak tabrakan: hari berbeda (Selasa)
      final c6 = TimeService.findSlotCollision(
        day: 2,
        startTime: '19:00',
        endTime: '20:30',
        existingSlots: list,
      );
      expect(c6, isNull);

      // Edit slot sendiri: dikecualikan id-nya sehingga tidak dianggap tabrakan
      final c7 = TimeService.findSlotCollision(
        day: 1,
        startTime: '19:00',
        endTime: '20:30',
        existingSlots: list,
        excludeSlotId: 'slot-1',
      );
      expect(c7, isNull);
    });

    test('TimeService sinkronisasi zona waktu aktif (WIB, WITA, WIT)', () {
      expect(TimeService.getTimezoneOffsetHours('Asia/Jakarta'), 7);
      expect(TimeService.getTimezoneOffsetHours('Asia/Makassar'), 8);
      expect(TimeService.getTimezoneOffsetHours('Asia/Jayapura'), 9);

      expect(TimeService.getTimezoneAbbr('Asia/Jakarta'), 'WIB');
      expect(TimeService.getTimezoneAbbr('Asia/Makassar'), 'WITA');
      expect(TimeService.getTimezoneAbbr('Asia/Jayapura'), 'WIT');

      final utcFixed = DateTime.utc(2026, 11, 14, 10, 0); // 10:00 UTC
      final wib = TimeService.nowInTimezone('Asia/Jakarta', utcFixed);
      final wita = TimeService.nowInTimezone('Asia/Makassar', utcFixed);
      final wit = TimeService.nowInTimezone('Asia/Jayapura', utcFixed);

      expect(wib.hour, 17); // 10 + 7
      expect(wita.hour, 18); // 10 + 8
      expect(wit.hour, 19); // 10 + 9

      expect(TimeService.formatLiveClock(wib, 'WIB'), contains('17:00 WIB'));
      expect(TimeService.formatLiveClock(wita, 'WITA'), contains('18:00 WITA'));
      expect(TimeService.formatLiveClock(wit, 'WIT'), contains('19:00 WIT'));
    });

    test('AppState ganti zona waktu memperbarui timezoneAbbr dan format display', () async {
      final appState = AppState();
      await appState.loadDbFuture;

      appState.updateProfile(timezone: 'Asia/Jakarta');
      expect(appState.timezone, 'Asia/Jakarta');
      expect(appState.timezoneAbbr, 'WIB');

      appState.updateProfile(timezone: 'Asia/Jayapura');
      expect(appState.timezone, 'Asia/Jayapura');
      expect(appState.timezoneAbbr, 'WIT');

      appState.updateProfile(timezone: 'Asia/Makassar');
      expect(appState.timezone, 'Asia/Makassar');
      expect(appState.timezoneAbbr, 'WITA');

      appState.dispose();
    });
  });
}
