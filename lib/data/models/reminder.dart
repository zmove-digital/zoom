enum ReminderRepeat { none, daily, weekly, monthly }

ReminderRepeat reminderRepeatFromName(String? name) {
  return ReminderRepeat.values.firstWhere(
    (ReminderRepeat r) => r.name == name,
    orElse: () => ReminderRepeat.none,
  );
}

class Reminder {
  Reminder({
    required this.id,
    required this.title,
    required this.dateTime,
    this.message = '',
    this.repeat = ReminderRepeat.none,
    this.enabled = true,
    this.soundPath,
    this.linkedType,
    this.linkedId,
  });

  final String id;
  String title;
  DateTime dateTime;
  String message;
  ReminderRepeat repeat;
  bool enabled;
  String? soundPath;
  String? linkedType;
  String? linkedId;

  Reminder copyWith({
    String? title,
    DateTime? dateTime,
    String? message,
    ReminderRepeat? repeat,
    bool? enabled,
    String? soundPath,
    String? linkedType,
    String? linkedId,
  }) {
    return Reminder(
      id: id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      message: message ?? this.message,
      repeat: repeat ?? this.repeat,
      enabled: enabled ?? this.enabled,
      soundPath: soundPath ?? this.soundPath,
      linkedType: linkedType ?? this.linkedType,
      linkedId: linkedId ?? this.linkedId,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'dateTime': dateTime.toIso8601String(),
        'message': message,
        'repeat': repeat.name,
        'enabled': enabled,
        'soundPath': soundPath,
        'linkedType': linkedType,
        'linkedId': linkedId,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        dateTime: DateTime.parse(json['dateTime'] as String),
        message: json['message'] as String? ?? '',
        repeat: reminderRepeatFromName(json['repeat'] as String?),
        enabled: json['enabled'] as bool? ?? true,
        soundPath: json['soundPath'] as String?,
        linkedType: json['linkedType'] as String?,
        linkedId: json['linkedId'] as String?,
      );
}
