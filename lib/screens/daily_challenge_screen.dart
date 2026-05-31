import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../widgets/surge_widgets.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});
  @override State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  StorageService? _storage;
  Map<String, dynamic>? _challenge;
  Map<String, dynamic>? _result;
  final _answerCtrl = TextEditingController();
  bool _loading     = false;
  bool _grading     = false;
  bool _submitted   = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _storage = await StorageService.get();
    _loadChallenge();
  }

  Future<void> _loadChallenge() async {
    // Check cache first
    final cached = _storage!.getCachedChallenge();
    if (cached != null) {
      setState(() => _challenge = cached);
      return;
    }
    setState(() => _loading = true);
    final words = _storage!.getWords().map((w) => w.word).toList();
    final c = await AiService.getDailyChallenge(words);
    if (c != null) await _storage!.cacheChallenge(c);
    if (mounted) setState(() { _challenge = c; _loading = false; });
  }

  Future<void> _submit() async {
    final answer = _answerCtrl.text.trim();
    if (answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Write something first!', style: GoogleFonts.dmSans()),
        backgroundColor: SurgeColors.warning));
      return;
    }
    if (AiService.apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Add your API key in Settings first',
          style: GoogleFonts.dmSans()),
        backgroundColor: SurgeColors.error));
      return;
    }
    setState(() => _grading = true);
    final words = List<String>.from(_challenge!['words'] ?? []);
    final result = await AiService.gradeDailyChallenge(
      _challenge!['challenge'] ?? '', answer, words);
    if (mounted) setState(() {
      _result    = result;
      _grading   = false;
      _submitted = true;
    });
  }

  void _reset() {
    setState(() {
      _result    = null;
      _submitted = false;
      _answerCtrl.clear();
    });
    _storage!.clearChallengeCache();
    _loadChallenge();
  }

  @override
  void dispose() { _answerCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SurgeColors.background,
      appBar: AppBar(
        backgroundColor: SurgeColors.background,
        title: Text('Daily Challenge', style: GoogleFonts.dmSans(
          fontWeight: FontWeight.w800, color: SurgeColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 18, color: SurgeColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_submitted)
            TextButton(
              onPressed: _reset,
              child: Text('New', style: GoogleFonts.dmSans(
                color: SurgeColors.cyan, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(
            color: SurgeColors.cyan, strokeWidth: 2))
        : _challenge == null
          ? _buildNoKey()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _submitted ? _buildResults() : _buildChallenge(),
            ),
    );
  }

  Widget _buildNoKey() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const EmptyState(
          emoji: '🔑',
          title: 'API Key Required',
          subtitle: 'Add your Google AI key in Settings to unlock Daily Challenges',
        ),
        const SizedBox(height: 24),
        SurgeButton(
          label: 'Go to Settings',
          icon: Icons.settings_outlined,
          secondary: true,
          onTap: () => Navigator.pop(context),
        ),
      ]),
    ),
  );

  Widget _buildChallenge() {
    final words    = List<String>.from(_challenge!['words'] ?? []);
    final tip      = _challenge!['tip'] ?? '';
    final diff     = _challenge!['difficulty'] ?? 'medium';
    final diffColor = diff == 'easy'
      ? SurgeColors.success
      : diff == 'hard' ? SurgeColors.error : SurgeColors.warning;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Header banner
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [SurgeColors.violet.withOpacity(0.9), SurgeColors.cyan.withOpacity(0.7)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
            color: SurgeColors.violet.withOpacity(0.3),
            blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8)),
              child: Text('TODAY\'S CHALLENGE', style: GoogleFonts.dmSans(
                fontSize: 10, fontWeight: FontWeight.w800,
                color: Colors.white, letterSpacing: 1)),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: diffColor.withOpacity(0.25),
                borderRadius: BorderRadius.circular(8)),
              child: Text(diff.toUpperCase(), style: GoogleFonts.dmSans(
                fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 14),
          Text(_challenge!['challenge'] ?? '', style: GoogleFonts.dmSans(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: Colors.white, height: 1.5)),
        ]),
      ).animate().fadeIn(duration: 350.ms),

      // Target words
      if (words.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text('USE THESE WORDS', style: GoogleFonts.dmSans(
          fontSize: 11, letterSpacing: 2,
          color: SurgeColors.textMuted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: words.map((w) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: SurgeColors.violet.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SurgeColors.violet.withOpacity(0.3)),
            ),
            child: Text(w, style: GoogleFonts.dmSans(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: SurgeColors.violet)),
          )).toList(),
        ).animate().fadeIn(delay: 80.ms),
      ],

      // Tip
      if (tip.isNotEmpty) ...[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: SurgeColors.cyan.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SurgeColors.cyan.withOpacity(0.2)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('💡 ', style: TextStyle(fontSize: 14)),
            Expanded(child: Text(tip, style: GoogleFonts.dmSans(
              fontSize: 13, color: SurgeColors.textSecondary, height: 1.5))),
          ]),
        ).animate().fadeIn(delay: 120.ms),
      ],

      // Answer input
      const SizedBox(height: 24),
      Text('YOUR ANSWER', style: GoogleFonts.dmSans(
        fontSize: 11, letterSpacing: 2,
        color: SurgeColors.textMuted, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      TextField(
        controller: _answerCtrl,
        maxLines: 5,
        style: GoogleFonts.dmSans(
          fontSize: 15, color: SurgeColors.textPrimary, height: 1.6),
        decoration: InputDecoration(
          hintText: 'Write your sentence(s) here...',
          hintStyle: GoogleFonts.dmSans(
            fontSize: 14, color: SurgeColors.textMuted),
          alignLabelWithHint: true,
        ),
      ).animate().fadeIn(delay: 160.ms),

      const SizedBox(height: 24),
      SurgeButton(
        label: 'Submit for Grading',
        icon: Icons.send_rounded,
        loading: _grading,
        onTap: _submit,
      ).animate().fadeIn(delay: 200.ms),

      const SizedBox(height: 40),
    ]);
  }

  Widget _buildResults() {
    if (_result == null) return const SizedBox.shrink();

    final score    = _result!['score'] ?? 0;
    final grade    = _result!['grade'] ?? '—';
    final feedback = _result!['feedback'] ?? '';
    final improved = _result!['improvedVersion'] ?? '';
    final used     = List<String>.from(_result!['usedWords'] ?? []);
    final missed   = List<String>.from(_result!['missedWords'] ?? []);

    final scoreColor = score >= 80
      ? SurgeColors.success
      : score >= 60 ? SurgeColors.warning : SurgeColors.error;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Score card
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: SurgeColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scoreColor.withOpacity(0.3)),
          boxShadow: [BoxShadow(
            color: scoreColor.withOpacity(0.15),
            blurRadius: 20)],
        ),
        child: Column(children: [
          Text(grade, style: GoogleFonts.dmSans(
            fontSize: 56, fontWeight: FontWeight.w900,
            color: scoreColor, height: 1)),
          const SizedBox(height: 4),
          Text('$score / 100', style: GoogleFonts.dmSans(
            fontSize: 16, color: SurgeColors.textMuted,
            fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          // Score bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: SurgeColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              minHeight: 6,
            ),
          ),
        ]),
      ).animate().fadeIn(duration: 400.ms).scale(
        begin: const Offset(0.9, 0.9)),

      // Your answer
      const SizedBox(height: 20),
      Text('YOUR ANSWER', style: GoogleFonts.dmSans(
        fontSize: 11, letterSpacing: 2,
        color: SurgeColors.textMuted, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SurgeColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SurgeColors.border),
        ),
        child: Text(_answerCtrl.text, style: GoogleFonts.dmSans(
          fontSize: 14, color: SurgeColors.textSecondary, height: 1.6)),
      ).animate().fadeIn(delay: 100.ms),

      // Words used / missed
      if (used.isNotEmpty || missed.isNotEmpty) ...[
        const SizedBox(height: 20),
        Row(children: [
          if (used.isNotEmpty) Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ USED', style: GoogleFonts.dmSans(
                fontSize: 11, letterSpacing: 1,
                color: SurgeColors.success, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: used.map((w) =>
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: SurgeColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: SurgeColors.success.withOpacity(0.3))),
                  child: Text(w, style: GoogleFonts.dmSans(
                    fontSize: 12, color: SurgeColors.success,
                    fontWeight: FontWeight.w600)),
                )).toList()),
            ],
          )),
          if (missed.isNotEmpty) Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('❌ MISSED', style: GoogleFonts.dmSans(
                fontSize: 11, letterSpacing: 1,
                color: SurgeColors.error, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: missed.map((w) =>
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: SurgeColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: SurgeColors.error.withOpacity(0.3))),
                  child: Text(w, style: GoogleFonts.dmSans(
                    fontSize: 12, color: SurgeColors.error,
                    fontWeight: FontWeight.w600)),
                )).toList()),
            ],
          )),
        ]).animate().fadeIn(delay: 150.ms),
      ],

      // Feedback
      if (feedback.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text('FEEDBACK', style: GoogleFonts.dmSans(
          fontSize: 11, letterSpacing: 2,
          color: SurgeColors.textMuted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SurgeColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SurgeColors.cyan.withOpacity(0.2))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🎯 ', style: TextStyle(fontSize: 16)),
            Expanded(child: Text(feedback, style: GoogleFonts.dmSans(
              fontSize: 14, color: SurgeColors.textSecondary, height: 1.6))),
          ]),
        ).animate().fadeIn(delay: 200.ms),
      ],

      // Improved version
      if (improved.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text('IMPROVED VERSION', style: GoogleFonts.dmSans(
          fontSize: 11, letterSpacing: 2,
          color: SurgeColors.textMuted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [SurgeColors.violet.withOpacity(0.1), SurgeColors.cyan.withOpacity(0.05)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SurgeColors.violet.withOpacity(0.2))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('✨ ', style: TextStyle(fontSize: 16)),
            Expanded(child: Text(improved, style: GoogleFonts.dmSans(
              fontSize: 14, color: SurgeColors.textPrimary,
              fontStyle: FontStyle.italic, height: 1.6))),
          ]),
        ).animate().fadeIn(delay: 250.ms),
      ],

      const SizedBox(height: 24),
      SurgeButton(
        label: 'New Challenge',
        icon: Icons.refresh_rounded,
        onTap: _reset,
      ).animate().fadeIn(delay: 300.ms),

      const SizedBox(height: 40),
    ]);
  }
}