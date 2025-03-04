// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'dart:math' as math;

// class NetworkDetailsScreen extends StatefulWidget {
//   final List<SystemMetric> networkData;

//   const NetworkDetailsScreen({super.key, required this.networkData});

//   @override
//   _NetworkDetailsScreenState createState() => _NetworkDetailsScreenState();
// }

// class _NetworkDetailsScreenState extends State<NetworkDetailsScreen> {
//   String selectedNetworkView = 'line';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Network Details'),
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16.0),
//         children: [
//           _buildChartTypeSelector(),
//           const SizedBox(height: 16),
//           SizedBox(
//             height: 300,
//             child: NetworkTrafficCard(
//               data: widget.networkData,
//               viewType: selectedNetworkView,
//             ),
//           ),
//           const SizedBox(height: 16),
//           PacketAnalysisCard(data: widget.networkData),
//           const SizedBox(height: 16),
//           ProtocolDistributionCard(),
//         ],
//       ),
//     );
//   }

//   Widget _buildChartTypeSelector() {
//     return SegmentedButton<String>(
//       segments: const [
//         ButtonSegment(
//             value: 'line', icon: Icon(Icons.show_chart), label: Text('Line')),
//         ButtonSegment(
//             value: 'area', icon: Icon(Icons.area_chart), label: Text('Area')),
//       ],
//       selected: {selectedNetworkView},
//       onSelectionChanged: (Set<String> newSelection) {
//         setState(() {
//           selectedNetworkView = newSelection.first;
//         });
//       },
//     );
//   }
// }

// class NetworkTrafficCard extends StatelessWidget {
//   final List<SystemMetric> data;
//   final String viewType;

