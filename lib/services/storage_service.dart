import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word_entry.dart';
import '../models/note_entry.dart';

class StorageService {
  static const _wordsKey  = 'surge_words';
  static const _notesKey  = 'surge_notes';
  static const _streakKey = 'surge_streak';
  static const _lastKey   = 'surge_last_open';
  static const _wotdKey   = 'surge_wotd';
  static const _wotdDate  = 'surge_wotd_date';
  static const _daysKey   = 'surge_active_days';

  static StorageService? _i;
  late SharedPreferences _p;

  StorageService._();
  static Future<StorageService> get() async {
    if (_i == null) {
      _i = StorageService._();
      _i!._p = await SharedPreferences.getInstance();
    }
    return _i!;
  }

  // ── Words ──────────────────────────────────────────────
  List<WordEntry> getWords() {
    final raw = _p.getString(_wordsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => WordEntry.fromJson(e)).toList();
  }

  Future<void> saveWords(List<WordEntry> words) =>
      _p.setString(_wordsKey, jsonEncode(words.map((e) => e.toJson()).toList()));

  Future<void> addWord(WordEntry w) async {
    final words = getWords()..insert(0, w);
    await saveWords(words);
  }

  Future<void> updateWord(WordEntry updated) async {
    final words = getWords();
    final i = words.indexWhere((w) => w.id == updated.id);
    if (i != -1) { words[i] = updated; await saveWords(words); }
  }

  Future<void> deleteWord(String id) async {
    final words = getWords()..removeWhere((w) => w.id == id);
    await saveWords(words);
  }

  // ── Notes ──────────────────────────────────────────────
  List<NoteEntry> getNotes() {
    final raw = _p.getString(_notesKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => NoteEntry.fromJson(e)).toList();
  }

  Future<void> saveNotes(List<NoteEntry> notes) =>
      _p.setString(_notesKey, jsonEncode(notes.map((e) => e.toJson()).toList()));

  Future<void> addNote(NoteEntry n) async {
    final notes = getNotes()..insert(0, n);
    await saveNotes(notes);
  }

  Future<void> updateNote(NoteEntry updated) async {
    final notes = getNotes();
    final i = notes.indexWhere((n) => n.id == updated.id);
    if (i != -1) { notes[i] = updated; await saveNotes(notes); }
  }

  Future<void> deleteNote(String id) async {
    final notes = getNotes()..removeWhere((n) => n.id == id);
    await saveNotes(notes);
  }

  // ── Streak ─────────────────────────────────────────────
  int getStreak() => _p.getInt(_streakKey) ?? 0;

  Future<void> updateStreak() async {
    final lastStr  = _p.getString(_lastKey);
    final today    = DateTime.now();
    final todayStr = _fmt(today);
    if (lastStr == null) {
      await _p.setInt(_streakKey, 1);
    } else if (lastStr != todayStr) {
      final last = DateTime.parse(lastStr);
      final diff = today.difference(last).inDays;
      await _p.setInt(_streakKey, diff == 1 ? getStreak() + 1 : 1);
    }
    await _p.setString(_lastKey, todayStr);
    final days = List<String>.from(_p.getStringList(_daysKey) ?? []);
    if (!days.contains(todayStr)) {
      days.add(todayStr);
      await _p.setStringList(_daysKey, days);
    }
  }

  List<String> getActiveDays() => _p.getStringList(_daysKey) ?? [];

  // ── Word of the Day ────────────────────────────────────
  Map<String, dynamic>? getCachedWotd() {
    final raw  = _p.getString(_wotdKey);
    final date = _p.getString(_wotdDate);
    if (raw == null || date == null) return null;
    if (date != _fmt(DateTime.now())) return null;
    return jsonDecode(raw);
  }

  Future<void> cacheWotd(Map<String, dynamic> w) async {
    await _p.setString(_wotdKey,  jsonEncode(w));
    await _p.setString(_wotdDate, _fmt(DateTime.now()));
  }

  // ── Stats ──────────────────────────────────────────────
  Map<String, int> getStats() {
    final words = getWords();
    return {
      'total':    words.length,
      'mastered': words.where((w) => w.mastery == MasteryLevel.mastered).length,
      'familiar': words.where((w) => w.mastery == MasteryLevel.familiar).length,
      'learning': words.where((w) => w.mastery == MasteryLevel.learning).length,
      'streak':   getStreak(),
    };
  }

  Future<void> clearAll() async {
    await saveWords([]);
    await saveNotes([]);
    await _p.remove(_streakKey);
    await _p.remove(_lastKey);
    await _p.remove(_daysKey);
  }

  // ── API Key ────────────────────────────────────────────
  String getApiKey() => _p.getString('surge_api_key') ?? '';

  Future<void> saveApiKey(String key) =>
      _p.setString('surge_api_key', key);

  // ── Daily Challenge cache ──────────────────────────────
  Map<String, dynamic>? getCachedChallenge() {
    final raw  = _p.getString('surge_challenge');
    final date = _p.getString('surge_challenge_date');
    if (raw == null || date == null) return null;
    if (date != _fmt(DateTime.now())) return null;
    return jsonDecode(raw);
  }

  Future<void> cacheChallenge(Map<String, dynamic> c) async {
    await _p.setString('surge_challenge', jsonEncode(c));
    await _p.setString('surge_challenge_date', _fmt(DateTime.now()));
  }

  Future<void> clearChallengeCache() async {
    await _p.remove('surge_challenge');
    await _p.remove('surge_challenge_date');
  }

  // ── Format ─────────────────────────────────────────────
  String _fmt(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}