// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:math' as math;
// import 'dart:async';

// class NetworkAnalyticsScreen extends StatefulWidget {
//   const NetworkAnalyticsScreen({super.key});

//   @override
//   _NetworkAnalyticsScreenState createState() => _NetworkAnalyticsScreenState();
// }

// class _NetworkAnalyticsScreenState extends State<NetworkAnalyticsScreen>
//     with SingleTickerProviderStateMixin {
//   // Data collections
//   final int maxDataPoints = 100; // Limit the number of data points
//   List<SystemMetric> networkData = [];
//   List<SystemMetric> cpuData = [];
//   List<MemoryUsage> memoryData = [];

//   // States
//   int timeCounter = 0;
//   String selectedNetworkView = 'line';
//   bool isLoading = true;
//   bool isPolling = true;
//   Timer? _pollingTimer;
//   late TabController _tabController;

//   // Filter
//   String timeRange = '1h';

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//     _initializeData();
//   }

//   @override
//   void dispose() {
//     _pollingTimer?.cancel();
//     _tabController.dispose();
//     super.dispose();
//   }

//   Future<void> _initializeData() async {
//     // Initial data fetch to populate charts
//     await _fetchSystemData();

//     setState(() {
//       isLoading = false;
//     });

//     // Setup more memory-efficient polling
//     _startPolling();
//   }

//   void _startPolling() {
//     // Using periodic timer instead of infinite loop for better memory management
//     _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
//       if (isPolling) {
//         _fetchSystemData();
//       }
//     });
//   }

//   void _togglePolling() {
//     setState(() {
//       isPolling = !isPolling;
//     });
//   }

//   Future<void> _fetchSystemData() async {
//     const String apiUrl = 'http://localhost:8080/status';

//     try {
//       final response = await http.get(Uri.parse(apiUrl));
//       if (response.statusCode == 200) {
//         final Map<String, dynamic> data = json.decode(response.body);

//         setState(() {
//           // Network data
//           final double networkIn = data['networkIn'].toDouble();
//           final double networkOut = data['networkOut'].toDouble();
//           _addDataPoint(
//               networkData, SystemMetric(timeCounter, networkIn, networkOut));

//           // CPU data
//           final double cpuUsage = data['cpuUsage'].toDouble();
//           final double idleUsage = 100 - cpuUsage;
//           _addDataPoint(
//               cpuData, SystemMetric(timeCounter, cpuUsage, idleUsage));

//           // Memory data
//           final double usedMem = data['memoryUsed'].toDouble();
//           final double availableMem = data['memoryAvailable'].toDouble();
//           final double cachedMem = data['memoryCached']?.toDouble() ?? 0.0;
//           final double bufferMem = data['memoryBuffer']?.toDouble() ?? 0.0;
//           _addDataPoint(
//               memoryData,
//               MemoryUsage(
//                   timeCounter, usedMem, availableMem, cachedMem, bufferMem));

//           timeCounter++;
//         });
//       } else {
//         throw Exception('Failed to load data: ${response.statusCode}');
//       }
//     } catch (e) {
//       debugPrint('Error fetching data: $e');
//     }
//   }

