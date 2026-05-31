import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../theme.dart';
import '../models/word_entry.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';
import '../widgets/surge_widgets.dart';

class AddWordScreen extends StatefulWidget {
  final String? prefill;
  const AddWordScreen({super.key, this.prefill});
  @override State<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends State<AddWordScreen> {
  final _wordCtrl    = TextEditingController();
  final _defCtrl     = TextEditingController();
  final _exCtrl      = TextEditingController();
  final _posCtrl     = TextEditingController();
  final _synCtrl     = TextEditingController();
  final _noteCtrl    = TextEditingController();
  WordTag _tag       = WordTag.vocabulary;
  bool _loadingAI    = false;
  bool _saving       = false;
  StorageService?    _storage;

  @override
  void initState() {
    super.initState();
    _setup();
    if (widget.prefill != null) {
      _wordCtrl.text = widget.prefill!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoFill());
    }
  }

  Future<void> _setup() async {
    _storage = await StorageService.get();
  }

Future<void> _autoFill() async {
    final word = _wordCtrl.text.trim();
    if (word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Type a word first', style: GoogleFonts.dmSans()),
        backgroundColor: SurgeColors.warning));
      return;
    }
    if (AiService.apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No API key — go to Settings first', style: GoogleFonts.dmSans()),
        backgroundColor: SurgeColors.error));
      return;
    }
    setState(() => _loadingAI = true);
    try {
      final data = await AiService.fillWordDetails(word);
      if (data != null && mounted) {
        _defCtrl.text = data['definition'] ?? '';
        _exCtrl.text  = data['example'] ?? '';
        _posCtrl.text = data['partOfSpeech'] ?? '';
        _synCtrl.text = (data['synonyms'] as List?)?.join(', ') ?? '';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Filled! ✅', style: GoogleFonts.dmSans()),
          backgroundColor: SurgeColors.success));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('AI returned nothing — check your API key', style: GoogleFonts.dmSans()),
          backgroundColor: SurgeColors.error));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e', style: GoogleFonts.dmSans()),
        backgroundColor: SurgeColors.error));
    }
    if (mounted) setState(() => _loadingAI = false);
  }

Future<void> _save() async {
    if (_wordCtrl.text.trim().isEmpty || _defCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Word and definition are required',
          style: GoogleFonts.dmSans()), backgroundColor: SurgeColors.error));
      return;
    }
    // Ensure storage is ready
    _storage ??= await StorageService.get();
    setState(() => _saving = true);
    final synonyms = _synCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final entry = WordEntry(
      id: const Uuid().v4(),
      word: _wordCtrl.text.trim(),
      definition: _defCtrl.text.trim(),
      example: _exCtrl.text.trim(),
      partOfSpeech: _posCtrl.text.trim(),
      synonyms: synonyms,
      tag: _tag,
      personalNote: _noteCtrl.text.trim(),
      addedAt: DateTime.now(),
    );
    await _storage!.addWord(entry);
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _wordCtrl.dispose(); _defCtrl.dispose(); _exCtrl.dispose();
    _posCtrl.dispose(); _synCtrl.dispose(); _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SurgeColors.background,
      appBar: AppBar(
        backgroundColor: SurgeColors.background,
        title: Text('Add Word', style: GoogleFonts.dmSans(
          fontWeight: FontWeight.w800, color: SurgeColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Word field + AI fill
          Row(children: [
            Expanded(child: TextField(
              controller: _wordCtrl,
              style: GoogleFonts.dmSans(fontSize: 15, color: SurgeColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Word or phrase...',
                prefixIcon: Icon(Icons.edit_rounded, size: 18, color: SurgeColors.textMuted),
              ),
              textCapitalization: TextCapitalization.words,
            )),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _loadingAI ? null : _autoFill,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 52, width: 52,
                decoration: BoxDecoration(
                  gradient: SurgeColors.gradientViolet,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: SurgeColors.violet.withOpacity(0.35), blurRadius: 12)],
                ),
                child: _loadingAI
                  ? const Center(child: SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                  : const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
              ),
            ),
          ]).animate().fadeIn(duration: 350.ms),

          const SizedBox(height: 6),
          Text('Tap ✦ to auto-fill with AI', style: GoogleFonts.dmSans(
            fontSize: 11, color: SurgeColors.textMuted)),

          const SizedBox(height: 18),
          _label('Definition *'),
          TextField(
            controller: _defCtrl, maxLines: 3,
            style: GoogleFonts.dmSans(fontSize: 14, color: SurgeColors.textPrimary),
            decoration: const InputDecoration(hintText: 'What does it mean?'),
          ).animate().fadeIn(delay: 60.ms, duration: 350.ms),

          const SizedBox(height: 14),
          _label('Example Sentence'),
          TextField(
            controller: _exCtrl, maxLines: 2,
            style: GoogleFonts.dmSans(fontSize: 14, color: SurgeColors.textPrimary),
            decoration: const InputDecoration(hintText: 'Use it in a sentence...'),
          ).animate().fadeIn(delay: 100.ms, duration: 350.ms),

          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('Part of Speech'),
              TextField(
                controller: _posCtrl,
                style: GoogleFonts.dmSans(fontSize: 14, color: SurgeColors.textPrimary),
                decoration: const InputDecoration(hintText: 'noun, verb...'),
              ),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('Synonyms'),
              TextField(
                controller: _synCtrl,
                style: GoogleFonts.dmSans(fontSize: 14, color: SurgeColors.textPrimary),
                decoration: const InputDecoration(hintText: 'word1, word2...'),
              ),
            ])),
          ]).animate().fadeIn(delay: 140.ms, duration: 350.ms),

          const SizedBox(height: 18),
          _label('Tag'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8,
            children: WordTag.values.map((t) => TagChip(
              tag: t, selected: _tag == t,
              onTap: () => setState(() => _tag = t),
            )).toList(),
          ).animate().fadeIn(delay: 180.ms, duration: 350.ms),

          const SizedBox(height: 18),
          _label('Personal Note'),
          TextField(
            controller: _noteCtrl, maxLines: 3,
            style: GoogleFonts.dmSans(fontSize: 14, color: SurgeColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Where did you hear this? Any context...'),
          ).animate().fadeIn(delay: 220.ms, duration: 350.ms),

          const SizedBox(height: 28),
          SurgeButton(label: 'Save to Bank', icon: Icons.save_rounded,
            onTap: _save, loading: _saving),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: GoogleFonts.dmSans(
      fontSize: 12, fontWeight: FontWeight.w700,
      color: SurgeColors.textMuted, letterSpacing: 0.5)),
  );
}
