import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '../bindings/performance_counter.dart';
import '../models/tag_data.dart';
import '../utils/feig_protocol.dart';

class InventoryResult {
  final List<TagData> tags;
  final double loopTimeMs;
  final int statusByte;

  const InventoryResult({
    required this.tags,
    required this.loopTimeMs,
    required this.statusByte,
  });
}

class FeigReaderService {
  Socket? _socket;
  StreamSubscription<List<int>>? _subscription;
  Completer<Uint8List>? _pendingResponse;
  final _rxBuffer = <int>[];
  int _expectedLength = -1;
  bool _running = false;
  StreamController<InventoryResult>? _inventoryController;

  bool get isConnected => _socket != null;

  Future<bool> connect(
    String ip,
    int port, {
    Duration timeout = const Duration(seconds: 5),
    required void Function() onDisconnected,
  }) async {
    try {
      await disconnect();
      _socket = await Socket.connect(
        InternetAddress(ip, type: InternetAddressType.IPv4),
        port,
        timeout: timeout,
      );
      _socket!.setOption(SocketOption.tcpNoDelay, true);

      _subscription = _socket!.listen(
        (data) {
          if (_pendingResponse == null) return;
          _rxBuffer.addAll(data);
          if (_expectedLength == -1 && _rxBuffer.length >= 3) {
            _expectedLength = _rxBuffer[1] * divUpperByte + _rxBuffer[2];
          }
          if (_expectedLength != -1 && _rxBuffer.length >= _expectedLength) {
            final resp = Uint8List.fromList(
              _rxBuffer.sublist(0, _expectedLength),
            );
            _rxBuffer.clear();
            _expectedLength = -1;
            final c = _pendingResponse!;
            _pendingResponse = null;
            c.complete(resp);
          }
        },
        onError: (Object e) {
          _socket?.destroy();
          _socket = null;
          final c = _pendingResponse;
          _pendingResponse = null;
          c?.completeError(e);
          _running = false;
          onDisconnected();
        },
        onDone: () {
          _socket?.destroy();
          _socket = null;
          final c = _pendingResponse;
          _pendingResponse = null;
          c?.completeError(StateError('Socket closed'));
          _running = false;
          onDisconnected();
        },
        cancelOnError: true,
      );

      return true;
    } on SocketException {
      _socket = null;
      return false;
    } catch (_) {
      _socket = null;
      return false;
    }
  }

  Stream<InventoryResult> startInventoryLoop() {
    _running = true;
    _inventoryController = StreamController<InventoryResult>.broadcast();
    _runLoop();
    return _inventoryController!.stream;
  }

  void stopInventoryLoop() {
    _running = false;
  }

  Future<void> _runLoop() async {
    final cmd = buildInventoryCommand();
    while (_running && _socket != null) {
      final t0 = PerformanceCounter.getCount();
      try {
        _socket!.add(cmd);
        final resp = await _receiveResponse();
        final loopMs = PerformanceCounter.elapsedMs(
          t0,
          PerformanceCounter.getCount(),
        );
        _inventoryController?.add(InventoryResult(
          tags: parseInventoryResponse(resp),
          loopTimeMs: loopMs,
          statusByte: resp.length > inventoryResponseStatusByte
              ? resp[inventoryResponseStatusByte]
              : 0,
        ));
      } catch (_) {
        _running = false;
        break;
      }
    }
    await _inventoryController?.close();
    _inventoryController = null;
  }

  Future<Uint8List> _receiveResponse() {
    _rxBuffer.clear();
    _expectedLength = -1;
    _pendingResponse = Completer<Uint8List>();
    return _pendingResponse!.future;
  }

  Future<void> disconnect() async {
    _running = false;
    await _subscription?.cancel();
    _subscription = null;
    final c = _pendingResponse;
    _pendingResponse = null;
    c?.completeError(StateError('Disconnected'));
    _socket?.destroy();
    _socket = null;
    _rxBuffer.clear();
    _expectedLength = -1;
  }
}
