// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:nidswebapp/controllers/alert_controller.dart';

// class AlertsScreen extends StatelessWidget {
//   final AlertController alertController = Get.put(AlertController());

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Alerts'),
//       ),
//       body: Obx(() {
//         if (alertController.isLoading.value) {
//           return Center(
//               child: CircularProgressIndicator(
//             color: Colors.black,
//           ));
//         } else {
//           return ListView.builder(
//             itemCount: alertController.alerts.length,
//             itemBuilder: (context, index) {
//               var alert = alertController.alerts[index];
//               return ListTile(
//                 title: Text(alert.message),
//                 subtitle: Text('Severity: ${alert.severity}'),
//                 trailing: Text(alert.timestamp.toString()),
//               );
//             },
//           );
//         }
//       }),
//     );
//   }
// }
