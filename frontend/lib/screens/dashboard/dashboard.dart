// import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:nidswebapp/db/degub_screen.dart';

import 'package:nidswebapp/go_api/terminal.dart';
import 'package:nidswebapp/go_api/web_socket.dart';
import 'package:nidswebapp/screens/dashboard/dashboard%20screens/Dash_board/analytics.dart';
import 'package:nidswebapp/screens/dashboard/dashboard%20screens/Dash_board/dashboard_final.dart';
import 'package:nidswebapp/screens/rules_view.dart';

import 'package:nidswebapp/wireshark/dash_wire.dart';

class NIDSDashboard extends StatefulWidget {
  const NIDSDashboard({super.key});

  @override
  State<NIDSDashboard> createState() => _NIDSDashboardState();
}

class _NIDSDashboardState extends State<NIDSDashboard> {
  int _selectedIndex = 0;
  late WebSocketService webSocketService;

  @override
  void initState() {
    super.initState();
    // Initialize WebSocketService in initState
    webSocketService = WebSocketService('ws://localhost:8080/ws');
  }

  @override
  void dispose() {
    // Dispose of WebSocketService to avoid memory leaks
    // webSocketService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white54,
      body: Row(
        children: [
          // Navigation Rail
          NavigationRail(
            backgroundColor: const Color.fromRGBO(33, 150, 243, 1),
            indicatorColor: Colors.white,
            useIndicator: true,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.wifi_tethering),
                label: Text('Packets'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics),
                label: Text('Analytics'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.warning),
                label: Text('Alerts'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.rule),
                label: Text('Rules'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.terminal),
                label: Text('CLI'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.sd_storage_outlined),
                label: Text('Database'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main Content
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                // DashboardView(),
                NetworkOverviewScreen(),
                WiresharkUI(),

                NetworkDetailsScreen(),

                AlertsView(),
                NIDSRuleEditor(),

                TerminalScreen(webSocketService: webSocketService),
                DebugScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// // Dashboard View
// class DashboardView extends StatelessWidget {
//   DashboardView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'NIDS Dashboard',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 24),
//           Expanded(
//             child: GridView.count(
//               crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
//               childAspectRatio: 1.5,
//               mainAxisSpacing: 16,
//               crossAxisSpacing: 16,
//               children: [
//                 SystemStatusCard(),

//                 AlertSummaryCard(),
//                 RuleStatusCard(),
//                 // NIDSDashboard(),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// Placeholder views for other sections
class AlertsView extends StatelessWidget {
  const AlertsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Alerts View'));
  }
}

//
