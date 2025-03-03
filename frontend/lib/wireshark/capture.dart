// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:nidswebapp/wireshark/packet_data.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:web_socket_channel/status.dart' as status;
// import 'package:intl/intl.dart';
// import 'package:file_selector/file_selector.dart'; // Import file_selector

// class PacketCaptureScreen extends StatefulWidget {
//   const PacketCaptureScreen({Key? key}) : super(key: key);

//   @override
//   _PacketCaptureScreenState createState() => _PacketCaptureScreenState();
// }

// class _PacketCaptureScreenState extends State<PacketCaptureScreen> {
//   late WebSocketChannel _channel;

//   // Use a fixed-size buffer to limit memory usage
//   final int _maxPackets = 1000; // Set a reasonable limit
//   final List<PacketData> _packets = [];

//   // For saving to file
//   List<PacketData> _allPackets = [];
//   bool _isSaving = false;
//   String? _currentSaveFilePath;

//   PacketData? _selectedPacket;
//   bool _isConnected = false;
//   bool _isCapturing = false;
//   int _totalPacketsReceived = 0;
//   int _droppedPackets = 0;

//   // Throttle UI updates
//   int _pendingUpdates = 0;
//   bool _updateScheduled = false;
//   final Duration _updateThrottle = const Duration(milliseconds: 500);

//   // WebSocket URL (Change this if running on a different server)
//   final String _webSocketUrl = "ws://localhost:8080/ws/packets";

//   // Scrolling control
//   final ScrollController _scrollController = ScrollController();
//   bool _autoScroll = true;

//   @override
//   void initState() {
//     super.initState();
//     _connectWebSocket();
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     if (_isConnected) {
//       _channel.sink.close(status.goingAway);
//     }
//     super.dispose();
//   }

//   void _connectWebSocket() {
//     print("Attempting to connect to $_webSocketUrl");
//     try {
//       _channel = WebSocketChannel.connect(Uri.parse(_webSocketUrl));
//       print("Connection established");

//       _channel.stream.listen(
//         (data) {
//           final packet = PacketData.fromJson(jsonDecode(data));
//           _addPacket(packet);
//         },
//         onDone: () {
//           print("WebSocket connection closed");
//           setState(() {
//             _isConnected = false;
//             _isCapturing = false;
//           });
//         },
//         onError: (error) {
//           print("WebSocket Error: $error");
//           setState(() {
//             _isConnected = false;
//             _isCapturing = false;
//           });
//           // Reconnect after 5 seconds
//           Future.delayed(const Duration(seconds: 5), _connectWebSocket);
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
//       Future.delayed(const Duration(seconds: 5), _connectWebSocket);
//     }
//   }

//   // Efficiently add packets with throttled UI updates
//   void _addPacket(PacketData packet) {
//     _totalPacketsReceived++;

//     // Use synchronized updates to avoid race conditions
//     synchronized(() {
//       // Always add to all packets list if saving is enabled
//       if (_isSaving) {
//         _allPackets.add(packet);
//       }

//       // Maintain a circular buffer for display
//       if (_packets.length >= _maxPackets) {
//         _packets.removeAt(0);
//         _droppedPackets++;
//       }
//       _packets.add(packet);
//       _pendingUpdates++;

//       // Throttle UI updates
//       if (!_updateScheduled) {
//         _updateScheduled = true;
//         Future.delayed(_updateThrottle, () {
//           setState(() {
//             _pendingUpdates = 0;
//             _updateScheduled = false;
//           });
//           // Auto-scroll to bottom if enabled
//           if (_autoScroll && _scrollController.hasClients) {
//             _scrollController.animateTo(
//               _scrollController.position.maxScrollExtent,
//               duration: const Duration(milliseconds: 200),
//               curve: Curves.easeOut,
//             );
//           }
//         });
//       }
//     });
//   }

//   // Simple synchronization utility
//   void synchronized(Function action) {
//     action();
//   }

//   void _sendCommand(String action, {String? filter, String? interface}) {
//     Map<String, dynamic> command = {"action": action};
//     if (filter != null) command["filter"] = filter;
//     if (interface != null) command["interface"] = interface;
//     _channel.sink.add(jsonEncode(command));

//     if (action == "start") {
//       setState(() {
//         _isCapturing = true;
//         // Clear the packets on new capture start
//         _packets.clear();
//         _totalPacketsReceived = 0;
//         _droppedPackets = 0;
//       });
//     } else if (action == "stop") {
//       setState(() {
//         _isCapturing = false;
//       });
//     }
//   }

//   void _clearPackets() {
//     setState(() {
//       _packets.clear();
//       _selectedPacket = null;
//       _totalPacketsReceived = 0;
//       _droppedPackets = 0;
//     });
//   }

//   // Future<void> _toggleSaveToFile() async {
//   //   if (_isSaving) {
//   //     // Stop saving and write file
//   //     await _savePacketsToFile();
//   //     setState(() {
//   //       _isSaving = false;
//   //       _allPackets = [];
//   //     });
//   //   } else {
//   //     // Let the user choose the file path
//   //     final String? filePath = await _getSaveFilePath();
//   //     if (filePath != null) {
//   //       setState(() {
//   //         _isSaving = true;
//   //         _currentSaveFilePath = filePath;
//   //         _allPackets = List.from(_packets); // Start with existing packets
//   //       });
//   //     } else {
//   //       ScaffoldMessenger.of(context).showSnackBar(
//   //         const SnackBar(content: Text("File path not selected")),
//   //       );
//   //     }
//   //   }
//   // }

//   Future<void> _toggleSaveToFile() async {
//     if (_isSaving) {
//       // Stop saving and write file
//       await _savePacketsToFile();
//       setState(() {
//         _isSaving = false;
//         _allPackets = [];
//       });
//     } else {
//       // Let the user choose the file path
//       final String? filePath = await _getSaveFilePath();
//       if (filePath != null) {
//         setState(() {
//           _isSaving = true;
//           _currentSaveFilePath = filePath;
//           _allPackets = List.from(_packets); // Start with existing packets
//         });
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("File path not selected")),
//         );
//       }
//     }
//   }

