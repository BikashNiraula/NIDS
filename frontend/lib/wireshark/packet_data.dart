class PacketData {
  final int no;
  final String time;
  final String source;
  final String destination;
  final String protocol;
  final int length;
  final String info;
  final String type;
  final Map<String, dynamic> rawData;

  const PacketData({
    required this.no,
    required this.time,
    required this.source,
    required this.destination,
    required this.protocol,
    required this.length,
    required this.info,
    required this.type,
    required this.rawData,
  });

  factory PacketData.fromJson(Map<String, dynamic> json) {
    return PacketData(
      no: json["no"] ?? 0,
      time: json["Timestamp"] ?? "Unknown",
      source: json["SourceIP"] ?? "Unknown",
      destination: json["DestinationIP"] ?? "Unknown",
      protocol: json["AppProtocol"] ?? json["NetworkProtocol"] ?? "Unknown",
      length: json["Length"] ?? 0,
      info: json["Flags"] ?? "None",
      type: json["Type"] ?? "normal",
      rawData: json,
    );
  }
}
