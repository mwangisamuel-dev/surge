import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  // gemini-2.5-flash works with v1beta for AI Studio keys
  static const _base = 'https://generativelanguage.googleapis.com/v1beta/models';
  static const _model = 'gemini-2.5-flash-preview-05-20';

  static String apiKey = '';

  // ── Core helper ────────────────────────────────────────
  static Future<String?> _ask(String prompt,
      {double temp = 0.4, int tokens = 500}) async {
    if (apiKey.isEmpty) return null;
    try {
      final res = await http.post(
        Uri.parse('$_base/$_model:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [{'text': prompt}]
            }
          ],
          'generationConfig': {
            'temperature': temp,
            'maxOutputTokens': tokens,
          },
        }),
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text == null) {
          print('Gemini: empty response body: ${res.body}');
          return null;
        }
        return (text as String).trim();
      } else {
        print('Gemini ${res.statusCode}: ${res.body}');
        return null;
      }
    } catch (e) {
      print('AiService error: $e');
      return null;
    }
  }

  static Map<String, dynamic>? _parseJson(String? text) {
    if (text == null) return null;
    final clean = text
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
    final s = clean.indexOf('{');
    final e = clean.lastIndexOf('}');
    if (s == -1 || e == -1) return null;
    try {
      return jsonDecode(clean.substring(s, e + 1));
    } catch (err) {
      print('JSON parse error: $err\nRaw: $clean');
      return null;
    }
  }

  // ── Fill word details ──────────────────────────────────
  static Future<Map<String, dynamic>?> fillWordDetails(String word) async {
    final text = await _ask(
      'Return a JSON object for the English word "$word". '
      'Keys: definition (string), example (string), '
      'partOfSpeech (string), synonyms (array of 3 strings). '
      'JSON only, no other text.',
      temp: 0.3, tokens: 300,
    );
    return _parseJson(text);
  }

  // ── Word of the Day ────────────────────────────────────
  static Future<Map<String, dynamic>?> getWordOfTheDay() async {
    if (apiKey.isEmpty) return _fallbackWotd();
    final text = await _ask(
      'Pick one interesting advanced English word or idiom. '
      'Return a JSON object with keys: word, definition, example, '
      'partOfSpeech, funFact. JSON only, no other text.',
      temp: 0.8, tokens: 350,
    );
    return _parseJson(text) ?? _fallbackWotd();
  }

  // ── Quick word suggestions for home screen rotation ───
  static Future<List<Map<String, dynamic>>> getWordSuggestions() async {
    if (apiKey.isEmpty) return _fallbackSuggestions();
    final text = await _ask(
      'Give me 4 different interesting English words or phrases. '
      'Return a JSON array like: '
      '[{"word":"word1","hint":"very short 5 word description"},'
      '{"word":"word2","hint":"very short 5 word description"},'
      '{"word":"word3","hint":"very short 5 word description"},'
      '{"word":"word4","hint":"very short 5 word description"}]. '
      'JSON only, no other text.',
      temp: 0.9, tokens: 300,
    );
    if (text == null) return _fallbackSuggestions();
    final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
    final s = clean.indexOf('[');
    final e = clean.lastIndexOf(']');
    if (s == -1 || e == -1) return _fallbackSuggestions();
    try {
      final list = jsonDecode(clean.substring(s, e + 1)) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return _fallbackSuggestions();
    }
  }

  // ── Daily Challenge ────────────────────────────────────
  static Future<Map<String, dynamic>?> getDailyChallenge(
      List<String> words) async {
    if (apiKey.isEmpty) return _fallbackChallenge();
    final wordList = words.isEmpty
        ? 'eloquent, persevere, nuance'
        : words.take(5).join(', ');
    final text = await _ask(
      'Create an English writing challenge using 2 of these words: $wordList. '
      'Return JSON with keys: challenge (string task), '
      'words (array of exactly 2 words from the list), '
      'tip (string), difficulty (easy or medium or hard). '
      'JSON only, no other text.',
      temp: 0.8, tokens: 300,
    );
    return _parseJson(text) ?? _fallbackChallenge();
  }

  static Future<Map<String, dynamic>?> gradeDailyChallenge(
      String challenge, String userAnswer, List<String> targetWords) async {
    if (apiKey.isEmpty) return _fallbackGrade();
    final text = await _ask(
      'You are an English teacher. Grade this student response.\n'
      'Task: $challenge\n'
      'Target words to use: ${targetWords.join(", ")}\n'
      'Student wrote: "$userAnswer"\n'
      'Return JSON with keys: '
      'score (integer 0-100), '
      'grade (string: A, B+, B, C+, C, D, or F), '
      'usedWords (array of target words student actually used), '
      'missedWords (array of target words student missed), '
      'feedback (string: 1-2 sentences of helpful specific feedback), '
      'improvedVersion (string: rewrite of their sentence if needed, empty string if already good). '
      'JSON only, no other text.',
      temp: 0.2, tokens: 450,
    );
    return _parseJson(text) ?? _fallbackGrade();
  }

  // ── Context Mode ───────────────────────────────────────
  static Future<Map<String, dynamic>?> getWordContext(String word) async {
    if (apiKey.isEmpty) return null;
    final text = await _ask(
      'Show real-world usage of the English word "$word". '
      'Return JSON with keys: '
      'contexts (array of 4 objects, each with source and example, '
      'sources: Twitter/X, News, Casual conversation, Professional), '
      'register (formal or informal or neutral), '
      'commonMistake (string), nativeTip (string). '
      'JSON only, no other text.',
      temp: 0.5, tokens: 500,
    );
    return _parseJson(text);
  }

  // ── Fallbacks ──────────────────────────────────────────
  static Map<String, dynamic> _fallbackWotd() => {
    'word': 'Serendipity',
    'definition': 'The occurrence of events by chance in a happy or beneficial way.',
    'example': 'Finding that old bookstore was pure serendipity — I discovered my favourite author there.',
    'partOfSpeech': 'noun',
    'funFact': 'Coined by Horace Walpole in 1754, inspired by a Persian fairy tale.',
  };

  static List<Map<String, dynamic>> _fallbackSuggestions() => [
    {'word': 'Ephemeral',   'hint': 'Lasting for a very short time'},
    {'word': 'Tenacious',   'hint': 'Holding firm to a goal'},
    {'word': 'Eloquent',    'hint': 'Fluent and persuasive in speech'},
    {'word': 'Perspicacious','hint': 'Having a ready insight'},
  ];

  static Map<String, dynamic> _fallbackChallenge() => {
    'challenge': 'Write two sentences about a goal you have, using vivid and precise vocabulary.',
    'words': [],
    'tip': 'Replace vague words like "good" or "nice" with something more specific.',
    'difficulty': 'easy',
  };

  static Map<String, dynamic> _fallbackGrade() => {
    'score': 0,
    'grade': '—',
    'usedWords': [],
    'missedWords': [],
    'feedback': 'Could not grade — check your API key in Settings.',
    'improvedVersion': '',
  };
}