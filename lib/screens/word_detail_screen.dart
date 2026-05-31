import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../models/word_entry.dart';
import '../services/storage_service.dart';
import '../widgets/surge_widgets.dart';

class WordDetailScreen extends StatefulWidget {
  final WordEntry word;
  final VoidCallback? onUpdate;
  const WordDetailScreen({super.key, required this.word, this.onUpdate});
  @override State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  late WordEntry _word;
  StorageService? _storage;

  @override
  void initState() {
    super.initState();
    _word = widget.word;
    StorageService.get().then((s) => _storage = s);
  }

  Future<void> _setMastery(MasteryLevel level) async {
    final updated = _word.copyWith(mastery: level);
    await _storage!.updateWord(updated);
    setState(() => _word = updated);
    widget.onUpdate?.call();
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: SurgeColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete word?', style: GoogleFonts.dmSans(
          fontWeight: FontWeight.w700, color: SurgeColors.textPrimary)),
        content: Text('This will remove "${_word.word}" from your bank.',
          style: GoogleFonts.dmSans(color: SurgeColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: SurgeColors.textMuted))),
          TextButton(onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.dmSans(color: SurgeColors.error, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirm == true) {
      await _storage!.deleteWord(_word.id);
      widget.onUpdate?.call();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagColor = Color(_word.tag.colorHex);
    return Scaffold(
      backgroundColor: SurgeColors.background,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          backgroundColor: SurgeColors.background,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: SurgeColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: SurgeColors.error, size: 20),
              onPressed: _delete,
            ),
          ],
          pinned: true,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Hero word block
              GlowCard(
                glowColor: tagColor,
                padding: const EdgeInsets.all(22),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    TagChip(tag: _word.tag),
                    const SizedBox(width: 8),
                    if (_word.partOfSpeech.isNotEmpty)
                      Text(_word.partOfSpeech, style: GoogleFonts.dmSans(
                        fontSize: 12, color: SurgeColors.textMuted, fontStyle: FontStyle.italic)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _word.word));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Copied!', style: GoogleFonts.dmSans()),
                            backgroundColor: SurgeColors.success, duration: const Duration(seconds: 1)));
                      },
                      child: const Icon(Icons.copy_rounded, size: 16, color: SurgeColors.textMuted),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Text(_word.word, style: GoogleFonts.dmSans(
                    fontSize: 32, fontWeight: FontWeight.w900,
                    color: SurgeColors.textPrimary, letterSpacing: -0.5,
                  )),
                  const SizedBox(height: 10),
                  Text(_word.definition, style: GoogleFonts.dmSans(
                    fontSize: 15, color: SurgeColors.textSecondary, height: 1.6)),
                ]),
              ).animate().fadeIn(duration: 350.ms),

              // Example
              if (_word.example.isNotEmpty) ...[
                const SizedBox(height: 14),
                _sectionLabel('Example'),
                GlowCard(
                  glowColor: SurgeColors.cyan,
                  padding: const EdgeInsets.all(16),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('💬 ', style: const TextStyle(fontSize: 16)),
                    Expanded(child: Text(_word.example, style: GoogleFonts.dmSans(
                      fontSize: 14, color: SurgeColors.textSecondary,
                      fontStyle: FontStyle.italic, height: 1.6))),
                  ]),
                ).animate().fadeIn(delay: 80.ms),
              ],

              // Synonyms
              if (_word.synonyms.isNotEmpty) ...[
                const SizedBox(height: 14),
                _sectionLabel('Synonyms'),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _word.synonyms.map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: SurgeColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: SurgeColors.border),
                    ),
                    child: Text(s, style: GoogleFonts.dmSans(
                      fontSize: 13, color: SurgeColors.textSecondary, fontWeight: FontWeight.w500)),
                  )).toList(),
                ).animate().fadeIn(delay: 120.ms),
              ],

              // Personal note
              if (_word.personalNote.isNotEmpty) ...[
                const SizedBox(height: 14),
                _sectionLabel('My Note'),
                GlowCard(
                  glowColor: SurgeColors.warning,
                  padding: const EdgeInsets.all(16),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('📝 ', style: const TextStyle(fontSize: 16)),
                    Expanded(child: Text(_word.personalNote, style: GoogleFonts.dmSans(
                      fontSize: 14, color: SurgeColors.textSecondary, height: 1.6))),
                  ]),
                ).animate().fadeIn(delay: 160.ms),
              ],

              // Mastery
              const SizedBox(height: 20),
              _sectionLabel('Mastery Level'),
              const SizedBox(height: 10),
              Row(children: MasteryLevel.values.map((level) {
                final selected = _word.mastery == level;
                final color = Color(level.colorHex);
                return Expanded(child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _setMastery(level),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? color.withOpacity(0.18) : SurgeColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? color : SurgeColors.border, width: selected ? 1.5 : 1),
                      ),
                      child: Column(children: [
                        Text(['😅', '🙂', '💪'][level.index], style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 4),
                        Text(level.label, style: GoogleFonts.dmSans(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: selected ? color : SurgeColors.textMuted)),
                      ]),
                    ),
                  ),
                ));
              }).toList()).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 14),
              Text(
                'Added ${_formatDate(_word.addedAt)}  •  ${_word.reviewCount} reviews  •  ${_word.missCount} misses',
                style: GoogleFonts.dmSans(fontSize: 11, color: SurgeColors.textMuted),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: GoogleFonts.dmSans(
      fontSize: 12, fontWeight: FontWeight.w700,
      color: SurgeColors.textMuted, letterSpacing: 0.8)),
  );

  String _formatDate(DateTime d) =>
    '${d.day}/${d.month}/${d.year}';
}
