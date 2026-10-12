enum Mood { great, good, neutral, bad, awful }

Mood moodFromName(String? name) {
  return Mood.values.firstWhere(
    (Mood m) => m.name == name,
    orElse: () => Mood.neutral,
  );
}

class AgendaEntry {
  AgendaEntry({
    required this.id,
    required this.date,
    this.title = '',
    this.content = '',
    this.mood = Mood.neutral,
    this.colorHex = '6C5CE7',
    this.tags = const <String>[],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  DateTime date;
  String title;
  String content;
  Mood mood;
  String colorHex;
  List<String> tags;
  final DateTime createdAt;
  DateTime updatedAt;

  AgendaEntry copyWith({
    DateTime? date,
    String? title,
    String? content,
    Mood? mood,
    String? colorHex,
    List<String>? tags,
  }) {
    return AgendaEntry(
      id: id,
      date: date ?? this.date,
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      colorHex: colorHex ?? this.colorHex,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'date': date.toIso8601String(),
        'title': title,
        'content': content,
        'mood': mood.name,
        'colorHex': colorHex,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AgendaEntry.fromJson(Map<String, dynamic> json) => AgendaEntry(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        mood: moodFromName(json['mood'] as String?),
        colorHex: json['colorHex'] as String? ?? '6C5CE7',
        tags: (json['tags'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) => e.toString())
            .toList(),
        createdAt: json['createdAt'] == null
            ? null
            : DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] == null
            ? null
            : DateTime.parse(json['updatedAt'] as String),
      );
}
