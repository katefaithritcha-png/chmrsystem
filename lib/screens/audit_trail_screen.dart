// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/audit_service.dart';
import '../models/common_models.dart';

class AuditTrailScreen extends StatefulWidget {
  const AuditTrailScreen({super.key});

  @override
  State<AuditTrailScreen> createState() => _AuditTrailScreenState();
}

class _AuditTrailScreenState extends State<AuditTrailScreen> {
  final _service = AuditService();
  String _level = 'all';
  final _actorCtrl = TextEditingController();
  final _actionCtrl = TextEditingController();
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
  }

  void _refresh() {
    setState(() {});
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
      initialDate: (isStart ? _start : _end) ?? now,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = DateTime(picked.year, picked.month, picked.day);
        } else {
          _end = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
    }
  }

  Future<void> _exportCsv(List<AuditEvent> items) async {
    final buf = StringBuffer();
    buf.writeln('Time,Level,Actor,Action');
    for (final e in items) {
      buf.writeln(
          '${e.time.toIso8601String()},${e.level},"${e.actor.replaceAll('"', '""')}","${e.action.replaceAll('"', '""')}"');
    }
    final dir = await getApplicationDocumentsDirectory();
    final name = 'audit_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(buf.toString().codeUnits, flush: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Exported: ${file.path}')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Trail'),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _level,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All')),
                DropdownMenuItem(value: 'info', child: Text('Info')),
                DropdownMenuItem(value: 'warning', child: Text('Warning')),
                DropdownMenuItem(value: 'error', child: Text('Error')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _level = v);
                _refresh();
              },
            ),
          ),
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _actorCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_search),
                        hintText: 'Filter by actorId',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _refresh(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _actionCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.filter_list),
                        hintText: 'Filter by action',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _refresh(),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(_start == null
                        ? 'Start date'
                        : _start!.toIso8601String().substring(0, 10)),
                    onPressed: () => _pickDate(isStart: true),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(_end == null
                        ? 'End date'
                        : _end!.toIso8601String().substring(0, 10)),
                    onPressed: () => _pickDate(isStart: false),
                  ),
                ]),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AuditEvent>>(
              stream: _service.streamLogs(
                level: _level,
                actorId: _actorCtrl.text.trim().isEmpty
                    ? null
                    : _actorCtrl.text.trim(),
                action: _actionCtrl.text.trim().isEmpty
                    ? null
                    : _actionCtrl.text.trim(),
                start: _start,
                end: _end,
              ),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(child: Text('Failed to load audit logs'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snap.data ?? const <AuditEvent>[];
                if (items.isEmpty) {
                  return const Center(child: Text('No audit events'));
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Row(
                        children: [
                          const Spacer(),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Clear audit logs'),
                                  content: const Text(
                                      'This will permanently delete the visible audit logs based on current filters. Continue?'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel')),
                                    ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Delete All')),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                try {
                                  final deleted = await _service.clearLogs(
                                    level: _level,
                                    actorId: _actorCtrl.text.trim().isEmpty
                                        ? null
                                        : _actorCtrl.text.trim(),
                                    action: _actionCtrl.text.trim().isEmpty
                                        ? null
                                        : _actionCtrl.text.trim(),
                                    start: _start,
                                    end: _end,
                                  );
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Deleted $deleted audit log(s)')),
                                  );
                                  _refresh();
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Failed to delete: $e')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.delete_forever,
                                color: Colors.red),
                            label: const Text('Clear All',
                                style: TextStyle(color: Colors.red)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _exportCsv(items),
                            icon: const Icon(Icons.download),
                            label: const Text('Export CSV'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final e = items[i];
                          final color = e.level == 'error'
                              ? Colors.red
                              : e.level == 'warning'
                                  ? Colors.orange
                                  : Colors.blueGrey;
                          return ListTile(
                            leading: Icon(Icons.event_note, color: color),
                            title: Text(e.action),
                            subtitle: Text('${e.actor} • ${e.time}'),
                            trailing: Text(e.level.toUpperCase(),
                                style: TextStyle(color: color)),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
