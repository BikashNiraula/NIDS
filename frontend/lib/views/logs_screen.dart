import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nidswebapp/controllers/log_controller.dart';

class LogsScreen extends StatelessWidget {
  final LogController logController = Get.put(LogController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logs'),
      ),
      body: Obx(() {
        if (logController.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        } else {
          return ListView.builder(
            itemCount: logController.logs.length,
            itemBuilder: (context, index) {
              var log = logController.logs[index];
              return ListTile(
                title: Text('Action: ${log.action}'),
                subtitle: Text('Rule ID: ${log.ruleID}'),
                trailing: Text(log.timestamp.toString()),
              );
            },
          );
        }
      }),
    );
  }
}
