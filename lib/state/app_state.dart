import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';
import '../core/database/database_service.dart';
import '../core/repository/app_repository.dart';
import '../core/time/time_service.dart';
import '../models/course.dart';
import '../models/schedule_slot.dart';
import '../models/task.dart';

class AppState extends ChangeNotifier {
  int _selectedTabIndex = 0;
  ThemeMode _themeMode = ThemeMode.light;

  String _taskSearchQuery = '';
  String _selectedStatusTab = 'Semua';
  String? _selectedCourseFilter; // null = Semua Matkul

  bool _isReminderH24 = true;
  bool _isReminderH1 = true;

  // Profile data (PRD Section 4.4 & 1.5 Flow F)
  String _displayName = 'Farid Noor Rahman';
  String _nim = '2411001';
  String _prodi = 'S1 Informatika • IFB5J';
  String _campus = 'Universitas Mulia';
  String _timezone = 'Asia/Makassar';
  bool _isLoggedIn = true;

  // Live Time state (PRD Section 1.7)
  late DateTime _liveNow;
  Timer? _minuteTicker;

  // Undo Toast state
  bool _showUndoToast = false;
  String _undoToastMessage = '';
  int _undoCountdown = 5;
  Timer? _undoToastTimer;
  CourseTask? _lastToggledTask;

  List<Course> _courses = [];
  List<CourseTask> _tasks = [];

  int get selectedTabIndex => _selectedTabIndex;
  ThemeMode get themeMode => _themeMode;
  String get taskSearchQuery => _taskSearchQuery;
  String get selectedStatusTab => _selectedStatusTab;
  String? get selectedCourseFilter => _selectedCourseFilter;
  bool get isReminderH24 => _isReminderH24;
  bool get isReminderH1 => _isReminderH1;
  bool get showUndoToast => _showUndoToast;
  String get undoToastMessage => _undoToastMessage;
  int get undoCountdown => _undoCountdown;
  bool get canUndo => _lastToggledTask != null;
  String get displayName => _displayName;
  String get nim => _nim;
  String get prodi => _prodi;
  String get campus => _campus;
  String get timezone => _timezone;
  bool get isLoggedIn => _isLoggedIn;
  DateTime get liveNow => _liveNow;

  List<Course> get courses => _courses;
  List<CourseTask> get tasks => _tasks;

  // Computed statistics
  int get totalCourses => _courses.length;
  int get totalSks => _courses.fold(0, (sum, c) => sum + c.sks);
  int get totalSlots => _courses.fold(0, (sum, c) => sum + c.slots.length);
  int get activeTasksCount => _tasks.where((t) => !t.isCompleted).length;
  int get completedTasksCount => _tasks.where((t) => t.isCompleted).length;

  final AppRepository _repository;
  AppRepository get repository => _repository;
  bool _isDbLoaded = false;
  bool get isDbLoaded => _isDbLoaded;

  Future<void>? _loadDbFuture;
  Future<void> get loadDbFuture => _loadDbFuture ?? Future.value();

  AppState({AppRepository? repository, DatabaseHelper? dbHelper, DatabaseService? dbService})
      : _repository = repository ??
            dbService?.repo ??
            AppRepository(dbHelper: dbHelper ?? dbService?.helper ?? DatabaseHelper.instance) {
    _liveNow = TimeService.nowInWita();
    _startMinuteTicker();
    _initializeData();
    _loadDbFuture = _loadFromDatabase();
  }

  Future<void> _loadFromDatabase() async {
    try {
      // Seluruh data mata kuliah & jadwal dimuat langsung dari Repository
      final loadedCourses = await _repository.getCourses();
      _courses = loadedCourses;

      // Selalu load seluruh catatan tugas & pengaturan dari database SQLite via Repository
      final loadedTasks = await _repository.getTasks();
      final settings = await _repository.getAllSettings();

      _tasks = loadedTasks;

      if (settings.containsKey('display_name')) _displayName = settings['display_name']!;
      if (settings.containsKey('nim')) _nim = settings['nim']!;
      if (settings.containsKey('prodi')) _prodi = settings['prodi']!;
      if (settings.containsKey('campus')) _campus = settings['campus']!;
      if (settings.containsKey('timezone')) _timezone = settings['timezone']!;
      if (settings.containsKey('is_logged_in')) _isLoggedIn = settings['is_logged_in'] == '1';
      if (settings.containsKey('is_reminder_h24')) _isReminderH24 = settings['is_reminder_h24'] == '1';
      if (settings.containsKey('is_reminder_h1')) _isReminderH1 = settings['is_reminder_h1'] == '1';
      if (settings.containsKey('theme_mode')) {
        _themeMode = settings['theme_mode'] == 'dark' ? ThemeMode.dark : ThemeMode.light;
      }

      _isDbLoaded = true;
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('Error loading from SQLite: $e');
    }
  }

