import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../models/word_entry.dart';
import '../services/storage_service.dart';
import '../widgets/surge_widgets.dart';

class DrillScreen extends StatefulWidget {
  const DrillScreen({super.key});
  @override State<DrillScreen> createState() => _DrillScreenState();
}

class _DrillScreenState extends State<DrillScreen>
    with SingleTickerProviderStateMixin {
  StorageService? _storage;
  List<WordEntry> _deck = [];
  int  _index   = 0;
  bool _flipped = false;
  bool _done    = false;
  bool _loading = true;
  int  _gotIt   = 0;
  int  _again   = 0;

  late AnimationController _flipCtrl;
  late Animation<double>   _flipAnim;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350));
    _flipAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut));
    _init();
  }

  Future<void> _init() async {
    _storage = await StorageService.get();
    _buildDeck();
  }

  void _buildDeck() {
    if (_storage == null) return;
    final all = _storage!.getWords();
    if (all.isEmpty) {
      setState(() { _deck = []; _loading = false; });
      return;
    }
    final deck = [...all]..shuffle(Random());
    deck.sort((a, b) => a.mastery.index.compareTo(b.mastery.index));
    setState(() {
      _deck    = deck.take(20).toList();
      _index   = 0;
      _flipped = false;
      _done    = false;
      _gotIt   = 0;
      _again   = 0;
      _loading = false;
    });
    _flipCtrl.reset();
  }

  void _flip() {
    HapticFeedback.lightImpact();
    if (!_flipped) {
      _flipCtrl.forward();
    } else {
      _flipCtrl.reverse();
    }
    setState(() => _flipped = !_flipped);
  }

  Future<void> _answer(bool correct) async {
    HapticFeedback.mediumImpact();
    final word = _deck[_index];
    final newMastery = correct
      ? (word.mastery == MasteryLevel.learning
          ? MasteryLevel.familiar
          : MasteryLevel.mastered)
      : MasteryLevel.learning;

    await _storage!.updateWord(word.copyWith(
      mastery:     newMastery,
      reviewCount: word.reviewCount + 1,
      missCount:   correct ? word.missCount : word.missCount + 1,
    ));

    setState(() {
      if (correct) _gotIt++; else _again++;
      if (_index + 1 >= _deck.length) {
        _done = true;
      } else {
        _index++;
        _flipped = false;
        _flipCtrl.reset();
      }
    });
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: SurgeColors.background,
        body: Center(child: CircularProgressIndicator(
          color: SurgeColors.cyan, strokeWidth: 2)),
      );
    }
    if (_deck.isEmpty) {
      return Scaffold(
        backgroundColor: SurgeColors.background,
        body: const SafeArea(child: EmptyState(
          emoji: '🃏',
          title: 'No words to drill',
          subtitle: 'Add some words to your bank first')),
      );
    }
    if (_done) return _buildResults();
    return _buildDrillView();
  }

  Widget _buildDrillView() {
    final word     = _deck[_index];
    final progress = _index / _deck.length;

    return Scaffold(
      backgroundColor: SurgeColors.background,
      body: SafeArea(
        child: Column(children: [
          // ── Header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(children: [
              Text('Drill', style: GoogleFonts.dmSans(
                fontSize: 20, fontWeight: FontWeight.w800,
                color: SurgeColors.textPrimary)),
              const Spacer(),
              Text('${_index + 1} of ${_deck.length}',
                style: GoogleFonts.dmSans(
                  fontSize: 13, color: SurgeColors.textMuted)),
            ]),
          ),

          const SizedBox(height: 12),

          // ── Progress bar ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: SurgeColors.card,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  SurgeColors.cyan),
                minHeight: 3,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Score pills + tag ────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              _pill('✅  $_gotIt', SurgeColors.success),
              const SizedBox(width: 8),
              _pill('↩  $_again', SurgeColors.error),
              const Spacer(),
              TagChip(tag: word.tag),
            ]),
          ),

          const SizedBox(height: 14),

          // ── Flip card ────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: _flip,
                child: AnimatedBuilder(
                  animation: _flipAnim,
                  builder: (context, _) {
                    final angle  = _flipAnim.value * pi;
                    final isBack = angle > pi / 2;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      child: isBack
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(pi),
                            child: _buildCardBack(word))
                        : _buildCardFront(word),
                    );
                  },
                ),
              ),
            ),
          ),

          // ── Hint or buttons ──────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _flipped
              ? _buildActions()
              : Padding(
                  key: const ValueKey('hint'),
                  padding: const EdgeInsets.only(bottom: 12, top: 4),
                  child: Text('Tap card to reveal',
                    style: GoogleFonts.dmSans(
                      fontSize: 12, color: SurgeColors.textMuted)),
                ),
          ),

          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  Widget _buildCardFront(WordEntry word) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: SurgeColors.card,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: SurgeColors.border),
    ),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('WORD', style: GoogleFonts.dmSans(
        fontSize: 10, letterSpacing: 2.5,
        color: SurgeColors.textMuted, fontWeight: FontWeight.w700)),
      const SizedBox(height: 18),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(word.word,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 34, fontWeight: FontWeight.w900,
            color: SurgeColors.textPrimary, letterSpacing: -0.5)),
      ),
      if (word.partOfSpeech.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(word.partOfSpeech, style: GoogleFonts.dmSans(
          fontSize: 13, color: SurgeColors.textMuted,
          fontStyle: FontStyle.italic)),
      ],
      const SizedBox(height: 28),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.touch_app_rounded,
          size: 14, color: SurgeColors.textMuted.withOpacity(0.5)),
        const SizedBox(width: 5),
        Text('tap to flip', style: GoogleFonts.dmSans(
          fontSize: 12, color: SurgeColors.textMuted.withOpacity(0.5))),
      ]),
    ]),
  );

  Widget _buildCardBack(WordEntry word) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: SurgeColors.card,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: SurgeColors.violet.withOpacity(0.25)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DEFINITION', style: GoogleFonts.dmSans(
          fontSize: 10, letterSpacing: 2,
          color: SurgeColors.violet, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Text(word.definition, style: GoogleFonts.dmSans(
          fontSize: 16, color: SurgeColors.textPrimary,
          height: 1.6, fontWeight: FontWeight.w500)),
        if (word.example.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SurgeColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SurgeColors.border)),
            child: Text('💬  ${word.example}',
              style: GoogleFonts.dmSans(
                fontSize: 13, color: SurgeColors.textSecondary,
                fontStyle: FontStyle.italic, height: 1.5)),
          ),
        ],
        if (word.synonyms.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6,
            children: word.synonyms.map((s) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: SurgeColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SurgeColors.border)),
              child: Text(s, style: GoogleFonts.dmSans(
                fontSize: 12, color: SurgeColors.textSecondary)),
            )).toList()),
        ],
      ],
    ),
  );

  Widget _buildActions() => Padding(
    key: const ValueKey('actions'),
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
    child: Row(children: [
      Expanded(child: GestureDetector(
        onTap: () => _answer(false),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: SurgeColors.error.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: SurgeColors.error.withOpacity(0.3)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('↩', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 7),
              Text('Again', style: GoogleFonts.dmSans(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: SurgeColors.error)),
            ]),
        ),
      )),
      const SizedBox(width: 10),
      Expanded(child: GestureDetector(
        onTap: () => _answer(true),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: SurgeColors.success.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: SurgeColors.success.withOpacity(0.3)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('✓', style: TextStyle(
                fontSize: 16, color: SurgeColors.success)),
              const SizedBox(width: 7),
              Text('Got it', style: GoogleFonts.dmSans(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: SurgeColors.success)),
            ]),
        ),
      )),
    ]).animate().fadeIn(duration: 200.ms).slideY(begin: 0.15),
  );

  Widget _buildResults() => Scaffold(
    backgroundColor: SurgeColors.background,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: SurgeColors.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: SurgeColors.border)),
              child: const Center(
                child: Text('⚡', style: TextStyle(fontSize: 36))),
            ),
            const SizedBox(height: 20),
            Text('Session done', style: GoogleFonts.dmSans(
              fontSize: 24, fontWeight: FontWeight.w800,
              color: SurgeColors.textPrimary)),
            const SizedBox(height: 6),
            Text('${_deck.length} cards reviewed',
              style: GoogleFonts.dmSans(
                fontSize: 14, color: SurgeColors.textMuted)),
            const SizedBox(height: 36),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _resultStat('Got it',  '$_gotIt',  SurgeColors.success),
              Container(width: 1, height: 40,
                color: SurgeColors.border,
                margin: const EdgeInsets.symmetric(horizontal: 24)),
              _resultStat('Again',  '$_again',  SurgeColors.error),
              Container(width: 1, height: 40,
                color: SurgeColors.border,
                margin: const EdgeInsets.symmetric(horizontal: 24)),
              _resultStat('Score',
                '${((_gotIt / _deck.length) * 100).round()}%',
                SurgeColors.cyan),
            ]),
            const SizedBox(height: 44),
            SurgeButton(
              label: 'Drill Again',
              icon: Icons.refresh_rounded,
              onTap: _buildDeck),
          ],
        ).animate().fadeIn(duration: 350.ms),
      ),
    ),
  );

  Widget _resultStat(String label, String value, Color color) =>
    Column(children: [
      Text(value, style: GoogleFonts.dmSans(
        fontSize: 28, fontWeight: FontWeight.w900, color: color)),
      const SizedBox(height: 3),
      Text(label, style: GoogleFonts.dmSans(
        fontSize: 12, color: SurgeColors.textMuted)),
    ]);

  Widget _pill(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.09),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.2))),
    child: Text(text, style: GoogleFonts.dmSans(
      fontSize: 12, fontWeight: FontWeight.w600, color: color)),
  );
}