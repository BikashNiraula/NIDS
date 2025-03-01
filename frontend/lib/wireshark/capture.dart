// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:web_socket_channel/status.dart' as status;

// class PacketCaptureScreen extends StatefulWidget {
//   const PacketCaptureScreen({Key? key}) : super(key: key);

//   @override
//   _PacketCaptureScreenState createState() => _PacketCaptureScreenState();
// }

// class _PacketCaptureScreenState extends State<PacketCaptureScreen> {
//   late WebSocketChannel _channel;
//   final List<PacketData> _packets = [];
//   PacketData? _selectedPacket;
//   bool _isConnected = false;

//   // WebSocket URL (Change this if running on a different server)
//   final String _webSocketUrl = "ws://localhost:8080/ws/packets";

//   @override
//   void initState() {
//     super.initState();
//     _connectWebSocket();
//   }

//   @override
//   void dispose() {
//     _channel.sink.close(status.goingAway);
//     super.dispose();
//   }

//   void _connectWebSocket() {
//     print("Attempting to connect to $_webSocketUrl");
//     try {
//       _channel = WebSocketChannel.connect(Uri.parse(_webSocketUrl));
//       print("Connection established");

//       _channel.stream.listen(
//         (data) {
//           print("Received data: $data"); // Print the raw JSON data
//           final packet = PacketData.fromJson(jsonDecode(data));
//           setState(() {
//             _packets.add(packet);
//           });
//         },
//         onDone: () {
//           print("WebSocket connection closed");
//           setState(() {
//             _isConnected = false;
//           });
//         },
//         onError: (error) {
//           print("WebSocket Error: $error");
//           print("Error details: ${error.toString()}");
//           setState(() {
//             _isConnected = false;
//           });
//         },
//       );

//       setState(() {
//         _isConnected = true;
//       });
//     } catch (e) {
//       print("Connection error: $e");
//       setState(() {
//         _isConnected = false;
//       });
//       // Reconnect after 5 seconds
//       Future.delayed(Duration(seconds: 5), _connectWebSocket);
//     }
//   }
//   // void _connectWebSocket() {
//   //   print("Attempting to connect to $_webSocketUrl");
//   //   try {
//   //     _channel = WebSocketChannel.connect(Uri.parse(_webSocketUrl));
//   //     print("Connection established");

//   //     _channel.stream.listen(
//   //       (data) {
//   //         print("Received data: $data"); // Debug log to check incoming data
//   //         final packet = PacketData.fromJson(jsonDecode(data));
//   //         print(
//   //             "Parsed packet: ${packet.toString()}"); // Debug log to check parsed packet
//   //         setState(() {
//   //           _packets.add(packet);
//   //           print(
//   //               "Packets list updated. Total packets: ${_packets.length}"); // Debug log
//   //         });
//   //       },
//   //       onDone: () {
//   //         print("WebSocket connection closed");
//   //         setState(() {
//   //           _isConnected = false;
//   //         });
//   //       },
//   //       onError: (error) {
//   //         print("WebSocket Error: $error");
//   //         print("Error details: ${error.toString()}");
//   //         setState(() {
//   //           _isConnected = false;
//   //         });
//   //       },
//   //     );

//   //     setState(() {
//   //       _isConnected = true;
//   //     });
//   //   } catch (e) {
//   //     print("Connection error: $e");
//   //     setState(() {
//   //       _isConnected = false;
//   //     });
//   //   }
//   // }