  void _startMinuteTicker() {
    _minuteTicker?.cancel();
    _minuteTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      _liveNow = TimeService.nowInWita();
      notifyListeners();
    });
  }

  /// Called on AppLifecycleState.resumed (PRD Section 1.7)
  void resumeTick() {
    _liveNow = TimeService.nowInWita();
    notifyListeners();
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _minuteTicker?.cancel();
    _undoToastTimer?.cancel();
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void _initializeData() {
    // Data mata kuliah dan tugas dimuat secara persisten dari SQLite, bukan hardcoded in-memory
    _courses = [];
    _tasks = [];
  }

  // Active session helper for TodayScreen
  ScheduleSlot? getActiveSlotToday() {
    final todaySlots = getTodaySlots();
    if (todaySlots.isEmpty) return null;

    // 1. Prioritaskan kelas yang sedang berlangsung real-time
    for (final slot in todaySlots) {
      final statusResult = TimeService.getClassStatus(_liveNow, slot);
      if (statusResult.status == ClassStatus.berlangsung) {
        return slot;
      }
    }

    // 2. Jika tidak ada yang berlangsung, pilih kelas mendatang berikutnya hari ini
    for (final slot in todaySlots) {
      final statusResult = TimeService.getClassStatus(_liveNow, slot);
      if (statusResult.status == ClassStatus.akanDatang) {
        return slot;
      }
    }

    // 3. Jika semua kelas hari ini telah selesai, tampilkan sesi terakhir hari ini
    return todaySlots.last;
  }

  List<ScheduleSlot> getTodaySlots() {
    final todayWeekday = _liveNow.weekday;
    final list = <ScheduleSlot>[];
    for (final course in _courses) {
      for (final slot in course.slots) {
        if (slot.day == todayWeekday) {
          list.add(slot);
        }
      }
    }
    list.sort((a, b) => a.startTime.compareTo(b.startTime));
    return list;
  }

  void setTabIndex(int index) {
    if (_selectedTabIndex != index) {
      _selectedTabIndex = index;
      notifyListeners();
    }
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    unawaited(_repository.setSetting('theme_mode', _themeMode == ThemeMode.dark ? 'dark' : 'light'));
  }

  void setTaskSearchQuery(String query) {
    _taskSearchQuery = query;
    notifyListeners();
  }

  void setStatusTab(String tab) {
    _selectedStatusTab = tab;
    notifyListeners();
  }

  void setCourseFilter(String? courseCode) {
    _selectedCourseFilter = courseCode;
    notifyListeners();
  }

  void updateProfile({String? displayName, String? nim, String? prodi, String? timezone}) {
    if (displayName != null) {
      _displayName = displayName;
      unawaited(_repository.setSetting('display_name', displayName));
    }
    if (nim != null) {
      _nim = nim;
      unawaited(_repository.setSetting('nim', nim));
    }
    if (prodi != null) {
      _prodi = prodi;
      unawaited(_repository.setSetting('prodi', prodi));
    }
    if (timezone != null) {
      _timezone = timezone;
      unawaited(_repository.setSetting('timezone', timezone));
    }
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
    unawaited(_repository.setSetting('is_logged_in', '0'));
  }

  void login(String email, String password) {
    _isLoggedIn = true;
    notifyListeners();
    unawaited(_repository.setSetting('is_logged_in', '1'));
  }

  // Task Completion & Undo
  void toggleTaskCompletion(String taskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final newStatus = !task.isCompleted;
      final updated = task.copyWith(isCompleted: newStatus);
      _tasks[index] = updated;
      _lastToggledTask = updated;

      _undoToastMessage = newStatus ? '1 tugas ditandai selesai' : '1 tugas dibuka kembali';
      _showUndoToast = true;
      _undoCountdown = 5;

      _undoToastTimer?.cancel();
      _undoToastTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_undoCountdown > 1) {
          _undoCountdown--;
          _safeNotifyListeners();
        } else {
          _showUndoToast = false;
          _lastToggledTask = null;
          timer.cancel();
          _undoToastTimer = null;
          _safeNotifyListeners();
        }
      });

      _safeNotifyListeners();
      unawaited(_repository.updateTask(updated));
    }
  }

  void undoLastAction() {
    _showUndoToast = false;
    _undoToastTimer?.cancel();
    _undoToastTimer = null;
    if (_lastToggledTask != null) {
      final index = _tasks.indexWhere((t) => t.id == _lastToggledTask!.id);
      if (index != -1) {
        _tasks[index].isCompleted = !_tasks[index].isCompleted;
        unawaited(_repository.updateTask(_tasks[index]));
      }
      _lastToggledTask = null;
    }
    _safeNotifyListeners();
  }

  void dismissUndoToast() {
    _showUndoToast = false;
    _lastToggledTask = null;
    _undoToastTimer?.cancel();
    _undoToastTimer = null;
    _safeNotifyListeners();
  }

  void showToast(String message) {
    _undoToastMessage = message;
    _showUndoToast = true;
    _lastToggledTask = null;
    _undoCountdown = 3;
    _undoToastTimer?.cancel();
    _undoToastTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_undoCountdown > 1) {
        _undoCountdown--;
        _safeNotifyListeners();
      } else {
        _showUndoToast = false;
        timer.cancel();
        _undoToastTimer = null;
        _safeNotifyListeners();
      }
    });
    _safeNotifyListeners();
  }

  // --- Task CRUD: UI -> ViewModel -> Repository -> SQLite -> Reload & Notify ---

  Future<void> addTask(CourseTask newTask) async {
    _tasks.insert(0, newTask);
    _safeNotifyListeners();
    await _repository.insertTask(newTask);
    _tasks = await _repository.getTasks();
    _safeNotifyListeners();
  }

  Future<void> updateTask(CourseTask updatedTask) async {
    final idx = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (idx != -1) {
      _tasks[idx] = updatedTask;
      _safeNotifyListeners();
    }
    await _repository.updateTask(updatedTask);
    _tasks = await _repository.getTasks();
    _safeNotifyListeners();
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    showToast('Tugas telah dihapus');
    _safeNotifyListeners();
    await _repository.deleteTask(taskId);
    _tasks = await _repository.getTasks();
    _safeNotifyListeners();
  }

  // --- Course CRUD ---

  Future<void> addCourse(Course course) async {
    _courses.add(course);
    _safeNotifyListeners();
    await _repository.insertCourse(course);
    _courses = await _repository.getCourses();
    _safeNotifyListeners();
  }

  Future<void> updateCourse(Course updatedCourse) async {
    final idx = _courses.indexWhere((c) => c.id == updatedCourse.id);
    if (idx != -1) {
      _courses[idx] = updatedCourse;
      _recalculateNextSessionTasks(updatedCourse.id);
      _safeNotifyListeners();
    }
    await _repository.updateCourse(updatedCourse);
    _courses = await _repository.getCourses();
    _safeNotifyListeners();
  }

  Future<void> deleteCourse(String courseId) async {
    _courses.removeWhere((c) => c.id == courseId);
    for (int i = 0; i < _tasks.length; i++) {
      if (_tasks[i].courseId == courseId) {
        final t = _tasks[i];
        final newDueMode = (t.dueMode == DueMode.nextSession) ? DueMode.fixed : t.dueMode;
        _tasks[i] = t.copyWith(
          courseId: null,
          courseCode: 'MANDIRI',
          courseName: 'Mandiri',
          dueMode: newDueMode,
          secondaryMeta: 'Mandiri',
        );
      }
    }
    showToast('Mata kuliah dihapus, tugas dialihkan ke mandiri');
    _safeNotifyListeners();
    await _repository.deleteCourse(courseId);
    _courses = await _repository.getCourses();
    _tasks = await _repository.getTasks();
    _safeNotifyListeners();
  }

  // --- Schedule Slots CRUD ---

  Future<void> addSlot(String courseId, ScheduleSlot slot) async {
    await _repository.insertSlot(slot);
    _courses = await _repository.getCourses();
    _recalculateNextSessionTasks(courseId);
    notifyListeners();
  }

  Future<void> updateSlot(String courseId, ScheduleSlot updatedSlot) async {
    await _repository.updateSlot(updatedSlot);
    _courses = await _repository.getCourses();
    _recalculateNextSessionTasks(courseId);
    notifyListeners();
  }

  Future<void> deleteSlot(String courseId, String slotId) async {
    await _repository.deleteSlot(slotId);
    _courses = await _repository.getCourses();
    _recalculateNextSessionTasks(courseId);
    notifyListeners();
  }

  void _recalculateNextSessionTasks(String courseId) {
    final course = getCourse(courseId);
    if (course == null) return;

    int adjustedCount = 0;
    final now = _liveNow;

    for (int i = 0; i < _tasks.length; i++) {
      final t = _tasks[i];
      if (t.courseId == courseId && t.dueMode == DueMode.nextSession && !t.isCompleted) {
        if (t.dueAt == null || t.dueAt!.isAfter(now)) {
          final nextDue = TimeService.calculateNextSession(
            createdAt: t.createdAt ?? now,
            slots: course.slots,
          );

          if (nextDue != null) {
            _tasks[i] = t.copyWith(
              dueAt: nextDue,
              dueText: TimeService.formatNextSessionText(nextDue),
            );
            adjustedCount++;
            unawaited(_repository.updateTask(_tasks[i]));
          }
        }
      }
    }

    if (adjustedCount > 0) {
      showToast('$adjustedCount tugas disesuaikan dengan jadwal baru');
    }
  }

  void toggleReminderH24() {
    _isReminderH24 = !_isReminderH24;
    notifyListeners();
    unawaited(_repository.setSetting('is_reminder_h24', _isReminderH24 ? '1' : '0'));
  }

  void toggleReminderH1() {
    _isReminderH1 = !_isReminderH1;
    notifyListeners();
    unawaited(_repository.setSetting('is_reminder_h1', _isReminderH1 ? '1' : '0'));
  }

  void clearAllData() {
    _courses = [];
    _tasks = [];
    notifyListeners();
    unawaited(_repository.clearAllData());
  }

  Future<void> saveCurrentCoursesAsPermanent() async {
    await _repository.savePermanentCourses(_courses);
    showToast('${_courses.length} matkul disimpan sebagai jadwal tetap');
  }

  Future<void> deleteAllCourses() async {
    await _repository.deleteAllCourses();
    _courses = await _repository.getCourses();
    _tasks = await _repository.getTasks();
    notifyListeners();
    showToast('Seluruh mata kuliah telah dihapus');
  }

  Future<void> resetToSavedPermanentCourses() async {
    await _repository.resetToSavedPermanentCourses();
    _courses = await _repository.getCourses();
    _tasks = await _repository.getTasks();
    notifyListeners();
    showToast('Jadwal berhasil direset ke matkul tetap');
  }

  Future<void> resetToDefaultCourses() async {
    await _repository.resetToDefaultCourses();
    _courses = await _repository.getCourses();
    _tasks = await _repository.getTasks();
    notifyListeners();
  }

  String exportDataAsJson() {
    final data = {
      'exported_at': DateTime.now().toIso8601String(),
      'timezone': _timezone,
      'user': {
        'name': _displayName,
        'nim': _nim,
        'prodi': _prodi,
        'campus': _campus,
        'email': 'farid.noor@mhs.universitasmulia.ac.id',
        'role': 'Mahasiswa',
      },
      'courses': _courses.map((c) => c.toJson()).toList(),
      'tasks': _tasks.map((t) => t.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Course? getCourse(String? courseId) {
    if (courseId == null) return null;
    try {
      return _courses.firstWhere((c) => c.id == courseId);
    } catch (_) {
      return null;
    }
  }
}
