// ignore_for_file: use_build_context_synchronously, duplicate_ignore

import 'package:flutter/material.dart';
import '../services/consultation_service.dart';

class ConsultationScreen extends StatelessWidget {
  const ConsultationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final queueSectionKey = GlobalKey();
    final svc = ConsultationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultation Records'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Queue refreshed')),
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/patients'),
        icon: const Icon(Icons.person_search),
        label: const Text('New Consultation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StreamBuilder<int>(
                  stream: svc.inQueueCount(),
                  initialData: 0,
                  builder: (ctx, snap) => _Kpi(
                    label: 'In Queue',
                    value: '${snap.data ?? 0}',
                    icon: Icons.pending_outlined,
                    color: Colors.orange,
                    onTap: () {
                      final c = queueSectionKey.currentContext;
                      if (c != null) {
                        Scrollable.ensureVisible(c,
                            duration: const Duration(milliseconds: 300));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                StreamBuilder<int>(
                  stream: svc.inProgressCount(),
                  initialData: 0,
                  builder: (ctx, snap) {
                    final count = snap.data ?? 0;
                    return _Kpi(
                      label: 'In Progress',
                      value: '$count',
                      icon: Icons.play_circle_outline,
                      color: Colors.blue,
                      onTap: count > 0
                          ? () async {
                              // Use one-shot fetch from Firestore to avoid initial empty cache emissions
                              final list = await ConsultationService()
                                  .fetchInProgressOnce();
                              if (list.isNotEmpty) {
                                _showInProgress(context);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'No consultations in progress.')),
                                  );
                                }
                              }
                            }
                          : null,
                    );
                  },
                ),
                const SizedBox(width: 12),
                StreamBuilder<int>(
                  stream: svc.todayDoneCount(),
                  initialData: 0,
                  builder: (ctx, snap) => _Kpi(
                    label: 'Today Done',
                    value: '${snap.data ?? 0}',
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                    onTap: () async {
                      final data = await svc.recentStream(limit: 10).first;
                      _showTodayDone(context, data);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Today's Queue
            Container(
              key: queueSectionKey,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Today\'s Queue',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  StreamBuilder<List<Map<String, Object>>>(
                    stream: svc.queueStream(),
                    initialData: const [],
                    builder: (ctx, snap) {
                      final queue = snap.data ?? const [];
                      if (queue.isEmpty) {
                        return const Text('No patients in queue.');
                      }
                      return Column(
                        children: queue
                            .map((e) => ListTile(
                                  leading: const Icon(Icons.person_outline,
                                      color: Colors.blue),
                                  title: Text('${e['name']} (${e['id']})'),
                                  subtitle:
                                      Text('${e['reason']} • ${e['time']}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () async {
                                          await svc.startConsultation(
                                              e['docId'] as String);
                                          // Navigate to consultation form
                                          // ignore: use_build_context_synchronously
                                          Navigator.pushNamed(
                                              context, '/consultation/new',
                                              arguments: {'docId': e['docId']});
                                        },
                                        icon: const Icon(Icons.play_arrow),
                                        label: const Text('Start'),
                                      ),
                                      IconButton(
                                        tooltip: 'More',
                                        icon: const Icon(Icons.more_vert),
                                        onPressed: () {
                                          _showQueueActions(context, e);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        tooltip: 'Delete',
                                        onPressed: () async {
                                          final ok = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text(
                                                  'Delete consultation'),
                                              content: const Text(
                                                  'This will remove the consultation permanently.'),
                                              actions: [
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            ctx, false),
                                                    child:
                                                        const Text('Cancel')),
                                                ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            ctx, true),
                                                    child:
                                                        const Text('Delete')),
                                              ],
                                            ),
                                          );
                                          if (ok == true) {
                                            try {
                                              await ConsultationService()
                                                  .removeFromQueue(
                                                      e['docId'] as String);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                        const SnackBar(
                                                            content: Text(
                                                                'Deleted')));
                                              }
                                            } catch (err) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                        content: Text(
                                                            'Failed: $err')));
                                              }
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Recent consultations
            Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recent Consultations',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  StreamBuilder<List<Map<String, Object>>>(
                    stream: svc.recentStream(limit: 10),
                    initialData: const [],
                    builder: (ctx, snap) {
                      final recent = snap.data ?? const [];
                      if (recent.isEmpty) {
                        return const Text('No recent consultations.');
                      }
                      return Column(
                        children: recent
                            .map((e) => ListTile(
                                  leading: const Icon(Icons.history,
                                      color: Colors.grey),
                                  title: Text('${e['name']} (${e['id']})'),
                                  subtitle:
                                      Text('Dx: ${e['dx']} • ${e['when']}'),
                                  onTap: () {
                                    _showVisitSummary(context, e);
                                  },
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.description_outlined),
                                        tooltip: 'Open chart',
                                        onPressed: () {
                                          _showVisitSummary(context, e);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        tooltip: 'Delete',
                                        onPressed: () async {
                                          final ok = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text(
                                                  'Delete consultation'),
                                              content: const Text(
                                                  'This will remove the consultation permanently.'),
                                              actions: [
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            ctx, false),
                                                    child:
                                                        const Text('Cancel')),
                                                ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            ctx, true),
                                                    child:
                                                        const Text('Delete')),
                                              ],
                                            ),
                                          );
                                          if (ok == true) {
                                            try {
                                              await ConsultationService()
                                                  .removeFromQueue(
                                                      e['docId'] as String);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                        const SnackBar(
                                                            content: Text(
                                                                'Deleted')));
                                              }
                                            } catch (err) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                        content: Text(
                                                            'Failed: $err')));
                                              }
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      );
                    },
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