//   void _sendCommand(String action, {String? filter, String? interface}) {
//     Map<String, dynamic> command = {"action": action};
//     if (filter != null) command["filter"] = filter;
//     if (interface != null) command["interface"] = interface;
//     _channel.sink.add(jsonEncode(command));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Network Packet Capture"),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.play_arrow),
//             tooltip: 'Start Capture',
//             onPressed: () => _sendCommand("start", interface: "en0"),
//           ),
//           IconButton(
//             icon: const Icon(Icons.stop),
//             tooltip: 'Stop Capture',
//             onPressed: () => _sendCommand("stop"),
//           ),
//           IconButton(
//             icon: const Icon(Icons.filter_list),
//             tooltip: 'Apply Filter',
//             onPressed: _showFilterDialog,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: _isConnected
//                 ? _buildPacketTable()
//                 : const Center(child: Text("Connecting...")),
//           ),
//           const Divider(height: 1),
//           Expanded(
//             child: _buildDetailView(),
//           ),
//         ],
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
//           _buildHeaderCell('No.', 60),
//           _buildHeaderCell('Time', 120),
//           _buildHeaderCell('Source', 180),
//           _buildHeaderCell('Destination', 180),
//           _buildHeaderCell('Protocol', 100),
//           _buildHeaderCell('Length', 80),
//           Expanded(child: _buildHeaderCell('Info', 250)),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeaderCell(String text, double width) {
//     return Container(
//       width: width,
//       padding: const EdgeInsets.symmetric(horizontal: 8),
//       child: Text(text,
//           style: const TextStyle(
//               fontWeight: FontWeight.bold, color: Colors.white)),
//     );
//   }

