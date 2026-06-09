import 'dart:typed_data';
import '../models/tag_data.dart';
import 'feig_utils.dart';

const int inventoryResponseStatusByte = 5;
const int inventoryResponseDatasetsByte = 6;
const int maskUpperByte = 0xFF;
const int maskLowerByte = 0xFF00;
const int divUpperByte = 256;

Uint8List buildInventoryCommand() {
  final cmd = Uint8List.fromList(
    [0x02, 0x00, 0x0A, 0x00, 0xB0, 0x01, 0x10, 0x01],
  );
  final crc = crc16Q1(cmd, cmd.length);
  return Uint8List.fromList([...cmd, crc & maskUpperByte, (crc >> 8) & maskUpperByte]);
}

List<TagData> parseInventoryResponse(Uint8List bytes) {
  final tags = <TagData>[];
  if (bytes.length <= inventoryResponseDatasetsByte) return tags;

  final numDatasets = bytes[inventoryResponseDatasetsByte];
  int offset = 10;

  for (int i = 0; i < numDatasets; i++) {
    if (offset >= bytes.length) break;

    final leninfo = bytes[offset];
    int snOffset;
    int rssiOffset;

    if (leninfo == 14) {
      snOffset = offset + 3;
      rssiOffset = offset + 18;
    } else if (leninfo == 16) {
      snOffset = offset + 5;
      rssiOffset = offset + 20;
    } else {
      offset += leninfo + 8;
      continue;
    }

    if (rssiOffset >= bytes.length || snOffset + 12 > bytes.length) break;

    final sn = bytes
        .sublist(snOffset, snOffset + 12)
        .map(formatHex1)
        .join();
    tags.add(TagData(serialNumber: sn, rssi: bytes[rssiOffset]));

    offset += leninfo + 8;
  }

  return tags;
}
