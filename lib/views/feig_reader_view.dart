import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/feig_reader_viewmodel.dart';
import '../widgets/connection_status_indicator.dart';

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

  Color _rssiColor(int rssi) {
    if (rssi > 200) return const Color(0xFF4CAF50);
    if (rssi > 100) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            title: Text(
              'FEIG Reader',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left panel: connection + inventory controls ───────────
              SizedBox(
                width: 320,
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _sectionLabel(context, 'Connection'),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _ipController,
                            enabled: !vm.isConnecting && !vm.isConnected,
                            decoration: _fieldDecoration(
                              context,
                              label: 'IP Address',
                              hint: '192.168.1.100',
                              icon: Icons.router_outlined,
                            ),
                            style: GoogleFonts.robotoMono(fontSize: 14),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.]'),
                              ),
                            ],
                            validator: _validateIp,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _portController,
                            enabled: !vm.isConnecting && !vm.isConnected,
                            decoration: _fieldDecoration(
                              context,
                              label: 'Port',
                              hint: '10001',
                              icon: Icons.settings_ethernet,
                            ),
                            style: GoogleFonts.robotoMono(fontSize: 14),
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
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 44,
                            child: vm.isConnected
                                ? OutlinedButton.icon(
                                    onPressed: vm.disconnect,
                                    icon: const Icon(Icons.link_off, size: 18),
                                    label: Text(
                                      'Disconnect',
                                      style: GoogleFonts.roboto(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          Theme.of(context).colorScheme.error,
                                      side: BorderSide(
                                        color:
                                            Theme.of(context).colorScheme.error,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  )
                                : FilledButton.icon(
                                    onPressed:
                                        vm.isConnecting ? null : _onConnect,
                                    icon: vm.isConnecting
                                        ? SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                            ),
                                          )
                                        : const Icon(Icons.link, size: 18),
                                    label: Text(
                                      vm.isConnecting
                                          ? 'Connecting…'
                                          : 'Connect',
                                      style: GoogleFonts.roboto(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: FilledButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          ConnectionStatusIndicator(
                            state: vm.state,
                            message: vm.statusMessage,
                          ),

                          // ── Inventory controls (connected only) ─────────
                          if (vm.isConnected) ...[
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),
                            _sectionLabel(context, 'Inventory'),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 44,
                              child: vm.isRunning
                                  ? OutlinedButton.icon(
                                      onPressed: vm.stopInventory,
                                      icon: const Icon(
                                        Icons.stop_circle_outlined,
                                        size: 18,
                                      ),
                                      label: Text(
                                        'Stop',
                                        style: GoogleFonts.roboto(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    )
                                  : FilledButton.icon(
                                      onPressed: vm.startInventory,
                                      icon: const Icon(
                                        Icons.play_circle_outlined,
                                        size: 18,
                                      ),
                                      label: Text(
                                        'Start Inventory',
                                        style: GoogleFonts.roboto(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: FilledButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                            ),
                            if (vm.isRunning || vm.loopTimeMs > 0) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Loop: ${vm.loopTimeMs.toStringAsFixed(1)} ms',
                                style: GoogleFonts.robotoMono(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const VerticalDivider(width: 1, thickness: 1),

              // ── Right panel: tag list ─────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header row with title + count badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Tags',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${vm.tags.length}',
                              style: GoogleFonts.roboto(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color:
                                    Theme.of(context).colorScheme.onPrimary,
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
                                style: GoogleFonts.roboto(fontSize: 13),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Tag list or placeholder
                    Expanded(
                      child: vm.tags.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.nfc,
                                    size: 48,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    vm.isRunning
                                        ? 'Scanning for tags…'
                                        : vm.isConnected
                                            ? 'Press Start Inventory'
                                            : 'Connect to the reader first',
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              itemCount: vm.tags.length,
                              separatorBuilder: (context, i) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (context, index) {
                                final tag = vm.tags[index];
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${index + 1}',
                                        style: GoogleFonts.robotoMono(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          tag.serialNumber,
                                          style: GoogleFonts.robotoMono(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _rssiColor(tag.rssi),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'RSSI ${tag.rssi}',
                                          style: GoogleFonts.roboto(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
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

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: GoogleFonts.roboto(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 18),
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: GoogleFonts.roboto(fontSize: 13),
      hintStyle: GoogleFonts.roboto(fontSize: 13),
    );
  }
}
