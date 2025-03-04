import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nidswebapp/go_api/urls.dart';
import 'package:nidswebapp/wireshark/packet_data.dart';
import 'package:nidswebapp/wireshark/web_socket_handler.dart';

import 'packet_manager.dart';
import 'ui_components.dart';
import 'file_handler.dart';

class PacketCaptureScreen extends StatefulWidget {
  const PacketCaptureScreen({Key? key}) : super(key: key);

  @override
  _PacketCaptureScreenState createState() => _PacketCaptureScreenState();
}

class _PacketCaptureScreenState extends State<PacketCaptureScreen> {
  late WebSocketHandler _webSocketHandler;
  late PacketManager _packetManager;
  bool _isSaving = false;
  bool _isConnected = false;
  bool _isCapturing = false;
  bool _isSavingInProgress = false;
  String? _currentSaveFilePath;
  PacketData? _selectedPacket;
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _webSocketHandler = WebSocketHandler(packetsURl);
    _packetManager = PacketManager(1000);
    _connectWebSocket();
  }

  void _connectWebSocket() {
    _webSocketHandler.connect(
      (packet) {
        _packetManager.addPacket(packet, _isSaving);
        setState(() {});
      },
      () {
        setState(() {
          _isConnected = false;
          _isCapturing = false;
        });
        Future.delayed(const Duration(seconds: 5), _connectWebSocket);
      },
      (error) {
        setState(() {
          _isConnected = false;
          _isCapturing = false;
        });
        Future.delayed(const Duration(seconds: 5), _connectWebSocket);
      },
    );
    setState(() {
      _isConnected = true;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    if (_isConnected) {
      _webSocketHandler.close();
    }
    super.dispose();
  }

  void _sendCommand(String action, {String? filter, String? interface}) {
    _webSocketHandler.sendCommand(action, filter: filter, interface: interface);
    if (action == "start") {
      setState(() {
        _isCapturing = true;
        _packetManager.clearPackets();
      });
    } else if (action == "stop") {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  Future<void> _toggleSaveToFile() async {
    if (_isSaving) {
      setState(() {
        _isSavingInProgress = true;
      });

      await FileHandler.savePacketsToFile(
          _currentSaveFilePath!, _packetManager.allPackets, context);

      setState(() {
        _isSaving = false;
        _isSavingInProgress = false;
      });
    } else {
      final String? filePath = await FileHandler.getSaveFilePath();
      if (filePath != null) {
        setState(() {
          _isSaving = true;
          _currentSaveFilePath = filePath;
        });

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
          IconButton(
            icon: const Icon(Icons.stop),
            tooltip: 'Stop Logging',
            onPressed: _isSaving ? _toggleSaveToFile : null,
            color: _isSaving ? Colors.red : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Clear Packets',
            onPressed: _packetManager.packets.isNotEmpty
                ? () {
                    _packetManager.clearPackets();
                    setState(() {});
                  }
                : null,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
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
                UIComponents.buildStatisticBadge(
                  "Packets",
                  _packetManager.totalPacketsReceived.toString(),
                  Icons.compare_arrows,
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                UIComponents.buildStatisticBadge(
                  "Buffered",
                  "${_packetManager.packets.length}/1000",
                  Icons.memory,
                  Colors.orange,
                ),
                const SizedBox(width: 8),
                if (_isSaving)
                  UIComponents.buildStatisticBadge(
                    "Saving",
                    _packetManager.allPackets.length.toString(),
                    Icons.save,
                    Colors.green,
                  ),
                const SizedBox(width: 8),
                if (_packetManager.droppedPackets > 0)
                  UIComponents.buildStatisticBadge(
                    "Dropped",
                    _packetManager.droppedPackets.toString(),
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
                          "Connecting to ws://localhost:8080/ws/packets...",
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

  Widget _buildPacketTable() {
    return Column(
      children: [
        _buildTableHeader(),
        Expanded(
          child: _packetManager.packets.isEmpty
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
                    if (notification is ScrollUpdateNotification &&
                        notification.dragDetails != null) {
                      setState(() {
                        _autoScroll = false;
                      });
                    }
                    return true;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _packetManager.packets.length,
                    itemExtent: 40.0,
                    itemBuilder: (context, index) {
                      final packet = _packetManager.packets[index];
                      return UIComponents.buildPacketRow(
                        packet,
                        index,
                        () {
                          setState(() {
                            _selectedPacket = packet;
                          });
                        },
                        _selectedPacket?.no == packet.no,
                      );
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
}
