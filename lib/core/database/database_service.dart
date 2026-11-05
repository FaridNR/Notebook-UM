import '../../models/course.dart';
import '../../models/schedule_slot.dart';
import '../../models/task.dart';
import '../repository/app_repository.dart';
import 'database_helper.dart';

/// DatabaseService adapter untuk kompatibilitas ke belakang.
/// Menggabungkan akses ke DatabaseHelper (koneksi) dan AppRepository (kueri).
class DatabaseService {
  static DatabaseService? _instance;
  final DatabaseHelper _helper;
  final AppRepository _repo;

  DatabaseService._({DatabaseHelper? helper, AppRepository? repo})
      : _helper = helper ?? DatabaseHelper.instance,
        _repo = repo ?? AppRepository(dbHelper: helper ?? DatabaseHelper.instance);

  static DatabaseService get instance => _instance ??= DatabaseService._();

  AppRepository get repo => _repo;
  DatabaseHelper get helper => _helper;

  static void setupDatabaseFactory({bool noIsolate = false}) {
    DatabaseHelper.setupDatabaseFactory(noIsolate: noIsolate);
  }

  Future<void> init({String? path}) => _helper.init(path: path);
  Future<void> close() => _helper.close();

  // Delegasi pemanggilan ke AppRepository
  Future<List<Course>> getCourses() => _repo.getCourses();
  Future<void> insertCourse(Course course) => _repo.insertCourse(course);
  Future<void> updateCourse(Course course) => _repo.updateCourse(course);
  Future<void> deleteCourse(String id) => _repo.deleteCourse(id);
  Future<void> deleteAllCourses() => _repo.deleteAllCourses();
  Future<void> savePermanentCourses(List<Course> courses) => _repo.savePermanentCourses(courses);
  Future<List<Course>> getPermanentCourses() => _repo.getPermanentCourses();
  Future<void> resetToSavedPermanentCourses() => _repo.resetToSavedPermanentCourses();
  Future<void> resetToDefaultCourses() => _repo.resetToDefaultCourses();
  Future<void> insertSlot(ScheduleSlot slot) => _repo.insertSlot(slot);
  Future<void> updateSlot(ScheduleSlot slot) => _repo.updateSlot(slot);
  Future<void> deleteSlot(String slotId) => _repo.deleteSlot(slotId);
  Future<List<CourseTask>> getTasks() => _repo.getTasks();
  Future<void> insertTask(CourseTask task) => _repo.insertTask(task);
  Future<void> updateTask(CourseTask task) => _repo.updateTask(task);
  Future<void> deleteTask(String taskId) => _repo.deleteTask(taskId);
  Future<Map<String, String>> getAllSettings() => _repo.getAllSettings();
  Future<void> setSetting(String key, String value) => _repo.setSetting(key, value);
  Future<bool> hasCourses() => _repo.hasCourses();
  Future<bool> isInitialSeeded() => _repo.isInitialSeeded();
  Future<void> clearAllData() => _repo.clearAllData();
  Future<void> seedInitialCourses([List<Course>? courses]) => _repo.seedInitialCourses(courses);
}
