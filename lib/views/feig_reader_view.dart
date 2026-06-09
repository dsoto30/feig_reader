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
    final ip = _ipController.text.trim();
    final port = int.parse(_portController.text.trim());
    widget.viewModel.connect(ip, port);
  }

  void _onDisconnect() => widget.viewModel.disconnect();

  String? _validateIp(String? value) {
    if (value == null || value.trim().isEmpty) return 'IP address required';
    final parts = value.trim().split('.');
    if (parts.length != 4) return 'Enter a valid IPv4 address';
    for (final p in parts) {
      final n = int.tryParse(p);
      if (n == null || n < 0 || n > 255) return 'Enter a valid IPv4 address';
    }
    return null;
  }

  String? _validatePort(String? value) {
    if (value == null || value.trim().isEmpty) return 'Port required';
    final n = int.tryParse(value.trim());
    if (n == null || n < 1 || n > 65535) return 'Port must be 1–65535';
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
        final busy = vm.isConnecting;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text(
              'FEIG Reader',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            centerTitle: false,
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Connection section ──────────────────────────────
                      Text(
                        'Connection',
                        style: GoogleFonts.roboto(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter the reader IP address and port to establish a TCP connection.',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _ipController,
                        enabled: !busy && !vm.isConnected,
                        decoration: InputDecoration(
                          labelText: 'IP Address',
                          hintText: '192.168.1.100',
                          prefixIcon: const Icon(Icons.router_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          labelStyle: GoogleFonts.roboto(),
                          hintStyle: GoogleFonts.roboto(),
                        ),
                        style: GoogleFonts.robotoMono(fontSize: 15),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                        ],
                        validator: _validateIp,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _portController,
                        enabled: !busy && !vm.isConnected,
                        decoration: InputDecoration(
                          labelText: 'Port',
                          hintText: '10001',
                          prefixIcon: const Icon(Icons.settings_ethernet),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          labelStyle: GoogleFonts.roboto(),
                          hintStyle: GoogleFonts.roboto(),
                        ),
                        style: GoogleFonts.robotoMono(fontSize: 15),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: _validatePort,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (!vm.isConnected && !busy) _onConnect();
                        },
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 48,
                        child: vm.isConnected
                            ? OutlinedButton.icon(
                                onPressed: _onDisconnect,
                                icon: const Icon(Icons.link_off),
                                label: Text(
                                  'Disconnect',
                                  style: GoogleFonts.roboto(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.error,
                                  side: BorderSide(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              )
                            : FilledButton.icon(
                                onPressed: busy ? null : _onConnect,
                                icon: busy
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                        ),
                                      )
                                    : const Icon(Icons.link),
                                label: Text(
                                  busy ? 'Connecting…' : 'Connect',
                                  style: GoogleFonts.roboto(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 24),
                      ConnectionStatusIndicator(
                        state: vm.state,
                        message: vm.statusMessage,
                      ),

                      // ── Inventory section (connected only) ──────────────
                      if (vm.isConnected) ...[
                        const SizedBox(height: 28),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          'Inventory',
                          style: GoogleFonts.roboto(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 48,
                          child: vm.isRunning
                              ? OutlinedButton.icon(
                                  onPressed: vm.stopInventory,
                                  icon: const Icon(Icons.stop_circle_outlined),
                                  label: Text(
                                    'Stop',
                                    style: GoogleFonts.roboto(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                )
                              : FilledButton.icon(
                                  onPressed: vm.startInventory,
                                  icon: const Icon(Icons.play_circle_outlined),
                                  label: Text(
                                    'Start Inventory',
                                    style: GoogleFonts.roboto(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                        ),
                        if (vm.isRunning || vm.loopTimeMs > 0) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Loop: ${vm.loopTimeMs.toStringAsFixed(1)} ms',
                            style: GoogleFonts.robotoMono(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (vm.tags.isEmpty)
                          Text(
                            vm.isRunning ? 'Scanning…' : 'No tags detected',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: vm.tags.length,
                            itemBuilder: (context, index) {
                              final tag = vm.tags[index];
                              return Card(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          tag.serialNumber,
                                          style: GoogleFonts.robotoMono(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
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
                                ),
                              );
                            },
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
