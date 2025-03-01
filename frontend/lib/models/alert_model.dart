class Alert {
  final DateTime timestamp;
  final String message;
  final String severity;
  final String sourceIP;
  final String destinationIP;
  final String ruleID;

  Alert({
    required this.timestamp,
    required this.message,
    required this.severity,
    required this.sourceIP,
    required this.destinationIP,
    required this.ruleID,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      timestamp: DateTime.parse(json['timestamp']),
      message: json['message'],
      severity: json['severity'],
      sourceIP: json['sourceIP'],
      destinationIP: json['destinationIP'],
      ruleID: json['ruleID'],
    );
  }
}
