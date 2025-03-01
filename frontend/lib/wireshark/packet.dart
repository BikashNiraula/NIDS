// import 'package:flutter/material.dart';

// class PacketCaptureScreen extends StatefulWidget {
//   const PacketCaptureScreen({Key? key}) : super(key: key);

//   @override
//   _PacketCaptureScreenState createState() => _PacketCaptureScreenState();
// }

// class PacketData {
//   final int no;
//   final String time;
//   final String source;
//   final String destination;
//   final String protocol;
//   final int length;
//   final String info;
//   final PacketType type;
//   final Map<String, dynamic>?
//       rawData; // Store raw packet data for detailed view

//   PacketData({
//     required this.no,
//     required this.time,
//     required this.source,
//     required this.destination,
//     required this.protocol,
//     required this.length,
//     required this.info,
//     this.type = PacketType.normal,
//     this.rawData,
//   });
// }

// enum PacketType { normal, attack, retransmission, clientHello, synAck }

// class _PacketCaptureScreenState extends State<PacketCaptureScreen> {
//   final List<PacketData> _packets = [];
//   PacketData? _selectedPacket;
//   bool _isLoading = true;

//   // Column width configurations
//   final Map<String, double> _columnWidths = {
//     'no': 60,
//     'time': 100,
//     'source': 150,
//     'destination': 150,
//     'protocol': 80,
//     'length': 80,
//     'info': 300,
//   };

//   @override
//   void initState() {
//     super.initState();
//     _fetchPacketData();
//   }

//   // Simulating fetching data from a network capture service
//   Future<void> _fetchPacketData() async {
//     setState(() {
//       _isLoading = true;
//     });

//     // This would be replaced with actual API call or service
//     await Future.delayed(const Duration(milliseconds: 500));

//     // Clear existing packets if needed
//     _packets.clear();

//     // Add packets from the network capture service
//     setState(() {
//       _loadSampleData(); // Replace with actual data fetching
//       _isLoading = false;
//     });
//   }

//   // Sample data - this would be replaced with real data from your packet capture service
//   void _loadSampleData() {
//     _packets.addAll([
//       PacketData(
//         no: 2145,
//         time: "14.493964",
//         source: "142.251.42.14",
//         destination: "10.100.30.53",
//         protocol: "TCP",
//         length: 60,
//         info: "443 → 65149 [ACK] Seq=6585 Ack=582 Win=30336 Len=0",
//         rawData: {
//           'frame': {
//             'number': 2145,
//             'timestamp': '14.493964',
//             'length_on_wire': 60,
//             'interface': 'en0',
//           },
//           'ethernet': {
//             'src_mac': '46:51:5a:ea:83:0e',
//             'dst_mac': '5c:8a:38:bc:2e:58',
//             'type': '0x0800',
//           },
//           'ipv4': {
//             'version': 4,
//             'header_length': 20,
//             'src_addr': '142.251.42.14',
//             'dst_addr': '10.100.30.53',
//           },
//           'tcp': {
//             'src_port': 443,
//             'dst_port': 65149,
//             'seq': 6585,
//             'ack': 582,
//             'flags': ['ACK'],
//             'window_size': 30336,
//           },
//         },
//       ),
//       // Additional sample packets with the same structure...
//       PacketData(
//         no: 2146,
//         time: "14.498892",
//         source: "10.100.30.53",
//         destination: "142.251.42.14",
//         protocol: "TLSv1",
//         length: 272,
//         info: "Application Data",
//         rawData: {
//           'frame': {
//             'number': 2146,
//             'timestamp': '14.498892',
//             'length_on_wire': 272,
//             'interface': 'en0',
//           },
//           // Additional protocol details would be here
//         },
//       ),
//       // More sample packets...
//     ]);
//   }

//   Color _getPacketColor(PacketType type) {
//     switch (type) {
//       case PacketType.attack:
//         return Colors.red.shade200;
//       case PacketType.retransmission:
//         return Colors.amber.shade200;
//       case PacketType.clientHello:
//         return Colors.green.shade200;
//       case PacketType.synAck:
//         return Colors.blue.shade200;
//       case PacketType.normal:
//       default:
//         return Colors.transparent;
//     }
//   }

