import 'package:flutter/material.dart';
import '../core/responsive/responsive_helper.dart';
import '../core/responsive/responsive_text.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/notifications_service.dart';
import '../models/common_models.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationsService();
  final _searchCtrl = TextEditingController();
  bool _unreadOnly = false;
  bool _todayOnly = false;
  bool _archivedOnly = false;

  // Cache + flags
  List<AppNotification> _items = const [];
  bool _loaded = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final role = context.read<AuthProvider?>()?.role ?? 'patient';
      final data = await _service
          .fetchNotifications(role: role)
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _items = data;
        _loaded = true;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _loaded = true; // avoid infinite spinner
        _error = e.toString();
      });
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loaded = true; // guarantee spinner stops
      });
    }
  }

  void _refresh() {
    // Keep showing cached list while refreshing in background
    _load();
  }

  Future<void> _markAllRead() async {
    final role = context.read<AuthProvider?>()?.role ?? 'patient';
    await _service.markAllRead(role: role);
    _refresh();
  }

  Future<void> _clearAll() async {
    final role = context.read<AuthProvider?>()?.role ?? 'patient';
    await _service.clearAll(role: role);
    _refresh();
  }

  Future<void> _archiveUnread() async {
    final role = context.read<AuthProvider?>()?.role ?? 'patient';
    await _service.archiveAllUnread(role: role);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.read<AuthProvider?>()?.role ?? 'patient';
    final isPatient = role == 'patient';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (!isPatient)
            IconButton(
                onPressed: _markAllRead,
                tooltip: 'Mark all read',
                icon: const Icon(Icons.done_all)),
          if (!isPatient)
            IconButton(
                onPressed: _archiveUnread,
                tooltip: 'Archive unread',
                icon: const Icon(Icons.inventory_2_outlined)),
          if (!isPatient)
            IconButton(
                onPressed: _clearAll,
                tooltip: 'Clear all',
                icon: const Icon(Icons.clear_all)),
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Builder(builder: (context) {
              final items = _items;
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No notifications'),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Note: $_error',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              }

              // KPIs
              final total = items.length;
              final unread = items.where((e) => !e.read).length;
              final today = items.where((e) {
                final now = DateTime.now();
                return e.time.year == now.year &&
                    e.time.month == now.month &&
                    e.time.day == now.day;
              }).length;

              // Filter & search
              final q = _searchCtrl.text.trim().toLowerCase();
              var filtered = items
                  .where(
                      (n) => q.isEmpty || n.message.toLowerCase().contains(q))
                  .toList();
              if (_archivedOnly) {
                filtered = filtered.where((n) => n.archived).toList();
              } else {
                filtered = filtered.where((n) => !n.archived).toList();
              }
              if (_unreadOnly) {
                filtered = filtered.where((n) => !n.read).toList();
              }
              if (_todayOnly) {
                final now = DateTime.now();
                filtered = filtered
                    .where((n) =>
                        n.time.year == now.year &&
                        n.time.month == now.month &&
                        n.time.day == now.day)
                    .toList();
              }

              // Group by date (day)
              final groups = <String, List<AppNotification>>{};
              for (final n in filtered) {
                final key = DateTime(n.time.year, n.time.month, n.time.day)
                    .toIso8601String();
                groups.putIfAbsent(key, () => []).add(n);
              }
              final keys = groups.keys.toList()
                ..sort(
                    (a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)));

              String labelFor(String iso) {
                final d = DateTime.parse(iso);
                final now = DateTime.now();
                final todayDate = DateTime(now.year, now.month, now.day);
                final yesterday = todayDate.subtract(const Duration(days: 1));
                final day = DateTime(d.year, d.month, d.day);
                if (day == todayDate) return 'Today';
                if (day == yesterday) return 'Yesterday';
                return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    Row(children: [
                      _kpi('Total', '$total', Icons.notifications, Colors.blue,
                          onTap: () {
                        setState(() {
                          _unreadOnly = false;
                          _todayOnly = false;
                          _archivedOnly = false;
                          _searchCtrl.clear();
                        });
                      }),
                      const SizedBox(width: 12),
                      _kpi('Unread', '$unread', Icons.mark_email_unread,
                          Colors.orange, onTap: () {
                        setState(() {
                          // Show only unread, non-archived
                          _unreadOnly = true;
                          _todayOnly = false;
                          _archivedOnly = false;
                        });
                      }),
                      const SizedBox(width: 12),
                      _kpi('Today', '$today', Icons.today, Colors.green,
                          onTap: () {
                        setState(() {
                          // Show only today's, non-archived
                          _todayOnly = true;
                          _unreadOnly = false;
                          _archivedOnly = false;
                        });
                      }),
                    ]),
                    const SizedBox(height: 16),

                    // Search field (filters controlled by KPI cards above)
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Search notifications...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilterChip(
                        label: const Text('Archived'),
                        selected: _archivedOnly,
                        onSelected: (v) => setState(() => _archivedOnly = v),
                      ),
                    ]),
                    const SizedBox(height: 12),

                    // Grouped list
                    ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: keys.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final k = keys[i];
                        final list = groups[k]!;
                        return Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        labelFor(k),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Text('${list.length} items',
                                        style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12)),
                                  ],
                                ),
                                const Divider(height: 16),
                                ...list.map((n) {
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 0),
                                    leading: InkWell(
                                      borderRadius: BorderRadius.circular(24),
                                      onTap: () async {
                                        try {
                                          await _service.markRead(
                                              n.id, !n.read);
                                          if (!context.mounted) return;
                                          setState(() {
                                            n.read = !n.read;
                                          });
                                        } catch (_) {}
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Icon(
                                          n.read
                                              ? Icons.notifications_none
                                              : Icons.notifications_active,
                                          color: n.read
                                              ? Colors.grey
                                              : Colors.blue,
                                        ),
                                      ),
                                    ),
                                    title: Text(n.message),
                                    subtitle: Text(n.time.toString()),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(n.read
                                              ? Icons.mark_email_unread
                                              : Icons.mark_email_read),
                                          tooltip: n.read
                                              ? 'Mark unread'
                                              : 'Mark read',
                                          onPressed: () async {
                                            try {
                                              await _service.markRead(
                                                  n.id, !n.read);
                                              if (!context.mounted) return;
                                              setState(() {
                                                n.read = !n.read;
                                              });
                                            } catch (_) {}
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            n.archived
                                                ? Icons.unarchive
                                                : Icons.archive_outlined,
                                          ),
                                          tooltip: n.archived
                                              ? 'Unarchive'
                                              : 'Archive',
                                          onPressed: () async {
                                            try {
                                              await _service.setArchived(
                                                  n.id, !n.archived);
                                              if (!context.mounted) return;
                                              setState(() {
                                                n.archived = !n.archived;
                                              });
                                            } catch (_) {}
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.more_vert),
                                          onPressed: () {
                                            _showNotificationMenu(
                                              context,
                                              n,
                                              onDelete: () async {
                                                try {
                                                  await _service
                                                      .deleteOne(n.id);
                                                  if (!context.mounted) return;
                                                  setState(() {
                                                    _items = _items
                                                        .where(
                                                            (x) => x.id != n.id)
                                                        .toList();
                                                  });
                                                } catch (e) {
                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content: Text(
                                                            'Delete failed: $e')),
                                                  );
                                                }
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  ],
                ),
              );
            }),
    );
  }
}

Widget _kpi(String label, String value, IconData icon, Color color,
    {VoidCallback? onTap}) {
  final card = Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Icon(icon, color: color),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ]),
      ),
    ]),
  );
  return Expanded(
      child: onTap == null ? card : InkWell(onTap: onTap, child: card));
}

void _showNotificationMenu(BuildContext context, AppNotification n,
    {Future<void> Function()? onDelete}) {
  showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Details'),
            onTap: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(n.message)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(ctx);
              if (onDelete != null) {
                onDelete();
              }
            },
          ),
        ],
      ),
    ),
  );
}
