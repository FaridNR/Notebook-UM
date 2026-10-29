import '../../models/schedule_slot.dart';

enum ClassStatus {
  akanDatang,
  berlangsung,
  selesai,
  tidakAktifHariIni,
}

class ClassStatusResult {
  final ClassStatus status;
  final String statusLabel;
  final double progress; // 0.0 to 1.0
  final String remainingText;
  final Duration? remainingDuration;

  const ClassStatusResult({
    required this.status,
    required this.statusLabel,
    this.progress = 0.0,
    this.remainingText = '',
    this.remainingDuration,
  });
}

class TimeService {
  // Default timezone identifier for NoteBook UM: Asia/Makassar (WITA, UTC+8)
  static const String defaultTimezone = 'Asia/Makassar';
  static const int witaOffsetHours = 8;

  /// Returns current DateTime adjusted to WITA (UTC+8)
  static DateTime nowInWita([DateTime? customNow]) {
    if (customNow != null) {
      if (customNow.isUtc) {
        final wita = customNow.add(const Duration(hours: witaOffsetHours));
        return DateTime(wita.year, wita.month, wita.day, wita.hour, wita.minute, wita.second);
      }
      return customNow;
    }
    final utc = DateTime.now().toUtc();
    final wita = utc.add(const Duration(hours: witaOffsetHours));
    return DateTime(wita.year, wita.month, wita.day, wita.hour, wita.minute, wita.second);
  }

  /// Parses "HH:mm" time string into a DateTime on the target date in local/profile time
  static DateTime timeToDateTime(DateTime baseDate, String timeStr) {
    final parts = timeStr.trim().split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    if (baseDate.isUtc) {
      return DateTime.utc(baseDate.year, baseDate.month, baseDate.day, hour, minute);
    }
    return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
  }

  /// Evaluates status of a class session at `now` (PRD Section 1.7)
  /// - sekarang < mulai -> akan_datang
  /// - mulai <= sekarang < selesai -> berlangsung
  /// - sekarang >= selesai -> selesai
  static ClassStatusResult getClassStatus(DateTime now, ScheduleSlot slot) {
    if (now.weekday != slot.day) {
      return const ClassStatusResult(
        status: ClassStatus.tidakAktifHariIni,
        statusLabel: 'Jadwal Hari Lain',
      );
    }

    final startDt = timeToDateTime(now, slot.startTime);
    final endDt = timeToDateTime(now, slot.endTime);

    if (now.isBefore(startDt)) {
      final diff = startDt.difference(now);
      final hours = diff.inHours;
      final mins = diff.inMinutes % 60;
      final remainingStr = hours > 0 ? '$hours jam $mins menit lagi' : '$mins menit lagi';

      return ClassStatusResult(
        status: ClassStatus.akanDatang,
        statusLabel: 'Akan Datang',
        progress: 0.0,
        remainingText: remainingStr,
        remainingDuration: diff,
      );
    } else if (now.isBefore(endDt)) {
      final totalMinutes = endDt.difference(startDt).inMinutes;
      final elapsedMinutes = now.difference(startDt).inMinutes;
      final progress = totalMinutes > 0 ? (elapsedMinutes / totalMinutes).clamp(0.0, 1.0) : 0.0;

      final diff = endDt.difference(now);
      final hours = diff.inHours;
      final mins = diff.inMinutes % 60;
      final percentStr = (progress * 100).toInt();
      final remainingStr = hours > 0
          ? 'Sisa ${hours}j ${mins}m ($percentStr% Berjalan)'
          : 'Sisa ${mins}m ($percentStr% Berjalan)';

      return ClassStatusResult(
        status: ClassStatus.berlangsung,
        statusLabel: 'Kuliah Sedang Berlangsung',
        progress: progress,
        remainingText: remainingStr,
        remainingDuration: diff,
      );
    } else {
      return const ClassStatusResult(
        status: ClassStatus.selesai,
        statusLabel: 'Selesai',
        progress: 1.0,
        remainingText: 'Selesai',
        remainingDuration: Duration.zero,
      );
    }
  }

