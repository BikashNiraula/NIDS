// // import 'package:flutter/material.dart';
// // import 'package:fl_chart/fl_chart.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';

// // class NetworkTrafficScreen extends StatefulWidget {
// //   const NetworkTrafficScreen({super.key});

// //   @override
// //   _NetworkTrafficScreenState createState() => _NetworkTrafficScreenState();
// // }

// // class _NetworkTrafficScreenState extends State<NetworkTrafficScreen> {
// //   List<NetworkUsage> networkData = [];
// //   int timeCounter = 0;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _fetchNetworkData();
// //   }

// //   Future<void> _fetchNetworkData() async {
// //     const String apiUrl = 'http://localhost:8080/status';

// //     while (true) {
// //       try {
// //         final response = await http.get(Uri.parse(apiUrl));
// //         if (response.statusCode == 200) {
// //           final Map<String, dynamic> data = json.decode(response.body);
// //           final double networkIn = data['networkIn'].toDouble();
// //           final double networkOut = data['networkOut'].toDouble();

// //           setState(() {
// //             networkData.add(NetworkUsage(timeCounter, networkIn + networkOut));
// //             timeCounter++;
// //           });

// //           // Limit the data points to 20 for better visualization
// //           if (networkData.length > 20) {
// //             networkData.removeAt(0);
// //           }
// //         } else {
// //           throw Exception('Failed to load data');
// //         }
// //       } catch (e) {
// //         print('Error fetching data: $e');
// //       }

// //       // Wait for 1 second before fetching the next data point
// //       await Future.delayed(const Duration(seconds: 1));
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Network Traffic Monitor'),
// //       ),
// //       body: Padding(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Column(
// //           children: [
// //             NetworkTrafficCard(data: networkData),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// // class NetworkTrafficCard extends StatelessWidget {
// //   final List<NetworkUsage> data;

// //   const NetworkTrafficCard({super.key, required this.data});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Card(
// //       elevation: 4,
// //       child: Padding(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             const Text(
// //               'Network Traffic',
// //               style: TextStyle(
// //                 fontSize: 18,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //             const SizedBox(height: 16),
// //             SizedBox(
// //               height: 200,
// //               child: LineChart(
// //                 _buildChart(),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   LineChartData _buildChart() {
// //     return LineChartData(
// //       gridData: FlGridData(show: true),
// //       titlesData: FlTitlesData(
// //         leftTitles: AxisTitles(
// //           sideTitles: SideTitles(showTitles: true, reservedSize: 40),
// //         ),
// //         bottomTitles: AxisTitles(
// //           sideTitles: SideTitles(
// //             showTitles: true,
// //             getTitlesWidget: (value, meta) => Text('${value.toInt()}s'),
// //             reservedSize: 22,
// //           ),
// //         ),
// //       ),
// //       borderData: FlBorderData(show: true),
// //       lineBarsData: [
// //         LineChartBarData(
// //           spots: data
// //               .map((usage) => FlSpot(usage.time.toDouble(), usage.usage))
// //               .toList(),
// //           isCurved: true,
// //           color: Colors.blue,
// //           barWidth: 3,
// //           isStrokeCapRound: true,
// //           belowBarData: BarAreaData(
// //             show: true,
// //             color: Colors.blue.withOpacity(0.3),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// // }

// // class NetworkUsage {
// //   final int time;
// //   final double usage;

// //   NetworkUsage(this.time, this.usage);
// // }

// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:math' as math;

// class NetworkTrafficScreen extends StatefulWidget {
//   const NetworkTrafficScreen({super.key});

//   @override
//   _NetworkTrafficScreenState createState() => _NetworkTrafficScreenState();
// }

// class _NetworkTrafficScreenState extends State<NetworkTrafficScreen> {
//   List<NetworkUsage> networkData = [];
//   int timeCounter = 0;
//   bool isDarkMode = false;
//   String selectedView = 'line'; // 'line' or 'area'

//   @override
//   void initState() {
//     super.initState();
//     _fetchNetworkData();
//   }

//   Future<void> _fetchNetworkData() async {
//     const String apiUrl = 'http://localhost:8080/status';

//     while (true) {
//       try {
//         final response = await http.get(Uri.parse(apiUrl));
//         if (response.statusCode == 200) {
//           final Map<String, dynamic> data = json.decode(response.body);
//           final double networkIn = data['networkIn'].toDouble();
//           final double networkOut = data['networkOut'].toDouble();

//           setState(() {
//             networkData.add(NetworkUsage(timeCounter, networkIn, networkOut));
//             timeCounter++;
//           });

