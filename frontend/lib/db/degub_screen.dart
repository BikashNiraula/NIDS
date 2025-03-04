// // // import 'package:flutter/material.dart';
// // // import 'package:nidswebapp/db/sqlite.dart';
// // // import 'package:nidswebapp/wireshark/packet_data.dart';

// // // class DebugScreen extends StatefulWidget {
// // //   @override
// // //   _DebugScreenState createState() => _DebugScreenState();
// // // }

// // // class _DebugScreenState extends State<DebugScreen> {
// // //   List<PacketData> packets = [];

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     fetchPackets();
// // //   }

// // //   void fetchPackets() async {
// // //     List<PacketData> data = await SQLiteHandler().getAllPackets();
// // //     setState(() {
// // //       packets = data;
// // //     });
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(title: Text('Debug Packets')),
// // //       body: packets.isEmpty
// // //           ? Center(child: Text('No Packets Found'))
// // //           : ListView.builder(
// // //               itemCount: packets.length,
// // //               itemBuilder: (context, index) {
// // //                 return ListTile(
// // //                   title: Text('Packet No: ${packets[index].no}'),
// // //                   subtitle: Text(
// // //                       '${packets[index].protocol} - ${packets[index].source} → ${packets[index].destination}'),
// // //                 );
// // //               },
// // //             ),
// // //       floatingActionButton: FloatingActionButton(
// // //         onPressed: fetchPackets,
// // //         child: Icon(Icons.refresh),
// // //       ),
// // //     );
// // //   }
// // // }

// // import 'package:flutter/material.dart';
// // import 'package:nidswebapp/db/sqlite.dart';
// // import 'package:nidswebapp/wireshark/packet_data.dart';

// // class DebugScreen extends StatefulWidget {
// //   @override
// //   _DebugScreenState createState() => _DebugScreenState();
// // }

// // class _DebugScreenState extends State<DebugScreen> {
// //   List<PacketData> packets = [];

// //   @override
// //   void initState() {
// //     super.initState();
// //     fetchPackets();
// //   }

// //   void fetchPackets() async {
// //     List<PacketData> data = await SQLiteHandler().getAllPackets();
// //     setState(() {
// //       packets = data;
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: Text('Debug Packets')),
// //       body: packets.isEmpty
// //           ? Center(child: Text('No Packets Found'))
// //           : SingleChildScrollView(
// //               scrollDirection: Axis.horizontal,
// //               child: DataTable(
// //                 columnSpacing: 20,
// //                 headingRowColor: MaterialStateColor.resolveWith(
// //                     (states) => Colors.blue.shade100),
// //                 columns: [
// //                   DataColumn(label: Text("No")),
// //                   DataColumn(label: Text("Time")),
// //                   DataColumn(label: Text("Source")),
// //                   DataColumn(label: Text("Destination")),
// //                   DataColumn(label: Text("Protocol")),
// //                   DataColumn(label: Text("Length")),
// //                   DataColumn(label: Text("Info")),
// //                 ],
// //                 rows: packets.map((packet) {
// //                   return DataRow(
// //                     cells: [
// //                       DataCell(Text(packet.no.toString())),
// //                       DataCell(Text(packet.time)),
// //                       DataCell(Text(packet.source)),
// //                       DataCell(Text(packet.destination)),
// //                       DataCell(Text(packet.protocol)),
// //                       DataCell(Text(packet.length.toString())),
// //                       DataCell(Text(packet.info)),
// //                     ],
// //                   );
// //                 }).toList(),
// //               ),
// //             ),
// //       floatingActionButton: FloatingActionButton(
// //         onPressed: fetchPackets,
// //         child: Icon(Icons.refresh),
// //       ),
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';
// import 'package:nidswebapp/db/sqlite.dart';
// import 'package:nidswebapp/wireshark/packet_data.dart';

// class DebugScreen extends StatefulWidget {
//   @override
//   _DebugScreenState createState() => _DebugScreenState();
// }

// class _DebugScreenState extends State<DebugScreen> {
//   List<PacketData> packets = [];
//   bool isLoading = true;
//   final ScrollController _horizontalController = ScrollController();
//   final ScrollController _verticalController = ScrollController();

//   @override
//   void initState() {
//     super.initState();
//     fetchPackets();
//   }

//   @override
//   void dispose() {
//     _horizontalController.dispose();
//     _verticalController.dispose();
//     super.dispose();
//   }

//   void fetchPackets() async {
//     setState(() {
//       isLoading = true;
//     });

