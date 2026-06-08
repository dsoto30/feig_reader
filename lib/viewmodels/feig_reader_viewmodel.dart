import 'package:flutter/foundation.dart';
import '../services/feig_reader_service.dart';

enum ReaderConnectionState { idle, connecting, connected, failed }

class FeigReaderViewModel extends ChangeNotifier {
  final FeigReaderService _service = FeigReaderService();

  ReaderConnectionState _state = ReaderConnectionState.idle;
  String _statusMessage = 'Not connected';
  String _lastIp = '';
  int _lastPort = 0;

  ReaderConnectionState get state => _state;
  String get statusMessage => _statusMessage;
  bool get isConnected => _state == ReaderConnectionState.connected;
  bool get isConnecting => _state == ReaderConnectionState.connecting;

  Future<void> connect(String ip, int port) async {
    _state = ReaderConnectionState.connecting;
    _statusMessage = 'Connecting to $ip:$port…';
    notifyListeners();

    final success = await _service.connect(ip, port);

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

  Future<void> disconnect() async {
    await _service.disconnect();
    _state = ReaderConnectionState.idle;
    _statusMessage = 'Disconnected from $_lastIp:$_lastPort';
    notifyListeners();
  }

  @override
  void dispose() {
    _service.disconnect();
    super.dispose();
  }
}