//   Color _getPacketTextColor(PacketType type) {
//     return type == PacketType.normal ? Colors.white : Colors.black;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Network Packet Capture'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.filter_list),
//             tooltip: 'Apply a display filter...',
//             onPressed: () {
//               // Implement filter functionality
//               _showFilterDialog();
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             tooltip: 'Restart capture',
//             onPressed: _fetchPacketData,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             flex: 3,
//             child: _isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : _buildPacketTable(),
//           ),
//           const Divider(height: 1, thickness: 1),
//           Expanded(
//             flex: 2,
//             child: _buildDetailView(),
//           ),
//         ],
//       ),
//       bottomNavigationBar: BottomAppBar(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           child: Row(
//             children: [
//               Text(
//                   'Packets: ${_packets.length} · Displaying: ${_packets.length}'),
//               const Spacer(),
//               const Text('Profile: Default'),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildPacketTable() {
//     return Column(
//       children: [
//         _buildTableHeader(),
//         Expanded(
//           child: ListView.builder(
//             itemCount: _packets.length,
//             itemBuilder: (context, index) {
//               final packet = _packets[index];
//               return _buildPacketRow(packet);
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildTableHeader() {
//     return Container(
//       color: Colors.blue,
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         children: [
//           _buildHeaderCell('No.', _columnWidths['no']!),
//           _buildHeaderCell('Time', _columnWidths['time']!),
//           _buildHeaderCell('Source', _columnWidths['source']!),
//           _buildHeaderCell('Destination', _columnWidths['destination']!),
//           _buildHeaderCell('Protocol', _columnWidths['protocol']!),
//           _buildHeaderCell('Length', _columnWidths['length']!),
//           Expanded(child: _buildHeaderCell('Info', _columnWidths['info']!)),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeaderCell(String text, double width) {
//     return Container(
//       width: text == 'Info' ? null : width,
//       padding: const EdgeInsets.symmetric(horizontal: 8),
//       child: Text(
//         text,
//         style: const TextStyle(
//           fontWeight: FontWeight.bold,
//           color: Colors.white,
//         ),
//         overflow: TextOverflow.ellipsis,
//       ),
//     );
//   }

//   Widget _buildPacketRow(PacketData packet) {
//     final isSelected = _selectedPacket?.no == packet.no;
//     final bgColor = isSelected
//         ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
//         : _getPacketColor(packet.type);
//     final textColor = _getPacketTextColor(packet.type);

//     return InkWell(
//       onTap: () {
//         setState(() {
//           _selectedPacket = packet;
//         });
//       },
//       child: Container(
//         color: bgColor,
//         padding: const EdgeInsets.symmetric(vertical: 4),
//         child: Row(
//           children: [
//             _buildCell(packet.no.toString(), _columnWidths['no']!, textColor),
//             _buildCell(packet.time, _columnWidths['time']!, textColor),
//             _buildCell(packet.source, _columnWidths['source']!, textColor),
//             _buildCell(
//                 packet.destination, _columnWidths['destination']!, textColor),
//             _buildCell(packet.protocol, _columnWidths['protocol']!, textColor),
//             _buildCell(
//                 packet.length.toString(), _columnWidths['length']!, textColor),
//             Expanded(
//                 child: _buildCell(
//                     packet.info, _columnWidths['info']!, textColor,
//                     expandable: true)),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCell(String text, double width, Color textColor,
//       {bool expandable = false}) {
//     return Container(
//       width: expandable ? null : width,
//       padding: const EdgeInsets.symmetric(horizontal: 8),
//       child: Text(
//         text,
//         style: TextStyle(color: textColor),
//         overflow: expandable ? TextOverflow.ellipsis : TextOverflow.clip,
//       ),
//     );
//   }

//   Widget _buildDetailView() {
//     if (_selectedPacket == null) {
//       return const Center(
//         child: Text('Select a packet to view details'),
//       );
//     }

//     // If there's raw data available, use it to populate the detail view
//     final rawData = _selectedPacket!.rawData;
//     if (rawData == null) {
//       return const Center(
//         child: Text('No detailed information available for this packet'),
//       );
//     }

//     return DefaultTabController(
//       length: 3,
//       child: Column(
//         children: [
//           TabBar(
//             tabs: const [
//               Tab(text: 'Frame'),
//               Tab(text: 'Ethernet'),
//               Tab(text: 'TCP/IP'),
//             ],
//             labelColor: Theme.of(context).colorScheme.primary,
//             unselectedLabelColor: Colors.black54,
//           ),
//           Expanded(
//             child: TabBarView(
//               children: [
//                 _buildProtocolDetails(rawData['frame'], 'Frame'),
//                 _buildProtocolDetails(rawData['ethernet'], 'Ethernet'),
//                 _buildProtocolDetails(
//                     rawData['tcp'] ?? rawData['udp'] ?? {}, 'TCP/IP'),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProtocolDetails(
//       Map<String, dynamic>? protocolData, String protocolName) {
//     if (protocolData == null || protocolData.isEmpty) {
//       return Center(
//         child: Text('No $protocolName data available for this packet'),
//       );
//     }

//     return Container(
//       color: const Color(0xFF262626),
//       child: ListView(
//         padding: const EdgeInsets.all(8),
//         children: [
//           Text(
//             '$protocolName Details',
//             style: const TextStyle(
//               fontFamily: 'Courier New',
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//           const SizedBox(height: 8),
//           ...protocolData.entries.map((entry) {
//             return Padding(
//               padding: const EdgeInsets.symmetric(vertical: 2),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   SizedBox(
//                     width: 150,
//                     child: Text(
//                       _formatFieldName(entry.key) + ':',
//                       style: const TextStyle(
//                         fontFamily: 'Courier New',
//                         color: Colors.grey,
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: Text(
//                       _formatFieldValue(entry.value),
//                       style: const TextStyle(
//                         fontFamily: 'Courier New',
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }).toList(),
//           const SizedBox(height: 16),
//           _buildHexDump(_generateHexDump(protocolName)),
//         ],
//       ),
//     );
//   }

//   String _formatFieldName(String name) {
//     // Convert snake_case to Title Case with spaces
//     return name
//         .split('_')
//         .map((word) =>
//             word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
//         .join(' ');
//   }

//   String _formatFieldValue(dynamic value) {
//     if (value is List) {
//       return value.join(', ');
//     }
//     return value.toString();
//   }

//   List<String> _generateHexDump(String protocolName) {
//     // In a real app, this would extract the actual hex values from the packet
//     // For now, we'll generate sample data based on the protocol
//     List<String> hexData = [];

//     // Add offsets and mock hex values
//     hexData.add('0000');

//     if (protocolName == 'Frame') {
//       hexData.add('5c 8a 38 bc 2e 58 46 51 5a ea 83 0e 08 00 45 00');
//       hexData.add('00 2c 00 00 40 00 40 06 35 8c fb 2d 8e 97 c0 a8');
//     } else if (protocolName == 'Ethernet') {
//       hexData.add('5c 8a 38 bc 2e 58 46 51 5a ea 83 0e 08 00');
//     } else {
//       hexData.add('00 2c 00 00 40 00 40 06 35 8c fb 2d 8e 97 c0 a8');
//       hexData.add('2a 08 fe 8e 01 bb 5d 14 b2 ba 21 03 01 d6 50 10');
//     }

//     return hexData;
//   }

//   Widget _buildHexDump(List<String> hexData) {
//     List<Widget> rows = [];

//     for (int i = 0; i < hexData.length; i++) {
//       if (i == 0) {
//         // This is an offset label
//         continue;
//       }

//       rows.add(
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             SizedBox(
//               width: 50,
//               child: Text(
//                 hexData[0], // Using the first item as offset
//                 style: const TextStyle(
//                   color: Colors.grey,
//                   fontFamily: 'Courier New',
//                 ),
//               ),
//             ),
//             Expanded(
//               child: Text(
//                 hexData[i],
//                 style: const TextStyle(
//                   fontFamily: 'Courier New',
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//       rows.add(const SizedBox(height: 4));
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Hex Dump:',
//           style: TextStyle(
//             fontFamily: 'Courier New',
//             fontSize: 14,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         const SizedBox(height: 8),
//         ...rows,
//       ],
//     );
//   }

//   void _showFilterDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Filter Packets'),
//         content: SizedBox(
//           width: 500,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextFormField(
//                 decoration: const InputDecoration(
//                   labelText: 'Display Filter Expression',
//                   hintText: 'e.g., ip.addr == 10.0.0.1 && tcp',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Wrap(
//                 spacing: 8,
//                 children: [
//                   FilterChip(
//                     label: const Text('TCP'),
//                     selected: true,
//                     onSelected: (bool value) {},
//                   ),
//                   FilterChip(
//                     label: const Text('UDP'),
//                     selected: false,
//                     onSelected: (bool value) {},
//                   ),
//                   FilterChip(
//                     label: const Text('HTTP'),
//                     selected: false,
//                     onSelected: (bool value) {},
//                   ),
//                   FilterChip(
//                     label: const Text('TLS'),
//                     selected: false,
//                     onSelected: (bool value) {},
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               // Apply the filter
//             },
//             child: const Text('Apply'),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class PacketCaptureScreen extends StatefulWidget {
  const PacketCaptureScreen({Key? key}) : super(key: key);

  @override
  _PacketCaptureScreenState createState() => _PacketCaptureScreenState();
}

class _PacketCaptureScreenState extends State<PacketCaptureScreen> {
  late WebSocketChannel _channel;
  final List<PacketData> _packets = [];
  PacketData? _selectedPacket;
  bool _isConnected = false;

  // WebSocket URL (Change this if running on a different server)
  final String _webSocketUrl = "ws://localhost:8080/ws/packets";

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _channel.sink.close(status.goingAway);
    super.dispose();
  }

  void _connectWebSocket() {
    print("Attempting to connect to $_webSocketUrl");
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_webSocketUrl));
      print("Connection established");

      _channel.stream.listen(
        (data) {
          print("Received data: $data");
          // Rest of your code
        },
        onDone: () {
          print("WebSocket connection closed");
          setState(() {
            _isConnected = false;
          });
        },
        onError: (error) {
          print("WebSocket Error: $error");
          print("Error details: ${error.toString()}");
          setState(() {
            _isConnected = false;
          });
        },
      );

      setState(() {
        _isConnected = true;
      });
    } catch (e) {
      print("Connection error: $e");
      setState(() {
        _isConnected = false;
      });
    }
  }

  // void _sendCommand(String action, {String? filter}) {
  //   Map<String, dynamic> command = {"action": action};
  //   if (filter != null) command["filter"] = filter;
  //   _channel.sink.add(jsonEncode(command));
  // }

  void _sendCommand(String action, {String? filter, String? interface}) {
    Map<String, dynamic> command = {"action": action};
    if (filter != null) command["filter"] = filter;
    if (interface != null) command["interface"] = interface;
    _channel.sink.add(jsonEncode(command));
  }

  Color _getPacketColor(String type) {
    switch (type) {
      case "attack":
        return Colors.red.shade200;
      case "retransmission":
        return Colors.orange.shade200;
      case "clientHello":
        return Colors.green.shade200;
      case "synAck":
        return Colors.blue.shade200;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Network Packet Capture"),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Start Capture',
            onPressed: () => // And then when starting:
                _sendCommand("start",
                    interface: "en0"), //* or whichever interface you want
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            tooltip: 'Stop Capture',
            onPressed: () => _sendCommand("stop"),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Apply Filter',
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isConnected
                ? _buildPacketTable()
                : const Center(child: Text("Connecting...")),
          ),
          const Divider(height: 1),
          Expanded(
            child: _buildDetailView(),
          ),
        ],
      ),
    );
  }

  Widget _buildPacketTable() {
    return Column(
      children: [
        _buildTableHeader(),
        Expanded(
          child: ListView.builder(
            itemCount: _packets.length,
            itemBuilder: (context, index) {
              final packet = _packets[index];
              return _buildPacketRow(packet);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: Colors.blue,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _buildHeaderCell('No.', 60),
          _buildHeaderCell('Time', 120),
          _buildHeaderCell('Source', 180),
          _buildHeaderCell('Destination', 180),
          _buildHeaderCell('Protocol', 100),
          _buildHeaderCell('Length', 80),
          Expanded(child: _buildHeaderCell('Info', 250)),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(text,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _buildPacketRow(PacketData packet) {
    final isSelected = _selectedPacket?.no == packet.no;
    final bgColor =
        isSelected ? Colors.blue.shade100 : _getPacketColor(packet.type);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPacket = packet;
        });
      },
      child: Container(
        color: bgColor,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            _buildCell(packet.no.toString(), 60),
            _buildCell(packet.time, 120),
            _buildCell(packet.source, 180),
            _buildCell(packet.destination, 180),
            _buildCell(packet.protocol, 100),
            _buildCell(packet.length.toString(), 80),
            Expanded(child: _buildCell(packet.info, 250, expandable: true)),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(String text, double width, {bool expandable = false}) {
    return Container(
      width: expandable ? null : width,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(text, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _buildDetailView() {
    if (_selectedPacket == null) {
      return const Center(child: Text("Select a packet to view details"));
    }

    return Container(
      padding: const EdgeInsets.all(8),
      child: ListView(
        children: _selectedPacket!.rawData.entries.map((entry) {
          return ListTile(
            title: Text(entry.key,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(jsonEncode(entry.value)),
          );
        }).toList(),
      ),
    );
  }

  void _showFilterDialog() {
    TextEditingController filterController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Apply Filter"),
        content: TextField(
          controller: filterController,
          decoration:
              const InputDecoration(labelText: "Enter filter expression"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              _sendCommand("filter", filter: filterController.text);
              Navigator.pop(context);
            },
            child: const Text("Apply"),
          ),
        ],
      ),
    );
  }
}

// Data Model
class PacketData {
  final int no;
  final String time;
  final String source;
  final String destination;
  final String protocol;
  final int length;
  final String info;
  final String type;
  final Map<String, dynamic> rawData;

  PacketData({
    required this.no,
    required this.time,
    required this.source,
    required this.destination,
    required this.protocol,
    required this.length,
    required this.info,
    required this.type,
    required this.rawData,
  });

  factory PacketData.fromJson(Map<String, dynamic> json) {
    return PacketData(
      no: json["no"],
      time: json["time"],
      source: json["source"],
      destination: json["destination"],
      protocol: json["protocol"],
      length: json["length"],
      info: json["info"],
      type: json["type"],
      rawData: json["rawData"] ?? {},
    );
  }
}
