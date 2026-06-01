import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../models/word_entry.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';
import '../widgets/surge_widgets.dart';
import 'add_word_screen.dart';
import 'word_detail_screen.dart';
import 'settings_screen.dart';
import 'daily_challenge_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StorageService? _storage;
  Map<String, dynamic>? _wotd;
  Map<String, int> _stats = {};
  List<WordEntry> _recent = [];
  bool _loadingWotd = false;

  // Always-available rotating suggestions
  final List<Map<String, dynamic>> _suggestions = [
    {'word': 'Ephemeral',      'hint': 'Lasting for a very short time'},
    {'word': 'Tenacious',      'hint': 'Holding firm despite opposition'},
    {'word': 'Eloquent',       'hint': 'Fluent and persuasive in speech'},
    {'word': 'Perspicacious',  'hint': 'Quick to notice and understand things'},
    {'word': 'Sanguine',       'hint': 'Optimistic especially in difficulties'},
    {'word': 'Equivocate',     'hint': 'Use vague language to avoid commitment'},
    {'word': 'Nonchalant',     'hint': 'Calm and casually unconcerned'},
    {'word': 'Insidious',      'hint': 'Proceeding harmfully in a subtle way'},
  ];

  int _suggestionIndex = 0;
  Timer? _suggestionTimer;

  @override
  void initState() {
    super.initState();
    _init();
    // Start rotating immediately — no API needed
    _suggestionTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        _suggestionIndex = (_suggestionIndex + 1) % _suggestions.length;
      });
    });
  }

  Future<void> _init() async {
    _storage = await StorageService.get();
    await _storage!.updateStreak();
    _refresh();
    _loadWotd();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _stats  = _storage!.getStats();
      _recent = _storage!.getWords().take(4).toList();
    });
  }

  Future<void> _loadWotd() async {
    final cached = _storage!.getCachedWotd();
    if (cached != null) { setState(() => _wotd = cached); return; }
    setState(() => _loadingWotd = true);
    final fresh = await AiService.getWordOfTheDay();
    if (fresh != null) await _storage!.cacheWotd(fresh);
    if (mounted) setState(() { _wotd = fresh; _loadingWotd = false; });
  }

  @override
  void dispose() {
    _suggestionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SurgeColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: SurgeColors.violet,
          backgroundColor: SurgeColors.card,
          onRefresh: () async { _refresh(); await _loadWotd(); },
          child: CustomScrollView(slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildStatsRow()),
            SliverToBoxAdapter(child: _buildWotdCard()),
            SliverToBoxAdapter(child: _buildSuggestions()),
            SliverToBoxAdapter(child: _buildDailyChallenge()),
            SliverToBoxAdapter(child: _buildRecentSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final streak = _stats['streak'] ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_greeting().toUpperCase(), style: GoogleFonts.dmSans(
              fontSize: 11, letterSpacing: 2,
              color: SurgeColors.textMuted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Row(children: [
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [SurgeColors.violet, SurgeColors.cyan],
                ).createShader(b),
                child: Text('SURGE', style: GoogleFonts.dmSans(
                  fontSize: 30, fontWeight: FontWeight.w900,
                  color: Colors.white, letterSpacing: -0.5)),
              ),
              if (streak > 0) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: SurgeColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: SurgeColors.warning.withOpacity(0.3)),
                  ),
                  child: Text('$streak day streak 🔥',
                    style: GoogleFonts.dmSans(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: SurgeColors.warning)),
                ),
              ],
            ]),
          ],
        )),
        GestureDetector(
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SettingsScreen())),
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: SurgeColors.card,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: SurgeColors.border),
            ),
            child: const Icon(Icons.settings_outlined,
              color: SurgeColors.textMuted, size: 18),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddWordScreen()))
            .then((_) => _refresh()),
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: SurgeColors.gradientViolet,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [BoxShadow(
                color: SurgeColors.violet.withOpacity(0.4),
                blurRadius: 12)],
            ),
            child: const Icon(Icons.add_rounded,
              color: Colors.white, size: 22),
          ),
        ),
      ]).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildStatsRow() {
    final total    = _stats['total']    ?? 0;
    final mastered = _stats['mastered'] ?? 0;
    final learning = _stats['learning'] ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(children: [
        StatTile(label: 'Total Words', value: '$total',
          color: SurgeColors.violet, icon: Icons.menu_book_rounded),
        const SizedBox(width: 10),
        StatTile(label: 'Mastered', value: '$mastered',
          color: SurgeColors.success, icon: Icons.verified_rounded),
        const SizedBox(width: 10),
        StatTile(label: 'Learning', value: '$learning',
          color: SurgeColors.error, icon: Icons.school_rounded),
      ]).animate().fadeIn(delay: 100.ms),
    );
  }

  Widget _buildWotdCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(
          title: 'Word of the Day',
          action: _wotd != null ? 'Add to Bank' : null,
          onAction: _wotd == null ? null : () => Navigator.push(context,
            MaterialPageRoute(builder: (_) =>
              AddWordScreen(prefill: _wotd!['word']?.toString())))
            .then((_) => _refresh()),
        ),
        const SizedBox(height: 12),
        if (_loadingWotd)
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: SurgeColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SurgeColors.border),
            ),
            child: const Center(child: CircularProgressIndicator(
              color: SurgeColors.cyan, strokeWidth: 2)),
          )
        else if (_wotd == null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: SurgeColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SurgeColors.border),
            ),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: SurgeColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.wifi_off_rounded,
                  color: SurgeColors.textMuted, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No connection', style: GoogleFonts.dmSans(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: SurgeColors.textPrimary)),
                  Text('Pull down to refresh when online',
                    style: GoogleFonts.dmSans(
                      fontSize: 12, color: SurgeColors.textMuted)),
                ],
              )),
            ]),
          )
        else
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  SurgeColors.violet.withOpacity(0.85),
                  SurgeColors.cyan.withOpacity(0.70),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [BoxShadow(
                color: SurgeColors.violet.withOpacity(0.25),
                blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('TODAY\'S WORD', style: GoogleFonts.dmSans(
                        fontSize: 10, fontWeight: FontWeight.w800,
                        color: Colors.white, letterSpacing: 1)),
                    ),
                    const Spacer(),
                    if ((_wotd!['partOfSpeech'] ?? '').toString().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_wotd!['partOfSpeech'].toString(),
                          style: GoogleFonts.dmSans(
                            fontSize: 11, color: Colors.white70,
                            fontStyle: FontStyle.italic)),
                      ),
                  ]),
                  const SizedBox(height: 14),
                  Text(_wotd!['word'] ?? '', style: GoogleFonts.dmSans(
                    fontSize: 30, fontWeight: FontWeight.w900,
                    color: Colors.white, letterSpacing: -0.5, height: 1)),
                  const SizedBox(height: 8),
                  Text(_wotd!['definition'] ?? '', style: GoogleFonts.dmSans(
                    fontSize: 14, color: Colors.white.withOpacity(0.85),
                    height: 1.5)),
                  if ((_wotd!['example'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💬 ', style: TextStyle(fontSize: 13)),
                          Expanded(child: Text(
                            _wotd!['example'].toString(),
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                              fontStyle: FontStyle.italic,
                              height: 1.5))),
                        ],
                      ),
                    ),
                  ],
                  if ((_wotd!['funFact'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      const Text('⚡ ', style: TextStyle(fontSize: 13)),
                      Expanded(child: Text(_wotd!['funFact'].toString(),
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.65),
                          height: 1.5))),
                    ]),
                  ],
                ],
              ),
            ),
          ),
      ]).animate().fadeIn(delay: 150.ms),
    );
  }

  Widget _buildSuggestions() {
    final current = _suggestions[_suggestionIndex];
    final dotCount = _suggestions.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Discover', style: GoogleFonts.dmSans(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: SurgeColors.textPrimary)),
          const Spacer(),
          Row(children: List.generate(dotCount, (i) =>
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(left: 4),
              width: i == _suggestionIndex ? 14 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: i == _suggestionIndex
                  ? SurgeColors.cyan
                  : SurgeColors.border,
                borderRadius: BorderRadius.circular(3)),
            ),
          )),
        ]),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.12, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
          ),
          child: GestureDetector(
            key: ValueKey(_suggestionIndex),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => AddWordScreen(
                prefill: current['word']?.toString()),
            )).then((_) => _refresh()),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SurgeColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: SurgeColors.cyan.withOpacity(0.2)),
              ),
              child: Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: SurgeColors.cyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('💡',
                    style: TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(current['word']?.toString() ?? '',
                      style: GoogleFonts.dmSans(
                        fontSize: 15, fontWeight: FontWeight.w800,
                        color: SurgeColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(current['hint']?.toString() ?? '',
                      style: GoogleFonts.dmSans(
                        fontSize: 12, color: SurgeColors.textMuted)),
                  ],
                )),
                const Icon(Icons.add_circle_outline_rounded,
                  color: SurgeColors.cyan, size: 20),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildDailyChallenge() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const DailyChallengeScreen())),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: SurgeColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: SurgeColors.warning.withOpacity(0.25)),
          ),
          child: Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: SurgeColors.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13)),
              child: const Center(child: Text('🔥',
                style: TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Challenge', style: GoogleFonts.dmSans(
                  fontSize: 14, fontWeight: FontWeight.w800,
                  color: SurgeColors.textPrimary)),
                Text('Write a sentence — get graded by AI',
                  style: GoogleFonts.dmSans(
                    fontSize: 12, color: SurgeColors.textMuted)),
              ],
            )),
            const Icon(Icons.chevron_right_rounded,
              color: SurgeColors.textMuted, size: 18),
          ]),
        ),
      ).animate().fadeIn(delay: 180.ms),
    );
  }

  Widget _buildRecentSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Recently Added'),
        const SizedBox(height: 12),
        if (_recent.isEmpty)
          const EmptyState(
            emoji: '📚',
            title: 'Bank is empty',
            subtitle: 'Tap + to add your first word',
          )
        else
          ...(_recent.asMap().entries.map((e) => WordCard(
            word: e.value,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => WordDetailScreen(
                word: e.value, onUpdate: _refresh))),
          ).animate().fadeIn(
            delay: (200 + e.key * 60).ms, duration: 300.ms))),
      ]),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}