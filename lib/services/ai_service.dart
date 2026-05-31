import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  static String apiKey = '';

  // ── Core helper ────────────────────────────────────────
  static Future<String?> _ask(String prompt, {double temp = 0.4, int tokens = 400}) async {
    if (apiKey.isEmpty) return null;
    try {
      final res = await http.post(
        Uri.parse('$_endpoint?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'temperature': temp, 'maxOutputTokens': tokens},
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['candidates'][0]['content']['parts'][0]['text'] as String).trim();
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
    final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
    final s = clean.indexOf('{');
    final e = clean.lastIndexOf('}');
    if (s == -1 || e == -1) return null;
    try { return jsonDecode(clean.substring(s, e + 1)); } catch (_) { return null; }
  }

  // ── Fill word details ──────────────────────────────────
  static Future<Map<String, dynamic>?> fillWordDetails(String word) async {
    final text = await _ask(
      'For the English word or phrase "$word", return ONLY a raw JSON object, no markdown, no backticks:\n'
      '{"definition":"clear concise definition","example":"one natural example sentence",'
      '"partOfSpeech":"noun or verb or adjective etc","synonyms":["word1","word2","word3"]}',
      temp: 0.3, tokens: 300,
    );
    return _parseJson(text);
  }

  // ── Word of the Day ────────────────────────────────────
  static Future<Map<String, dynamic>?> getWordOfTheDay() async {
    if (apiKey.isEmpty) return _fallbackWotd();
    final text = await _ask(
      'Pick one interesting advanced English word, idiom, or phrasal verb. '
      'Return ONLY a raw JSON object, no markdown, no backticks:\n'
      '{"word":"the word or phrase","definition":"clear definition",'
      '"example":"natural example sentence","partOfSpeech":"noun or verb etc",'
      '"funFact":"one interesting fact about this word origin or usage"}',
      temp: 0.7, tokens: 300,
    );
    return _parseJson(text) ?? _fallbackWotd();
  }

  // ── Daily Challenge ────────────────────────────────────
  static Future<Map<String, dynamic>?> getDailyChallenge(List<String> words) async {
    if (apiKey.isEmpty) return _fallbackChallenge();
    final wordList = words.take(5).join(', ');
    final text = await _ask(
      'Create a daily English writing challenge using some of these words: $wordList. '
      'Return ONLY a raw JSON object, no markdown, no backticks:\n'
      '{"challenge":"write one sentence or two using at least 2 of these words naturally",'
      '"words":["word1","word2"],'
      '"tip":"a quick tip on how to use these words naturally",'
      '"difficulty":"easy or medium or hard"}',
      temp: 0.8, tokens: 300,
    );
    return _parseJson(text) ?? _fallbackChallenge();
  }

  static Future<Map<String, dynamic>?> gradeDailyChallenge(
      String challenge, String userAnswer, List<String> targetWords) async {
    if (apiKey.isEmpty) return _fallbackGrade();
    final text = await _ask(
      'Grade this English writing challenge response.\n'
      'Challenge: "$challenge"\n'
      'Target words to use: ${targetWords.join(', ')}\n'
      'Student answer: "$userAnswer"\n'
      'Return ONLY a raw JSON object, no markdown, no backticks:\n'
      '{"score":85,"grade":"B+","usedWords":["word1"],"missedWords":["word2"],'
      '"feedback":"specific helpful feedback in 1-2 sentences",'
      '"improvedVersion":"a better version of their sentence if needed, or empty string if good"}',
      temp: 0.3, tokens: 400,
    );
    return _parseJson(text) ?? _fallbackGrade();
  }

  // ── Context Mode ───────────────────────────────────────
  static Future<Map<String, dynamic>?> getWordContext(String word) async {
    if (apiKey.isEmpty) return null;
    final text = await _ask(
      'For the English word or phrase "$word", give real-world usage context. '
      'Return ONLY a raw JSON object, no markdown, no backticks:\n'
      '{"contexts":['
        '{"source":"Twitter/X","example":"realistic tweet using this word naturally"},'
        '{"source":"News headline","example":"realistic news headline using this word"},'
        '{"source":"Casual conversation","example":"realistic casual dialogue using this word"},'
        '{"source":"Business/Professional","example":"realistic professional usage"}'
      '],'
      '"register":"formal or informal or neutral",'
      '"commonMistake":"one common mistake people make with this word",'
      '"nativeTip":"one tip on how native speakers actually use this word"}',
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
    'funFact': 'Coined by Horace Walpole in 1754, inspired by a Persian fairy tale "The Three Princes of Serendip".',
  };

  static Map<String, dynamic> _fallbackChallenge() => {
    'challenge': 'Write two sentences describing your morning using vivid, precise vocabulary.',
    'words': [],
    'tip': 'Try to replace common words like "good" or "nice" with more specific alternatives.',
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