//   Future<String?> _getSaveFilePath() async {
//     try {
//       final String fileName =
//           'packet_capture_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';

//       final FileSaveLocation? file = await getSaveLocation(
//         suggestedName: fileName,
//         acceptedTypeGroups: [
//           XTypeGroup(
//             label: 'JSON',
//             extensions: ['json'],
//           ),
//         ],
//       );

//       return file
//           ?.path; // This will return the download path or null if canceled
//     } catch (e) {
//       print('Error: $e');
//       return null;
//     }
//   }

//   Future<void> _savePacketsToFile() async {
//     try {
//       if (_allPackets.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("No packets to save")),
//         );
//         return;
//       }

//       // Convert packets to JSON
//       final packetsList = _allPackets.map((p) => p.rawData).toList();
//       final jsonData = jsonEncode(packetsList);

//       // Write to file
//       final file = File(_currentSaveFilePath!);
//       await file.writeAsString(jsonData);

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//             content: Text(
//                 "Saved ${_allPackets.length} packets to $_currentSaveFilePath")),
//       );
//     } catch (e) {
//       print("Error saving file: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error saving file: $e")),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Network Packet Capture"),
//         actions: [
//           // Pause button
//           IconButton(
//             icon: _isCapturing
//                 ? const Icon(Icons.pause)
//                 : const Icon(Icons.play_arrow),
//             tooltip: _isCapturing ? 'Pause Capture' : 'Start Capture',
//             onPressed: _isConnected
//                 ? () => _sendCommand(_isCapturing ? "stop" : "start",
//                     interface: "en0")
//                 : null,
//           ),
//           // Save to file button
//           IconButton(
//             icon: Icon(_isSaving ? Icons.save_alt : Icons.save_outlined),
//             tooltip: _isSaving
//                 ? 'Stop Saving and Save to File'
//                 : 'Start Saving to File',
//             onPressed: _isConnected ? _toggleSaveToFile : null,
//             color: _isSaving ? Colors.green : null,
//           ),
//           // Stop logging button
//           IconButton(
//             icon: const Icon(Icons.stop),
//             tooltip: 'Stop Logging',
//             onPressed: _isSaving ? _toggleSaveToFile : null,
//             color: _isSaving ? Colors.red : null,
//           ),
//           IconButton(
//             icon: const Icon(Icons.delete),
//             tooltip: 'Clear Packets',
//             onPressed: _packets.isNotEmpty ? _clearPackets : null,
//           ),
//           IconButton(
//             icon: const Icon(Icons.filter_list),
//             tooltip: 'Apply Filter',
//             onPressed: _isConnected ? _showFilterDialog : null,
//           ),
//           // Toggle auto-scroll
//           IconButton(
//             icon:
//                 Icon(_autoScroll ? Icons.vertical_align_bottom : Icons.height),
//             tooltip:
//                 _autoScroll ? 'Auto-scroll enabled' : 'Auto-scroll disabled',
//             onPressed: () {
//               setState(() {
//                 _autoScroll = !_autoScroll;
//               });
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Connection status and statistics bar
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//             color: Colors.grey.shade200,
//             child: Row(
//               children: [
//                 Icon(_isConnected ? Icons.link : Icons.link_off,
//                     color: _isConnected ? Colors.green : Colors.red),
//                 const SizedBox(width: 8),
//                 Text(_isConnected ? "Connected" : "Disconnected"),
//                 const Spacer(),
//                 Text("Total packets: $_totalPacketsReceived"),
//                 const SizedBox(width: 16),
//                 Text("Buffered: ${_packets.length}/$_maxPackets"),
//                 const SizedBox(width: 16),
//                 if (_isSaving)
//                   Text("Saving: ${_allPackets.length}",
//                       style: const TextStyle(color: Colors.green)),
//                 const SizedBox(width: 16),
//                 if (_droppedPackets > 0)
//                   Text("Dropped: $_droppedPackets",
//                       style: const TextStyle(color: Colors.red)),
//               ],
//             ),
//           ),
//           Expanded(
//             child: _isConnected
//                 ? _buildPacketTable()
//                 : const Center(child: CircularProgressIndicator()),
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
//           child: _packets.isEmpty
//               ? const Center(child: Text("No packets captured"))
//               : NotificationListener<ScrollNotification>(
//                   onNotification: (ScrollNotification notification) {
//                     // Detect if user is manually scrolling
//                     if (notification is ScrollUpdateNotification &&
//                         notification.dragDetails != null) {
//                       setState(() {
//                         // Disable auto-scroll when user manually scrolls
//                         _autoScroll = false;
//                       });
//                     }
//                     return true;
//                   },
//                   child: ListView.builder(
//                     controller: _scrollController,
//                     itemCount: _packets.length,
//                     // Use a more efficient approach with itemExtent
//                     itemExtent: 30.0, // Fixed height for each row
//                     itemBuilder: (context, index) {
//                       final packet = _packets[index];
//                       return _buildPacketRow(packet);
//                     },
//                   ),
//                 ),
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
//         height: 30, // Fixed height for better performance
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
//       alignment: Alignment.centerLeft,
//       child: Text(
//         text,
//         overflow: TextOverflow.ellipsis,
//         maxLines: 1, // Limit to one line for better performance
//       ),
//     );
//   }

