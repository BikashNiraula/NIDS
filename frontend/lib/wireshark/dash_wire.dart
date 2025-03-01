import 'package:flutter/material.dart';
import 'package:nidswebapp/wireshark/capture.dart';
import 'package:nidswebapp/wireshark/packet.dart';

// Wireshark-like Tab Bar
class WiresharkTabBar extends StatelessWidget {
  final TabController controller;

  const WiresharkTabBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      tabs: const [
        Tab(icon: Icon(Icons.wifi, color: Colors.white)), // Wi-Fi icon
        Tab(icon: Icon(Icons.play_arrow, color: Colors.white)), // Start
        Tab(icon: Icon(Icons.stop, color: Colors.white)), // Stop
        Tab(icon: Icon(Icons.pause, color: Colors.white)), // Pause
        Tab(text: 'Capture', icon: Icon(Icons.camera_alt, color: Colors.white)),
        Tab(text: 'Analyze', icon: Icon(Icons.analytics, color: Colors.white)),
        Tab(
            text: 'Statistics',
            icon: Icon(Icons.bar_chart, color: Colors.white)),
        Tab(text: 'Telephony', icon: Icon(Icons.phone, color: Colors.white)),
        Tab(text: 'Wireless', icon: Icon(Icons.wifi, color: Colors.white)),
        Tab(text: 'Tools', icon: Icon(Icons.build, color: Colors.white)),
        Tab(text: 'Help', icon: Icon(Icons.help, color: Colors.white)),
      ],
      isScrollable: true,
      indicatorColor: Colors.green, // Disable selection indicator
      labelColor: Colors.white, // Set label color to white
      unselectedLabelColor: Colors.grey, // Set unselected label color to grey
    );
  }
}


// Capture Filter Input
class CaptureFilterInput extends StatelessWidget {
  const CaptureFilterInput({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        style: const TextStyle(color: Colors.white), // Text color
        decoration: InputDecoration(
          labelText: 'Enter a capture filter...',
          labelStyle: const TextStyle(color: Colors.white), // Label text color
          prefixIcon:
              const Icon(Icons.filter_list, color: Colors.white), // Icon color
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Colors.white), // Border color
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide:
                const BorderSide(color: Colors.white), // Enabled border color
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide:
                const BorderSide(color: Colors.white), // Focused border color
          ),
        ),
      ),
    );
  }
}

// Network Interfaces Dropdown
class NetworkInterfacesDropdown extends StatelessWidget {
  final List<String> interfaces = [
    'All',
    'en0',
    'eth0',
    'wlan0'
  ]; // Example interfaces

  NetworkInterfacesDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DropdownButtonFormField<String>(
        dropdownColor: Colors.black, // Dropdown background color
        style: const TextStyle(color: Colors.white), // Text color
        decoration: InputDecoration(
          labelText: 'Select Interface',
          labelStyle: const TextStyle(color: Colors.white), // Label text color
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Colors.white), // Border color
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide:
                const BorderSide(color: Colors.white), // Enabled border color
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide:
                const BorderSide(color: Colors.white), // Focused border color
          ),
        ),
        items: interfaces.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white)), // Dropdown item text color
          );
        }).toList(),
        onChanged: (value) {
          // Handle interface selection
        },
      ),
    );
  }
}

//* Main starting UI
// Wireshark-like UI
class WiresharkUI extends StatefulWidget {
  const WiresharkUI({super.key});

  @override
  State<WiresharkUI> createState() => _WiresharkUIState();
}

class _WiresharkUIState extends State<WiresharkUI>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 10, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Background color

      body: Column(
        children: [
          WiresharkTabBar(controller: _tabController),
          const CaptureFilterInput(),
          NetworkInterfacesDropdown(), // Dropdown for network interfaces
          const Expanded(child: NetworkInterfacesList()),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Network Interfaces List
class NetworkInterfacesList extends StatelessWidget {
  const NetworkInterfacesList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5, // Example count, replace with real data
      itemBuilder: (context, index) {
        return ListTile(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                // return PacketCaptureScreen();
                return PacketCaptureScreen();
              },
            ));
          },
          title: Text('Wi-Fi: en$index',
              style: const TextStyle(color: Colors.white)), // Text color
          subtitle: const Text('No Packets',
              style: TextStyle(color: Colors.grey)), // Subtitle color
          trailing: const Icon(Icons.wifi, color: Colors.white), // Icon color
        );
      },
    );
  }
}
