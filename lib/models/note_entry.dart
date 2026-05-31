class NoteEntry {
  final String id;
  String title;
  String body;
  final DateTime createdAt;
  DateTime updatedAt;

  NoteEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'body': body,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory NoteEntry.fromJson(Map<String, dynamic> j) => NoteEntry(
    id: j['id'], title: j['title'], body: j['body'],
    createdAt: DateTime.parse(j['createdAt']),
    updatedAt: DateTime.parse(j['updatedAt']),
  );
}
