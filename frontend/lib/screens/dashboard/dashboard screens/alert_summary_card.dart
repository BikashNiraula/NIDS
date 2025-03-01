// Alert Summary Card
import 'package:flutter/material.dart';

class AlertSummaryCard extends StatelessWidget {
  const AlertSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Alerts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: const [
                  AlertItem(
                    severity: 'High',
                    message: 'Potential SQL Injection Attempt',
                    time: '2 min ago',
                    color: Colors.red,
                  ),
                  AlertItem(
                    severity: 'Medium',
                    message: 'Unusual Port Scan Detected',
                    time: '5 min ago',
                    color: Colors.orange,
                  ),
                  AlertItem(
                    severity: 'Low',
                    message: 'Failed Login Attempt',
                    time: '10 min ago',
                    color: Colors.yellow,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Alert Item Widget
class AlertItem extends StatelessWidget {
  final String severity;
  final String message;
  final String time;
  final Color color;

  const AlertItem({
    super.key,
    required this.severity,
    required this.message,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$severity • $time',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
