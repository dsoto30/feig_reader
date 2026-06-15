import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/feig_reader_provider.dart';
import '../widgets/connection_status_indicator.dart';
import '../widgets/signal_stats_widget.dart';

class FeigReaderView extends ConsumerStatefulWidget {
  const FeigReaderView({super.key});

  @override
  ConsumerState<FeigReaderView> createState() => _FeigReaderViewState();
}

class _FeigReaderViewState extends ConsumerState<FeigReaderView> {
  final _ipController = TextEditingController(text: '192.168.12.10');
  final _portController = TextEditingController(text: '10001');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _onConnect() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(feigReaderProvider.notifier).connect(
      _ipController.text.trim(),
      int.parse(_portController.text.trim()),
    );
  }

  String? _validateIp(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final parts = value.trim().split('.');
    if (parts.length != 4) return 'Invalid IPv4';
    for (final p in parts) {
      final n = int.tryParse(p);
      if (n == null || n < 0 || n > 255) return 'Invalid IPv4';
    }
    return null;
  }

  String? _validatePort(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final n = int.tryParse(value.trim());
    if (n == null || n < 1 || n > 65535) return 'Invalid port';
    return null;
  }

  String _formatCurrency(int amount) {
    final s = amount.toString();
    final buf = StringBuffer('\$');
    final offset = s.length % 3;
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (i - offset) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Color _rssiColor(int rssi) {
    if (rssi > 200) return const Color(0xFF15803D);
    if (rssi > 100) return const Color(0xFFB45309);
    return const Color(0xFFB91C1C);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feigReaderProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.nfc, size: 22),
            const SizedBox(width: 10),
            const Text('FEIG Reader'),
          ],
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left panel ───────────────────────────────────────────
          SizedBox(
            width: 340,
            child: Container(
              color: cs.surfaceContainerLowest,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionHeader(context, 'CONNECTION'),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ipController,
                        enabled: !state.isConnecting && !state.isConnected,
                        decoration: InputDecoration(
                          labelText: 'IP Address',
                          hintText: '192.168.1.100',
                          prefixIcon: const Icon(
                            Icons.router_outlined,
                            size: 20,
                          ),
                        ),
                        style: GoogleFonts.robotoMono(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[\d.]'),
                          ),
                        ],
                        validator: _validateIp,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _portController,
                        enabled: !state.isConnecting && !state.isConnected,
                        decoration: const InputDecoration(
                          labelText: 'Port',
                          hintText: '10001',
                          prefixIcon: Icon(
                            Icons.settings_ethernet,
                            size: 20,
                          ),
                        ),
                        style: GoogleFonts.robotoMono(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: _validatePort,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (!state.isConnected && !state.isConnecting) {
                            _onConnect();
                          }
                        },
                      ),
                      const SizedBox(height: 18),
                      state.isConnected
                          ? OutlinedButton.icon(
                              onPressed: () =>
                                  ref.read(feigReaderProvider.notifier).disconnect(),
                              icon: const Icon(Icons.link_off, size: 18),
                              label: const Text('Disconnect'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: cs.error,
                                side: BorderSide(color: cs.error),
                              ),
                            )
                          : FilledButton.icon(
                              onPressed: state.isConnecting ? null : _onConnect,
                              icon: state.isConnecting
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: cs.onPrimary,
                                      ),
                                    )
                                  : const Icon(Icons.link, size: 18),
                              label: Text(
                                state.isConnecting ? 'Connecting…' : 'Connect',
                              ),
                            ),
                      const SizedBox(height: 18),
                      ConnectionStatusIndicator(
                        state: state.connectionState,
                        message: state.statusMessage,
                      ),

                      // ── Scan controls ──────────────────────────────
                      if (state.isConnected) ...[
                        const SizedBox(height: 28),
                        const Divider(),
                        const SizedBox(height: 20),
                        _sectionHeader(context, 'SCAN'),
                        const SizedBox(height: 16),
                        state.isRunning
                            ? OutlinedButton.icon(
                                onPressed: () => ref
                                    .read(feigReaderProvider.notifier)
                                    .stopInventory(),
                                icon: const Icon(
                                  Icons.stop_circle_outlined,
                                  size: 18,
                                ),
                                label: const Text('Stop Scan'),
                              )
                            : FilledButton.icon(
                                onPressed: () => ref
                                    .read(feigReaderProvider.notifier)
                                    .startInventory(),
                                icon: const Icon(
                                  Icons.play_circle_outlined,
                                  size: 18,
                                ),
                                label: const Text('Start Scan'),
                              ),
                        if (state.isRunning || state.loopTimeMs > 0) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${state.loopTimeMs.toStringAsFixed(1)} ms / loop',
                                style: GoogleFonts.robotoMono(
                                  fontSize: 13,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],

                      // ── Signal stats ───────────────────────────────
                      if (state.isRunning || state.minRssi != null) ...[
                        const SizedBox(height: 28),
                        const Divider(),
                        const SizedBox(height: 20),
                        SignalStatsWidget(
                          statusByte: state.lastStatusByte,
                          statusDesc: state.lastStatusDesc,
                          min: state.minRssi,
                          max: state.maxRssi,
                          avg: state.avgRssi,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),

          // ── Right panel ───────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header: count, denomination chips, total ────────
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    border: Border(
                      bottom: BorderSide(color: cs.outlineVariant),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tags count row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'DETECTED TAGS',
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            constraints: const BoxConstraints(minWidth: 32),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${state.tags.length}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: cs.onPrimary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (state.tags.isNotEmpty)
                            TextButton.icon(
                              onPressed: () =>
                                  ref.read(feigReaderProvider.notifier).clearTags(),
                              icon: const Icon(Icons.clear_all, size: 16),
                              label: Text(
                                'Clear',
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Denomination chips
                      Text(
                        'CHIP VALUE',
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: kDenominations
                            .map(
                              (d) => ChoiceChip(
                                label: Text('\$$d'),
                                selected: state.denomination == d,
                                selectedColor: cs.primary,
                                labelPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 4,
                                ),
                                labelStyle: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: state.denomination == d
                                      ? cs.onPrimary
                                      : cs.onSurface,
                                ),
                                onSelected: (_) => ref
                                    .read(feigReaderProvider.notifier)
                                    .setDenomination(d),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),

                      // Total
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'TOTAL',
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            _formatCurrency(state.totalValue),
                            style: GoogleFonts.roboto(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: cs.primary,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Tag list ────────────────────────────────────────
                Expanded(
                  child: state.tags.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.nfc,
                                size: 56,
                                color: cs.outlineVariant,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                state.isRunning
                                    ? 'Scanning for tags…'
                                    : state.isConnected
                                    ? 'Press Start Scan to begin'
                                    : 'Connect to the reader first',
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.tags.length,
                          separatorBuilder: (context, i) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final tag = state.tags[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: cs.outlineVariant,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: cs.shadow.withValues(alpha: 0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 28,
                                    child: Text(
                                      '${index + 1}',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.roboto(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 20,
                                    color: cs.outlineVariant,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      tag.serialNumber,
                                      style: GoogleFonts.robotoMono(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _rssiColor(tag.rssi)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _rssiColor(tag.rssi)
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      'RSSI ${tag.rssi}',
                                      style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _rssiColor(tag.rssi),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String text) {
    return Text(
      text,
      style: GoogleFonts.roboto(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