//   const NetworkTrafficCard(
//       {super.key, required this.data, required this.viewType});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 8,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text('Network Traffic Detail',
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 _buildLegendItem('In', Colors.greenAccent),
//                 const SizedBox(width: 16),
//                 _buildLegendItem('Out', Colors.orangeAccent),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Expanded(
//               child: LineChart(
//                 _buildDetailedChart(),
//                 key: ValueKey(
//                     data.length), // Rebuild only when data length changes
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLegendItem(String label, Color color) {
//     return Row(
//       children: [
//         Container(
//           width: 12,
//           height: 12,
//           color: color,
//         ),
//         const SizedBox(width: 4),
//         Text(label, style: const TextStyle(fontSize: 12)),
//       ],
//     );
//   }

//   LineChartData _buildDetailedChart() {
//     // Limit the number of data points to the last 100
//     final displayedData =
//         data.length > 100 ? data.sublist(data.length - 100) : data;

//     // Calculate maxY value
//     final double maxYValue = displayedData.isEmpty
//         ? 10
//         : displayedData
//                 .map((e) => math.max(e.value1, e.value2))
//                 .reduce(math.max) *
//             1.2;

//     return LineChartData(
//       gridData: FlGridData(show: false), // Disable grid lines
//       titlesData: FlTitlesData(show: false), // Disable titles
//       borderData: FlBorderData(show: false), // Disable border
//       minX: displayedData.isNotEmpty ? displayedData.first.time.toDouble() : 0,
//       maxX: displayedData.isNotEmpty ? displayedData.last.time.toDouble() : 0,
//       minY: 0,
//       maxY: maxYValue,
//       lineBarsData: [
//         LineChartBarData(
//           spots: displayedData
//               .map((usage) => FlSpot(usage.time.toDouble(), usage.value1))
//               .toList(),
//           isCurved: false, // Disable curve
//           color: Colors.greenAccent,
//           barWidth: 2,
//           isStrokeCapRound: true,
//           dotData: const FlDotData(show: false),
//           belowBarData: BarAreaData(show: false), // Disable area chart
//         ),
//         LineChartBarData(
//           spots: displayedData
//               .map((usage) => FlSpot(usage.time.toDouble(), usage.value2))
//               .toList(),
//           isCurved: false, // Disable curve
//           color: Colors.orangeAccent,
//           barWidth: 2,
//           isStrokeCapRound: true,
//           dotData: const FlDotData(show: false),
//           belowBarData: BarAreaData(show: false), // Disable area chart
//         ),
//       ],
//     );
//   }
// }

// class PacketAnalysisCard extends StatelessWidget {
//   final List<SystemMetric> data;

//   const PacketAnalysisCard({super.key, required this.data});

//   @override
//   Widget build(BuildContext context) {
//     // Calculate packet statistics
//     final avgIn = data.isEmpty
//         ? 0
//         : data.map((e) => e.value1).reduce((a, b) => a + b) / data.length;
//     final avgOut = data.isEmpty
//         ? 0
//         : data.map((e) => e.value2).reduce((a, b) => a + b) / data.length;
//     final maxIn = data.isEmpty
//         ? 0
//         : data.map((e) => e.value1).reduce((a, b) => math.max(a, b));
//     final maxOut = data.isEmpty
//         ? 0
//         : data.map((e) => e.value2).reduce((a, b) => math.max(a, b));

//     return Card(
//       elevation: 8,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text('Packet Analysis',
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 16),
//             GridView.count(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               crossAxisCount: 2,
//               childAspectRatio: 2.5,
//               crossAxisSpacing: 16,
//               mainAxisSpacing: 16,
//               children: [
//                 _buildMetricTile('Avg Traffic In', '$avgIn MB/s',
//                     Icons.arrow_downward, Colors.green),
//                 _buildMetricTile('Avg Traffic Out', '$avgOut MB/s',
//                     Icons.arrow_upward, Colors.orange),
//                 _buildMetricTile(
//                     'Peak Traffic In', '$maxIn MB/s', Icons.speed, Colors.blue),
//                 _buildMetricTile('Peak Traffic Out', '$maxOut MB/s',
//                     Icons.speed, Colors.red),
//                 _buildMetricTile('Packet Drop Rate', '0.02%',
//                     Icons.error_outline, Colors.amber),
//                 _buildMetricTile(
//                     'Avg Latency', '5.2 ms', Icons.timer, Colors.purple),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMetricTile(
//       String title, String value, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(8),
//         color: color.withOpacity(0.1),
//       ),
//       child: Row(
//         children: [
//           Icon(icon, color: color, size: 20),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(title, style: const TextStyle(fontSize: 12)),
//                 const SizedBox(height: 2),
//                 Text(value,
//                     style: const TextStyle(
//                         fontWeight: FontWeight.bold, fontSize: 14)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class ProtocolDistributionCard extends StatelessWidget {
//   final Map<String, double> protocolData = {
//     'TCP': 65.2,
//     'UDP': 22.4,
//     'HTTP': 8.7,
//     'HTTPS': 2.3,
//     'Other': 1.4,
//   };

//   ProtocolDistributionCard({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 8,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text('Protocol Distribution',
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 16),
//             SizedBox(
//               height: 250,
//               child: Row(
//                 children: [
//                   Expanded(
//                     flex: 3,
//                     child: PieChart(_buildProtocolChart()),
//                   ),
//                   Expanded(
//                     flex: 2,
//                     child: _buildProtocolLegend(),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   PieChartData _buildProtocolChart() {
//     final List<Color> colors = [
//       Colors.blue,
//       Colors.green,
//       Colors.amber,
//       Colors.purple,
//       Colors.grey,
//     ];

//     return PieChartData(
//       sectionsSpace: 0, // No space between sections
//       centerSpaceRadius: 40,
//       sections: List.generate(protocolData.entries.length, (index) {
//         final entry = protocolData.entries.elementAt(index);
//         return PieChartSectionData(
//           color: colors[index % colors.length],
//           value: entry.value,
//           title: '${entry.value}%',
//           radius: 80,
//           titleStyle: const TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: 14,
//           ),
//         );
//       }),
//     );
//   }

