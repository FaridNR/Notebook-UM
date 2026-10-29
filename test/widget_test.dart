import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notebook_um/main.dart';
import 'package:notebook_um/screens/courses_screen.dart';
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
}
