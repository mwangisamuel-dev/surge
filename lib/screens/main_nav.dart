import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'bank_screen.dart';
import 'drill_screen.dart';
import 'notes_screen.dart';
import 'progress_screen.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});
  @override State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _index = 0;

  final _pages = const [
    HomeScreen(),
    BankScreen(),
    DrillScreen(),
    NotesScreen(),
    ProgressScreen(),
  ];

  void _onTap(int i) {
    HapticFeedback.lightImpact();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SurgeColors.background,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: SurgeColors.surface,
        border: Border(top: BorderSide(color: SurgeColors.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(children: [
            _navItem(0, Icons.home_rounded,       'Home'),
            _navItem(1, Icons.menu_book_rounded,  'Bank'),
            _centerButton(),
            _navItem(3, Icons.edit_note_rounded,  'Notes'),
            _navItem(4, Icons.bar_chart_rounded,  'Progress'),
          ]),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData icon, String label) {
    final selected = _index == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTap(idx),
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: selected
                ? SurgeColors.cyan.withOpacity(0.12)
                : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
              color: selected ? SurgeColors.cyan : SurgeColors.textMuted,
              size: 22),
          ),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.dmSans(
            fontSize: 10, fontWeight: FontWeight.w600,
            color: selected ? SurgeColors.cyan : SurgeColors.textMuted)),
        ]),
      ),
    );
  }

  Widget _centerButton() {
    final active = _index == 2;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTap(2),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 50, height: 50,
            decoration: BoxDecoration(
              gradient: active
                ? SurgeColors.gradientCyan
                : SurgeColors.gradientViolet,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(
                color: (active ? SurgeColors.cyan : SurgeColors.violet)
                  .withOpacity(0.45),
                blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.style_rounded,
              color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}