enum TaskPriority { high, medium, low }

enum TaskDueCategory { urgent, nextSession, upcoming, completed }

enum DueMode { none, fixed, nextSession }

class CourseTask {
  final String id;
  final String title;
  final String notes;
  final String? courseId;
  final String courseCode;
  final String courseName;
  final TaskPriority priority;
  final TaskDueCategory dueCategory;
  final DueMode dueMode;
  final DateTime? dueAt;
  final DateTime? createdAt;
  final String dueText;
  final String? secondaryMeta;
  bool isCompleted;
  final String? completedNote;
  final bool reminderEnabled;

  CourseTask({
    required this.id,
    required this.title,
    this.notes = '',
    this.courseId,
    required this.courseCode,
    required this.courseName,
    required this.priority,
    required this.dueCategory,
    this.dueMode = DueMode.none,
    this.dueAt,
    this.createdAt,
    required this.dueText,
    this.secondaryMeta,
    this.isCompleted = false,
    this.completedNote,
    this.reminderEnabled = true,
  });

  CourseTask copyWith({
    String? id,
    String? title,
    String? notes,
    String? courseId,
    String? courseCode,
    String? courseName,
    TaskPriority? priority,
    TaskDueCategory? dueCategory,
    DueMode? dueMode,
    DateTime? dueAt,
    DateTime? createdAt,
    String? dueText,
    String? secondaryMeta,
    bool? isCompleted,
    String? completedNote,
    bool? reminderEnabled,
  }) {
    return CourseTask(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      courseId: courseId ?? this.courseId,
      courseCode: courseCode ?? this.courseCode,
      courseName: courseName ?? this.courseName,
      priority: priority ?? this.priority,
      dueCategory: dueCategory ?? this.dueCategory,
      dueMode: dueMode ?? this.dueMode,
      dueAt: dueAt ?? this.dueAt,
      createdAt: createdAt ?? this.createdAt,
      dueText: dueText ?? this.dueText,
      secondaryMeta: secondaryMeta ?? this.secondaryMeta,
      isCompleted: isCompleted ?? this.isCompleted,
      completedNote: completedNote ?? this.completedNote,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'courseId': courseId,
        'courseCode': courseCode,
        'courseName': courseName,
        'priority': priority.name,
        'dueCategory': dueCategory.name,
        'dueMode': dueMode.name,
        'dueAt': dueAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
        'dueText': dueText,
        'secondaryMeta': secondaryMeta,
        'isCompleted': isCompleted,
        'completedNote': completedNote,
        'reminderEnabled': reminderEnabled,
      };
}
