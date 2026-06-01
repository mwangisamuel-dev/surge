import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';
import '../models/word_entry.dart';
import '../services/storage_service.dart';
import '../widgets/surge_widgets.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  StorageService? _storage;
  Map<String, int> _stats      = {};
  List<WordEntry>  _words      = [];
  List<String>     _activeDays = [];
  bool             _loading    = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  // Re-sync every time the tab is visited
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_storage != null) _sync();
  }

  Future<void> _init() async {
    _storage = await StorageService.get();
    _sync();
  }

  void _sync() {
    if (!mounted || _storage == null) return;
    setState(() {
      _stats      = _storage!.getStats();
      _words      = _storage!.getWords();
      _activeDays = _storage!.getActiveDays();
      _loading    = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SurgeColors.background,
      body: SafeArea(
        child: _loading
          ? const Center(child: CircularProgressIndicator(
              color: SurgeColors.mint, strokeWidth: 2))
          : RefreshIndicator(
              color: SurgeColors.violet,
              backgroundColor: SurgeColors.card,
              onRefresh: () async => _sync(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(),
                    const SizedBox(height: 20),
                    _buildStreakBanner(),
                    const SizedBox(height: 14),
                    _buildStatsGrid(),
                    const SizedBox(height: 16),
                    if (_words.isNotEmpty) ...[
                      _buildMasteryChart(),
                      const SizedBox(height: 16),
                      _buildTagBreakdown(),
                      const SizedBox(height: 16),
                    ],
                    _buildActivityCalendar(),
                    const SizedBox(height: 16),
                    _buildMilestones(),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildPageHeader() => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Progress', style: GoogleFonts.dmSans(
          fontSize: 22, fontWeight: FontWeight.w800,
          color: SurgeColors.textPrimary)),
        const SizedBox(height: 2),
        Text('Pull down to refresh', style: GoogleFonts.dmSans(
          fontSize: 12, color: SurgeColors.textMuted)),
      ]),
      const Spacer(),
      GestureDetector(
        onTap: _sync,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: SurgeColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: SurgeColors.border)),
          child: const Icon(Icons.refresh_rounded,
            size: 16, color: SurgeColors.textMuted),
        ),
      ),
    ],
  ).animate().fadeIn();

  Widget _buildStreakBanner() {
    final streak = _stats['streak'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SurgeColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SurgeColors.warning.withOpacity(0.2)),
      ),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Current Streak', style: GoogleFonts.dmSans(
            fontSize: 11, color: SurgeColors.textMuted,
            fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$streak', style: GoogleFonts.dmSans(
              fontSize: 44, fontWeight: FontWeight.w900,
              color: SurgeColors.warning, height: 1)),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('days', style: GoogleFonts.dmSans(
                fontSize: 15, color: SurgeColors.textSecondary,
                fontWeight: FontWeight.w600)),
            ),
          ]),
        ]),
        const Spacer(),
        Text(streak == 0 ? '😴' : streak < 3 ? '🌱' :
          streak < 7 ? '🔥' : streak < 30 ? '⚡' : '💎',
          style: const TextStyle(fontSize: 38)),
      ]),
    ).animate().fadeIn(delay: 80.ms);
  }

  Widget _buildStatsGrid() {
    final total    = _stats['total']    ?? 0;
    final mastered = _stats['mastered'] ?? 0;
    final familiar = _stats['familiar'] ?? 0;
    final learning = _stats['learning'] ?? 0;

    return Column(children: [
      Row(children: [
        StatTile(label: 'Total Words', value: '$total',
          color: SurgeColors.violet, icon: Icons.menu_book_rounded),
        const SizedBox(width: 10),
        StatTile(label: 'Mastered', value: '$mastered',
          color: SurgeColors.success, icon: Icons.verified_rounded),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        StatTile(label: 'Familiar', value: '$familiar',
          color: SurgeColors.warning, icon: Icons.star_half_rounded),
        const SizedBox(width: 10),
        StatTile(label: 'Learning', value: '$learning',
          color: SurgeColors.error, icon: Icons.school_rounded),
      ]),
    ]).animate().fadeIn(delay: 120.ms);
  }

  Widget _buildMasteryChart() {
    final mastered = (_stats['mastered'] ?? 0).toDouble();
    final familiar = (_stats['familiar'] ?? 0).toDouble();
    final learning = (_stats['learning'] ?? 0).toDouble();
    final total    = mastered + familiar + learning;
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SurgeColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SurgeColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Mastery Breakdown'),
          const SizedBox(height: 18),
          SizedBox(
            height: 150,
            child: Row(children: [
              SizedBox(
                width: 130,
                child: PieChart(PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 34,
                  sections: [
                    PieChartSectionData(
                      value: mastered,
                      color: SurgeColors.success,
                      radius: 34,
                      title: '${(mastered / total * 100).round()}%',
                      titleStyle: GoogleFonts.dmSans(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                    PieChartSectionData(
                      value: familiar,
                      color: SurgeColors.warning,
                      radius: 34,
                      title: '${(familiar / total * 100).round()}%',
                      titleStyle: GoogleFonts.dmSans(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                    PieChartSectionData(
                      value: learning,
                      color: SurgeColors.error,
                      radius: 34,
                      title: '${(learning / total * 100).round()}%',
                      titleStyle: GoogleFonts.dmSans(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                  ],
                )),
              ),
              const SizedBox(width: 20),
              Expanded(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legend('Mastered', SurgeColors.success, mastered.toInt()),
                  const SizedBox(height: 10),
                  _legend('Familiar', SurgeColors.warning, familiar.toInt()),
                  const SizedBox(height: 10),
                  _legend('Learning', SurgeColors.error,   learning.toInt()),
                ],
              )),
            ]),
          ),
        ]),
    ).animate().fadeIn(delay: 160.ms);
  }

  Widget _legend(String label, Color color, int count) => Row(children: [
    Container(width: 8, height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 8),
    Text(label, style: GoogleFonts.dmSans(
      fontSize: 12, color: SurgeColors.textSecondary)),
    const Spacer(),
    Text('$count', style: GoogleFonts.dmSans(
      fontSize: 13, fontWeight: FontWeight.w700,
      color: SurgeColors.textPrimary)),
  ]);

  Widget _buildTagBreakdown() {
    final tagCounts = <WordTag, int>{};
    for (final w in _words) {
      tagCounts[w.tag] = (tagCounts[w.tag] ?? 0) + 1;
    }
    if (tagCounts.isEmpty) return const SizedBox.shrink();
    final total = _words.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SurgeColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SurgeColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'By Category'),
          const SizedBox(height: 14),
          ...tagCounts.entries.map((e) {
            final pct   = e.value / total;
            final color = Color(e.key.colorHex);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    TagChip(tag: e.key),
                    const Spacer(),
                    Text('${e.value}', style: GoogleFonts.dmSans(
                      fontSize: 12, color: SurgeColors.textMuted,
                      fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: SurgeColors.surface,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        color.withOpacity(0.7)),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            );
          }),
        ]),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildActivityCalendar() {
    final now       = DateTime.now();
    final start     = now.subtract(const Duration(days: 62));
    final days      = List.generate(63, (i) => start.add(Duration(days: i)));
    final activeSet = _activeDays.toSet();

    String fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}'
      '-${d.day.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SurgeColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SurgeColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Activity'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 4, runSpacing: 4,
            children: days.map((d) {
              final isActive = activeSet.contains(fmt(d));
              final isToday  = fmt(d) == fmt(now);
              return Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: isActive
                    ? SurgeColors.violet.withOpacity(0.55)
                    : SurgeColors.surface,
                  borderRadius: BorderRadius.circular(5),
                  border: isToday
                    ? Border.all(color: SurgeColors.mint, width: 1.5)
                    : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(children: [
            _calLegend(SurgeColors.violet.withOpacity(0.55), 'Active'),
            const SizedBox(width: 14),
            _calLegend(SurgeColors.surface, 'Inactive',
              border: SurgeColors.border),
            const SizedBox(width: 14),
            _calLegend(SurgeColors.surface, 'Today',
              border: SurgeColors.mint),
          ]),
        ]),
    ).animate().fadeIn(delay: 240.ms);
  }

  Widget _calLegend(Color color, String label, {Color? border}) =>
    Row(children: [
      Container(
        width: 10, height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
          border: border != null ? Border.all(color: border) : null)),
      const SizedBox(width: 5),
      Text(label, style: GoogleFonts.dmSans(
        fontSize: 11, color: SurgeColors.textMuted)),
    ]);

  Widget _buildMilestones() {
    final total    = _stats['total']    ?? 0;
    final mastered = _stats['mastered'] ?? 0;
    final streak   = _stats['streak']  ?? 0;

    final all = <Map<String, dynamic>>[
      {'e':'🌱','t':'First word added',    'u': total >= 1},
      {'e':'📖','t':'10 words collected',  'u': total >= 10},
      {'e':'📚','t':'50 words collected',  'u': total >= 50},
      {'e':'🏅','t':'100 word bank',       'u': total >= 100},
      {'e':'⭐','t':'First word mastered', 'u': mastered >= 1},
      {'e':'🌟','t':'10 words mastered',   'u': mastered >= 10},
      {'e':'🔥','t':'3 day streak',        'u': streak >= 3},
      {'e':'⚡','t':'7 day streak',        'u': streak >= 7},
      {'e':'💎','t':'30 day streak',       'u': streak >= 30},
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'Milestones'),
      const SizedBox(height: 12),
      ...all.map((m) {
        final unlocked = m['u'] as bool;
        return Container(
          margin: const EdgeInsets.only(bottom: 7),
          padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: unlocked ? SurgeColors.card : SurgeColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: unlocked
                ? SurgeColors.border : SurgeColors.surface)),
          child: Row(children: [
            Text(unlocked ? m['e'] : '🔒',
              style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(child: Text(m['t'], style: GoogleFonts.dmSans(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: unlocked
                ? SurgeColors.textPrimary : SurgeColors.textMuted))),
            if (unlocked)
              const Icon(Icons.check_circle_rounded,
                color: SurgeColors.success, size: 16),
          ]),
        );
      }),
    ]).animate().fadeIn(delay: 280.ms);
  }
}