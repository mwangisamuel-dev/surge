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
  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _index = 0;

  void _onTap(int i) {
    HapticFeedback.lightImpact();
    setState(() => _index = i);
  }

  static const List<Widget> _pages = [
    const HomeScreen(),
    const BankScreen(),
    const DrillScreen(),
    const NotesScreen(),
    const ProgressScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SurgeColors.background,
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: SurgeColors.surface,
        border: const Border(
            top: BorderSide(color: SurgeColors.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(children: [
            _navItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
            _navItem(
                1, Icons.menu_book_rounded, Icons.menu_book_outlined, 'Bank'),
            _centerDrillButton(),
            _navItem(3, Icons.edit_note_rounded, Icons.edit_outlined, 'Notes'),
            _navItem(
                4, Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Stats'),
          ]),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData active, IconData inactive, String label) {
    final sel = _index == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTap(idx),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color:
                    sel ? SurgeColors.violet.withAlpha(31) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(sel ? active : inactive,
                  color: sel ? SurgeColors.violetLight : SurgeColors.textMuted,
                  size: 22),
            ),
            const SizedBox(height: 3),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color:
                        sel ? SurgeColors.violetLight : SurgeColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _centerDrillButton() {
    final active = _index == 2;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTap(2),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: active
                  ? SurgeColors.gradientMint
                  : SurgeColors.gradientViolet,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: (active ? SurgeColors.mint : SurgeColors.violet)
                        .withAlpha(89),
                    blurRadius: 14,
                    offset: const Offset(0, 4))
              ],
            ),
            child:
                const Icon(Icons.style_rounded, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}
