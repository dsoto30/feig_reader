import 'dart:convert';
import 'dart:typed_data';

int crc16Q1(Uint8List buffer, int length) {
  int crc = 0xFFFF;
  for (int i = 0; i < length; i++) {
    crc ^= buffer[i];
    for (int j = 0; j < 8; j++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0x8408 : crc >> 1;
    }
  }
  return crc & 0xFFFF;
}

String formatHex1(int val) =>
    val.toRadixString(16).padLeft(2, '0').toUpperCase();

String convert2Base64(String msg) => base64Encode(utf8.encode(msg));