  /// Computes the exact `due_at` for next_session mode (PRD Section 1.7):
  /// "titik acuan = created_at tugas; due_at = waktu mulai slot pertama
  /// (dalam rentang valid_from - valid_until) setelah titik acuan.
  /// Nilai ini disimpan agar tidak 'bergeser terus' seiring waktu.
  /// Hitung ulang hanya saat jadwal mata kuliah berubah, dan hanya untuk tugas
  /// yang belum selesai dan belum lewat tenggat."
  static DateTime? calculateNextSession({
    required DateTime createdAt,
    required List<ScheduleSlot> slots,
    DateTime? validFrom,
    DateTime? validUntil,
  }) {
    if (slots.isEmpty) return null;

    DateTime? earliestNext;

    // Search up to 14 days ahead of createdAt to find the next valid session
    for (int dayOffset = 0; dayOffset <= 14; dayOffset++) {
      final candidateDate = createdAt.add(Duration(days: dayOffset));
      final candidateWeekday = candidateDate.weekday; // 1 = Monday ... 7 = Sunday

      // Check date bounds if provided
      if (validFrom != null && candidateDate.isBefore(DateTime(validFrom.year, validFrom.month, validFrom.day))) {
        continue;
      }
      if (validUntil != null && candidateDate.isAfter(DateTime(validUntil.year, validUntil.month, validUntil.day, 23, 59, 59))) {
        continue;
      }

      for (final slot in slots) {
        if (slot.day == candidateWeekday) {
          final slotStart = timeToDateTime(candidateDate, slot.startTime);
          if (slotStart.isAfter(createdAt)) {
            if (earliestNext == null || slotStart.isBefore(earliestNext)) {
              earliestNext = slotStart;
            }
          }
        }
      }

      // If we found the earliest occurrence, we can return it once all matching slots for that day have been compared
      if (earliestNext != null) {
        return earliestNext;
      }
    }

    return null;
  }

  /// Formats next session due date for display (e.g. "Sesi Kamis, 27 Okt • 13:00 WITA")
  static String formatNextSessionText(DateTime dueAt) {
    const dayNames = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

    final dayName = dayNames[dueAt.weekday];
    final day = dueAt.day;
    final month = monthNames[dueAt.month];
    final hour = dueAt.hour.toString().padLeft(2, '0');
    final minute = dueAt.minute.toString().padLeft(2, '0');

    return 'Sesi $dayName, $day $month • $hour:$minute WITA';
  }

  /// Formats human countdown text (e.g. "Sisa 33j", "Jatuh tempo hari ini", "Terlambat")
  static String getCountdownText({
    required DateTime now,
    required DateTime dueAt,
    required bool isCompleted,
  }) {
    if (isCompleted) return 'Selesai';

    final diff = dueAt.difference(now);
    if (diff.isNegative) {
      final pastHours = (-diff.inHours);
      if (pastHours >= 24) {
        final days = pastHours ~/ 24;
        return 'Terlambat $days hari';
      }
      return 'Terlambat ${-diff.inMinutes} menit';
    }

    if (diff.inHours < 24) {
      if (diff.inHours == 0) {
        return 'Sisa ${diff.inMinutes} menit';
      }
      return 'Sisa ${diff.inHours}j ${diff.inMinutes % 60}m';
    } else {
      final days = diff.inDays;
      return 'Sisa $days hari';
    }
  }

  /// Formats date header (e.g., "Rabu, 26 Okt • 14:15 WITA")
  static String formatLiveClock(DateTime dateTime) {
    const dayNames = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

    final dayName = dayNames[dateTime.weekday];
    final day = dateTime.day;
    final month = monthNames[dateTime.month];
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$dayName, $day $month • $hour:$minute WITA';
  }
}