//   Widget _buildProtocolLegend() {
//     final List<Color> colors = [
//       Colors.blue,
//       Colors.green,
//       Colors.amber,
//       Colors.purple,
//       Colors.grey,
//     ];

//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: List.generate(protocolData.entries.length, (index) {
//         final entry = protocolData.entries.elementAt(index);
//         return Padding(
//           padding: const EdgeInsets.symmetric(vertical: 4.0),
//           child: Row(
//             children: [
//               Container(
//                 width: 16,
//                 height: 16,
//                 color: colors[index % colors.length],
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   '${entry.key}: ${entry.value}%',
//                   style: const TextStyle(fontSize: 14),
//                 ),
//               ),
//             ],
//           ),
//         );
//       }),
//     );
//   }
// }

// // Data Models
// class SystemMetric {
//   final int time;
//   final double value1;
//   final double value2;

//   SystemMetric(this.time, this.value1, this.value2);
// }

// class MemoryUsage {
//   final int time;
//   final double usedMemory;
//   final double availableMemory;
//   final double cachedMemory;
//   final double bufferMemory;

//   MemoryUsage(this.time, this.usedMemory, this.availableMemory,
//       this.cachedMemory, this.bufferMemory);
// }
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class NetworkDetailsScreen extends StatefulWidget {
  const NetworkDetailsScreen({super.key});

  @override
  _NetworkDetailsScreenState createState() => _NetworkDetailsScreenState();
}

class _NetworkDetailsScreenState extends State<NetworkDetailsScreen> {
  String selectedNetworkView = 'line';
  List<SystemMetric> networkData = [];

  @override
  void initState() {
    super.initState();
    // Initialize or fetch network data here
    _initializeNetworkData();
  }

  void _initializeNetworkData() {
    // Example: Populate networkData with some dummy data
    // You can replace this with actual data fetching logic
    for (int i = 0; i < 100; i++) {
      networkData.add(SystemMetric(i, math.Random().nextDouble() * 100,
          math.Random().nextDouble() * 100));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildChartTypeSelector(),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: NetworkTrafficCard(
              data: networkData,
              viewType: selectedNetworkView,
            ),
          ),
          const SizedBox(height: 16),
          PacketAnalysisCard(data: networkData),
          const SizedBox(height: 16),
          ProtocolDistributionCard(),
        ],
      ),
    );
  }

  Widget _buildChartTypeSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
            value: 'line', icon: Icon(Icons.show_chart), label: Text('Line')),
        ButtonSegment(
            value: 'area', icon: Icon(Icons.area_chart), label: Text('Area')),
      ],
      selected: {selectedNetworkView},
      onSelectionChanged: (Set<String> newSelection) {
        setState(() {
          selectedNetworkView = newSelection.first;
        });
      },
    );
  }
}

class NetworkTrafficCard extends StatelessWidget {
  final List<SystemMetric> data;
  final String viewType;

  const NetworkTrafficCard(
      {super.key, required this.data, required this.viewType});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Network Traffic Detail',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildLegendItem('In', Colors.greenAccent),
                const SizedBox(width: 16),
                _buildLegendItem('Out', Colors.orangeAccent),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LineChart(
                _buildDetailedChart(),
                key: ValueKey(
                    data.length), // Rebuild only when data length changes
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  LineChartData _buildDetailedChart() {
    // Limit the number of data points to the last 100
    final displayedData =
        data.length > 100 ? data.sublist(data.length - 100) : data;

    // Calculate maxY value
    final double maxYValue = displayedData.isEmpty
        ? 10
        : displayedData
                .map((e) => math.max(e.value1, e.value2))
                .reduce(math.max) *
            1.2;

    return LineChartData(
      gridData: FlGridData(show: false), // Disable grid lines
      titlesData: FlTitlesData(show: false), // Disable titles
      borderData: FlBorderData(show: false), // Disable border
      minX: displayedData.isNotEmpty ? displayedData.first.time.toDouble() : 0,
      maxX: displayedData.isNotEmpty ? displayedData.last.time.toDouble() : 0,
      minY: 0,
      maxY: maxYValue,
      lineBarsData: [
        LineChartBarData(
          spots: displayedData
              .map((usage) => FlSpot(usage.time.toDouble(), usage.value1))
              .toList(),
          isCurved: false, // Disable curve
          color: Colors.greenAccent,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false), // Disable area chart
        ),
        LineChartBarData(
          spots: displayedData
              .map((usage) => FlSpot(usage.time.toDouble(), usage.value2))
              .toList(),
          isCurved: false, // Disable curve
          color: Colors.orangeAccent,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false), // Disable area chart
        ),
      ],
    );
  }
}