//   Widget _buildDetailView() {
//     if (_selectedPacket == null) {
//       return const Center(child: Text("Select a packet to view details"));
//     }

//     // Simplified detail view with simple header-like section titles
//     return Container(
//       padding: const EdgeInsets.all(8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(bottom: 8.0),
//             child: Text(
//               "Packet #${_selectedPacket!.no} - ${_selectedPacket!.protocol}",
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//             ),
//           ),
//           Expanded(
//             child: ListView(
//               children: _selectedPacket!.rawData.entries.map((entry) {
//                 return Card(
//                   margin: const EdgeInsets.only(bottom: 8),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Container(
//                         width: double.infinity,
//                         color: Colors.blue.shade100,
//                         padding: const EdgeInsets.all(8),
//                         child: Text(
//                           entry.key,
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 14,
//                           ),
//                         ),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: SelectableText(
//                           entry.value is Map || entry.value is List
//                               ? const JsonEncoder.withIndent('  ')
//                                   .convert(entry.value)
//                               : entry.value.toString(),
//                           style: const TextStyle(fontFamily: 'monospace'),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),
//         ],
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
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nidswebapp/wireshark/packet_data.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:intl/intl.dart';
import 'package:file_selector/file_selector.dart';

class PacketCaptureScreen extends StatefulWidget {
  const PacketCaptureScreen({Key? key}) : super(key: key);

