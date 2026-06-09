import 'dart:ffi';
import 'dart:io' show Platform;
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

typedef _QpcNative = Int32 Function(Pointer<Int64>);
typedef _QpcDart = int Function(Pointer<Int64>);

class PerformanceCounter {
  static late _QpcDart _qpc;
  static late _QpcDart _qpf;
  static int _freq = 1000000;
  static bool _useNative = false;
  static late Stopwatch _sw;

  static void init() {
    if (!kIsWeb && Platform.isWindows) {
      try {
        final lib = DynamicLibrary.open('kernel32.dll');
        _qpc = lib.lookupFunction<_QpcNative, _QpcDart>(
          'QueryPerformanceCounter',
        );
        _qpf = lib.lookupFunction<_QpcNative, _QpcDart>(
          'QueryPerformanceFrequency',
        );
        final p = calloc<Int64>();
        _qpf(p);
        _freq = p.value;
        calloc.free(p);
        _useNative = true;
        return;
      } catch (_) {
        // fall through to Stopwatch fallback
      }
    }
    _sw = Stopwatch()..start();
  }

  static int getCount() {
    if (_useNative) {
      final p = calloc<Int64>();
      _qpc(p);
      final v = p.value;
      calloc.free(p);
      return v;
    }
    return _sw.elapsedMicroseconds;
  }

  static int get frequency => _freq;

  static double elapsedMs(int c1, int c2) => (c2 - c1) / _freq * 1000.0;
}
