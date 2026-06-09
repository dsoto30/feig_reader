import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SignalStatsWidget extends StatelessWidget {
  final int? min;
  final int? max;
  final double? avg;
  final int statusByte;
  final String statusDesc;

  const SignalStatsWidget({
    super.key,
    required this.statusByte,
    required this.statusDesc,
    this.min,
    this.max,
    this.avg,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasStats = min != null && max != null && avg != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status row
          Text(
            'STATUS',
            style: GoogleFonts.roboto(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '0x${statusByte.toRadixString(16).padLeft(2, '0').toUpperCase()}',
                  style: GoogleFonts.robotoMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                statusDesc,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),

          if (hasStats) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 8),
            Text(
              'SIGNAL STATS',
              style: GoogleFonts.roboto(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 8),
            _StatRow(label: 'MIN', value: min!, cs: cs),
            const SizedBox(height: 4),
            _StatRow(label: 'MAX', value: max!, cs: cs),
            const SizedBox(height: 4),
            _StatRow(label: 'AVG', value: avg!.round(), cs: cs),
          ],
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int value;
  final ColorScheme cs;

  const _StatRow({required this.label, required this.value, required this.cs});

  Color _rssiColor(int rssi) {
    if (rssi > 200) return const Color(0xFF15803D);
    if (rssi > 100) return const Color(0xFFB45309);
    return const Color(0xFFB91C1C);
  }

  @override
  Widget build(BuildContext context) {
    final color = _rssiColor(value);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 30,
          child: Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            '$value',
            style: GoogleFonts.robotoMono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
