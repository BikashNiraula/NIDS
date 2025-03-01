import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nidswebapp/screens/dashboard/dashboard.dart';
import 'package:nidswebapp/views/alert_screen.dart';
import 'package:nidswebapp/views/logs_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Intrusion Detection ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NIDSDashboard(),
      getPages: [
        GetPage(name: '/dashboard', page: () => NIDSDashboard()),
        GetPage(name: '/alerts', page: () => AlertsScreen()),
        GetPage(name: '/logs', page: () => LogsScreen()),
      ],
    );
  }
}
