import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/feig_reader_viewmodel.dart';
import '../widgets/connection_status_indicator.dart';
import '../widgets/signal_stats_widget.dart';

class FeigReaderView extends StatefulWidget {
  final FeigReaderViewModel viewModel;

  const FeigReaderView({super.key, required this.viewModel});

  @override
  State<FeigReaderView> createState() => _FeigReaderViewState();
}

class _FeigReaderViewState extends State<FeigReaderView> {
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
    widget.viewModel.connect(
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
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
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
                            enabled: !vm.isConnecting && !vm.isConnected,
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
                            enabled: !vm.isConnecting && !vm.isConnected,
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
                              if (!vm.isConnected && !vm.isConnecting) {
                                _onConnect();
                              }
                            },
                          ),
                          const SizedBox(height: 18),
                          vm.isConnected
                              ? OutlinedButton.icon(
                                  onPressed: vm.disconnect,
                                  icon: const Icon(Icons.link_off, size: 18),
                                  label: const Text('Disconnect'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: cs.error,
                                    side: BorderSide(color: cs.error),
                                  ),
                                )
                              : FilledButton.icon(
                                  onPressed: vm.isConnecting
                                      ? null
                                      : _onConnect,
                                  icon: vm.isConnecting
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
                                    vm.isConnecting ? 'Connecting…' : 'Connect',
                                  ),
                                ),
                          const SizedBox(height: 18),
                          ConnectionStatusIndicator(
                            state: vm.state,
                            message: vm.statusMessage,
                          ),

                          // ── Scan controls ──────────────────────────────
                          if (vm.isConnected) ...[
                            const SizedBox(height: 28),
                            const Divider(),
                            const SizedBox(height: 20),
                            _sectionHeader(context, 'SCAN'),
                            const SizedBox(height: 16),
                            vm.isRunning
                                ? OutlinedButton.icon(
                                    onPressed: vm.stopInventory,
                                    icon: const Icon(
                                      Icons.stop_circle_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Stop Scan'),
                                  )
                                : FilledButton.icon(
                                    onPressed: vm.startInventory,
                                    icon: const Icon(
                                      Icons.play_circle_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Start Scan'),
                                  ),
                            if (vm.isRunning || vm.loopTimeMs > 0) ...[
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
                                    '${vm.loopTimeMs.toStringAsFixed(1)} ms / loop',
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
                          if (vm.isRunning || vm.minRssi != null) ...[
                            const SizedBox(height: 28),
                            const Divider(),
                            const SizedBox(height: 20),
                            SignalStatsWidget(
                              statusByte: vm.lastStatusByte,
                              statusDesc: vm.lastStatusDesc,
                              min: vm.minRssi,
                              max: vm.maxRssi,
                              avg: vm.avgRssi,
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
                                  '${vm.tags.length}',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: cs.onPrimary,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (vm.tags.isNotEmpty)
                                TextButton.icon(
                                  onPressed: vm.clearTags,
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
                            children: FeigReaderViewModel.denominations
                                .map(
                                  (d) => ChoiceChip(
                                    label: Text('\$$d'),
                                    selected: vm.denomination == d,
                                    selectedColor: cs.primary,
                                    labelPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 4,
                                    ),
                                    labelStyle: GoogleFonts.roboto(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: vm.denomination == d
                                          ? cs.onPrimary
                                          : cs.onSurface,
                                    ),
                                    onSelected: (_) => vm.setDenomination(d),
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
                                _formatCurrency(vm.totalValue),
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
                      child: vm.tags.isEmpty
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
                                    vm.isRunning
                                        ? 'Scanning for tags…'
                                        : vm.isConnected
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
                              itemCount: vm.tags.length,
                              separatorBuilder: (context, i) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final tag = vm.tags[index];
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
                                        color: cs.shadow.withValues(
                                          alpha: 0.06,
                                        ),
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
                                          color: _rssiColor(
                                            tag.rssi,
                                          ).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: _rssiColor(
                                              tag.rssi,
                                            ).withValues(alpha: 0.4),
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
      },
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
