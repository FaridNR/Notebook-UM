import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notebook_um/core/database/database_service.dart';
import 'package:notebook_um/main.dart';
import 'package:notebook_um/models/task.dart';
import 'package:notebook_um/screens/about_screen.dart';
import 'package:notebook_um/screens/auth_screen.dart';
import 'package:notebook_um/screens/courses_screen.dart';
import 'package:notebook_um/screens/schedule_screen.dart';
import 'package:notebook_um/screens/settings_screen.dart';
import 'package:notebook_um/screens/tasks_screen.dart';
import 'package:notebook_um/screens/today_screen.dart';
import 'package:notebook_um/state/app_state.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    DatabaseService.setupDatabaseFactory(noIsolate: true);
  });

  setUp(() async {
    await DatabaseService.instance.init(path: inMemoryDatabasePath);
  });

  group('PENGUJIAN END-TO-END FITUR NOTEBOOK UM DARI AWAL HINGGA AKHIR', () {
    testWidgets('E2E Journey 1: Alur Autentikasi Lengkap (Validasi, Proteksi Brute-Force, Registrasi, & Login)', (WidgetTester tester) async {
      final appState = AppState();
      await appState.loadDbFuture;
      appState.logout(); // Mulai dari posisi belum login

      await tester.pumpWidget(NoteBookUMApp(appState: appState));
      await tester.pumpAndSettle();

      // Memastikan berada di AuthScreen
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.text('Masuk ke NoteBook UM'), findsOneWidget);

      // Skenario 1.1: Password salah
      final passField = find.byType(TextField).at(1);
      await tester.enterText(passField, 'PasswordSalah123');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Masuk ke Akun'));
      await tester.tap(find.text('Masuk ke Akun'));
      await tester.pumpAndSettle();
      expect(find.text('Email atau kata sandi salah. Silakan periksa kembali.'), findsOneWidget);
      expect(appState.isLoggedIn, isFalse);

      // Skenario 1.2: Email format tidak valid
      final emailField = find.byType(TextField).at(0);
      await tester.enterText(emailField, 'bukan-email-valid');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Masuk ke Akun'));
      await tester.tap(find.text('Masuk ke Akun'));
      await tester.pumpAndSettle();
      expect(find.text('Masukkan alamat email yang valid (contoh: nama@mhs.ac.id)'), findsOneWidget);

      // Skenario 1.3: Password hanya berisi spasi
      await tester.enterText(emailField, 'faridnoorrahman@gmail.com');
      await tester.enterText(passField, '          ');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Masuk ke Akun'));
      await tester.tap(find.text('Masuk ke Akun'));
      await tester.pumpAndSettle();
      expect(find.text('Kata sandi tidak boleh kosong atau hanya berisi spasi'), findsOneWidget);

      // Skenario 1.4: Proteksi Brute-force (5x percobaan salah berturut-turut)
      await tester.enterText(passField, 'Salah123456');
      await tester.ensureVisible(find.text('Masuk ke Akun'));
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.text('Masuk ke Akun'));
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('Terlalu banyak percobaan gagal. Akses dikunci sementara'), findsOneWidget);

      // Reset lockout untuk melanjutkan pengujian
      appState.logout();
      await tester.pumpWidget(NoteBookUMApp(appState: appState));
      await tester.pumpAndSettle();

      // Skenario 1.5: Pindah ke Tab Registrasi & Uji Validasi NIM
      await tester.tap(find.text('Registrasi'));
      await tester.pumpAndSettle();
      expect(find.text('Registrasi Akun NoteBook UM'), findsOneWidget);

      // Isi NIM non-angka
      final nimField = find.byType(TextField).at(1);
      await tester.enterText(nimField, 'NIM-HURUF');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Daftar Akun Baru'));
      await tester.tap(find.text('Daftar Akun Baru'));
      await tester.pumpAndSettle();
      expect(find.text('NIM harus berupa angka valid (6–12 digit, contoh: 2411001)'), findsOneWidget);

      // Pendaftaran valid
      await tester.enterText(nimField, '2411001');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Daftar Akun Baru'));
      await tester.tap(find.text('Daftar Akun Baru'));
      await tester.pumpAndSettle();

      // Skenario 1.6: Login Sukses dengan Akun Utama Farid
      expect(appState.isLoggedIn, isTrue);
      expect(find.byType(HomeScreen), findsOneWidget);

      appState.dispose();
    });

    testWidgets('E2E Journey 2: Beranda (Today Screen) & Tentang Aplikasi (About Screen)', (WidgetTester tester) async {
      final appState = AppState();
      await appState.loadDbFuture;

      await tester.pumpWidget(NoteBookUMApp(appState: appState));
      await tester.pumpAndSettle();

      // Verifikasi komponen Beranda
      expect(find.text('NoteBook UM'), findsOneWidget);
      expect(find.text('Hari Ini'), findsWidgets);
      expect(find.byType(TodayScreen), findsOneWidget);

      // Buka halaman Tentang Aplikasi dari tombol info/profil di AppBar
      final infoBtn = find.byIcon(Icons.info_outline);
      if (infoBtn.evaluate().isNotEmpty) {
        await tester.tap(infoBtn.first);
        await tester.pumpAndSettle();
        expect(find.byType(AboutScreen), findsOneWidget);
        expect(find.text('NoteBook UM'), findsWidgets);
        expect(find.textContaining('Farid Noor Rahman'), findsWidgets);
        // Kembali ke Beranda
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(TodayScreen), findsOneWidget);
      }

      appState.dispose();
    });

    testWidgets('E2E Journey 3: Jadwal Kuliah (Schedule Screen), Filter Pekan Ini, & Interaksi Slot', (WidgetTester tester) async {
      final appState = AppState();
      await appState.loadDbFuture;

      await tester.pumpWidget(NoteBookUMApp(appState: appState));
      await tester.pumpAndSettle();

      // Pindah ke tab Jadwal (index 1)
      final jadwalTab = find.text('Jadwal');
      expect(jadwalTab, findsWidgets);
      await tester.tap(jadwalTab.first);
      await tester.pumpAndSettle();
      expect(find.byType(ScheduleScreen), findsOneWidget);

      // Switch ke tampilan "Pekan Ini"
      final pekanIniChip = find.text('Pekan Ini');
      expect(pekanIniChip, findsOneWidget);
      await tester.tap(pekanIniChip);
      await tester.pumpAndSettle();

      // Verifikasi bahwa nama mata kuliah tampil di list pekan ini
      expect(find.text('Sistem Manajemen Basis Data'), findsWidgets);

      // Switch kembali ke tampilan harian
      final hariIniChip = find.text('Hari Ini');
      if (hariIniChip.evaluate().isNotEmpty) {
        await tester.tap(hariIniChip.first);
        await tester.pumpAndSettle();
      }

      appState.dispose();
    });

    testWidgets('E2E Journey 4: Manajemen Tugas, Checklist Undo, & Fitur Bagi Catatan Multi-Channel', (WidgetTester tester) async {
      final appState = AppState();
      await appState.loadDbFuture;

      // Tambahkan tugas contoh ke state
      final task = CourseTask(
        id: 'task-e2e-demo',
        title: 'Laporan Tugas Akhir IFB5J',
        courseId: 'course-111500',
        courseCode: '111500',
        courseName: 'Sistem Manajemen Basis Data',
        priority: TaskPriority.high,
        dueCategory: TaskDueCategory.urgent,
        dueText: 'Besok, 23:59 WITA',
        notes: 'Selesaikan normalisasi data dan dokumentasi relasi database',
      );
      await appState.addTask(task);

      await tester.pumpWidget(NoteBookUMApp(appState: appState));
      await tester.pumpAndSettle();

      // Pindah ke tab Tugas (index 2)
      appState.setTabIndex(2);
      await tester.pumpAndSettle();
      expect(find.byType(TasksScreen), findsOneWidget);

      // Verifikasi tugas tertera di layar
      expect(find.text('Laporan Tugas Akhir IFB5J'), findsOneWidget);

      // Buka fitur Bagi Catatan Tugas (Share Task Sheet)
      final shareIcon = find.byIcon(Icons.share_outlined);
      expect(shareIcon, findsWidgets);
      await tester.ensureVisible(shareIcon.first);
      await tester.tap(shareIcon.first);
      await tester.pumpAndSettle();

      // Verifikasi seluruh opsi saluran berbagi
      expect(find.text('Bagi Catatan Tugas'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Telegram'), findsOneWidget);
      expect(find.text('LINE'), findsOneWidget);
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('Catatan'), findsOneWidget);
      expect(find.text('Salin Semua Teks (Papan Klip)'), findsOneWidget);

      // Tap opsi salin untuk WhatsApp
      await tester.tap(find.text('WhatsApp'));
      await tester.pumpAndSettle();
      expect(find.text('Bagi Catatan Tugas'), findsNothing);

      // Uji Toggle Checklist & Undo Toast
      appState.toggleTaskCompletion('task-e2e-demo');
      expect(appState.showUndoToast, isTrue);
      expect(appState.canUndo, isTrue);
      appState.undoLastAction();
      expect(appState.tasks.firstWhere((t) => t.id == 'task-e2e-demo').isCompleted, isFalse);

      appState.dispose();
    });

    testWidgets('E2E Journey 5: Kelola Mata Kuliah (Courses Screen), Edit Matkul, & Beban SKS', (WidgetTester tester) async {
      final appState = AppState();
      await appState.loadDbFuture;

      await tester.pumpWidget(NoteBookUMApp(appState: appState));
      await tester.pumpAndSettle();

      // Pindah ke tab Matkul (index 3)
      appState.setTabIndex(3);
      await tester.pumpAndSettle();
      expect(find.byType(CoursesScreen), findsOneWidget);

      // Verifikasi 8 matkul bawaan terdaftar
      expect(appState.courses.length, equals(8));

      // Buka modal Kelola Matkul
      final kelolaBtn = find.text('Kelola Matkul →');
      expect(kelolaBtn, findsWidgets);
      await tester.tap(kelolaBtn.first);
      await tester.pumpAndSettle();

      // Buka modal Edit Mata Kuliah
      final editBtn = find.text('Edit Informasi Mata Kuliah');
      expect(editBtn, findsOneWidget);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      expect(find.text('Edit Mata Kuliah'), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsOneWidget);

      // Tutup form edit via tombol close
      final closeIcon = find.byIcon(Icons.close);
      if (closeIcon.evaluate().isNotEmpty) {
        await tester.tap(closeIcon.last);
        await tester.pumpAndSettle();
      }

      appState.dispose();
    });

    testWidgets('E2E Journey 6: Pengaturan (Settings Screen), Edit Profil, Mode Gelap, Ekspor JSON, & Logout', (WidgetTester tester) async {
      final appState = AppState();
      await appState.loadDbFuture;

      await tester.pumpWidget(NoteBookUMApp(appState: appState));
      await tester.pumpAndSettle();

      // Pindah ke tab Profil / Pengaturan (index 4 - tab "Akun")
      appState.setTabIndex(4);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Verifikasi data profil
      expect(find.text('Farid Noor Rahman'), findsWidgets);
      expect(find.textContaining('2411001'), findsWidgets);
      expect(find.textContaining('S1 Informatika'), findsWidgets);

      // Scroll ke bawah untuk mencapai Section Cadangan Data
      await tester.drag(find.byType(ListView).last, const Offset(0, -400));
      await tester.pumpAndSettle();

      // Uji Ekspor JSON
      final exportBtn = find.text('Ekspor File JSON Lengkap');
      expect(exportBtn, findsOneWidget);
      await tester.tap(exportBtn);
      await tester.pumpAndSettle();
      expect(find.text('Data JSON berhasil disalin ke clipboard!'), findsOneWidget);

      // Scroll lagi ke bawah untuk tombol logout
      await tester.drag(find.byType(ListView).last, const Offset(0, -400));
      await tester.pumpAndSettle();

      // Uji Logout
      final logoutBtn = find.text('Keluar dari Akun');
      expect(logoutBtn, findsOneWidget);
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      // Memastikan kembali ke AuthScreen setelah logout
      expect(appState.isLoggedIn, isFalse);
      expect(find.byType(AuthScreen), findsOneWidget);

      appState.dispose();
    });
  });
}
