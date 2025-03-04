import 'dart:convert';

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

  factory PacketData.fromMap(Map<String, dynamic> map) {
    return PacketData(
      no: map['no'],
      time: map['time'],
      source: map['source'],
      destination: map['destination'],
      protocol: map['protocol'],
      length: map['length'],
      info: map['info'],
      type: map['type'],
      rawData: jsonDecode(map['rawData']), // Convert JSON string back to Map
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'no': no,
      'time': time,
      'source': source,
      'destination': destination,
      'protocol': protocol,
      'length': length,
      'info': info,
      'type': type,
      'rawData': jsonEncode(rawData), // Convert Map to JSON string
    };
  }
}
