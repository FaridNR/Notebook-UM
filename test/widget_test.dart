import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:notebook_um/main.dart';
import 'package:notebook_um/models/task.dart';
import 'package:notebook_um/screens/courses_screen.dart';
import 'package:notebook_um/screens/tasks_screen.dart';
import 'package:notebook_um/widgets/edit_task_sheet.dart';
import 'package:notebook_um/state/app_state.dart';

void main() {
  testWidgets('NoteBook UM app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NoteBookUMApp());
    expect(find.text('NoteBook UM'), findsOneWidget);
    expect(find.text('Hari Ini'), findsWidgets);
  });

  testWidgets('Form Tambah Mata Kuliah urutan: Kode Mata Kuliah -> Nama Matkul -> Dosen -> SKS -> Warna', (WidgetTester tester) async {
    final appState = AppState();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CoursesScreen(appState: appState),
        ),
      ),
    );

    // Tap tombol Tambah Mata Kuliah (Tambah Matkul)
    final tambahBtn = find.text('Tambah Matkul');
    expect(tambahBtn, findsOneWidget);
    await tester.tap(tambahBtn);
    await tester.pumpAndSettle();

    // Verifikasi label Kode Mata Kuliah di paling atas
    expect(find.text('Kode Mata Kuliah'), findsOneWidget);
    expect(find.text('Nama Mata Kuliah'), findsOneWidget);
    expect(find.text('Dosen Pengampu'), findsOneWidget);
    expect(find.text('Beban SKS'), findsOneWidget);
    expect(find.text('Identitas Warna'), findsOneWidget);

    // Verifikasi posisi vertikal (Kode Mata Kuliah paling atas, diikuti Nama Matkul, dst.)
    final kodeY = tester.getTopLeft(find.text('Kode Mata Kuliah')).dy;
    final namaY = tester.getTopLeft(find.text('Nama Mata Kuliah')).dy;
    final dosenY = tester.getTopLeft(find.text('Dosen Pengampu')).dy;
    final sksY = tester.getTopLeft(find.text('Beban SKS')).dy;
    final warnaY = tester.getTopLeft(find.text('Identitas Warna')).dy;

    expect(kodeY < namaY, isTrue);
    expect(namaY < dosenY, isTrue);
    expect(dosenY < sksY, isTrue);
    expect(sksY < warnaY, isTrue);

    appState.dispose();
  });

  testWidgets('Tombol tengah bergaya DANA (Tugas) membuka AddTaskSheet', (WidgetTester tester) async {
    await tester.pumpWidget(const NoteBookUMApp());

    // Verifikasi tombol Tugas di navigasi bawah (tombol tengah menonjol DANA)
    final tugasBtn = find.text('Tugas');
    expect(tugasBtn, findsWidgets);

    // Tap tombol Tugas di tengah dock
    await tester.tap(tugasBtn.first);
    await tester.pumpAndSettle();

    // Verifikasi modal Tambah Tugas terbuka
    expect(find.text('Tambah Tugas'), findsOneWidget);
    expect(find.text('Pencatatan Cepat & Terhubung Sesi Kuliah'), findsOneWidget);
  });

  testWidgets('Halaman Tentang Aplikasi dapat dibuka dari Beranda dan menampilkan info aplikasi & profil', (WidgetTester tester) async {
    await tester.pumpWidget(const NoteBookUMApp());
    await tester.pumpAndSettle();

    // Verifikasi tombol info / Tentang Aplikasi tersedia di Header Beranda
    final aboutBtn = find.byTooltip('Tentang Aplikasi');
    expect(aboutBtn, findsOneWidget);

    // Tap Tentang Aplikasi di Header
    await tester.tap(aboutBtn);
    await tester.pumpAndSettle();

    // Verifikasi berada di Halaman Tentang Aplikasi
    expect(find.text('Tentang Aplikasi'), findsWidgets);
    expect(find.text('Farid Noor Rahman'), findsOneWidget);
    expect(find.text('2411001'), findsOneWidget);
    expect(find.text('S1 Informatika'), findsOneWidget);
    expect(find.text('Versi 1.0.0 (Build 1) • IFB5J'), findsOneWidget);
    expect(find.text('Informasi Akademik & Pengembang'), findsOneWidget);
    expect(find.text('Pramudya Prima Insan, S.Kom., M.Kom.'), findsOneWidget);

    // Tekan tombol kembali
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    // Kembali ke Beranda
    expect(find.text('NoteBook UM'), findsOneWidget);
  });

  testWidgets('Consumer menampilkan jumlah total catatan secara reaktif pada halaman Daftar Tugas', (WidgetTester tester) async {
    final appState = AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: MaterialApp(
          home: Scaffold(
            body: TasksScreen(appState: appState),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verifikasi awal: 0 Catatan (menggunakan Consumer)
    expect(find.text('Total: 0 Catatan'), findsOneWidget);
    expect(find.textContaining('Total 0 Catatan'), findsOneWidget);

    // Tambah 1 catatan tugas baru ke AppState
    appState.addTask(
      CourseTask(
        id: 'task-test-01',
        title: 'Tugas Praktikum Kriptografi',
        courseId: 'course-110700',
        courseCode: '110700',
        courseName: 'Kriptografi',
        priority: TaskPriority.high,
        dueCategory: TaskDueCategory.urgent,
        dueText: 'Hari ini, 23:59 WITA',
        notes: 'Implementasi ROT13 & Vigenere',
      ),
    );
    await tester.pumpAndSettle();

    // Verifikasi Consumer me-rebuild tampilan dan menampilkan Total: 1 Catatan
    expect(find.text('Total: 1 Catatan'), findsOneWidget);
    expect(find.textContaining('Total 1 Catatan • 1 Aktif • 0 Selesai'), findsOneWidget);

    appState.dispose();
  });

  testWidgets('M1: Fitur ubah judul, deskripsi, dan tenggat tugas (M1-T1 s/d M1-T4)', (WidgetTester tester) async {
    final appState = AppState();
    final task = CourseTask(
      id: 'task-test-edit',
      title: 'StudyLog',
      courseId: 'course-111100',
      courseCode: '111100',
      courseName: 'Penalaran Komputer',
      priority: TaskPriority.medium,
      dueCategory: TaskDueCategory.upcoming,
      dueText: '6/11/2026 • 23:59 WITA',
      notes: 'Membuat pencatat tugas real-time',
    );
    appState.addTask(task);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: MaterialApp(
          home: Scaffold(
            body: TasksScreen(appState: appState),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verifikasi task awal tampil pada card
    expect(find.text('StudyLog'), findsOneWidget);
    expect(find.text('Membuat pencatat tugas real-time'), findsOneWidget);

    // Tap kartu tugas untuk membuka modal detail sheet
    await tester.tap(find.text('StudyLog'));
    await tester.pumpAndSettle();

    // Verifikasi tombol Ubah tersedia dan tap tombol Ubah
    final ubahBtn = find.text('Ubah');
    expect(ubahBtn, findsOneWidget);
    await tester.tap(ubahBtn);
    await tester.pumpAndSettle();

    // Verifikasi form Ubah Tugas terbuka
    expect(find.text('Ubah Tugas'), findsOneWidget);
    expect(find.text('Judul Tugas / Catatan'), findsOneWidget);
    expect(find.text('Deskripsi / Catatan'), findsOneWidget);
    expect(find.text('Tenggat Waktu'), findsOneWidget);

    // M1-T1: Kosongkan judul lalu klik Simpan Perubahan -> pesan wajib diisi tampil
    final judulField = find.byType(TextFormField).first;
    await tester.enterText(judulField, '');
    final simpanBtn = find.text('Simpan Perubahan');
    await tester.ensureVisible(simpanBtn);
    await tester.pumpAndSettle();
    await tester.tap(simpanBtn);
    await tester.pumpAndSettle();
    expect(find.text('Judul tugas wajib diisi dan tidak boleh hanya spasi'), findsOneWidget);

    // M1-T2: Isi dengan hanya spasi -> validasi menolak input
    await tester.enterText(judulField, '    ');
    await tester.ensureVisible(simpanBtn);
    await tester.pumpAndSettle();
    await tester.tap(simpanBtn);
    await tester.pumpAndSettle();
    expect(find.text('Judul tugas wajib diisi dan tidak boleh hanya spasi'), findsOneWidget);

    // M1-T4: Ubah judul, deskripsi, dan pilih tenggat Next Session
    await tester.enterText(judulField, 'StudyLog Pro Max');
    final descField = find.byType(TextFormField).at(1);
    await tester.enterText(descField, 'Pencatatan real-time dan notifikasi tenggat');
    final nextSessionChip = find.descendant(
      of: find.byType(EditTaskSheet),
      matching: find.text('Next Session'),
    );
    await tester.tap(nextSessionChip);
    await tester.pumpAndSettle();

    // Simpan Perubahan
    final simpanActionBtn = find.descendant(
      of: find.byType(EditTaskSheet),
      matching: find.text('Simpan Perubahan'),
    );
    await tester.ensureVisible(simpanActionBtn);
    await tester.pumpAndSettle();
    await tester.tap(simpanActionBtn);
    await tester.pumpAndSettle();

    // M1-T3: SnackBar konfirmasi muncul
    expect(find.textContaining('berhasil diperbarui'), findsOneWidget);

    // M1-T4: Isi Card di layar tugas telah ter-update dengan judul dan deskripsi baru
    expect(find.text('StudyLog Pro Max'), findsOneWidget);
    expect(find.text('Pencatatan real-time dan notifikasi tenggat'), findsOneWidget);
    expect(find.text('StudyLog'), findsNothing);

    appState.dispose();
  });
}