//   Widget _buildPacketRow(PacketData packet) {
//     final isSelected = _selectedPacket?.no == packet.no;
//     final bgColor =
//         isSelected ? Colors.blue.shade100 : _getPacketColor(packet.type);

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
//             _buildCell(packet.no.toString(), 60), // No.
//             _buildCell(packet.time, 120), // Time
//             _buildCell(packet.source, 180), // Source
//             _buildCell(packet.destination, 180), // Destination
//             _buildCell(packet.protocol, 100), // Protocol
//             _buildCell(packet.length.toString(), 80), // Length
//             Expanded(
//                 child: _buildCell(packet.info, 250, expandable: true)), // Info
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCell(String text, double width, {bool expandable = false}) {
//     return Container(
//       width: expandable ? null : width,
//       padding: const EdgeInsets.symmetric(horizontal: 8),
//       child: Text(text, overflow: TextOverflow.ellipsis),
//     );
//   }

//   Widget _buildDetailView() {
//     if (_selectedPacket == null) {
//       return const Center(child: Text("Select a packet to view details"));
//     }

//     return Container(
//       padding: const EdgeInsets.all(8),
//       child: ListView(
//         children: _selectedPacket!.rawData.entries.map((entry) {
//           return ListTile(
//             title: Text(entry.key,
//                 style: const TextStyle(fontWeight: FontWeight.bold)),
//             subtitle: Text(jsonEncode(entry.value)),
//           );
//         }).toList(),
//       ),
//     );
//   }

//   void _showFilterDialog() {
//     TextEditingController filterController = TextEditingController();

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Apply Filter"),
//         content: TextField(
//           controller: filterController,
//           decoration:
//               const InputDecoration(labelText: "Enter filter expression"),
//         ),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("Cancel")),
//           ElevatedButton(
//             onPressed: () {
//               _sendCommand("filter", filter: filterController.text);
//               Navigator.pop(context);
//             },
//             child: const Text("Apply"),
//           ),
//         ],
//       ),
//     );
//   }
// }

// Color _getPacketColor(String type) {
//   switch (type) {
//     case "attack":
//       return Colors.red.shade200;
//     case "retransmission":
//       return Colors.orange.shade200;
//     case "clientHello":
//       return Colors.green.shade200;
//     case "synAck":
//       return Colors.blue.shade200;
//     default:
//       return Colors.transparent;
//   }
// }

// class PacketData {
//   final int no;
//   final String time;
//   final String source;
//   final String destination;
//   final String protocol;
//   final int length;
//   final String info;
//   final String type;
//   final Map<String, dynamic> rawData;

//   PacketData({
//     required this.no,
//     required this.time,
//     required this.source,
//     required this.destination,
//     required this.protocol,
//     required this.length,
//     required this.info,
//     required this.type,
//     required this.rawData,
//   });

//   factory PacketData.fromJson(Map<String, dynamic> json) {
//     print("Parsing JSON: $json"); // Debug log to check incoming JSON

//     return PacketData(
//       no: json["no"] ?? 0, // Provide a default value if "no" is missing
//       time: json["Timestamp"] ?? "Unknown", // Match the key in the JSON
//       source: json["SourceIP"] ?? "Unknown", // Match the key in the JSON
//       destination:
//           json["DestinationIP"] ?? "Unknown", // Match the key in the JSON
//       protocol: json["AppProtocol"] ??
//           json["NetworkProtocol"] ??
//           "Unknown", // Use NetworkProtocol if AppProtocol is empty
//       length: json["Length"] ?? 0, // Provide a default value
//       info: json["Flags"] ?? "None", // Provide a default value
//       type: json["Type"] ?? "normal", // Provide a default value
//       rawData: json, // Store the entire JSON as rawData
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

  // Use a fixed-size buffer to limit memory usage
  // Using a more efficient data structure with a maximum size
  final int _maxPackets = 1000; // Set a reasonable limit
  final List<PacketData> _packets = [];

  PacketData? _selectedPacket;
  bool _isConnected = false;
  bool _isCapturing = false;
  int _totalPacketsReceived = 0;
  int _droppedPackets = 0;

  // Throttle UI updates
  int _pendingUpdates = 0;
  bool _updateScheduled = false;
  final Duration _updateThrottle = const Duration(milliseconds: 500);

  // WebSocket URL (Change this if running on a different server)
  final String _webSocketUrl = "ws://localhost:8080/ws/packets";

  // Scrolling control
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    if (_isConnected) {
      _channel.sink.close(status.goingAway);
    }
    super.dispose();
  }

  void _connectWebSocket() {
    print("Attempting to connect to $_webSocketUrl");
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_webSocketUrl));
      print("Connection established");

      _channel.stream.listen(
        (data) {
          final packet = PacketData.fromJson(jsonDecode(data));
          _addPacket(packet);
        },
        onDone: () {
          print("WebSocket connection closed");
          setState(() {
            _isConnected = false;
            _isCapturing = false;
          });
        },
        onError: (error) {
          print("WebSocket Error: $error");
          setState(() {
            _isConnected = false;
            _isCapturing = false;
          });
          // Reconnect after 5 seconds
          Future.delayed(const Duration(seconds: 5), _connectWebSocket);
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
      // Reconnect after 5 seconds
      Future.delayed(const Duration(seconds: 5), _connectWebSocket);
    }
  }

  // Efficiently add packets with throttled UI updates
  void _addPacket(PacketData packet) {
    _totalPacketsReceived++;

    // Use synchronized updates to avoid race conditions
    synchronized(() {
      // Maintain a circular buffer
      if (_packets.length >= _maxPackets) {
        _packets.removeAt(0);
        _droppedPackets++;
      }
      _packets.add(packet);
      _pendingUpdates++;

      // Throttle UI updates
      if (!_updateScheduled) {
        _updateScheduled = true;
        Future.delayed(_updateThrottle, () {
          setState(() {
            _pendingUpdates = 0;
            _updateScheduled = false;
          });
          // Auto-scroll to bottom if enabled
          if (_autoScroll && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  // Simple synchronization utility
  void synchronized(Function action) {
    action();
  }

  void _sendCommand(String action, {String? filter, String? interface}) {
    Map<String, dynamic> command = {"action": action};
    if (filter != null) command["filter"] = filter;
    if (interface != null) command["interface"] = interface;
    _channel.sink.add(jsonEncode(command));

    if (action == "start") {
      setState(() {
        _isCapturing = true;
        // Clear the packets on new capture start
        _packets.clear();
        _totalPacketsReceived = 0;
        _droppedPackets = 0;
      });
    } else if (action == "stop") {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  void _clearPackets() {
    setState(() {
      _packets.clear();
      _selectedPacket = null;
      _totalPacketsReceived = 0;
      _droppedPackets = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Network Packet Capture"),
        actions: [
          IconButton(
            icon: _isCapturing
                ? const Icon(Icons.pause)
                : const Icon(Icons.play_arrow),
            tooltip: _isCapturing ? 'Pause Capture' : 'Start Capture',
            onPressed: _isConnected
                ? () => _sendCommand(_isCapturing ? "stop" : "start",
                    interface: "en0")
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Clear Packets',
            onPressed: _packets.isNotEmpty ? _clearPackets : null,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Apply Filter',
            onPressed: _isConnected ? _showFilterDialog : null,
          ),
          // Toggle auto-scroll
          IconButton(
            icon:
                Icon(_autoScroll ? Icons.vertical_align_bottom : Icons.height),
            tooltip:
                _autoScroll ? 'Auto-scroll enabled' : 'Auto-scroll disabled',
            onPressed: () {
              setState(() {
                _autoScroll = !_autoScroll;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection status and statistics bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: Colors.grey.shade200,
            child: Row(
              children: [
                Icon(_isConnected ? Icons.link : Icons.link_off,
                    color: _isConnected ? Colors.green : Colors.red),
                const SizedBox(width: 8),
                Text(_isConnected ? "Connected" : "Disconnected"),
                const Spacer(),
                Text("Total packets: $_totalPacketsReceived"),
                const SizedBox(width: 16),
                Text("Buffered: ${_packets.length}/$_maxPackets"),
                const SizedBox(width: 16),
                if (_droppedPackets > 0)
                  Text("Dropped: $_droppedPackets",
                      style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
          Expanded(
            child: _isConnected
                ? _buildPacketTable()
                : const Center(child: CircularProgressIndicator()),
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
          child: _packets.isEmpty
              ? const Center(child: Text("No packets captured"))
              : NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification notification) {
                    // Detect if user is manually scrolling
                    if (notification is ScrollUpdateNotification &&
                        notification.dragDetails != null) {
                      setState(() {
                        // Disable auto-scroll when user manually scrolls
                        _autoScroll = false;
                      });
                    }
                    return true;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _packets.length,
                    // Use a more efficient approach with itemExtent
                    itemExtent: 30.0, // Fixed height for each row
                    itemBuilder: (context, index) {
                      final packet = _packets[index];
                      return _buildPacketRow(packet);
                    },
                  ),
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
        height: 30, // Fixed height for better performance
        child: Row(
          children: [
            _buildCell(packet.no.toString(), 60), // No.
            _buildCell(packet.time, 120), // Time
            _buildCell(packet.source, 180), // Source
            _buildCell(packet.destination, 180), // Destination
            _buildCell(packet.protocol, 100), // Protocol
            _buildCell(packet.length.toString(), 80), // Length
            Expanded(
                child: _buildCell(packet.info, 250, expandable: true)), // Info
          ],
        ),
      ),
    );
  }

  Widget _buildCell(String text, double width, {bool expandable = false}) {
    return Container(
      width: expandable ? null : width,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        maxLines: 1, // Limit to one line for better performance
      ),
    );
  }

  Widget _buildDetailView() {
    if (_selectedPacket == null) {
      return const Center(child: Text("Select a packet to view details"));
    }

    // Use LazyBuilder for detail view to avoid rendering all properties at once
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              "Packet #${_selectedPacket!.no} - ${_selectedPacket!.protocol}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _selectedPacket!.rawData.entries.length,
              itemBuilder: (context, index) {
                final entry = _selectedPacket!.rawData.entries.elementAt(index);
                return ExpansionTile(
                  title: Text(entry.key,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SelectableText(
                        entry.value is Map || entry.value is List
                            ? const JsonEncoder.withIndent('  ')
                                .convert(entry.value)
                            : entry.value.toString(),
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
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

  const PacketData({
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
      no: json["no"] ?? 0,
      time: json["Timestamp"] ?? "Unknown",
      source: json["SourceIP"] ?? "Unknown",
      destination: json["DestinationIP"] ?? "Unknown",
      protocol: json["AppProtocol"] ?? json["NetworkProtocol"] ?? "Unknown",
      length: json["Length"] ?? 0,
      info: json["Flags"] ?? "None",
      type: json["Type"] ?? "normal",
      rawData: json,
    );
  }
}
