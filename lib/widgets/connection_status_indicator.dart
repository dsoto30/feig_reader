import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/feig_reader_viewmodel.dart' show ReaderConnectionState;

class ConnectionStatusIndicator extends StatelessWidget {
  final ReaderConnectionState state;
  final String message;

  const ConnectionStatusIndicator({
    super.key,
    required this.state,
    required this.message,
  });

  Color get _dotColor => switch (state) {
    ReaderConnectionState.connected => const Color(0xFF15803D),
    ReaderConnectionState.connecting => const Color(0xFFB45309),
    ReaderConnectionState.failed => const Color(0xFFB91C1C),
    ReaderConnectionState.idle => const Color(0xFF64748B),
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _dotColor.withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message,
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
