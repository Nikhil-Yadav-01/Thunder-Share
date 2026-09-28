import 'package:flutter/material.dart';

class PermissionCard extends StatelessWidget {
  final String title;
  final String status;
  final VoidCallback onRequest;

  const PermissionCard({
    super.key,
    required this.title,
    required this.status,
    required this.onRequest,
  });

  Color get statusColor {
    if (status == 'granted') {
      return Colors.green;
    }

    if (status == 'permanentlyDenied') {
      return Colors.orange;
    }

    if (status == 'denied') {
      return Colors.red;
    }

    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),

            const SizedBox(height: 8),

            Text(
              'Status: $status',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRequest,
                child: Text('Request $title'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