void _showQueueActions(BuildContext context, Map<String, Object> item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('Start consultation'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/consultation/new');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Open patient record'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/patients');
            },
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Reschedule'),
            onTap: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rescheduled')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
            title: const Text('Remove from queue',
                style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(ctx);
              try {
                await ConsultationService()
                    .removeFromQueue(item['docId'] as String);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Removed from queue')),
                  );
                }
              } catch (err) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $err')),
                  );
                }
              }
            },
          ),
          ],
        ),
      ),
    ),
  );
}

void _showTodayDone(BuildContext context, List<Map<String, Object>> recent) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          const Text('Today Done',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...recent.map((e) => ListTile(
                leading:
                    const Icon(Icons.check_circle_outline, color: Colors.green),
                title: Text('${e['name']} (${e['id']})'),
                subtitle: Text('Dx: ${e['dx']} • ${e['when']}'),
                trailing: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showVisitSummary(context, e);
                  },
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Chart'),
                ),
              )),
        ],
          ),
        ),
      ),
    ),
  );
}

void _showVisitSummary(BuildContext context, Map<String, Object> item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Consultation Summary',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx)),
            ],
          ),
          const SizedBox(height: 8),
          Text('${item['name']} (${item['id']})'),
          const SizedBox(height: 6),
          Text('Dx: ${item['dx'] ?? '—'}'),
          const SizedBox(height: 6),
          Text('${item['when'] ?? ''}'),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chart opened')),
                );
              },
              icon: const Icon(Icons.description_outlined),
              label: const Text('Open full chart'),
            ),
          )
        ],
          ),
        ),
      ),
    ),
  );
}

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _Kpi(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return Expanded(
        child: onTap == null ? card : InkWell(onTap: onTap, child: card));
  }
}

void _showInProgress(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          const Text('In Progress',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          FutureBuilder<List<Map<String, Object>>>(
            future: ConsultationService().fetchInProgressOnce(),
            builder: (c, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child:
                      Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              if (snap.hasError) {
                return const Text('Failed to load in-progress consultations');
              }
              final list = snap.data ?? const [];
              if (list.isEmpty) {
                return const Text('No consultations in progress.');
              }
              return Column(
                children: list
                    .map((e) => ListTile(
                          leading: const Icon(Icons.person_outline,
                              color: Colors.blue),
                          title: Text('${e['name']} (${e['id']})'),
                          subtitle: Text('${e['reason']} • ${e['started']}'),
                          trailing: TextButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.pushNamed(context, '/consultation/new',
                                  arguments: {'docId': e['docId']});
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Resume'),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
          ),
        ),
      ),
    ),
  );
}
