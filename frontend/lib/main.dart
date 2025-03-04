import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nidswebapp/db/degub_screen.dart';
import 'package:nidswebapp/db/sqlite.dart';
import 'package:nidswebapp/screens/dashboard/dashboard.dart';
import 'package:nidswebapp/views/alert_screen.dart';
import 'package:nidswebapp/views/logs_screen.dart';
import 'package:sqflite_common/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> initServices() async {
  print('Initializing Services...');
  try {
    await SQLiteHandler().init();
    print('Database Initialized');
  } catch (e) {
    Get.snackbar("Error", "Failed to initialize SQLite Database");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (GetPlatform.isWeb) {
    databaseFactory =
        databaseFactoryFfiWeb; // This is what initializes the IndexedDB storage
    print("Database Factory Initialized for Web");
  }

  await initServices();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Intrusion Detection System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NIDSDashboard(),
      getPages: [
        GetPage(name: '/dashboard', page: () => NIDSDashboard()),
        GetPage(name: '/alerts', page: () => AlertsScreen()),
        GetPage(name: '/logs', page: () => LogsScreen()),
        GetPage(name: '/debug', page: () => DebugScreen()), // Debug Route
      ],
    );
  }
}
