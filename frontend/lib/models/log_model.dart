class LogEntry {
  final DateTime timestamp;
  final String sourceIP;
  final String destinationIP;
  final String ruleID;
  final String action;

  LogEntry({
    required this.timestamp,
    required this.sourceIP,
    required this.destinationIP,
    required this.ruleID,
    required this.action,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.parse(json['timestamp']),
      sourceIP: json['sourceIP'],
      destinationIP: json['destinationIP'],
      ruleID: json['ruleID'],
      action: json['action'],
    );
  }
}
