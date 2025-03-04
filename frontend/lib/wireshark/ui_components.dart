import 'package:flutter/material.dart';
import 'package:nidswebapp/wireshark/packet_data.dart';

class UIComponents {
  static Widget buildStatisticBadge(
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

  static Widget buildPacketRow(
      PacketData packet, int index, GestureTapCallback onTap, bool isSelected) {
    final baseColor = _getPacketColor(packet.type);

    return InkWell(
      onTap: onTap ,
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

  static Widget _buildCell(String text, double width,
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

  static Color _getPacketColor(String type) {
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
}
