import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/health_alerts_service.dart';

class HealthAlertsScreen extends StatefulWidget {
  const HealthAlertsScreen({super.key});

  @override
  State<HealthAlertsScreen> createState() => _HealthAlertsScreenState();
}

class _HealthAlertsScreenState extends State<HealthAlertsScreen> {
  String _typeFilter = 'All';
  bool _pinnedOnly = false;

  @override
  Widget build(BuildContext context) {
    final service = HealthAlertsService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts & Bulletin Board'),
        actions: [
          IconButton(
            tooltip: 'Create alert',
            icon: const Icon(Icons.add_alert_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/health-alerts/new');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final label in const [
                    'All',
                    'Emergency',
                    'Advisory',
                    'Reminder',
                    'Health Tip',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: _typeFilter == label,
                        onSelected: (_) {
                          setState(() => _typeFilter = label);
                        },
                      ),
                    ),
                  const SizedBox(width: 12),
                  FilterChip(
                    label: const Text('Pinned only'),
                    selected: _pinnedOnly,
                    onSelected: (v) => setState(() => _pinnedOnly = v),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: service.streamAllAlertsForBoard(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                var docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No alerts yet'));
                }

                final now = DateTime.now();
                DateTime? toDate(dynamic ts) {
                  if (ts is Timestamp) return ts.toDate();
                  return DateTime.tryParse('${ts ?? ''}');
                }

                // Apply category and pinned filters before bucketing
                String? typeCodeForFilter(String label) {
                  switch (label) {
                    case 'Emergency':
                      return 'EMERGENCY';
                    case 'Advisory':
                      return 'ADVISORY';
                    case 'Reminder':
                      return 'REMINDER';
                    case 'Health Tip':
                      return 'HEALTH_TIP';
                  }
                  return null; // All
                }

                final typeCode = typeCodeForFilter(_typeFilter);
                docs = docs.where((d) {
                  final data = d.data();
                  final type = (data['type'] ?? '').toString();
                  final pinned = (data['pinned'] as bool?) ?? false;
                  if (typeCode != null && type != typeCode) return false;
                  if (_pinnedOnly && !pinned) return false;
                  return true;
                }).toList();

                final ongoing = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                final upcoming =
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                final past = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                for (final d in docs) {
                  final data = d.data();
                  final start = toDate(data['startAt']);
                  final expiry = toDate(data['expiresAt']);
                  final status = (data['status'] ?? 'ACTIVE').toString();
                  if (start == null) {
                    past.add(d);
                    continue;
                  }
                  final isActiveWindow = !now.isBefore(start) &&
                      (expiry == null || !now.isAfter(expiry));
                  if (status == 'ACTIVE' && isActiveWindow) {
                    ongoing.add(d);
                  } else if (start.isAfter(now)) {
                    upcoming.add(d);
                  } else {
                    past.add(d);
                  }
                }

                Widget section(String title,
                    List<QueryDocumentSnapshot<Map<String, dynamic>>> items) {
                  if (items.isEmpty) return const SizedBox.shrink();
                  final ordered = [
                    ...items.where((d) {
                      final data = d.data();
                      return (data['pinned'] as bool?) ?? false;
                    }),
                    ...items.where((d) {
                      final data = d.data();
                      return !((data['pinned'] as bool?) ?? false);
                    }),
                  ];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: ordered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final doc = ordered[index];
                          final data = doc.data();
                          final id = doc.id;
                          final title =
                              (data['title'] ?? 'Health Alert').toString();
                          final message = (data['message'] ?? '').toString();
                          final type = (data['type'] ?? '').toString();
                          final priority = (data['priority'] ?? '').toString();
                          final startAt = toDate(data['startAt']);
                          final expiresAt = toDate(data['expiresAt']);
                          final createdByRole =
                              (data['createdByRole'] ?? 'admin').toString();

                          Color badgeColor;
                          Color badgeBg;
                          switch (priority) {
                            case 'HIGH':
                              badgeColor = Colors.redAccent;
                              badgeBg =
                                  Colors.redAccent.withValues(alpha: 0.12);
                              break;
                            case 'MEDIUM':
                              badgeColor = Colors.orange;
                              badgeBg =
                                  Colors.orangeAccent.withValues(alpha: 0.12);
                              break;
                            default:
                              badgeColor = Colors.green;
                              badgeBg = Colors.green.withValues(alpha: 0.12);
                          }

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                await service.markAlertRead(id);
                                if (!context.mounted) return;
                                showDialog(
                                  context: context,
                                  builder: (dialogCtx) => AlertDialog(
                                    title: Text(title),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (startAt != null)
                                            Text(
                                              'Posted: ${startAt.toString().split('.').first}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                      color: Colors.black54),
                                            ),
                                          if (expiresAt != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Expires: ${expiresAt.toString().split('.').first}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                      color: Colors.black54),
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          Text(message),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogCtx),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: badgeBg,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            priority.isEmpty ? 'LOW' : priority,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: badgeColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (type.isNotEmpty)
                                          Chip(
                                            label: Text(type),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Posted by: $createdByRole',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      message,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (startAt != null ||
                                        expiresAt != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          if (startAt != null)
                                            Text(
                                              'Posted: ${startAt.toLocal().toString().split('.').first}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.black45,
                                              ),
                                            ),
                                          if (expiresAt != null) ...[
                                            const SizedBox(width: 12),
                                            Text(
                                              'Expires: ${expiresAt.toLocal().toString().split('.').first}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.black45,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      section('Ongoing Alerts', ongoing),
                      section('Upcoming Announcements', upcoming),
                      section('Past / Expired Alerts', past),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