class PacketAnalysisCard extends StatelessWidget {
  final List<SystemMetric> data;

  const PacketAnalysisCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Calculate packet statistics
    final avgIn = data.isEmpty
        ? 0
        : data.map((e) => e.value1).reduce((a, b) => a + b) / data.length;
    final avgOut = data.isEmpty
        ? 0
        : data.map((e) => e.value2).reduce((a, b) => a + b) / data.length;
    final maxIn = data.isEmpty
        ? 0
        : data.map((e) => e.value1).reduce((a, b) => math.max(a, b));
    final maxOut = data.isEmpty
        ? 0
        : data.map((e) => e.value2).reduce((a, b) => math.max(a, b));

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Packet Analysis',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildMetricTile('Avg Traffic In', '$avgIn MB/s',
                    Icons.arrow_downward, Colors.green),
                _buildMetricTile('Avg Traffic Out', '$avgOut MB/s',
                    Icons.arrow_upward, Colors.orange),
                _buildMetricTile(
                    'Peak Traffic In', '$maxIn MB/s', Icons.speed, Colors.blue),
                _buildMetricTile('Peak Traffic Out', '$maxOut MB/s',
                    Icons.speed, Colors.red),
                _buildMetricTile('Packet Drop Rate', '0.02%',
                    Icons.error_outline, Colors.amber),
                _buildMetricTile(
                    'Avg Latency', '5.2 ms', Icons.timer, Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProtocolDistributionCard extends StatelessWidget {
  final Map<String, double> protocolData = {
    'TCP': 65.2,
    'UDP': 22.4,
    'HTTP': 8.7,
    'HTTPS': 2.3,
    'Other': 1.4,
  };

  ProtocolDistributionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Protocol Distribution',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(_buildProtocolChart()),
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildProtocolLegend(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PieChartData _buildProtocolChart() {
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.amber,
      Colors.purple,
      Colors.grey,
    ];

    return PieChartData(
      sectionsSpace: 0, // No space between sections
      centerSpaceRadius: 40,
      sections: List.generate(protocolData.entries.length, (index) {
        final entry = protocolData.entries.elementAt(index);
        return PieChartSectionData(
          color: colors[index % colors.length],
          value: entry.value,
          title: '${entry.value}%',
          radius: 80,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        );
      }),
    );
  }

  Widget _buildProtocolLegend() {
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.amber,
      Colors.purple,
      Colors.grey,
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(protocolData.entries.length, (index) {
        final entry = protocolData.entries.elementAt(index);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                color: colors[index % colors.length],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${entry.key}: ${entry.value}%',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// Data Models
class SystemMetric {
  final int time;
  final double value1;
  final double value2;

  SystemMetric(this.time, this.value1, this.value2);
}

class MemoryUsage {
  final int time;
  final double usedMemory;
  final double availableMemory;
  final double cachedMemory;
  final double bufferMemory;

  MemoryUsage(this.time, this.usedMemory, this.availableMemory,
      this.cachedMemory, this.bufferMemory);
}