  @override
  _PacketCaptureScreenState createState() => _PacketCaptureScreenState();
}

class _PacketCaptureScreenState extends State<PacketCaptureScreen> {
  late WebSocketChannel _channel;

  // Use a fixed-size buffer to limit memory usage
  final int _maxPackets = 1000; // Set a reasonable limit
  final List<PacketData> _packets = [];

  // For saving to file
  List<PacketData> _allPackets = [];
  bool _isSaving = false;
  String? _currentSaveFilePath;

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

  // Saving status indicator
  bool _isSavingInProgress = false;

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
      // Always add to all packets list if saving is enabled
      if (_isSaving) {
        _allPackets.add(packet);
      }

      // Maintain a circular buffer for display
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
          if (mounted) {
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

  Future<void> _toggleSaveToFile() async {
    if (_isSaving) {
      // Show save in progress
      setState(() {
        _isSavingInProgress = true;
      });

      // Stop saving and write file
      await _savePacketsToFile();

      setState(() {
        _isSaving = false;
        _allPackets = [];
        _isSavingInProgress = false;
      });
    } else {
      // Let the user choose the file path
      final String? filePath = await _getSaveFilePath();
      if (filePath != null) {
        setState(() {
          _isSaving = true;
          _currentSaveFilePath = filePath;
          _allPackets = List.from(_packets); // Start with existing packets
        });

        // Show a snackbar to confirm saving has started
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("Recording packets to file: ${filePath.split('/').last}"),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File path not selected")),
        );
      }
    }
  }