//           if (networkData.length > 20) {
//             networkData.removeAt(0);
//           }
//         } else {
//           throw Exception('Failed to load data');
//         }
//       } catch (e) {
//         print('Error fetching data: $e');
//       }
//       await Future.delayed(const Duration(seconds: 1));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Theme(
//       data: isDarkMode ? ThemeData.dark() : ThemeData.light(),
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('Network Traffic Monitor'),
//           actions: [
//             IconButton(
//               icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
//               onPressed: () {
//                 setState(() {
//                   isDarkMode = !isDarkMode;
//                 });
//               },
//             ),
//           ],
//         ),
//         body: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             children: [
//               _buildStatisticsCards(),
//               const SizedBox(height: 16),
//               _buildChartTypeSelector(),
//               const SizedBox(height: 16),
//               Expanded(
//                 child: NetworkTrafficCard(
//                   data: networkData,
//                   isDarkMode: isDarkMode,
//                   viewType: selectedView,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildStatisticsCards() {
//     final latestData = networkData.isNotEmpty ? networkData.last : null;

//     return GridView.count(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       crossAxisCount: 2,
//       childAspectRatio: 1.5,
//       crossAxisSpacing: 16,
//       mainAxisSpacing: 16,
//       children: [
//         _buildStatCard('Network In', latestData?.networkIn ?? 0,
//             Icons.arrow_downward, Colors.green),
//         _buildStatCard('Network Out', latestData?.networkOut ?? 0,
//             Icons.arrow_upward, Colors.orange),
//         _buildStatCard(
//             'Total Usage',
//             latestData != null
//                 ? latestData.networkIn + latestData.networkOut
//                 : 0,
//             Icons.data_usage,
//             Colors.blue),
//         _buildStatCard(
//             'Peak Usage',
//             networkData.isEmpty
//                 ? 0
//                 : networkData
//                     .map((e) => e.networkIn + e.networkOut)
//                     .reduce(math.max),
//             Icons.show_chart,
//             Colors.purple),
//       ],
//     );
//   }

//   Widget _buildStatCard(
//       String title, double value, IconData icon, Color color) {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: color, size: 24),
//             const SizedBox(height: 8),
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: isDarkMode ? Colors.white70 : Colors.black54,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               '${value.toStringAsFixed(2)} MB/s',
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
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
//       selected: {selectedView},
//       onSelectionChanged: (Set<String> newSelection) {
//         setState(() {
//           selectedView = newSelection.first;
//         });
//       },
//     );
//   }
// }

// class NetworkTrafficCard extends StatelessWidget {
//   final List<NetworkUsage> data;
//   final bool isDarkMode;
//   final String viewType;

//   const NetworkTrafficCard({
//     super.key,
//     required this.data,
//     required this.isDarkMode,
//     required this.viewType,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 8,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Container(
//         padding: const EdgeInsets.all(16.0),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(16),
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: isDarkMode
//                 ? [Colors.grey[900]!, Colors.grey[800]!]
//                 : [Colors.white, Colors.grey[100]!],
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Network Traffic',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: isDarkMode ? Colors.white : Colors.black87,
//               ),
//             ),
//             const SizedBox(height: 24),
//             Expanded(
//               child: LineChart(
//                 _buildChart(),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   LineChartData _buildChart() {
//     return LineChartData(
//       gridData: FlGridData(
//         show: true,
//         drawVerticalLine: true,
//         horizontalInterval: 1,
//         verticalInterval: 1,
//         getDrawingHorizontalLine: (value) {
//           return FlLine(
//             color: isDarkMode ? Colors.white24 : Colors.black12,
//             strokeWidth: 1,
//           );
//         },
//         getDrawingVerticalLine: (value) {
//           return FlLine(
//             color: isDarkMode ? Colors.white24 : Colors.black12,
//             strokeWidth: 1,
//           );
//         },
//       ),
//       titlesData: FlTitlesData(
//         leftTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 40,
//             getTitlesWidget: (value, meta) {
//               return Text(
//                 '${value.toInt()} MB/s',
//                 style: TextStyle(
//                   color: isDarkMode ? Colors.white70 : Colors.black54,
//                   fontSize: 12,
//                 ),
//               );
//             },
//           ),
//         ),
//         bottomTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             getTitlesWidget: (value, meta) {
//               return Padding(
//                 padding: const EdgeInsets.only(top: 8.0),
//                 child: Text(
//                   '${value.toInt()}s',
//                   style: TextStyle(
//                     color: isDarkMode ? Colors.white70 : Colors.black54,
//                     fontSize: 12,
//                   ),
//                 ),
//               );
//             },
//             reservedSize: 32,
//           ),
//         ),
//         rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//       ),
//       borderData: FlBorderData(show: false),
//       lineBarsData: [
//         LineChartBarData(
//           spots: data
//               .map((usage) => FlSpot(
//                   usage.time.toDouble(), usage.networkIn + usage.networkOut))
//               .toList(),
//           isCurved: true,
//           gradient: LinearGradient(colors: [Colors.blue[300]!, Colors.blue]),
//           barWidth: 4,
//           isStrokeCapRound: true,
//           dotData: FlDotData(show: false),
//           belowBarData: BarAreaData(
//             show: viewType == 'area',
//             gradient: LinearGradient(
//               colors: [
//                 Colors.blue.withOpacity(0.3),
//                 Colors.blue.withOpacity(0.0)
//               ],
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//             ),
//           ),
//         ),
//       ],
//       lineTouchData: LineTouchData(
//         touchTooltipData: LineTouchTooltipData(
//           tooltipRoundedRadius: 8,
//           getTooltipItems: (touchedSpots) {
//             return touchedSpots.map((spot) {
//               return LineTooltipItem(
//                 '${spot.y.toStringAsFixed(2)} MB/s\n',
//                 TextStyle(
//                   color: isDarkMode ? Colors.white : Colors.black87,
//                   fontWeight: FontWeight.bold,
//                 ),
//                 children: [
//                   TextSpan(
//                     text: 'Time: ${spot.x.toInt()}s',
//                     style: TextStyle(
//                       color: isDarkMode ? Colors.white70 : Colors.black54,
//                       fontWeight: FontWeight.normal,
//                     ),
//                   ),
//                 ],
//               );
//             }).toList();
//           },
//         ),
//       ),
//     );
//   }
// }

