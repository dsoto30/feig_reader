import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tag_data.dart';
import '../services/feig_reader_service.dart';
import '../utils/feig_protocol.dart';

enum ReaderConnectionState { idle, connecting, connected, failed }

const List<int> kDenominations = [5, 25, 100, 500, 1000];

class FeigReaderState {
  final ReaderConnectionState connectionState;
  final String statusMessage;
  final Map<String, int> tagMap;
  final double loopTimeMs;
  final bool isRunning;
  final int lastStatusByte;
  final int denomination;

  const FeigReaderState({
    this.connectionState = ReaderConnectionState.idle,
    this.statusMessage = 'Not connected',
    this.tagMap = const {},
    this.loopTimeMs = 0,
    this.isRunning = false,
    this.lastStatusByte = 0,
    this.denomination = 5,
  });

  bool get isConnected => connectionState == ReaderConnectionState.connected;
  bool get isConnecting => connectionState == ReaderConnectionState.connecting;
  int get totalValue => tagMap.length * denomination;
  String get lastStatusDesc => describeStatus(lastStatusByte);

  int? get minRssi => tagMap.isEmpty ? null : tagMap.values.reduce(min);
  int? get maxRssi => tagMap.isEmpty ? null : tagMap.values.reduce(max);
  double? get avgRssi =>
      tagMap.isEmpty
          ? null
          : tagMap.values.fold(0, (a, b) => a + b) / tagMap.length;

  List<TagData> get tags {
    final entries = tagMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries
        .map((e) => TagData(serialNumber: e.key, rssi: e.value))
        .toList();
  }

  FeigReaderState copyWith({
    ReaderConnectionState? connectionState,
    String? statusMessage,
    Map<String, int>? tagMap,
    double? loopTimeMs,
    bool? isRunning,
    int? lastStatusByte,
    int? denomination,
  }) => FeigReaderState(
    connectionState: connectionState ?? this.connectionState,
    statusMessage: statusMessage ?? this.statusMessage,
    tagMap: tagMap ?? this.tagMap,
    loopTimeMs: loopTimeMs ?? this.loopTimeMs,
    isRunning: isRunning ?? this.isRunning,
    lastStatusByte: lastStatusByte ?? this.lastStatusByte,
    denomination: denomination ?? this.denomination,
  );
}

final feigServiceProvider = Provider<FeigReaderService>((ref) {
  final service = FeigReaderService();
  ref.onDispose(() => service.disconnect());
  return service;
});

class FeigReaderNotifier extends Notifier<FeigReaderState> {
  StreamSubscription<InventoryResult>? _sub;

  @override
  FeigReaderState build() => const FeigReaderState();

  FeigReaderService get _service => ref.read(feigServiceProvider);

  Future<void> connect(String ip, int port) async {
    state = state.copyWith(
      connectionState: ReaderConnectionState.connecting,
      statusMessage: 'Connecting to $ip:$port…',
    );
    final ok = await _service.connect(ip, port, onDisconnected: _onLost);
    state = state.copyWith(
      connectionState:
          ok ? ReaderConnectionState.connected : ReaderConnectionState.failed,
      statusMessage:
          ok ? 'Connected to $ip:$port' : 'Failed — check IP/port and try again',
    );
  }

  void _onLost() {
    _sub?.cancel();
    _sub = null;
    state = state.copyWith(
      isRunning: false,
      connectionState: ReaderConnectionState.failed,
      statusMessage: 'Connection lost — cable unplugged or remote closed',
    );
  }

  Future<void> startInventory() async {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true);
    _sub = _service.startInventoryLoop().listen(
      (result) {
        state = state.copyWith(
          tagMap: Map.fromEntries(
            result.tags.map((t) => MapEntry(t.serialNumber, t.rssi)),
          ),
          loopTimeMs: result.loopTimeMs,
          lastStatusByte: result.statusByte,
        );
      },
      onDone: () => state = state.copyWith(isRunning: false),
      onError: (_) => state = state.copyWith(isRunning: false),
      cancelOnError: true,
    );
  }

  Future<void> stopInventory() async {
    _service.stopInventoryLoop();
    await _sub?.cancel();
    _sub = null;
    state = state.copyWith(isRunning: false);
  }

  Future<void> disconnect() async {
    await stopInventory();
    await _service.disconnect();
    state = state.copyWith(
      connectionState: ReaderConnectionState.idle,
      statusMessage: 'Not connected',
    );
  }

  void clearTags() => state = state.copyWith(tagMap: {});
  void setDenomination(int value) => state = state.copyWith(denomination: value);
}

final feigReaderProvider =
    NotifierProvider<FeigReaderNotifier, FeigReaderState>(
      FeigReaderNotifier.new,
    );
