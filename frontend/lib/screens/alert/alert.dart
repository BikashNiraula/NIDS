
// import 'package:flutter/material.dart';
// import 'package:nidswebapp/screens/alert/alert_service.dart';

// class AlertsPage extends StatefulWidget {
//   @override
//   _AlertsPageState createState() => _AlertsPageState();
// }

// class _AlertsPageState extends State<AlertsPage> {
//   List<Map<String, dynamic>> alerts = [];
//   late AlertService _alertService;

//   @override
//   void initState() {
//     super.initState();
//     _alertService = AlertService();
//     _connectToAlerts();
//   }

//   void _connectToAlerts() {
//     _alertService.alertStream.listen(
//       (data) {
//         print("🚨 Alert Received: $data");
//         final alertData = _parseAlertMessage(data.toString());
//         setState(() {
//           alerts.insert(0, alertData);
//         });
//       },
//       onError: (error) {
//         print('❌ WebSocket error: $error');
//         _showErrorDialog(error.toString());
//       },
//       onDone: () {
//         print('⚠️ WebSocket connection closed');
//         _showErrorDialog('WebSocket connection closed');
//       },
//     );
//   }

//   Map<String, dynamic> _parseAlertMessage(String message) {
//     try {
//       // More flexible parsing
//       return {
//         'sid': _extractValue(message, 'SID', 'N/A'),
//         'msg': message,
//         'source_ip': _extractValue(message, 'Source IP', 'Unknown'),
//         'source_port': _extractValue(message, 'Source Port', 'Unknown'),
//         'destination_ip': _extractValue(message, 'Destination IP', 'Unknown'),
//         'destination_port':
//             _extractValue(message, 'Destination Port', 'Unknown'),
//         'protocol': _extractValue(message, 'Protocol', 'Unknown'),
//       };
//     } catch (e) {
//       print("⚠️ Parsing Error: $e");
//       return {
//         'sid': 'N/A',
//         'msg': message,
//         'source_ip': 'Unknown',
//         'source_port': 'Unknown',
//         'destination_ip': 'Unknown',
//         'destination_port': 'Unknown',
//         'protocol': 'Unknown',
//       };
//     }
//   }

//   // Utility method to extract values more flexibly
//   String _extractValue(String message, String key, String defaultValue) {
//     final regex = RegExp('$key[: ]+([^,\n]+)', caseSensitive: false);
//     final match = regex.firstMatch(message);
//     return match?.group(1)?.trim() ?? defaultValue;
//   }

//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('WebSocket Error'),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: Text('OK'),
//           )
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('NIDS Alerts'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh),
//             onPressed: () => setState(() => alerts.clear()),
//           )
//         ],
//       ),
//       body: alerts.isEmpty
//           ? Center(child: Text('No alerts received'))
//           : ListView.builder(
//               itemCount: alerts.length,
//               itemBuilder: (context, index) {
//                 final alert = alerts[index];
//                 return Card(
//                   margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//                   child: ListTile(
//                     title: Text(alert['msg'],
//                         style: TextStyle(fontWeight: FontWeight.bold)),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('SID: ${alert['sid']}'),
//                         Text(
//                             'Source: ${alert['source_ip']}:${alert['source_port']}'),
//                         Text(
//                             'Destination: ${alert['destination_ip']}:${alert['destination_port']}'),
//                         Text('Protocol: ${alert['protocol']}'),
//                       ],
//                     ),
//                     leading: Icon(Icons.warning, color: Colors.red),
//                   ),
//                 );
//               },
//             ),
//     );
//   }

//   @override
//   void dispose() {
//     _alertService.close(); // Close the WebSocket connection
//     print("❌ WebSocket Closed");
//     super.dispose();
//   }
// }
import 'package:flutter/material.dart';
import 'package:nidswebapp/db/sqlite.dart';
import 'package:nidswebapp/screens/alert/alert_service.dart';

class AlertsPage extends StatefulWidget {
  @override
  _AlertsPageState createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  List<Map<String, dynamic>> alerts = [];
  late AlertService _alertService;
  final SQLiteHandler _dbHelper = SQLiteHandler(); // SQLiteHandler instance

  @override
  void initState() {
    super.initState();
    _alertService = AlertService();
    _loadAlerts(); // Load alerts from the database when the page initializes
    _connectToAlerts();
  }

  void _loadAlerts() async {
    final savedAlerts = await _dbHelper.getAllAlerts();
    setState(() {
      alerts = savedAlerts;
    });
  }

  void _connectToAlerts() {
    _alertService.alertStream.listen(
      (data) async {
        print("🚨 Alert Received: $data");
        final alertData = _parseAlertMessage(data.toString());
        setState(() {
          alerts.insert(0, alertData);
        });

        // Save the alert to the database
        await _dbHelper.saveAlert(alertData);
      },
      onError: (error) {
        print('❌ WebSocket error: $error');
        _showErrorDialog(error.toString());
      },
      onDone: () {
        print('⚠️ WebSocket connection closed');
        _showErrorDialog('WebSocket connection closed');
      },
    );
  }

  Map<String, dynamic> _parseAlertMessage(String message) {
    try {
      return {
        'sid': _extractValue(message, 'SID', 'N/A'),
        'msg': message,
        'source_ip': _extractValue(message, 'Source IP', 'Unknown'),
        'source_port': _extractValue(message, 'Source Port', 'Unknown'),
        'destination_ip': _extractValue(message, 'Destination IP', 'Unknown'),
        'destination_port':
            _extractValue(message, 'Destination Port', 'Unknown'),
        'protocol': _extractValue(message, 'Protocol', 'Unknown'),
      };
    } catch (e) {
      print("⚠️ Parsing Error: $e");
      return {
        'sid': 'N/A',
        'msg': message,
        'source_ip': 'Unknown',
        'source_port': 'Unknown',
        'destination_ip': 'Unknown',
        'destination_port': 'Unknown',
        'protocol': 'Unknown',
      };
    }
  }

  String _extractValue(String message, String key, String defaultValue) {
    final regex = RegExp('$key[: ]+([^,\n]+)', caseSensitive: false);
    final match = regex.firstMatch(message);
    return match?.group(1)?.trim() ?? defaultValue;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('WebSocket Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NIDS Alerts'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              await _dbHelper.clearAlerts(); // Clear alerts from the database
              setState(() {
                alerts.clear();
              });
            },
          )
        ],
      ),
      body: alerts.isEmpty
          ? Center(child: Text('No alerts received'))
          : ListView.builder(
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    title: Text(alert['msg'],
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SID: ${alert['sid']}'),
                        Text(
                            'Source: ${alert['source_ip']}:${alert['source_port']}'),
                        Text(
                            'Destination: ${alert['destination_ip']}:${alert['destination_port']}'),
                        Text('Protocol: ${alert['protocol']}'),
                      ],
                    ),
                    leading: Icon(Icons.warning, color: Colors.red),
                  ),
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    _alertService.close(); // Close the WebSocket connection
    print("❌ WebSocket Closed");
    super.dispose();
  }
}