//   void _addDataPoint<T>(List<T> dataList, T newData) {
//     if (dataList.length >= maxDataPoints) {
//       dataList.removeAt(0);
//     }
//     dataList.add(newData);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('NIDS Network Monitor'),
//         actions: [
//           IconButton(
//             icon: Icon(isPolling ? Icons.pause : Icons.play_arrow),
//             onPressed: _togglePolling,
//             tooltip: isPolling ? 'Pause Updates' : 'Resume Updates',
//           ),
//           PopupMenuButton<String>(
//             icon: const Icon(Icons.more_vert),
//             onSelected: (value) {
//               setState(() {
//                 timeRange = value;
//               });
//             },
//             itemBuilder: (context) => [
//               const PopupMenuItem(value: '1h', child: Text('1 Hour')),
//               const PopupMenuItem(value: '3h', child: Text('3 Hours')),
//               const PopupMenuItem(value: '12h', child: Text('12 Hours')),
//               const PopupMenuItem(value: '24h', child: Text('24 Hours')),
//             ],
//           ),
//         ],
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: const [
//             Tab(text: 'Overview'),
//             Tab(text: 'Network Details'),
//           ],
//         ),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : TabBarView(
//               controller: _tabController,
//               children: [
//                 _buildOverviewTab(),
//                 _buildNetworkDetailsTab(),
//               ],
//             ),
//     );
//   }

//   Widget _buildOverviewTab() {
//     return RefreshIndicator(
//       onRefresh: _fetchSystemData,
//       child: SingleChildScrollView(
//         physics: const AlwaysScrollableScrollPhysics(),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildSummaryCards(),
//               const SizedBox(height: 24),
//               _buildNetworkOverviewCard(),
//               const SizedBox(height: 24),
//               Row(
//                 children: [
//                   Expanded(child: _buildMemoryPieChartCard()),
//                   const SizedBox(width: 16),
//                   Expanded(child: _buildCPUUsageCard()),
//                 ],
//               ),
//               const SizedBox(height: 24),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildNetworkDetailsTab() {
//     return ListView(
//       padding: const EdgeInsets.all(16.0),
//       children: [
//         _buildChartTypeSelector(),
//         const SizedBox(height: 16),
//         SizedBox(
//           height: 300,
//           child: NetworkTrafficCard(
//             data: networkData,
//             viewType: selectedNetworkView,
//           ),
//         ),
//         const SizedBox(height: 16),
//         PacketAnalysisCard(data: networkData),
//         const SizedBox(height: 16),
//         ProtocolDistributionCard(),
//       ],
//     );
//   }

//   Widget _buildSummaryCards() {
//     final latestNetworkData = networkData.isNotEmpty ? networkData.last : null;
//     final latestMemoryData = memoryData.isNotEmpty ? memoryData.last : null;
//     final latestCpuData = cpuData.isNotEmpty ? cpuData.last : null;

//     return GridView.count(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       crossAxisCount: 2,
//       childAspectRatio: 1.5,
//       crossAxisSpacing: 16,
//       mainAxisSpacing: 16,
//       children: [
//         _buildStatCard('Network In', latestNetworkData?.value1 ?? 0,
//             Icons.arrow_downward, Colors.green, 'MB/s'),
//         _buildStatCard('Network Out', latestNetworkData?.value2 ?? 0,
//             Icons.arrow_upward, Colors.orange, 'MB/s'),
//         _buildStatCard('CPU Usage', latestCpuData?.value1 ?? 0, Icons.memory,
//             Colors.blue, '%'),
//         _buildStatCard('Memory Used', latestMemoryData?.usedMemory ?? 0,
//             Icons.storage, Colors.purple, 'MB'),
//       ],
//     );
//   }

//   Widget _buildStatCard(
//       String title, double value, IconData icon, Color color, String unit) {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: color, size: 24),
//             const SizedBox(height: 8),
//             Text(title, style: const TextStyle(fontSize: 14)),
//             const SizedBox(height: 4),
//             Text('${value.toStringAsFixed(2)} $unit',
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 )),
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
//       selected: {selectedNetworkView},
//       onSelectionChanged: (Set<String> newSelection) {
//         setState(() {
//           selectedNetworkView = newSelection.first;
//         });
//       },
//     );
//   }

