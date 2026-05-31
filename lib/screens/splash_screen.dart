import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: SurgeColors.background,
      body: Stack(
        children: [
          // Background glow blob top
          Positioned(
            top: -100, left: -60,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  SurgeColors.violet.withOpacity(0.18),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Background glow blob bottom
          Positioned(
            bottom: -80, right: -60,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  SurgeColors.cyan.withOpacity(0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Only the full logo (has icon + wordmark combined)
                Image.asset(
                  'assets/images/logo.png',
                  width: size.width * 0.65,
                )
                .animate()
                .fadeIn(duration: 700.ms)
                .scale(
                  begin: const Offset(0.85, 0.85),
                  curve: Curves.easeOutBack,
                  duration: 700.ms,
                ),

                const SizedBox(height: 48),

                // Thin animated progress line
                SizedBox(
                  width: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      backgroundColor: SurgeColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        SurgeColors.cyan),
                      minHeight: 2,
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

                const SizedBox(height: 14),

                Text(
                  'CONSTANTLY GROWING',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    letterSpacing: 4,
                    color: SurgeColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}