  Future<String?> _getSaveFilePath() async {
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

  Future<void> _savePacketsToFile() async {
    try {
      if (_allPackets.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No packets to save")),
        );
        return;
      }

      // Convert packets to JSON
      final packetsList = _allPackets.map((p) => p.rawData).toList();
      final jsonData = jsonEncode(packetsList);

      // Write to file
      final file = File(_currentSaveFilePath!);
      await file.writeAsString(jsonData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Saved ${_allPackets.length} packets to ${_currentSaveFilePath!.split('/').last}"),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Network Packet Capture"),
        actions: [
          // Pause button
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
          // Save to file button with loading indicator
          _isSavingInProgress
              ? const SizedBox(
                  width: 48,
                  height: 48,
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(_isSaving ? Icons.save_alt : Icons.save_outlined),
                  tooltip: _isSaving
                      ? 'Stop Saving and Save to File'
                      : 'Start Saving to File',
                  onPressed: _isConnected ? _toggleSaveToFile : null,
                  color: _isSaving ? Colors.green : null,
                ),
          // Stop logging button
          IconButton(
            icon: const Icon(Icons.stop),
            tooltip: 'Stop Logging',
            onPressed: _isSaving ? _toggleSaveToFile : null,
            color: _isSaving ? Colors.red : null,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                // Connection status indicator with better styling
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isConnected
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isConnected ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isConnected ? Icons.link : Icons.link_off,
                        color: _isConnected ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isConnected ? "Connected" : "Disconnected",
                        style: TextStyle(
                          color: _isConnected
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Statistics with improved visual separation
                _buildStatisticBadge(
                  "Packets",
                  _totalPacketsReceived.toString(),
                  Icons.compare_arrows,
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildStatisticBadge(
                  "Buffered",
                  "${_packets.length}/$_maxPackets",
                  Icons.memory,
                  Colors.orange,
                ),
                const SizedBox(width: 8),
                if (_isSaving)
                  _buildStatisticBadge(
                    "Saving",
                    _allPackets.length.toString(),
                    Icons.save,
                    Colors.green,
                  ),
                const SizedBox(width: 8),
                if (_droppedPackets > 0)
                  _buildStatisticBadge(
                    "Dropped",
                    _droppedPackets.toString(),
                    Icons.remove_circle_outline,
                    Colors.red,
                  ),
              ],
            ),
          ),
          Expanded(
            child: _isConnected
                ? _buildPacketTable()
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          "Connecting to $_webSocketUrl...",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _buildDetailView(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticBadge(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            "$label: ",
            style: TextStyle(fontSize: 12, color: color),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
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
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_find,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        "No packets captured",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      if (!_isCapturing)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text("Start Capture"),
                          onPressed: () =>
                              _sendCommand("start", interface: "en0"),
                        ),
                    ],
                  ),
                )
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
                    // Using itemExtent for better performance
                    itemExtent: 40.0, // Slightly taller for better readability
                    itemBuilder: (context, index) {
                      final packet = _packets[index];
                      return _buildPacketRow(packet, index);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildPacketRow(PacketData packet, int index) {
    final isSelected = _selectedPacket?.no == packet.no;
    final baseColor = _getPacketColor(packet.type);

    // Instead of changing the entire background, use a subtle left border and lighter background
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPacket = packet;
        });
      },
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : baseColor,
          border: Border(
            left: BorderSide(
              color: isSelected ? Colors.blue.shade700 : Colors.transparent,
              width: 3,
            ),
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            _buildCell('${index + 1}', 60, isNumeric: true), // No.
            _buildCell(packet.time, 120), // Time
            _buildCell(packet.source, 180), // Source
            _buildCell(packet.destination, 180), // Destination
            _buildCell(packet.protocol, 100), // Protocol
            _buildCell(packet.length.toString(), 80, isNumeric: true), // Length
            Expanded(
              child: _buildCell(packet.info, 250,
                  expandable: true, isHighlighted: isSelected), // Info
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(String text, double width,
      {bool expandable = false,
      bool isNumeric = false,
      bool isHighlighted = false}) {
    return Container(
      width: expandable ? null : width,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildDetailView() {
    if (_selectedPacket == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "Select a packet to view details",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    // Enhanced detail view with better styling
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Icon(
                  _getProtocolIcon(_selectedPacket!.protocol),
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Packet #${_selectedPacket!.no} - ${_selectedPacket!.protocol}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "From ${_selectedPacket!.source} to ${_selectedPacket!.destination}",
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    "${_selectedPacket!.length} bytes",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: _selectedPacket!.rawData.entries.map((entry) {
                final isJsonData = entry.value is Map || entry.value is List;
                final jsonData = isJsonData
                    ? const JsonEncoder.withIndent('  ').convert(entry.value)
                    : entry.value.toString();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (isJsonData) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  "JSON",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: isJsonData
                            ? BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                              )
                            : null,
                        child: SelectableText(
                          jsonData,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            height: 1.5,
                            color: isJsonData ? Colors.grey.shade800 : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getProtocolIcon(String protocol) {
    switch (protocol.toLowerCase()) {
      case 'tcp':
        return Icons.compare_arrows;
      case 'udp':
        return Icons.send;
      case 'http':
      case 'https':
        return Icons.http;
      case 'dns':
        return Icons.dns;
      case 'icmp':
        return Icons.report_problem;
      case 'arp':
        return Icons.link;
      default:
        return Icons.data_usage;
    }
  }

  void _showFilterDialog() {
    TextEditingController filterController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Apply Filter"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: filterController,
              decoration: const InputDecoration(
                labelText: "Enter filter expression",
                hintText: "e.g., tcp or port 80",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Examples:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 4),
            _buildFilterExample("tcp", "Show only TCP packets"),
            _buildFilterExample("port 80", "HTTP traffic"),
            _buildFilterExample(
                "host 192.168.1.1", "Traffic to/from specific host"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (filterController.text.isNotEmpty) {
                _sendCommand("filter", filter: filterController.text);
                Navigator.pop(context);
              }
            },
            child: const Text("Apply"),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterExample(String filter, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              filter,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

Color _getPacketColor(String type) {
  switch (type) {
    case "attack":
      return Colors.red.shade50;
    case "retransmission":
      return Colors.orange.shade50;
    case "clientHello":
      return Colors.green.shade50;
    case "synAck":
      return Colors.blue.shade50;
    default:
      return Colors.transparent;
  }
}
