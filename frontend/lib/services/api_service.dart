// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:nidswebapp/models/alert_model.dart';
// import 'package:nidswebapp/models/log_model.dart';

// class ApiService {
//   static const String baseUrl = 'http://your-go-backend:8080';

//   Future<List<Alert>> getAlerts() async {
//     final response = await http.get(Uri.parse('$baseUrl/alerts'));
//     if (response.statusCode == 200) {
//       List<dynamic> data = json.decode(response.body);
//       return data.map((json) => Alert.fromJson(json)).toList();
//     } else {
//       throw Exception('Failed to load alerts');
//     }
//   }

//   Future<List<LogEntry>> getLogs() async {
//     final response = await http.get(Uri.parse('$baseUrl/logs'));
//     if (response.statusCode == 200) {
//       List<dynamic> data = json.decode(response.body);
//       return data.map((json) => LogEntry.fromJson(json)).toList();
//     } else {
//       throw Exception('Failed to load logs');
//     }
//   }
// }
