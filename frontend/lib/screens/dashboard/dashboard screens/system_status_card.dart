import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SystemStatusController extends GetxController {
  var os = 'Loading...'.obs;
  var cpuUsage = 'Loading...'.obs;
  var memoryUsage = 'Loading...'.obs;
  var diskUsage = 'Loading...'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSystemStatus();
  }

  Future<void> fetchSystemStatus() async {
    while (true) {
      try {
        final response =
            await http.get(Uri.parse('http://localhost:8080/status'));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);

          os.value = data['os'];
          cpuUsage.value = '${data['cpuUsage'].toStringAsFixed(2)}%';
          memoryUsage.value = '${data['memoryUsage'].toStringAsFixed(2)}%';
          diskUsage.value = '${data['diskUsage'].toStringAsFixed(2)}%';
        } else {
          os.value = 'Failed to load';
          cpuUsage.value = 'Failed to load';
          memoryUsage.value = 'Failed to load';
          diskUsage.value = 'Failed to load';
        }
      } catch (e) {
        os.value = 'Error';
        cpuUsage.value = 'Error';
        memoryUsage.value = 'Error';
        diskUsage.value = 'Error';
      }
      await Future.delayed(const Duration(seconds: 2)); // Poll every 2 sec
    }
  }
}

class SystemStatusCard extends StatelessWidget {
  final SystemStatusController controller = Get.put(SystemStatusController());

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Prevents overflow
          children: [
            const Text(
              'System Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Obx(() => Text('OS: ${controller.os.value}')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, // Prevents overflow
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMetricColumn(
                      'CPU Usage', controller.cpuUsage, Colors.green),
                  _buildMetricColumn(
                      'Memory', controller.memoryUsage, Colors.orange),
                  _buildMetricColumn('Disk', controller.diskUsage, Colors.blue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, RxString value, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Obx(() => Text(
              value.value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color),
            )),
      ],
    );
  }
}
