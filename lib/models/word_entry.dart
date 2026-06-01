enum WordTag { vocabulary, idiom, phrasal, slang, grammar, formal }
enum MasteryLevel { learning, familiar, mastered }

class WordEntry {
  final String id;
  final String word;
  final String definition;
  final String example;
  final String partOfSpeech;
  final List<String> synonyms;
  final WordTag tag;
  MasteryLevel mastery;
  final String personalNote;
  final DateTime addedAt;
  int reviewCount;
  int missCount;

  WordEntry({
    required this.id,
    required this.word,
    required this.definition,
    required this.example,
    this.partOfSpeech = '',
    this.synonyms = const [],
    this.tag = WordTag.vocabulary,
    this.mastery = MasteryLevel.learning,
    this.personalNote = '',
    required this.addedAt,
    this.reviewCount = 0,
    this.missCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'word': word, 'definition': definition,
    'example': example, 'partOfSpeech': partOfSpeech,
    'synonyms': synonyms, 'tag': tag.index,
    'mastery': mastery.index, 'personalNote': personalNote,
    'addedAt': addedAt.toIso8601String(),
    'reviewCount': reviewCount, 'missCount': missCount,
  };

  factory WordEntry.fromJson(Map<String, dynamic> j) => WordEntry(
    id: j['id'], word: j['word'], definition: j['definition'],
    example: j['example'], partOfSpeech: j['partOfSpeech'] ?? '',
    synonyms: List<String>.from(j['synonyms'] ?? []),
    tag: WordTag.values[j['tag'] ?? 0],
    mastery: MasteryLevel.values[j['mastery'] ?? 0],
    personalNote: j['personalNote'] ?? '',
    addedAt: DateTime.parse(j['addedAt']),
    reviewCount: j['reviewCount'] ?? 0,
    missCount: j['missCount'] ?? 0,
  );

  WordEntry copyWith({MasteryLevel? mastery, int? reviewCount, int? missCount}) => WordEntry(
    id: id, word: word, definition: definition, example: example,
    partOfSpeech: partOfSpeech, synonyms: synonyms, tag: tag,
    mastery: mastery ?? this.mastery, personalNote: personalNote,
    addedAt: addedAt,
    reviewCount: reviewCount ?? this.reviewCount,
    missCount: missCount ?? this.missCount,
  );
}
extension WordTagX on WordTag {
  String get label   => const ['Vocab','Idiom','Phrasal','Slang','Grammar','Formal'][index];
  int    get colorHex=> const [0xFF7C6EFA,0xFF4ECDC4,0xFFFF9E7E,0xFFFFD166,0xFF95C8B0,0xFFB8A9FF][index];
  String get emoji   => const ['📖','💬','🔗','😎','✏️','🎓'][index];
}



extension MasteryX on MasteryLevel {
  String get label => const ['Learning','Familiar','Mastered'][index];
  int get colorHex => const [0xFFFF4D6D,0xFFFFB347,0xFF22C55E][index];
}
