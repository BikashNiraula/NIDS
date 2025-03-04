import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nidswebapp/go_api/urls.dart';
import 'package:nidswebapp/go_api/web_socket.dart';
import 'package:nidswebapp/wireshark/packet_capture_screen.dart';

class WiresharkUI extends StatefulWidget {
  const WiresharkUI({super.key});

  @override
  State<WiresharkUI> createState() => _WiresharkUIState();
}

class _WiresharkUIState extends State<WiresharkUI>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> interfaces = [];
  late WebSocketService _webSocketService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 10, vsync: this);
    _webSocketService = WebSocketService(interfaceURL);

    _webSocketService.stream.listen((message) {
      setState(() {
        interfaces = json.decode(message);
      });
    }, onError: (error) {
      print("WebSocket error: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Background color
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(10.0),
            child: Text(
              "Select Network Interface",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          Expanded(child: NetworkInterfacesList(interfaces: interfaces)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _webSocketService.dispose(); // Close WebSocket connection
    super.dispose();
  }
}

// Network Interfaces List
class NetworkInterfacesList extends StatelessWidget {
  final List<dynamic> interfaces;

  const NetworkInterfacesList({super.key, required this.interfaces});

  @override
  Widget build(BuildContext context) {
    return interfaces.isEmpty
        ? const Center(
            child: Text(
              "No interfaces found",
              style: TextStyle(color: Colors.white),
            ),
          )
        : ListView.builder(
            itemCount: interfaces.length,
            itemBuilder: (context, index) {
              final interface = interfaces[index];
              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) {
                        return PacketCaptureScreen();
                      },
                    ));
                  },
                  title: Text(
                    interface['Name'] ?? 'Unknown Interface',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    "${interface['Description'] ?? 'No Description'}\nIP: ${interface['IPAddress'] ?? 'No IP'}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.wifi, color: Colors.white),
                ),
              );
            },
          );
  }
}
