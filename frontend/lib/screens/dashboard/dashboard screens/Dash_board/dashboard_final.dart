import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:nidswebapp/go_api/urls.dart';

// Define data classes
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

class NetworkOverviewScreen extends StatefulWidget {
  const NetworkOverviewScreen({super.key});

  @override
  _NetworkOverviewScreenState createState() => _NetworkOverviewScreenState();
}

class _NetworkOverviewScreenState extends State<NetworkOverviewScreen> {
  // Data collections - using efficient circular buffers
  final int maxDataPoints = 60; // Limit data points for better performance
  final List<SystemMetric> networkData = [];
  final List<SystemMetric> cpuData = [];
  final List<MemoryUsage> memoryData = [];

  // States
  int timeCounter = 0;
  bool isLoading = true;
  Timer? _pollingTimer;

  // Efficient polling interval
  final Duration pollingInterval = const Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _fetchSystemData();
    setState(() {
      isLoading = false;
    });
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(pollingInterval, (timer) {
      _fetchSystemData();
    });
  }

  Future<void> _fetchSystemData() async {
    try {
      final response = await http.get(Uri.parse(statusURL));
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
                timeCounter, usedMem, availableMem, cachedMem, bufferMem),
          );

          timeCounter++;
        });
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
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchSystemData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCompactSummaryRow(),
                      const SizedBox(height: 16),
                      _buildNetworkOverviewCard(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildMemoryCard()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildCPUCard()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCompactSummaryRow() {
    final latestNetworkData = networkData.isNotEmpty ? networkData.last : null;
    final latestCpuData = cpuData.isNotEmpty ? cpuData.last : null;
    final latestMemoryData = memoryData.isNotEmpty ? memoryData.last : null;

    return Row(
      children: [
        Expanded(
          child: _buildCompactStatCard(
            'Network In',
            latestNetworkData?.value1 ?? 0,
            Icons.arrow_downward,
            Colors.green,
            'MB/s',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactStatCard(
            'Network Out',
            latestNetworkData?.value2 ?? 0,
            Icons.arrow_upward,
            Colors.orange,
            'MB/s',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactStatCard(
            'CPU',
            latestCpuData?.value1 ?? 0,
            Icons.memory,
            Colors.blue,
            '%',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactStatCard(
            'Memory',
            latestMemoryData?.usedMemory ?? 0,
            Icons.storage,
            Colors.purple,
            'MB',
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStatCard(
      String title, double value, IconData icon, Color color, String unit) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Text(title, style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${value.toStringAsFixed(1)} $unit',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkOverviewCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Network Traffic',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: networkData.isEmpty
                  ? const Center(child: Text('No network data available'))
                  : LineChart(_buildNetworkChart()),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildNetworkChart() {
    // Find max Y value for better scaling
    double maxY = 0;
    double minY = 0;
    for (var data in networkData) {
      maxY = maxY < data.value1 ? data.value1 : maxY; // Incoming traffic
      minY = minY > -data.value2
          ? -data.value2
          : minY; // Outgoing traffic (negative)
    }
    maxY = maxY * 1.1; // Add 10% padding
    minY = minY * 1.1; // Add 10% padding

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (maxY - minY) / 5, // Divide Y-axis into 5 intervals
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.3),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: networkData.length > 10 ? networkData.length / 5 : 1,
            getTitlesWidget: (value, meta) {
              if (value % 5 != 0) return const SizedBox.shrink();
              final int idx = value.toInt();
              if (idx < 0 || idx >= networkData.length)
                return const SizedBox.shrink();
              return Text('${networkData[idx].time}s');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: (maxY - minY) / 5,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt().abs()}',
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: networkData.first.time.toDouble(),
      maxX: networkData.last.time.toDouble(),
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        // Incoming traffic (above X-axis)
        LineChartBarData(
          spots: networkData
              .map((data) => FlSpot(data.time.toDouble(), data.value1))
              .toList(),
          isCurved: false,
          color: Colors.green,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
        ),
        // Outgoing traffic (below X-axis)
        LineChartBarData(
          spots: networkData
              .map((data) => FlSpot(data.time.toDouble(), -data.value2))
              .toList(),
          isCurved: false,
          color: Colors.orange,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((spot) {
              final color = spot.barIndex == 0 ? Colors.green : Colors.orange;
              final name = spot.barIndex == 0 ? 'In: ' : 'Out: ';
              return LineTooltipItem(
                '$name${spot.y.toStringAsFixed(1)} MB/s',
                TextStyle(color: color, fontWeight: FontWeight.bold),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildMemoryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Memory Usage',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: memoryData.isEmpty
                  ? const Center(child: Text('No memory data available'))
                  : _buildMemoryChart(),
            ),
            if (memoryData.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _buildMemoryLegend(),
              ),
          ],
        ),
      ),
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

  Widget _buildMemoryChart() {
    final latestMemory = memoryData.last;
    final double used = latestMemory.usedMemory;
    final double available = latestMemory.availableMemory;
    final total = used + available;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 30,
              sections: [
                PieChartSectionData(
                  color: Colors.redAccent,
                  value: used,
                  title: '${(used / total * 100).toStringAsFixed(1)}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.green,
                  value: available,
                  title: '${(available / total * 100).toStringAsFixed(1)}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMemoryStatText('Used', used, Colors.redAccent),
              const SizedBox(height: 8),
              _buildMemoryStatText('Free', available, Colors.green),
              const SizedBox(height: 8),
              _buildMemoryStatText('Total', total, Colors.blue),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemoryStatText(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold), // Increased font size
            ),
          ],
        ),
        Text(
          '${(value).toStringAsFixed(0)} MB',
          style: TextStyle(
              fontSize: 12,
              color: Colors.grey.withOpacity(0.8)), // Increased font size
        ),
      ],
    );
  }

  Widget _buildCPUCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CPU Utilization',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: cpuData.isEmpty
                  ? const Center(child: Text('No CPU data available'))
                  : _buildCPUChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCPUChart() {
    // Get the last 10 CPU data points or fewer if we have less
    final dataPoints =
        cpuData.length > 10 ? cpuData.sublist(cpuData.length - 10) : cpuData;

    // Find the maximum CPU usage for scaling the Y-axis
    double maxY = 100; // CPU usage is always between 0% and 100%
    if (dataPoints.isNotEmpty) {
      maxY =
          dataPoints.map((data) => data.value1).reduce((a, b) => a > b ? a : b);
      maxY = maxY * 1.1; // Add 10% padding
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5, // Divide Y-axis into 5 intervals
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: dataPoints.length > 5 ? dataPoints.length / 5 : 1,
              getTitlesWidget: (value, meta) {
                if (value % 5 != 0) return const SizedBox.shrink();
                final int idx = value.toInt();
                if (idx < 0 || idx >= dataPoints.length)
                  return const SizedBox.shrink();
                return Text('${dataPoints[idx].time}s');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: maxY / 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: dataPoints.first.time.toDouble(),
        maxX: dataPoints.last.time.toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: dataPoints
                .map((data) => FlSpot(data.time.toDouble(), data.value1))
                .toList(),
            isCurved: false,
            color: Colors.blue,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  'CPU: ${spot.y.toStringAsFixed(1)}%',
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
