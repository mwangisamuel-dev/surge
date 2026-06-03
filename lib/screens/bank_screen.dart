import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../models/word_entry.dart';
import '../services/storage_service.dart';
import '../widgets/surge_widgets.dart';
import 'add_word_screen.dart';
import 'word_detail_screen.dart';

class BankScreen extends StatefulWidget {
  const BankScreen({super.key});
  @override State<BankScreen> createState() => _BankScreenState();
}

class _BankScreenState extends State<BankScreen> {
  StorageService? _storage;
  List<WordEntry> _all = [];
  List<WordEntry> _filtered = [];
  WordTag? _activeTag;
  MasteryLevel? _activeMastery;
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _storage = await StorageService.get();
    _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _all = _storage!.getWords();
      _applyFilter();
    });
  }

  void _applyFilter() {
    _filtered = _all.where((w) {
      final matchTag     = _activeTag == null || w.tag == _activeTag;
      final matchMastery = _activeMastery == null || w.mastery == _activeMastery;
      final matchQuery   = _query.isEmpty ||
          w.word.toLowerCase().contains(_query.toLowerCase()) ||
          w.definition.toLowerCase().contains(_query.toLowerCase());
      return matchTag && matchMastery && matchQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SurgeColors.background,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          _buildSearch(),
          _buildTagFilter(),
          _buildMasteryFilter(),
          Expanded(child: _buildList()),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'bank_fab',
        onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AddWordScreen())).then((_) => _refresh()),
        backgroundColor: SurgeColors.violet,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Word Bank', style: GoogleFonts.dmSans(
          fontSize: 24, fontWeight: FontWeight.w900, color: SurgeColors.textPrimary)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: SurgeColors.violet.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SurgeColors.violet.withOpacity(0.3)),
          ),
          child: Text('${_all.length} words', style: GoogleFonts.dmSans(
            fontSize: 12, color: SurgeColors.violet, fontWeight: FontWeight.w700)),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms),
  );

  Widget _buildSearch() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
    child: TextField(
      controller: _searchCtrl,
      onChanged: (v) => setState(() { _query = v; _applyFilter(); }),
      style: GoogleFonts.dmSans(fontSize: 14, color: SurgeColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Search words...',
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: SurgeColors.textMuted),
        suffixIcon: _query.isNotEmpty ? GestureDetector(
          onTap: () { _searchCtrl.clear(); setState(() { _query = ''; _applyFilter(); }); },
          child: const Icon(Icons.close_rounded, size: 18, color: SurgeColors.textMuted),
        ) : null,
      ),
    ).animate().fadeIn(delay: 60.ms),
  );

  Widget _buildTagFilter() => SizedBox(
    height: 48,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      children: [
        _filterChip('All', _activeTag == null, () => setState(() { _activeTag = null; _applyFilter(); }), SurgeColors.mint),
        ...WordTag.values.map((t) => Padding(
          padding: const EdgeInsets.only(left: 8),
          child: TagChip(
            tag: t, selected: _activeTag == t,
            onTap: () => setState(() {
              _activeTag = _activeTag == t ? null : t;
              _applyFilter();
            }),
          ),
        )),
      ],
    ),
  );

  Widget _buildMasteryFilter() => SizedBox(
    height: 44,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      children: [
        _filterChip('All levels', _activeMastery == null,
          () => setState(() { _activeMastery = null; _applyFilter(); }), SurgeColors.textMuted),
        ...MasteryLevel.values.map((m) {
          final color = Color(m.colorHex);
          final selected = _activeMastery == m;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: GestureDetector(
              onTap: () => setState(() { _activeMastery = selected ? null : m; _applyFilter(); }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: selected ? color.withOpacity(0.18) : SurgeColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selected ? color : SurgeColors.border),
                ),
                child: Text(m.label, style: GoogleFonts.dmSans(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: selected ? color : SurgeColors.textMuted)),
              ),
            ),
          );
        }),
      ],
    ),
  );

  Widget _buildList() {
    if (_filtered.isEmpty) {
      return _all.isEmpty
        ? const EmptyState(emoji: '📚', title: 'Bank is empty', subtitle: 'Tap + to add your first word')
        : const EmptyState(emoji: '🔍', title: 'No matches', subtitle: 'Try a different filter or search');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => WordCard(
        word: _filtered[i],
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => WordDetailScreen(word: _filtered[i], onUpdate: _refresh)
        )),
        onDelete: () async {
          await _storage!.deleteWord(_filtered[i].id);
          _refresh();
        },
      ).animate().fadeIn(delay: (i * 40).ms, duration: 300.ms),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap, Color color) =>
    GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : SurgeColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : SurgeColors.border),
        ),
        child: Text(label, style: GoogleFonts.dmSans(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: selected ? color : SurgeColors.textMuted)),
      ),
    );
}
