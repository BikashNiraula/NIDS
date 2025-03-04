import 'package:nidswebapp/wireshark/packet_data.dart';

class PacketManager {
  final int _maxPackets;
  final List<PacketData> _packets = [];
  List<PacketData> _allPackets = [];
  int _totalPacketsReceived = 0;
  int _droppedPackets = 0;

  PacketManager(this._maxPackets);

  void addPacket(PacketData packet, bool isSaving) {
    _totalPacketsReceived++;

    if (isSaving) {
      _allPackets.add(packet);
    }

    if (_packets.length >= _maxPackets) {
      _packets.removeAt(0);
      _droppedPackets++;
    }
    _packets.add(packet);
  }

  void clearPackets() {
    _packets.clear();
    _totalPacketsReceived = 0;
    _droppedPackets = 0;
  }

  List<PacketData> get packets => _packets;
  List<PacketData> get allPackets => _allPackets;
  int get totalPacketsReceived => _totalPacketsReceived;
  int get droppedPackets => _droppedPackets;
}
