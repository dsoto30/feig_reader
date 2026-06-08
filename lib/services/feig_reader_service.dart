import 'dart:io';

class FeigReaderService {
  Socket? _socket;

  bool get isConnected => _socket != null;

  Future<bool> connect(
    String ip,
    int port, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      await disconnect();
      _socket = await Socket.connect(
        InternetAddress(ip, type: InternetAddressType.IPv4),
        port,
        timeout: timeout,
      );
      _socket!.setOption(SocketOption.tcpNoDelay, true);
      return true;
    } on SocketException {
      _socket = null;
      return false;
    } catch (_) {
      _socket = null;
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _socket?.close();
    } catch (_) {}
    _socket = null;
  }
}
