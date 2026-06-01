import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../widgets/surge_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _keyCtrl = TextEditingController(text: AiService.apiKey);
  bool _obscure = true;
  StorageService? _storage;

  //get back here
  @override
  void initState() {
    super.initState();
    StorageService.get().then((s) {
      setState(() => _storage = s);
      final saved = s.getApiKey();
      if (saved.isNotEmpty) {
        _keyCtrl.text = saved;
        AiService.apiKey = saved;
      }
    });
  }

  @override
  void dispose() { _keyCtrl.dispose(); super.dispose(); }
//get back here too
  void _saveKey() async {
    final key = _keyCtrl.text.trim();
    AiService.apiKey = key;
    await _storage!.saveApiKey(key);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('API key saved ✅', style: GoogleFonts.dmSans()),
      backgroundColor: SurgeColors.success));
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: SurgeColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear all data?', style: GoogleFonts.dmSans(
          fontWeight: FontWeight.w700, color: SurgeColors.textPrimary)),
        content: Text('This will delete all words, notes, and progress. Cannot be undone.',
          style: GoogleFonts.dmSans(color: SurgeColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: SurgeColors.textMuted))),
          TextButton(onPressed: () => Navigator.pop(context, true),
            child: Text('Clear Everything', style: GoogleFonts.dmSans(
              color: SurgeColors.error, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirm == true && _storage != null) {
      await _storage!.clearAll();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('All data cleared', style: GoogleFonts.dmSans()),
        backgroundColor: SurgeColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SurgeColors.background,
      appBar: AppBar(
        backgroundColor: SurgeColors.background,
        title: Text('Settings', style: GoogleFonts.dmSans(
          fontWeight: FontWeight.w800, color: SurgeColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          _sectionTitle('AI Features'),
          const SizedBox(height: 10),
          GlowCard(
            glowColor: SurgeColors.violet,
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('✦', style: TextStyle(color: SurgeColors.violet, fontSize: 18)),
                const SizedBox(width: 8),
                Text('Google AI API Key', style: GoogleFonts.dmSans(
                  fontSize: 14, fontWeight: FontWeight.w700, color: SurgeColors.textPrimary)),
              ]),
              const SizedBox(height: 6),
              Text('Required for AI auto-fill and Word of the Day. Free at aistudio.google.com.',
                style: GoogleFonts.dmSans(fontSize: 12, color: SurgeColors.textMuted)),
              const SizedBox(height: 14),
              TextField(
                controller: _keyCtrl,
                obscureText: _obscure,
                style: GoogleFonts.dmMono(fontSize: 13, color: SurgeColors.textSecondary),
                decoration: InputDecoration(
                  hintText: 'AIza...',
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 18, color: SurgeColors.textMuted),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SurgeButton(label: 'Save API Key', icon: Icons.key_rounded, onTap: _saveKey),
              const SizedBox(height: 8),
              Text('Get your free key at aistudio.google.com',
                style: GoogleFonts.dmSans(fontSize: 11, color: SurgeColors.textMuted)),
            ]),
          ).animate().fadeIn(delay: 80.ms),

          const SizedBox(height: 20),
          _sectionTitle('About'),
          const SizedBox(height: 10),
          GlowCard(
            glowColor: SurgeColors.mint,
            padding: const EdgeInsets.all(18),
            child: Column(children: [
              _infoRow('App', 'Surge'),
              _divider(),
              _infoRow('Version', '1.0.0'),
              _divider(),
              _infoRow('Tagline', 'Constantly Growing'),
              _divider(),
              _infoRow('Storage', 'Offline (local)'),
            ]),
          ).animate().fadeIn(delay: 140.ms),

          const SizedBox(height: 20),
          _sectionTitle('Data'),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _clearAll,
            child: Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SurgeColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SurgeColors.error.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.delete_forever_rounded, color: SurgeColors.error, size: 20),
                const SizedBox(width: 12),
                Text('Clear All Data', style: GoogleFonts.dmSans(
                  fontSize: 14, fontWeight: FontWeight.w700, color: SurgeColors.error)),
              ]),
            ),
          ).animate().fadeIn(delay: 180.ms),

          const SizedBox(height: 40),
          Center(child: Column(children: [
            Image.asset('assets/images/favicon.png', width: 36),
            const SizedBox(height: 8),
            Text('SURGE', style: GoogleFonts.dmSans(
              fontSize: 13, letterSpacing: 3, fontWeight: FontWeight.w800, color: SurgeColors.textMuted)),
            Text('Constantly Growing', style: GoogleFonts.dmSans(
              fontSize: 11, color: SurgeColors.textMuted)),
          ])).animate().fadeIn(delay: 300.ms),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: GoogleFonts.dmSans(
    fontSize: 12, fontWeight: FontWeight.w700, color: SurgeColors.textMuted, letterSpacing: 1));
  Widget _infoRow(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Text(l, style: GoogleFonts.dmSans(fontSize: 13, color: SurgeColors.textSecondary)),
      const Spacer(),
      Text(v, style: GoogleFonts.dmSans(fontSize: 13, color: SurgeColors.textPrimary, fontWeight: FontWeight.w600)),
    ]),
  );
  Widget _divider() => Container(height: 1, color: SurgeColors.border);
}
