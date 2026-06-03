import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../theme.dart';
import '../models/note_entry.dart';
import '../services/storage_service.dart';
import '../widgets/surge_widgets.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  StorageService? _storage;
  List<NoteEntry> _notes = [];

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
    setState(() => _notes = _storage!.getNotes());
  }

  void _openNote(NoteEntry? note) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _NoteEditorScreen(note: note, storage: _storage!),
    )).then((_) => _refresh());
  }

  Future<void> _delete(String id) async {
    await _storage!.deleteNote(id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SurgeColors.background,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Notes', style: GoogleFonts.dmSans(
                  fontSize: 24, fontWeight: FontWeight.w900, color: SurgeColors.textPrimary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: SurgeColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: SurgeColors.warning.withOpacity(0.3)),
                  ),
                  child: Text('${_notes.length} notes', style: GoogleFonts.dmSans(
                    fontSize: 12, color: SurgeColors.warning, fontWeight: FontWeight.w700)),
                ),
              ],
            ).animate().fadeIn(duration: 300.ms),
          ),
          Expanded(
            child: _notes.isEmpty
              ? const EmptyState(emoji: '📝', title: 'No notes yet', subtitle: 'Jot down grammar rules,\nphrases or anything you want to remember')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                  itemCount: _notes.length,
                  itemBuilder: (_, i) => _NoteCard(
                    note: _notes[i],
                    onTap: () => _openNote(_notes[i]),
                    onDelete: () => _delete(_notes[i].id),
                  ).animate().fadeIn(delay: (i * 50).ms, duration: 300.ms),
                ),
          ),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'notes_fab',
        onPressed: () => _openNote(null),
        backgroundColor: SurgeColors.warning,
        child: const Icon(Icons.edit_rounded, color: Colors.black),
      ),   
    );
  }
}

class _NoteCard extends StatelessWidget {
  final NoteEntry note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _NoteCard({required this.note, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: SurgeColors.gradientCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SurgeColors.warning.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: SurgeColors.warning.withOpacity(0.06), blurRadius: 16)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('📝', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(child: Text(note.title, style: GoogleFonts.dmSans(
              fontSize: 15, fontWeight: FontWeight.w700, color: SurgeColors.textPrimary))),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.close_rounded, size: 16, color: SurgeColors.textMuted),
            ),
          ]),
          if (note.body.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(note.body, maxLines: 3, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(fontSize: 13, color: SurgeColors.textSecondary, height: 1.5)),
          ],
          const SizedBox(height: 10),
          Text(_fmt(note.updatedAt), style: GoogleFonts.dmSans(
            fontSize: 11, color: SurgeColors.textMuted)),
        ]),
      ),
    );
  }

  String _fmt(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _NoteEditorScreen extends StatefulWidget {
  final NoteEntry? note;
  final StorageService storage;
  const _NoteEditorScreen({this.note, required this.storage});
  @override State<_NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<_NoteEditorScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _bodyCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note?.title ?? '');
    _bodyCtrl  = TextEditingController(text: widget.note?.body  ?? '');
  }

  @override
  void dispose() { _titleCtrl.dispose(); _bodyCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Title is required', style: GoogleFonts.dmSans()),
          backgroundColor: SurgeColors.error));
      return;
    }
    setState(() => _saving = true);
    if (widget.note == null) {
      await widget.storage.addNote(NoteEntry(
        id: const Uuid().v4(),
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    } else {
      widget.note!.title = _titleCtrl.text.trim();
      widget.note!.body  = _bodyCtrl.text.trim();
      widget.note!.updatedAt = DateTime.now();
      await widget.storage.updateNote(widget.note!);
    }
    if (mounted) { setState(() => _saving = false); Navigator.pop(context); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SurgeColors.background,
      appBar: AppBar(
        backgroundColor: SurgeColors.background,
        title: Text(widget.note == null ? 'New Note' : 'Edit Note',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, color: SurgeColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: SurgeColors.gradientViolet,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _saving
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Save', style: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(
            controller: _titleCtrl,
            style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w800, color: SurgeColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Note title...',
              hintStyle: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w800, color: SurgeColors.textMuted),
              border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
              filled: false,
            ),
          ),
          Divider(color: SurgeColors.border, height: 1),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _bodyCtrl,
              maxLines: null, expands: true,
              style: GoogleFonts.dmSans(fontSize: 15, color: SurgeColors.textSecondary, height: 1.7),
              decoration: InputDecoration(
                hintText: 'Start writing...',
                hintStyle: GoogleFonts.dmSans(fontSize: 15, color: SurgeColors.textMuted),
                border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
