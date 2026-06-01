import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/word_entry.dart';

// ── Base card ──────────────────────────────────────────────────────────────
class GlowCard extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final double radius;

  const GlowCard({
    super.key, required this.child,
    this.glowColor = SurgeColors.violet,
    this.padding, this.onTap, this.radius = 20,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: SurgeColors.card,
        border: Border.all(color: SurgeColors.border),
      ),
      padding: padding ?? const EdgeInsets.all(18),
      child: child,
    ),
  );
}

// ── Tag chip ───────────────────────────────────────────────────────────────
class TagChip extends StatelessWidget {
  final WordTag tag;
  final bool selected;
  final VoidCallback? onTap;

  const TagChip({super.key, required this.tag,
    this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(tag.colorHex);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.18) : SurgeColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color.withOpacity(0.6) : SurgeColors.border),
        ),
        child: Text(tag.label, style: GoogleFonts.plusJakartaSans(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: selected ? color : SurgeColors.textMuted)),
      ),
    );
  }
}

// ── Mastery badge ──────────────────────────────────────────────────────────
class MasteryBadge extends StatelessWidget {
  final MasteryLevel level;
  const MasteryBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final color = Color(level.colorHex);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(level.label, style: GoogleFonts.plusJakartaSans(
        fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ── Stat tile ──────────────────────────────────────────────────────────────
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const StatTile({super.key, required this.label, required this.value,
    required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SurgeColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SurgeColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 10),
        Text(value, style: GoogleFonts.plusJakartaSans(
          fontSize: 20, fontWeight: FontWeight.w800,
          color: SurgeColors.textPrimary, height: 1)),
        const SizedBox(height: 3),
        Text(label, style: GoogleFonts.plusJakartaSans(
          fontSize: 11, color: SurgeColors.textMuted,
          fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}

// ── Section header ─────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title,
    this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: GoogleFonts.plusJakartaSans(
        fontSize: 16, fontWeight: FontWeight.w700,
        color: SurgeColors.textPrimary)),
      if (action != null)
        GestureDetector(
          onTap: onAction,
          child: Row(children: [
            Text(action!, style: GoogleFonts.plusJakartaSans(
              fontSize: 12, color: SurgeColors.mint,
              fontWeight: FontWeight.w600)),
            const Icon(Icons.chevron_right_rounded,
              size: 14, color: SurgeColors.mint),
          ]),
        ),
    ],
  );
}

// ── Word card ──────────────────────────────────────────────────────────────
class WordCard extends StatelessWidget {
  final WordEntry word;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const WordCard({super.key, required this.word,
    this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final tagColor = Color(word.tag.colorHex);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SurgeColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SurgeColors.border),
        ),
        child: Row(children: [
          // Soft color dot accent
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: tagColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(
              word.tag.emoji,
              style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Flexible(child: Text(word.word,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: SurgeColors.textPrimary))),
                const SizedBox(width: 6),
                if (word.partOfSpeech.isNotEmpty)
                  Text(word.partOfSpeech,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10, color: SurgeColors.textMuted,
                      fontStyle: FontStyle.italic)),
              ]),
              const SizedBox(height: 3),
              Text(word.definition,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: SurgeColors.textSecondary)),
            ],
          )),
          const SizedBox(width: 8),
          MasteryBadge(level: word.mastery),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.close_rounded,
                size: 14, color: SurgeColors.textMuted),
            ),
          ],
        ]),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const EmptyState({super.key, required this.emoji,
    required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: SurgeColors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: SurgeColors.border),
          ),
          child: Center(child: Text(emoji,
            style: const TextStyle(fontSize: 30))),
        ),
        const SizedBox(height: 16),
        Text(title, style: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w700,
          color: SurgeColors.textPrimary)),
        const SizedBox(height: 6),
        Text(subtitle, style: GoogleFonts.plusJakartaSans(
          fontSize: 13, color: SurgeColors.textMuted, height: 1.6),
          textAlign: TextAlign.center),
      ]),
    ),
  );
}

// ── Surge button ───────────────────────────────────────────────────────────
class SurgeButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool secondary;
  final IconData? icon;
  final bool loading;
  final Color? color;

  const SurgeButton({super.key, required this.label, this.onTap,
    this.secondary = false, this.icon, this.loading = false, this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: double.infinity, height: 54,
      decoration: BoxDecoration(
        gradient: secondary || color != null ? null : SurgeColors.gradientViolet,
        color: color ?? (secondary ? SurgeColors.surface : null),
        borderRadius: BorderRadius.circular(16),
        border: secondary ? Border.all(color: SurgeColors.border) : null,
      ),
      child: loading
        ? const Center(child: SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2, color: Colors.white)))
        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[
              Icon(icon, size: 17,
                color: secondary ? SurgeColors.textSecondary : Colors.white),
              const SizedBox(width: 8),
            ],
            Text(label, style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: secondary ? SurgeColors.textSecondary : Colors.white)),
          ]),
    ),
  );
}