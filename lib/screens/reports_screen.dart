import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../services/reports_service.dart';
import '../models/common_models.dart';
import 'report_detail_screen.dart';
import '../services/inventory_service.dart';
import '../core/responsive/responsive_helper.dart';
import '../core/responsive/responsive_text.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _service = ReportsService();
  final _inv = InventoryService();
  String _range = 'week';
  late Future<List<ReportSummary>> _future;
  final _searchCtrl = TextEditingController();
  final Set<String> _programs = {
    // default: show all
    'Patients',
    'Appointments',
    'Admissions',
    'Discharges',
    'Approvals',
    'Immunizations',
    'Notifications',
    'Messages',
    'Audit',
    'Backups',
    'Outbreak',
    'Follow-ups',
    'Visits',
  };

  @override
  void initState() {
    super.initState();
    _future = _service.fetchReports(range: _range);
  }

  Future<void> _showCsvDialog(String title, String csv) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 700,
          child: SingleChildScrollView(
            child: Text(csv, style: const TextStyle(fontFamily: 'monospace')),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          FilledButton.icon(
            onPressed: () async {
              final name =
                  '${title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.csv';
              await _saveFile(Uint8List.fromList(utf8.encode(csv)), name);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.save_alt),
            label: const Text('Save CSV'),
          ),
        ],
      ),
    );
  }

  void _refresh() {
    setState(() {
      _future = _service.fetchReports(range: _range);
    });
  }

  Future<void> _generate() async {
    await _service.generateReport(range: _range);
    _refresh();
  }

  Future<void> _saveFile(Uint8List bytes, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$filename';
    final f = File(path);
    await f.writeAsBytes(bytes, flush: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved to: $path')),
    );
  }

  void _exportReport(ReportSummary r) async {
    // Create a view of metrics filtered by selected programs
    final filtered = Map<String, num>.fromEntries(
      r.metrics.entries.where((e) => _includeMetric(e.key)),
    );
    final view = ReportSummary(
      id: r.id,
      title: r.title,
      createdAt: r.createdAt,
      metrics: filtered,
    );
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Export as PDF'),
              onTap: () async {
                Navigator.pop(ctx);
                final bytes = await _service.exportReportPdf(view);
                final name =
                    '${r.title.replaceAll(' ', '_')}_${r.createdAt.millisecondsSinceEpoch}.pdf';
                await _saveFile(bytes, name);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.blue),
              title: const Text('Export as CSV'),
              onTap: () async {
                Navigator.pop(ctx);
                final bytes = await _service.exportReportCsv(view);
                final name =
                    '${r.title.replaceAll(' ', '_')}_${r.createdAt.millisecondsSinceEpoch}.csv';
                await _saveFile(bytes, name);
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _includeMetric(String key) {
    final k = key.toLowerCase();
    if (k.contains('patient')) return _programs.contains('Patients');
    if (k.contains('appointment')) return _programs.contains('Appointments');
    if (k.contains('admission')) return _programs.contains('Admissions');
    if (k.contains('discharge')) return _programs.contains('Discharges');
    if (k.contains('approval')) return _programs.contains('Approvals');
    if (k.contains('immun')) return _programs.contains('Immunizations');
    if (k.contains('notification')) return _programs.contains('Notifications');
    if (k.contains('message') || k.contains('unread'))
      return _programs.contains('Messages');
    if (k.contains('audit')) return _programs.contains('Audit');
    if (k.contains('backup')) return _programs.contains('Backups');
    if (k.contains('outbreak')) return _programs.contains('Outbreak');
    if (k.contains('follow')) return _programs.contains('Follow-ups');
    if (k.contains('visit')) return _programs.contains('Visits');
    return true; // fallback include
  }

  @override
  Widget build(BuildContext context) {
    final responsivePadding = ResponsiveHelper.getResponsivePadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const ResponsiveHeading2('Reports'),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _range,
              items: const [
                DropdownMenuItem(value: 'day', child: Text('Day')),
                DropdownMenuItem(value: 'week', child: Text('Week')),
                DropdownMenuItem(value: 'month', child: Text('Month')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _range = v);
                _refresh();
              },
            ),
          ),
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generate,
        icon: const Icon(Icons.playlist_add),
        label: const Text('Generate'),
      ),
      body: FutureBuilder<List<ReportSummary>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(child: Text('Failed to load reports'));
          }
          final items = snap.data ?? const <ReportSummary>[];
          if (items.isEmpty) {
            return const Center(child: Text('No reports'));
          }
          // KPIs
          final now = DateTime.now();
          final total = items.length;
          final thisMonth = items
              .where((r) =>
                  r.createdAt.year == now.year &&
                  r.createdAt.month == now.month)
              .length;
          final last7 = items
              .where((r) => now.difference(r.createdAt).inDays <= 7)
              .length;

          // Search filter
          final query = _searchCtrl.text.trim().toLowerCase();
          final filtered = query.isEmpty
              ? items
              : items
                  .where((r) => r.title.toLowerCase().contains(query))
                  .toList();

          return SingleChildScrollView(
            padding: responsivePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Medicine Inventory Reports',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ListTile(
                          leading: const Icon(Icons.list_alt_outlined,
                              color: Colors.blue),
                          title: const Text('Medicine inventory summary'),
                          subtitle:
                              const Text('Totals and next expiry per medicine'),
                          onTap: () async {
                            final csv = await _inv.inventorySummaryCsv();
                            await _showCsvDialog(
                                'Medicine Inventory Summary', csv);
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                              Icons.report_gmailerrorred_outlined,
                              color: Colors.blue),
                          title: const Text('Expired medicine report'),
                          onTap: () async {
                            final csv = await _inv.expiredBatchesCsv();
                            await _showCsvDialog('Expired Medicines', csv);
                          },
                        ),
                        ListTile(
                          leading:
                              const Icon(Icons.bar_chart, color: Colors.blue),
                          title: const Text('Monthly consumption report'),
                          onTap: () async {
                            final csv =
                                await _inv.monthlyConsumptionCsv(days: 30);
                            await _showCsvDialog(
                                'Monthly Consumption (30d)', csv);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.inventory_outlined,
                              color: Colors.blue),
                          title: const Text('Restock report'),
                          onTap: () async {
                            final csv = await _inv.restockCsv(days: 30);
                            await _showCsvDialog('Restock (30d)', csv);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 240,
                        child: _kpi(context, 'Total Reports', '$total',
                            Icons.bar_chart, Colors.blue, onTap: () {
                          _searchCtrl.clear();
                          setState(() {});
                        }),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 240,
                        child: _kpi(context, 'This Month', '$thisMonth',
                            Icons.calendar_month, Colors.green, onTap: () {
                          setState(() => _range = 'month');
                          _refresh();
                        }),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 240,
                        child: _kpi(context, 'Last 7 Days', '$last7',
                            Icons.timer, Colors.orange, onTap: () {
                          setState(() => _range = 'week');
                          _refresh();
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Search bar
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search reports by title...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                // Program filters
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in const [
                      'Patients',
                      'Appointments',
                      'Admissions',
                      'Discharges',
                      'Approvals',
                      'Immunizations',
                      'Notifications',
                      'Messages',
                      'Audit',
                      'Backups',
                      'Outbreak',
                      'Follow-ups',
                      'Visits',
                    ])
                      FilterChip(
                        label: Text(p),
                        selected: _programs.contains(p),
                        onSelected: (sel) {
                          setState(() {
                            if (sel) {
                              _programs.add(p);
                            } else {
                              _programs.remove(p);
                            }
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Cards grid/list
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final r = filtered[i];
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.insert_chart_outlined,
                                color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('Created: ${r.createdAt}',
                                      style: const TextStyle(
                                          color: Colors.black54, fontSize: 12)),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: r.metrics.entries
                                        .where((e) => _includeMetric(e.key))
                                        .take(8)
                                        .map((e) => _metricChip(e.key, e.value))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              ReportDetailScreen(report: r)),
                                    );
                                  },
                                  icon: const Icon(Icons.visibility),
                                  label: const Text('View'),
                                  style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(100, 36)),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    IconButton(
                                      tooltip: 'Export',
                                      icon: const Icon(Icons.file_download),
                                      onPressed: () => _exportReport(r),
                                    ),
                                    IconButton(
                                      tooltip: 'Share',
                                      icon: const Icon(Icons.share),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text('Shared')),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Widget _kpi(BuildContext context, String label, String value, IconData icon,
    Color color,
    {VoidCallback? onTap}) {
  final card = Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Icon(icon, color: color),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
                fontSize: 12)),
      ]),
    ]),
  );
  return Expanded(
      child: onTap == null ? card : InkWell(onTap: onTap, child: card));
}

Widget _metricChip(String label, num? value) {
  return Chip(
    label: Text('$label: ${value ?? 0}'),
    backgroundColor: Colors.blue.withValues(alpha: 0.08),
    side: BorderSide.none,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    padding: const EdgeInsets.symmetric(horizontal: 6),
  );
}