//   Widget _buildNetworkOverviewCard() {
//     return Card(
//       elevation: 8,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text('Network Traffic Overview',
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 16),
//             SizedBox(
//               height: 250,
//               child: networkData.isEmpty
//                   ? const Center(child: Text('No network data available'))
//                   : LineChart(_buildNetworkOverviewChart()),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMemoryPieChartCard() {
//     return Card(
//       elevation: 8,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text('Memory Usage',
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 16),
//             SizedBox(
//               height: 200,
//               child: memoryData.isEmpty
//                   ? const Center(child: Text('No memory data available'))
//                   : PieChart(_buildMemoryPieChart()),
//             ),
//             const SizedBox(height: 16),
//             _buildMemoryLegend(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCPUUsageCard() {
//     return Card(
//       elevation: 8,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text('CPU Utilization',
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 16),
//             SizedBox(
//               height: 200,
//               child: cpuData.isEmpty
//                   ? const Center(child: Text('No CPU data available'))
//                   : BarChart(_buildCpuBarChart()),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   LineChartData _buildNetworkOverviewChart() {
//     return LineChartData(
//       gridData: FlGridData(
//         show: true,
//         drawVerticalLine: false,
//         horizontalInterval: 1,
//       ),
//       titlesData: FlTitlesData(
//         show: true,
//         bottomTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 30,
//             getTitlesWidget: (value, meta) {
//               if (value.toInt() % 10 == 0) {
//                 return Text('${value.toInt()}s');
//               }
//               return const Text('');
//             },
//           ),
//         ),
//         leftTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 42,
//             getTitlesWidget: (value, meta) {
//               return Text('${value.toInt()} MB/s');
//             },
//           ),
//         ),
//         rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//       ),
//       borderData: FlBorderData(show: true),
//       minX: networkData.first.time.toDouble(),
//       maxX: networkData.last.time.toDouble(),
//       lineBarsData: [
//         LineChartBarData(
//           spots: networkData
//               .map((data) => FlSpot(data.time.toDouble(), data.value1))
//               .toList(),
//           isCurved: true,
//           color: Colors.greenAccent,
//           barWidth: 3,
//           isStrokeCapRound: true,
//           dotData: FlDotData(show: false),
//           belowBarData: BarAreaData(
//             show: true,
//             color: Colors.greenAccent.withOpacity(0.2),
//           ),
//         ),
//         LineChartBarData(
//           spots: networkData
//               .map((data) => FlSpot(data.time.toDouble(), data.value2))
//               .toList(),
//           isCurved: true,
//           color: Colors.orangeAccent,
//           barWidth: 3,
//           isStrokeCapRound: true,
//           dotData: FlDotData(show: false),
//           belowBarData: BarAreaData(
//             show: true,
//             color: Colors.orangeAccent.withOpacity(0.2),
//           ),
//         ),
//       ],
//     );
//   }

//   PieChartData _buildMemoryPieChart() {
//     final latestMemory = memoryData.last;
//     final double used = latestMemory.usedMemory;
//     final double cached = latestMemory.cachedMemory;
//     final double buffer = latestMemory.bufferMemory;
//     final double available = latestMemory.availableMemory;

//     return PieChartData(
//       sectionsSpace: 2,
//       centerSpaceRadius: 40,
//       sections: [
//         PieChartSectionData(
//           color: Colors.redAccent,
//           value: used,
//           title: '${(used / (used + available) * 100).toStringAsFixed(1)}%',
//           radius: 80,
//           titleStyle:
//               const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         PieChartSectionData(
//           color: Colors.orangeAccent,
//           value: cached,
//           title: cached > 5
//               ? '${(cached / (used + available) * 100).toStringAsFixed(1)}%'
//               : '',
//           radius: 80,
//           titleStyle:
//               const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         PieChartSectionData(
//           color: Colors.amberAccent,
//           value: buffer,
//           title: buffer > 5
//               ? '${(buffer / (used + available) * 100).toStringAsFixed(1)}%'
//               : '',
//           radius: 80,
//           titleStyle:
//               const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//         ),
//         PieChartSectionData(
//           color: Colors.green,
//           value: available,
//           title:
//               '${(available / (used + available) * 100).toStringAsFixed(1)}%',
//           radius: 80,
//           titleStyle:
//               const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//       ],
//     );
//   }

//   Widget _buildMemoryLegend() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceAround,
//       children: [
//         _buildLegendItem('Used', Colors.redAccent),
//         _buildLegendItem('Cached', Colors.orangeAccent),
//         _buildLegendItem('Buffer', Colors.amberAccent),
//         _buildLegendItem('Free', Colors.green),
//       ],
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