//     List<PacketData> data = await SQLiteHandler().getAllPackets();

//     if (mounted) {
//       setState(() {
//         packets = data;
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Debug Packets'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh),
//             onPressed: fetchPackets,
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : _buildPacketTable(),
//     );
//   }

//   Widget _buildPacketTable() {
//     if (packets.isEmpty) {
//       return Center(child: Text('No Packets Found'));
//     }

//     return Scrollbar(
//       controller: _verticalController,
//       thumbVisibility: true,
//       child: ListView(
//         controller: _verticalController,
//         children: [
//           Scrollbar(
//             controller: _horizontalController,
//             thumbVisibility: true,
//             scrollbarOrientation: ScrollbarOrientation.bottom,
//             child: SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               controller: _horizontalController,
//               child: DataTable(
//                 columnSpacing: 20,
//                 headingRowColor: MaterialStateColor.resolveWith(
//                     (states) => Colors.blue.shade100),
//                 columns: const [
//                   DataColumn(label: Text("No")),
//                   DataColumn(label: Text("Time")),
//                   DataColumn(label: Text("Source")),
//                   DataColumn(label: Text("Destination")),
//                   DataColumn(label: Text("Protocol")),
//                   DataColumn(label: Text("Length")),
//                   DataColumn(label: Text("Info")),
//                 ],
//                 rows: List.generate(
//                   packets.length > 100 ? 100 : packets.length,
//                   (index) {
//                     final packet = packets[index];
//                     return DataRow(
//                       cells: [
//                         DataCell(Text(packet.no.toString())),
//                         DataCell(Text(packet.time)),
//                         DataCell(Text(packet.source)),
//                         DataCell(Text(packet.destination)),
//                         DataCell(Text(packet.protocol)),
//                         DataCell(Text(packet.length.toString())),
//                         DataCell(
//                           Container(
//                             constraints: BoxConstraints(maxWidth: 300),
//                             child: Text(
//                               packet.info,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ),
//           if (packets.length > 100)
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Center(
//                 child: Text(
//                   'Showing first 100 of ${packets.length} packets. Use filters to narrow results.',
//                   style: TextStyle(fontStyle: FontStyle.italic),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:nidswebapp/db/db_file_selector.dart';
import 'package:nidswebapp/db/sqlite.dart';
import 'package:nidswebapp/wireshark/packet_data.dart';

class DebugScreen extends StatefulWidget {
  @override
  _DebugScreenState createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  List<PacketData> packets = [];
  bool isLoading = true;
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchPackets();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  void fetchPackets() async {
    setState(() {
      isLoading = true;
    });

    List<PacketData> data = await SQLiteHandler().getAllPackets();

    if (mounted) {
      setState(() {
        packets = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Debug Packets'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchPackets,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Add the database selector widget
          DatabaseSelector(onDatabaseChanged: fetchPackets),
          // Stats summary
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Total Packets: ${packets.length}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          // Data table
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : _buildPacketTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildPacketTable() {
    if (packets.isEmpty) {
      return Center(child: Text('No Packets Found'));
    }

    return Scrollbar(
      controller: _verticalController,
      thumbVisibility: true,
      child: ListView(
        controller: _verticalController,
        children: [
          Scrollbar(
            controller: _horizontalController,
            thumbVisibility: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _horizontalController,
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: MaterialStateColor.resolveWith(
                    (states) => Colors.blue.shade100),
                columns: const [
                  DataColumn(label: Text("No")),
                  DataColumn(label: Text("Time")),
                  DataColumn(label: Text("Source")),
                  DataColumn(label: Text("Destination")),
                  DataColumn(label: Text("Protocol")),
                  DataColumn(label: Text("Length")),
                  DataColumn(label: Text("Info")),
                ],
                rows: List.generate(
                  packets.length > 100 ? 100 : packets.length,
                  (index) {
                    final packet = packets[index];
                    return DataRow(
                      cells: [
                        DataCell(Text(packet.no.toString())),
                        DataCell(Text(packet.time)),
                        DataCell(Text(packet.source)),
                        DataCell(Text(packet.destination)),
                        DataCell(Text(packet.protocol)),
                        DataCell(Text(packet.length.toString())),
                        DataCell(
                          Container(
                            constraints: BoxConstraints(maxWidth: 300),
                            child: Text(
                              packet.info,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          if (packets.length > 100)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'Showing first 100 of ${packets.length} packets. Use filters to narrow results.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
