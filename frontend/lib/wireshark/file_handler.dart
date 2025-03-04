import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:nidswebapp/wireshark/packet_data.dart';
import 'package:intl/intl.dart';

class FileHandler {
  static Future<String?> getSaveFilePath() async {
    try {
      final String fileName =
          'packet_capture_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';

      final FileSaveLocation? file = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: [
          XTypeGroup(
            label: 'JSON',
            extensions: ['json'],
          ),
        ],
      );

      return file?.path;
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  static Future<void> savePacketsToFile(
      String filePath, List<PacketData> packets, BuildContext context) async {
    try {
      if (packets.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No packets to save")),
        );
        return;
      }

      final packetsList = packets.map((p) => p.rawData).toList();
      final jsonData = jsonEncode(packetsList);

      final file = File(filePath);
      await file.writeAsString(jsonData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Saved ${packets.length} packets to ${filePath.split('/').last}"),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OPEN FOLDER',
            onPressed: () {
              // This would open the folder containing the file
              // Platform-specific implementation needed
            },
          ),
        ),
      );
    } catch (e) {
      print("Error saving file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving file: $e")),
      );
    }
  }
}
