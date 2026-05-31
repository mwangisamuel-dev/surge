import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent';

  static String apiKey = '';

  // ── Core helper ────────────────────────────────────────
  static Future<String?> _ask(String prompt,
      {double temp = 0.4, int tokens = 400}) async {
    if (apiKey.isEmpty) return null;
    try {
      final res = await http.post(
        Uri.parse('$_endpoint?key=$apiKey'),
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
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['candidates'][0]['content']['parts'][0]['text'] as String)
            .trim();
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
    } catch (_) {
      return null;
    }
  }

  // ── Fill word details ──────────────────────────────────
  static Future<Map<String, dynamic>?> fillWordDetails(String word) async {
    final text = await _ask(
      'For the English word or phrase "$word" return a JSON object with these exact keys: '
      'definition (string), example (string), partOfSpeech (string), synonyms (array of strings). '
      'Return only valid JSON, nothing else.',
      temp: 0.3,
      tokens: 300,
    );
    return _parseJson(text);
  }

  // ── Word of the Day ────────────────────────────────────
  static Future<Map<String, dynamic>?> getWordOfTheDay() async {
    if (apiKey.isEmpty) return _fallbackWotd();
    final text = await _ask(
      'Pick one interesting advanced English word, idiom, or phrasal verb and return a JSON object '
      'with these exact keys: word (string), definition (string), example (string), '
      'partOfSpeech (string), funFact (string). Return only valid JSON, nothing else.',
      temp: 0.7,
      tokens: 300,
    );
    return _parseJson(text) ?? _fallbackWotd();
  }

  // ── Daily Challenge ────────────────────────────────────
  static Future<Map<String, dynamic>?> getDailyChallenge(
      List<String> words) async {
    if (apiKey.isEmpty) return _fallbackChallenge();
    final wordList = words.take(5).join(', ');
    final text = await _ask(
      'Create a daily English writing challenge using some of these words: $wordList. '
      'Return a JSON object with these exact keys: '
      'challenge (string instruction), words (array of 2 target words from the list), '
      'tip (string), difficulty (string: easy or medium or hard). '
      'Return only valid JSON, nothing else.',
      temp: 0.8,
      tokens: 300,
    );
    return _parseJson(text) ?? _fallbackChallenge();
  }

  static Future<Map<String, dynamic>?> gradeDailyChallenge(
      String challenge, String userAnswer, List<String> targetWords) async {
    if (apiKey.isEmpty) return _fallbackGrade();
    final text = await _ask(
      'Grade this English writing response. '
      'Challenge: "$challenge". '
      'Target words: ${targetWords.join(', ')}. '
      'Student answer: "$userAnswer". '
      'Return a JSON object with these exact keys: '
      'score (integer 0-100), grade (string like A or B+ or C), '
      'usedWords (array of target words the student used), '
      'missedWords (array of target words the student missed), '
      'feedback (string, 1-2 sentences of specific helpful feedback), '
      'improvedVersion (string, better version of their sentence or empty string if good). '
      'Return only valid JSON, nothing else.',
      temp: 0.3,
      tokens: 400,
    );
    return _parseJson(text) ?? _fallbackGrade();
  }

  // ── Context Mode ───────────────────────────────────────
  static Future<Map<String, dynamic>?> getWordContext(String word) async {
    if (apiKey.isEmpty) return null;
    final text = await _ask(
      'For the English word or phrase "$word" provide real-world usage context. '
      'Return a JSON object with these exact keys: '
      'contexts (array of 4 objects each with source string and example string, '
      'sources should be: Twitter/X, News headline, Casual conversation, Business/Professional), '
      'register (string: formal or informal or neutral), '
      'commonMistake (string), nativeTip (string). '
      'Return only valid JSON, nothing else.',
      temp: 0.5,
      tokens: 500,
    );
    return _parseJson(text);
  }

  // ── Fallbacks ──────────────────────────────────────────
  static Map<String, dynamic> _fallbackWotd() => {
        'word': 'Serendipity',
        'definition':
            'The occurrence of events by chance in a happy or beneficial way.',
        'example':
            'Finding that old bookstore was pure serendipity — I discovered my favourite author there.',
        'partOfSpeech': 'noun',
        'funFact':
            'Coined by Horace Walpole in 1754, inspired by a Persian fairy tale "The Three Princes of Serendip".',
      };

  static Map<String, dynamic> _fallbackChallenge() => {
        'challenge':
            'Write two sentences describing your morning using vivid, precise vocabulary.',
        'words': [],
        'tip':
            'Try to replace common words like "good" or "nice" with more specific alternatives.',
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