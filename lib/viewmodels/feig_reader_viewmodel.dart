import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/tag_data.dart';
import '../services/feig_reader_service.dart';

enum ReaderConnectionState { idle, connecting, connected, failed }

class FeigReaderViewModel extends ChangeNotifier {
  final FeigReaderService _service = FeigReaderService();

  ReaderConnectionState _state = ReaderConnectionState.idle;
  String _statusMessage = 'Not connected';
  String _lastIp = '';
  int _lastPort = 0;

  List<TagData> _tags = const [];
  double _loopTimeMs = 0.0;
  bool _isRunning = false;
  StreamSubscription<InventoryResult>? _inventorySub;

  ReaderConnectionState get state => _state;
  String get statusMessage => _statusMessage;
  bool get isConnected => _state == ReaderConnectionState.connected;
  bool get isConnecting => _state == ReaderConnectionState.connecting;
  List<TagData> get tags => _tags;
  double get loopTimeMs => _loopTimeMs;
  bool get isRunning => _isRunning;

  Future<void> connect(String ip, int port) async {
    _state = ReaderConnectionState.connecting;
    _statusMessage = 'Connecting to $ip:$port…';
    notifyListeners();

    final success = await _service.connect(
      ip,
      port,
      onDisconnected: _onUnexpectedDisconnect,
    );

    if (success) {
      _state = ReaderConnectionState.connected;
      _statusMessage = 'Connected to $ip:$port';
      _lastIp = ip;
      _lastPort = port;
    } else {
      _state = ReaderConnectionState.failed;
      _statusMessage = 'Failed — check IP/port and try again';
    }
    notifyListeners();
  }

  void _onUnexpectedDisconnect() {
    _isRunning = false;
    _state = ReaderConnectionState.failed;
    _statusMessage = 'Connection lost — cable unplugged or remote closed';
    notifyListeners();
  }

  Future<void> startInventory() async {
    if (_isRunning) return;
    _isRunning = true;
    _tags = const [];
    notifyListeners();

    _inventorySub = _service.startInventoryLoop().listen(
      (result) {
        _tags = result.tags;
        _loopTimeMs = result.loopTimeMs;
        notifyListeners();
      },
      onError: (Object _) {
        _isRunning = false;
        notifyListeners();
      },
      onDone: () {
        _isRunning = false;
        notifyListeners();
      },
      cancelOnError: true,
    );
  }

  Future<void> stopInventory() async {
    _service.stopInventoryLoop();
    await _inventorySub?.cancel();
    _inventorySub = null;
    _isRunning = false;
    notifyListeners();
  }

  Future<void> disconnect() async {
    await stopInventory();
    await _service.disconnect();
    _state = ReaderConnectionState.idle;
    _statusMessage = 'Disconnected from $_lastIp:$_lastPort';
    notifyListeners();
  }

  @override
  void dispose() {
    _inventorySub?.cancel();
    _service.stopInventoryLoop();
    _service.disconnect();
    super.dispose();
  }
}
