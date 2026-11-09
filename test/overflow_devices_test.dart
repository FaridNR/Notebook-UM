import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notebook_um/core/database/database_service.dart';
import 'package:notebook_um/main.dart';
import 'package:notebook_um/models/task.dart';
import 'package:notebook_um/screens/about_screen.dart';
import 'package:notebook_um/screens/auth_screen.dart';
import 'package:notebook_um/state/app_state.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    DatabaseService.setupDatabaseFactory(noIsolate: true);
  });

  setUp(() async {
    await DatabaseService.instance.init(path: inMemoryDatabasePath);
  });

  final deviceProfiles = <String, Size>{
    // Android
    'Android Small (360x640)': const Size(360, 640),
    'Android Standard (393x852)': const Size(393, 852),
    'Android Large (412x915)': const Size(412, 915),
    // iOS
    'iPhone SE (375x667)': const Size(375, 667),
    'iPhone 15 (393x852)': const Size(393, 852),
    'iPhone Pro Max (430x932)': const Size(430, 932),
    // Tablet
    'Android Tablet Portrait (800x1280)': const Size(800, 1280),
    'Android Tablet Landscape (1280x800)': const Size(1280, 800),
    // iPad
    'iPad Mini / 9.7 (768x1024)': const Size(768, 1024),
    'iPad Air 11 (820x1180)': const Size(820, 1180),
    'iPad Pro 12.9 (1024x1366)': const Size(1024, 1366),
    // Web
    'Web 720p (1280x720)': const Size(1280, 720),
    'Web 1080p (1920x1080)': const Size(1920, 1080),
  };

  for (final entry in deviceProfiles.entries) {
    final deviceName = entry.key;
    final size = entry.value;

    testWidgets('Audit overflow pada $deviceName', (WidgetTester tester) async {
      final List<String> overflowErrors = [];

      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        final message = details.exceptionAsString();
        if (message.contains('overflowed') ||
            message.contains('RenderFlex') ||
            message.contains('unbounded constraints')) {
          overflowErrors.add('[$deviceName] $message');
        }
        originalOnError?.call(details);
      };

      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        FlutterError.onError = originalOnError;
      });

      final appState = AppState();
      await appState.loadDbFuture;

      // Tambahkan beberapa task dengan nama bervariasi
      appState.addTask(
        CourseTask(
          id: 'test-task-1',
          title: 'Implementasi Algoritma Enkripsi Vigenere Cipher & Kripto Klasik',
          courseId: appState.courses.isNotEmpty ? appState.courses.first.id : '110600',
          courseCode: appState.courses.isNotEmpty ? appState.courses.first.code : '110600',
          courseName: appState.courses.isNotEmpty ? appState.courses.first.name : 'Jaringan Nirkabel',
          priority: TaskPriority.high,
          dueCategory: TaskDueCategory.urgent,
          dueText: 'Senin, 16 November 2026 • 23:59 WITA',
          notes: 'Dikerjakan berkelompok dengan laporan terstruktur format PDF',
        ),
      );

      // 1. Test App di HomeScreen (Tab 0: Hari Ini)
      await tester.pumpWidget(NoteBookUMApp(appState: appState));
      await tester.pumpAndSettle();

      // Tab 1: Jadwal
      appState.setTabIndex(1);
      await tester.pumpAndSettle();

      // Tab 2: Tugas
      appState.setTabIndex(2);
      await tester.pumpAndSettle();

      // Tab 3: Matkul
      appState.setTabIndex(3);
      await tester.pumpAndSettle();

      // Tab 4: Akun / Pengaturan
      appState.setTabIndex(4);
      await tester.pumpAndSettle();

      // Test AboutScreen
      await tester.pumpWidget(
        MaterialApp(
          home: AboutScreen(appState: appState),
        ),
      );
      await tester.pumpAndSettle();

      // Test AuthScreen
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(appState: appState),
        ),
      );
      await tester.pumpAndSettle();

      appState.dispose();

      expect(overflowErrors, isEmpty, reason: 'Ditemukan layout overflow pada $deviceName: ${overflowErrors.join("\n")}');
    });
  }
}
