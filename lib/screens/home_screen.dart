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

  final List<Map<String, dynamic>> _suggestions = [
    {'word': 'Ephemeral',     'hint': 'Lasting a very short time',         'color': 0xFF7C6EFA},
    {'word': 'Tenacious',     'hint': 'Holding firm despite opposition',   'color': 0xFF4ECDC4},
    {'word': 'Eloquent',      'hint': 'Fluent and persuasive in speech',   'color': 0xFFFF9E7E},
    {'word': 'Sanguine',      'hint': 'Optimistic in difficulties',        'color': 0xFFFFD166},
    {'word': 'Nonchalant',    'hint': 'Calm and casually unconcerned',     'color': 0xFF95C8B0},
    {'word': 'Insidious',     'hint': 'Harmful in a subtle way',           'color': 0xFFB8A9FF},
    {'word': 'Perspicacious', 'hint': 'Quick to notice and understand',    'color': 0xFFFF6B8A},
    {'word': 'Equivocate',    'hint': 'Use vague language to avoid truth', 'color': 0xFF4ECDC4},
  ];

  int _suggestionIndex = 0;
  Timer? _suggestionTimer;

  @override
  void initState() {
    super.initState();
    _init();
    _suggestionTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() =>
        _suggestionIndex = (_suggestionIndex + 1) % _suggestions.length);
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
  void dispose() { _suggestionTimer?.cancel(); super.dispose(); }

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
            SliverToBoxAdapter(child: _buildCategoryCards()),
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
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 0),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_greeting(), style: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: SurgeColors.textMuted,
              fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Text('Surge', style: GoogleFonts.plusJakartaSans(
                fontSize: 32, fontWeight: FontWeight.w800,
                color: SurgeColors.textPrimary,
                letterSpacing: -1)),
              const SizedBox(width: 10),
              if (streak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: SurgeColors.lemonSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('🔥', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text('$streak days', style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: SurgeColors.lemon)),
                  ]),
                ),
            ]),
          ],
        )),
        // Settings
        GestureDetector(
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SettingsScreen())),
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: SurgeColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SurgeColors.border),
            ),
            child: const Icon(Icons.settings_outlined,
              color: SurgeColors.textMuted, size: 18),
          ),
        ),
        const SizedBox(width: 8),
        // Add word
        GestureDetector(
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddWordScreen()))
            .then((_) => _refresh()),
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: SurgeColors.gradientViolet,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.add_rounded,
              color: Colors.white, size: 22),
          ),
        ),
      ]).animate().fadeIn(duration: 350.ms),
    );
  }

  Widget _buildStatsRow() {
    final total    = _stats['total']    ?? 0;
    final mastered = _stats['mastered'] ?? 0;
    final learning = _stats['learning'] ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
      child: Row(children: [
        _miniStat('$total', 'Words', SurgeColors.violetLight),
        const SizedBox(width: 8),
        _miniStat('$mastered', 'Mastered', SurgeColors.mint),
        const SizedBox(width: 8),
        _miniStat('$learning', 'Learning', SurgeColors.peach),
      ]).animate().fadeIn(delay: 80.ms),
    );
  }

  Widget _miniStat(String value, String label, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: SurgeColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SurgeColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: GoogleFonts.plusJakartaSans(
          fontSize: 22, fontWeight: FontWeight.w800,
          color: SurgeColors.textPrimary, height: 1)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.plusJakartaSans(
          fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ]),
    ),
  );

  Widget _buildWotdCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Word of the Day', style: GoogleFonts.plusJakartaSans(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: SurgeColors.textPrimary)),
          const Spacer(),
          if (_wotd != null)
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => AddWordScreen(
                  prefill: _wotd!['word']?.toString())))
                .then((_) => _refresh()),
              child: Text('Add to Bank', style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: SurgeColors.mint,
                fontWeight: FontWeight.w600)),
            ),
        ]),
        const SizedBox(height: 12),

        if (_loadingWotd)
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: SurgeColors.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: SurgeColors.border)),
            child: const Center(child: CircularProgressIndicator(
              color: SurgeColors.violet, strokeWidth: 2)),
          )
        else if (_wotd == null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: SurgeColors.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: SurgeColors.border)),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: SurgeColors.surface,
                  borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.cloud_off_rounded,
                  color: SurgeColors.textMuted, size: 20)),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No connection', style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: SurgeColors.textPrimary)),
                  Text('Pull down to refresh when online',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: SurgeColors.textMuted)),
                ])),
            ]),
          )
        else
          // Editorial WOTD card — big bold word, soft background
          Container(
            decoration: BoxDecoration(
              color: SurgeColors.lavenderSoft,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: SurgeColors.violet.withOpacity(0.2))),
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
                        color: SurgeColors.violet.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20)),
                      child: Text('TODAY', style: GoogleFonts.plusJakartaSans(
                        fontSize: 10, fontWeight: FontWeight.w800,
                        color: SurgeColors.lavender, letterSpacing: 1.5)),
                    ),
                    const Spacer(),
                    if ((_wotd!['partOfSpeech'] ?? '').isNotEmpty)
                      Text(_wotd!['partOfSpeech'].toString(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: SurgeColors.textMuted,
                          fontStyle: FontStyle.italic)),
                  ]),
                  const SizedBox(height: 14),
                  Text(_wotd!['word'] ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 34, fontWeight: FontWeight.w800,
                      color: SurgeColors.textPrimary,
                      letterSpacing: -1, height: 1.1)),
                  const SizedBox(height: 10),
                  Text(_wotd!['definition'] ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, color: SurgeColors.textSecondary,
                      height: 1.6)),
                  if ((_wotd!['example'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SurgeColors.background.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12)),
                      child: Text('💬  ${_wotd!['example']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: SurgeColors.textSecondary,
                          fontStyle: FontStyle.italic, height: 1.5)),
                    ),
                  ],
                  if ((_wotd!['funFact'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text('⚡  ${_wotd!['funFact']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: SurgeColors.textMuted,
                        height: 1.5)),
                  ],
                ],
              ),
            ),
          ),
      ]).animate().fadeIn(delay: 120.ms),
    );
  }

  // Inspo-style rotating color category cards
  Widget _buildCategoryCards() {
    final current = _suggestions[_suggestionIndex];
    final color   = Color(current['color'] as int);
    final colors  = [
      SurgeColors.lavenderSoft, SurgeColors.mintSoft,
      SurgeColors.peachSoft,    SurgeColors.lemonSoft,
    ];
    final accents = [
      SurgeColors.lavender, SurgeColors.mint,
      SurgeColors.peach,    SurgeColors.lemon,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Discover', style: GoogleFonts.plusJakartaSans(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: SurgeColors.textPrimary)),
          const Spacer(),
          Row(children: List.generate(_suggestions.length, (i) =>
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(left: 3),
              width: i == _suggestionIndex ? 16 : 4,
              height: 4,
              decoration: BoxDecoration(
                color: i == _suggestionIndex
                  ? SurgeColors.mint : SurgeColors.border,
                borderRadius: BorderRadius.circular(2)),
            ))),
        ]),
        const SizedBox(height: 12),

        // Main rotating card
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.08, 0), end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
          ),
          child: GestureDetector(
            key: ValueKey(_suggestionIndex),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => AddWordScreen(
                prefill: current['word']?.toString())))
              .then((_) => _refresh()),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.2))),
              child: Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20)),
                      child: Text('NEW WORD', style: GoogleFonts.plusJakartaSans(
                        fontSize: 9, fontWeight: FontWeight.w800,
                        color: color, letterSpacing: 1.5)),
                    ),
                    const SizedBox(height: 12),
                    Text(current['word']?.toString() ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26, fontWeight: FontWeight.w800,
                        color: SurgeColors.textPrimary,
                        letterSpacing: -0.5, height: 1)),
                    const SizedBox(height: 6),
                    Text(current['hint']?.toString() ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: SurgeColors.textSecondary)),
                  ],
                )),
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 22),
                ),
              ]),
            ),
          ),
        ),

        const SizedBox(height: 10),
        // 4 small category pills
        Row(children: List.generate(4, (i) {
          final idx = (_suggestionIndex + i + 1) % _suggestions.length;
          return Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => AddWordScreen(
                  prefill: _suggestions[idx]['word']?.toString())))
                .then((_) => _refresh()),
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                padding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: Color(_suggestions[idx]['color'] as int)
                    .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(_suggestions[idx]['color'] as int)
                      .withOpacity(0.15))),
                child: Text(
                  _suggestions[idx]['word']?.toString() ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: SurgeColors.textSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center),
              ),
            ),
          );
        })),
      ]),
    );
  }

  Widget _buildDailyChallenge() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const DailyChallengeScreen())),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: SurgeColors.peachSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: SurgeColors.peach.withOpacity(0.2))),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: SurgeColors.peach.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14)),
              child: const Center(child: Text('🔥',
                style: TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Challenge', style: GoogleFonts.plusJakartaSans(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: SurgeColors.textPrimary)),
                const SizedBox(height: 2),
                Text('Write a sentence — get graded by AI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: SurgeColors.textSecondary)),
              ],
            )),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: SurgeColors.peach.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_forward_rounded,
                color: SurgeColors.peach, size: 16),
            ),
          ]),
        ),
      ).animate().fadeIn(delay: 200.ms),
    );
  }

  Widget _buildRecentSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
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
            delay: (180 + e.key * 50).ms, duration: 300.ms))),
      ]),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning ☀️';
    if (h < 17) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
  }
}