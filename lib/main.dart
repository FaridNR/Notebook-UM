import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/auth_screen.dart';
import 'screens/today_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/courses_screen.dart';
import 'screens/settings_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/add_task_sheet.dart';
import 'widgets/dock_navigation.dart';
import 'widgets/undo_toast.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const NoteBookUMApp());
}

class NoteBookUMApp extends StatefulWidget {
  const NoteBookUMApp({super.key});

  @override
  State<NoteBookUMApp> createState() => _NoteBookUMAppState();
}

class _NoteBookUMAppState extends State<NoteBookUMApp> with WidgetsBindingObserver {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appState.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // PRD Section 1.7: saat app kembali ke depan (AppLifecycleState.resumed) hitung ulang segera
    if (state == AppLifecycleState.resumed) {
      _appState.resumeTick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'NoteBook UM',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _appState.themeMode,
          home: _appState.isLoggedIn
              ? HomeScreen(appState: _appState)
              : AuthScreen(appState: _appState),
        );
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  final AppState appState;

  const HomeScreen({
    super.key,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: appState.selectedTabIndex,
            children: [
              TodayScreen(appState: appState),
              ScheduleScreen(appState: appState),
              TasksScreen(appState: appState),
              CoursesScreen(appState: appState),
              SettingsScreen(appState: appState),
            ],
          ),
          if (appState.showUndoToast)
            Positioned(
              left: 16,
              right: 16,
              bottom: 90,
              child: UndoToast(
                message: appState.undoToastMessage,
                countdown: appState.undoCountdown,
                onUndo: appState.canUndo ? () => appState.undoLastAction() : null,
                onDismiss: () => appState.dismissUndoToast(),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DockNavigation(
              selectedIndex: appState.selectedTabIndex,
              onTabSelected: (index) => appState.setTabIndex(index),
              onCenterAction: () {
                appState.setTabIndex(2);
                AddTaskSheet.show(context, appState);
              },
            ),
          ),
        ],
      ),
    );
  }
}
