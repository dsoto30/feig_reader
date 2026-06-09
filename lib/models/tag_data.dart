final class TagData {
  final String serialNumber;
  final int rssi;

  const TagData({required this.serialNumber, required this.rssi});

  @override
  bool operator ==(Object other) =>
      other is TagData &&
      other.serialNumber == serialNumber &&
      other.rssi == rssi;

  @override
  int get hashCode => Object.hash(serialNumber, rssi);
}
