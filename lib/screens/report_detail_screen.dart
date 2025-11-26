import 'package:flutter/material.dart';
import '../core/responsive/responsive_helper.dart';
import '../core/responsive/responsive_text.dart';
import '../models/common_models.dart';

class ReportDetailScreen extends StatelessWidget {
  final ReportSummary report;
  const ReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        actions: const [],
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.title,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Created: ${report.createdAt}'),
                    const SizedBox(height: 16),
                    const Text('Key Metrics',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...report.metrics.entries.map((e) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.analytics),
                          title: Text(e.key),
                          trailing: Text(e.value.toString()),
                        )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