//   BarChartData _buildCpuBarChart() {
//     // Get the last 10 CPU data points or fewer if we have less
//     final dataPoints =
//         cpuData.length > 10 ? cpuData.sublist(cpuData.length - 10) : cpuData;

//     return BarChartData(
//       alignment: BarChartAlignment.spaceAround,
//       maxY: 100,
//       barTouchData: BarTouchData(enabled: false),
//       titlesData: FlTitlesData(
//         show: true,
//         bottomTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             getTitlesWidget: (value, meta) {
//               final int index = value.toInt();
//               if (index >= 0 && index < dataPoints.length) {
//                 if (index % 2 == 0) {
//                   return Text('${dataPoints[index].time}s');
//                 }
//               }
//               return const Text('');
//             },
//             reservedSize: 28,
//           ),
//         ),
//         leftTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 30,
//             interval: 20,
//             getTitlesWidget: (value, meta) {
//               return Text('${value.toInt()}%');
//             },
//           ),
//         ),
//         rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//       ),
//       borderData: FlBorderData(show: false),
//       gridData: FlGridData(show: true, horizontalInterval: 20),
//       barGroups: dataPoints.asMap().entries.map((entry) {
//         final int index = entry.key;
//         final data = entry.value;
//         return BarChartGroupData(
//           x: index,
//           barRods: [
//             BarChartRodData(
//               toY: 100,
//               rodStackItems: [
//                 BarChartRodStackItem(0, data.value1, Colors.blue),
//                 BarChartRodStackItem(data.value1, 100, Colors.grey.shade300),
//               ],
//               borderRadius: BorderRadius.zero,
//               width: 15,
//             ),
//           ],
//         );
//       }).toList(),
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
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           const Text('Network Traffic Detail',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//           const SizedBox(height: 8),
//           Row(
//             children: [
//               _buildLegendItem('In', Colors.greenAccent),
//               const SizedBox(width: 16),
//               _buildLegendItem('Out', Colors.orangeAccent),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Expanded(
//             child: LineChart(
//               _buildDetailedChart(),
//               key: ValueKey(
//                   data.length), // Rebuild only when data length changes
//             ),
//           )
//         ]),
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
//       gridData: FlGridData(
//         show: true,
//         drawVerticalLine: false, // Disable vertical grid lines
//       ),
//       titlesData: FlTitlesData(
//         show: true,
//         bottomTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 30,
//             getTitlesWidget: (value, meta) {
//               final int index = value.toInt();
//               if (index % 10 == 0) {
//                 return Text('${index}s', style: const TextStyle(fontSize: 10));
//               }
//               return const Text('');
//             },
//           ),
//         ),
//         leftTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 40,
//             getTitlesWidget: (value, meta) {
//               return Text('${value.toInt()} MB/s',
//                   style: const TextStyle(fontSize: 10));
//             },
//           ),
//         ),
//         rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//       ),
//       borderData: FlBorderData(show: true),
//       minX: displayedData.isNotEmpty ? displayedData.first.time.toDouble() : 0,
//       maxX: displayedData.isNotEmpty ? displayedData.last.time.toDouble() : 0,
//       minY: 0,
//       maxY: maxYValue,
//       lineBarsData: [
//         LineChartBarData(
//           spots: displayedData
//               .map((usage) => FlSpot(usage.time.toDouble(), usage.value1))
//               .toList(),
//           isCurved: true,
//           color: Colors.greenAccent,
//           barWidth: 3,
//           isStrokeCapRound: true,
//           dotData: const FlDotData(show: false),
//           belowBarData: BarAreaData(
//             show: viewType == 'area',
//             color: Colors.greenAccent.withOpacity(0.2),
//           ),
//         ),
//         LineChartBarData(
//           spots: displayedData
//               .map((usage) => FlSpot(usage.time.toDouble(), usage.value2))
//               .toList(),
//           isCurved: true,
//           color: Colors.orangeAccent,
//           barWidth: 3,
//           isStrokeCapRound: true,
//           dotData: const FlDotData(show: false),
//           belowBarData: BarAreaData(
//             show: viewType == 'area',
//             color: Colors.orangeAccent.withOpacity(0.2),
//           ),
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
//     final maxIn = data.isEmpty ? 0 : data.map((e) => e.value1).reduce(math.max);
//     final maxOut =
//         data.isEmpty ? 0 : data.map((e) => e.value2).reduce(math.max);

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
//       sectionsSpace: 2,
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
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'dart:async';

class NetworkAnalyticsScreen extends StatefulWidget {
  const NetworkAnalyticsScreen({super.key});

  @override
  _NetworkAnalyticsScreenState createState() => _NetworkAnalyticsScreenState();
}

class _NetworkAnalyticsScreenState extends State<NetworkAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  // Data collections
  final int maxDataPoints = 100; // Limit the number of data points
  List<SystemMetric> networkData = [];
  List<SystemMetric> cpuData = [];
  List<MemoryUsage> memoryData = [];

  // States
  int timeCounter = 0;
  String selectedNetworkView = 'line';
  bool isLoading = true;
  bool isPolling = true;
  Timer? _pollingTimer;
  late TabController _tabController;

  // Filter
  String timeRange = '1h';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    // Initial data fetch to populate charts
    await _fetchSystemData();

    setState(() {
      isLoading = false;
    });

    // Setup more memory-efficient polling
    _startPolling();
  }

  void _startPolling() {
    // Using periodic timer instead of infinite loop for better memory management
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (isPolling) {
        _fetchSystemData();
      }
    });
  }

  void _togglePolling() {
    setState(() {
      isPolling = !isPolling;
    });
  }

  Future<void> _fetchSystemData() async {
    const String apiUrl = 'http://localhost:8080/status';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        setState(() {
          // Network data
          final double networkIn = data['networkIn'].toDouble();
          final double networkOut = data['networkOut'].toDouble();
          _addDataPoint(
              networkData, SystemMetric(timeCounter, networkIn, networkOut));

          // CPU data
          final double cpuUsage = data['cpuUsage'].toDouble();
          final double idleUsage = 100 - cpuUsage;
          _addDataPoint(
              cpuData, SystemMetric(timeCounter, cpuUsage, idleUsage));

          // Memory data
          final double usedMem = data['memoryUsed'].toDouble();
          final double availableMem = data['memoryAvailable'].toDouble();
          final double cachedMem = data['memoryCached']?.toDouble() ?? 0.0;
          final double bufferMem = data['memoryBuffer']?.toDouble() ?? 0.0;
          _addDataPoint(
              memoryData,
              MemoryUsage(
                  timeCounter, usedMem, availableMem, cachedMem, bufferMem));

          timeCounter++;
        });
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }
  }

  void _addDataPoint<T>(List<T> dataList, T newData) {
    if (dataList.length >= maxDataPoints) {
      dataList.removeAt(0);
    }
    dataList.add(newData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NIDS Network Monitor'),
        actions: [
          IconButton(
            icon: Icon(isPolling ? Icons.pause : Icons.play_arrow),
            onPressed: _togglePolling,
            tooltip: isPolling ? 'Pause Updates' : 'Resume Updates',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              setState(() {
                timeRange = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '1h', child: Text('1 Hour')),
              const PopupMenuItem(value: '3h', child: Text('3 Hours')),
              const PopupMenuItem(value: '12h', child: Text('12 Hours')),
              const PopupMenuItem(value: '24h', child: Text('24 Hours')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Network Details'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildNetworkDetailsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _fetchSystemData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCards(),
              const SizedBox(height: 24),
              _buildNetworkOverviewCard(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildMemoryPieChartCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildCPUUsageCard()),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkDetailsTab() {
    return ListView(
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
    );
  }

  Widget _buildSummaryCards() {
    final latestNetworkData = networkData.isNotEmpty ? networkData.last : null;
    final latestMemoryData = memoryData.isNotEmpty ? memoryData.last : null;
    final latestCpuData = cpuData.isNotEmpty ? cpuData.last : null;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard('Network In', latestNetworkData?.value1 ?? 0,
            Icons.arrow_downward, Colors.green, 'MB/s'),
        _buildStatCard('Network Out', latestNetworkData?.value2 ?? 0,
            Icons.arrow_upward, Colors.orange, 'MB/s'),
        _buildStatCard('CPU Usage', latestCpuData?.value1 ?? 0, Icons.memory,
            Colors.blue, '%'),
        _buildStatCard('Memory Used', latestMemoryData?.usedMemory ?? 0,
            Icons.storage, Colors.purple, 'MB'),
      ],
    );
  }

  Widget _buildStatCard(
      String title, double value, IconData icon, Color color, String unit) {
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
            Text('${value.toStringAsFixed(2)} $unit',
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
      selected: {selectedNetworkView},
      onSelectionChanged: (Set<String> newSelection) {
        setState(() {
          selectedNetworkView = newSelection.first;
        });
      },
    );
  }

  Widget _buildNetworkOverviewCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Network Traffic Overview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: networkData.isEmpty
                  ? const Center(child: Text('No network data available'))
                  : LineChart(_buildNetworkOverviewChart()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryPieChartCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Memory Usage',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: memoryData.isEmpty
                  ? const Center(child: Text('No memory data available'))
                  : PieChart(_buildMemoryPieChart()),
            ),
            const SizedBox(height: 16),
            _buildMemoryLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildCPUUsageCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CPU Utilization',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: cpuData.isEmpty
                  ? const Center(child: Text('No CPU data available'))
                  : BarChart(_buildCpuBarChart()),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildNetworkOverviewChart() {
    return LineChartData(
      gridData: FlGridData(show: false), // Disable grid lines
      titlesData: FlTitlesData(show: false), // Disable titles
      borderData: FlBorderData(show: false), // Disable border
      minX: networkData.first.time.toDouble(),
      maxX: networkData.last.time.toDouble(),
      lineBarsData: [
        LineChartBarData(
          spots: networkData
              .map((data) => FlSpot(data.time.toDouble(), data.value1))
              .toList(),
          isCurved: false, // Disable curve
          color: Colors.greenAccent,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false), // Disable area chart
        ),
        LineChartBarData(
          spots: networkData
              .map((data) => FlSpot(data.time.toDouble(), data.value2))
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

  PieChartData _buildMemoryPieChart() {
    final latestMemory = memoryData.last;
    final double used = latestMemory.usedMemory;
    final double available = latestMemory.availableMemory;

    return PieChartData(
      sectionsSpace: 0, // No space between sections
      centerSpaceRadius: 40,
      sections: [
        PieChartSectionData(
          color: Colors.redAccent,
          value: used,
          title: '${(used / (used + available) * 100).toStringAsFixed(1)}%',
          radius: 80,
          titleStyle:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        PieChartSectionData(
          color: Colors.green,
          value: available,
          title:
              '${(available / (used + available) * 100).toStringAsFixed(1)}%',
          radius: 80,
          titleStyle:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMemoryLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem('Used', Colors.redAccent),
        _buildLegendItem('Free', Colors.green),
      ],
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

  BarChartData _buildCpuBarChart() {
    // Get the last 10 CPU data points or fewer if we have less
    final dataPoints =
        cpuData.length > 10 ? cpuData.sublist(cpuData.length - 10) : cpuData;

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: 100,
      barTouchData: BarTouchData(enabled: false),
      titlesData: FlTitlesData(show: false), // Disable titles
      borderData: FlBorderData(show: false), // Disable border
      gridData: FlGridData(show: false), // Disable grid lines
      barGroups: dataPoints.asMap().entries.map((entry) {
        final int index = entry.key;
        final data = entry.value;
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: data.value1,
              color: Colors.blue,
              width: 15,
            ),
          ],
        );
      }).toList(),
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
    final maxIn = data.isEmpty ? 0 : data.map((e) => e.value1).reduce(math.max);
    final maxOut =
        data.isEmpty ? 0 : data.map((e) => e.value2).reduce(math.max);

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