// class NetworkUsage {
//   final int time;
//   final double networkIn;
//   final double networkOut;

//   NetworkUsage(this.time, this.networkIn, this.networkOut);
// }
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;

class NetworkTrafficScreen extends StatefulWidget {
  const NetworkTrafficScreen({super.key});

  @override
  _NetworkTrafficScreenState createState() => _NetworkTrafficScreenState();
}

class _NetworkTrafficScreenState extends State<NetworkTrafficScreen> {
  List<NetworkUsage> networkData = [];
  int timeCounter = 0;
  String selectedView = 'line'; // 'line' or 'area'

  @override
  void initState() {
    super.initState();
    _fetchNetworkData();
  }

  Future<void> _fetchNetworkData() async {
    const String apiUrl = 'http://localhost:8080/status';

    while (true) {
      try {
        final response = await http.get(Uri.parse(apiUrl));
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          final double networkIn = data['networkIn'].toDouble();
          final double networkOut = data['networkOut'].toDouble();

          setState(() {
            networkData.add(NetworkUsage(timeCounter, networkIn, networkOut));
            timeCounter++;
          });

          if (networkData.length > 20) {
            networkData.removeAt(0);
          }
        } else {
          throw Exception('Failed to load data');
        }
      } catch (e) {
        print('Error fetching data: $e');
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Traffic Monitor'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildStatisticsCards(),
              const SizedBox(height: 16),
              _buildChartTypeSelector(),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: NetworkTrafficCard(
                  data: networkData,
                  viewType: selectedView,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    final latestData = networkData.isNotEmpty ? networkData.last : null;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard('Network In', latestData?.networkIn ?? 0,
            Icons.arrow_downward, Colors.green),
        _buildStatCard('Network Out', latestData?.networkOut ?? 0,
            Icons.arrow_upward, Colors.orange),
        _buildStatCard(
            'Total Usage',
            latestData != null
                ? latestData.networkIn + latestData.networkOut
                : 0,
            Icons.data_usage,
            Colors.blue),
        _buildStatCard(
            'Peak Usage',
            networkData.isEmpty
                ? 0
                : networkData
                    .map((e) => e.networkIn + e.networkOut)
                    .reduce(math.max),
            Icons.show_chart,
            Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(
      String title, double value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text('${value.toStringAsFixed(2)} MB/s',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
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
      selected: {selectedView},
      onSelectionChanged: (Set<String> newSelection) {
        setState(() {
          selectedView = newSelection.first;
        });
      },
    );
  }
}

class NetworkTrafficCard extends StatelessWidget {
  final List<NetworkUsage> data;
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
            const Text('Network Traffic',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Expanded(child: LineChart(_buildChart())),
          ],
        ),
      ),
    );
  }

  LineChartData _buildChart() {
    return LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: data
              .map((usage) => FlSpot(
                  usage.time.toDouble(), usage.networkIn + usage.networkOut))
              .toList(),
          isCurved: true,
          gradient: LinearGradient(colors: [Colors.blue[300]!, Colors.blue]),
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: viewType == 'area',
            gradient: LinearGradient(colors: [
              Colors.blue.withOpacity(0.3),
              Colors.blue.withOpacity(0.0)
            ]),
          ),
        ),
      ],
    );
  }
}

class NetworkUsage {
  final int time;
  final double networkIn;
  final double networkOut;
  NetworkUsage(this.time, this.networkIn, this.networkOut);
}
