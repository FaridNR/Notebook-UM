class ScheduleSlot {
  final String id;
  final String courseId;
  final String courseCode;
  final String courseName;
  final int day; // 1 = Senin, 2 = Selasa, 3 = Rabu, 4 = Kamis, 5 = Jumat, 6 = Sabtu, 7 = Minggu
  final String dayName;
  final String startTime;
  final String endTime;
  final String room;
  final int durationMinutes;
  final bool isCompleted;

  const ScheduleSlot({
    required this.id,
    required this.courseId,
    required this.courseCode,
    required this.courseName,
    required this.day,
    required this.dayName,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.durationMinutes,
    this.isCompleted = false,
  });

  ScheduleSlot copyWith({
    String? id,
    String? courseId,
    String? courseCode,
    String? courseName,
    int? day,
    String? dayName,
    String? startTime,
    String? endTime,
    String? room,
    int? durationMinutes,
    bool? isCompleted,
  }) {
    return ScheduleSlot(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      courseCode: courseCode ?? this.courseCode,
      courseName: courseName ?? this.courseName,
      day: day ?? this.day,
      dayName: dayName ?? this.dayName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseId': courseId,
        'courseCode': courseCode,
        'courseName': courseName,
        'day': day,
        'dayName': dayName,
        'startTime': startTime,
        'endTime': endTime,
        'room': room,
        'durationMinutes': durationMinutes,
        'isCompleted': isCompleted,
      };

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) => ScheduleSlot(
        id: json['id'] as String,
        courseId: json['courseId'] as String,
        courseCode: json['courseCode'] as String,
        courseName: json['courseName'] as String,
        day: json['day'] as int,
        dayName: json['dayName'] as String,
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
        room: json['room'] as String,
        durationMinutes: json['durationMinutes'] as int,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
}
