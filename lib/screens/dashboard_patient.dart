// ignore_for_file: invalid_use_of_protected_member, prefer_const_declarations, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/creative_dashboard.dart';
import '../widgets/curvy_bottom_nav.dart';
import '../services/notifications_service.dart';
import '../services/chrms_alerts_service.dart';
import '../models/common_models.dart';

class DashboardPatient extends StatefulWidget {
  const DashboardPatient({super.key});

  @override
  State<DashboardPatient> createState() => _DashboardPatientState();
}

class _NextAppointmentHero extends StatelessWidget {
  final String? uid;
  const _NextAppointmentHero({required this.uid});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primaryContainer, cs.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  child: const Icon(Icons.calendar_today),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Next Appointment',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Confirmed',
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(color: cs.onSecondaryContainer, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (uid == null)
              const Text('Sign in to view your appointment',
                  style: TextStyle(color: Colors.black54))
            else
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('appointments')
                    .where('createdBy', isEqualTo: uid)
                    .limit(10)
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Text('Loading...',
                        style: TextStyle(color: Colors.black54));
                  }
                  // pick the nearest upcoming (>= now)
                  final now = DateTime.now();
                  DateTime? pickDate(Map<String, dynamic> m) {
                    final ts = m['date'];
                    if (ts is Timestamp) return ts.toDate();
                    return DateTime.tryParse('${ts ?? ''}');
                  }

                  final docs = snap.data!.docs
                      .map((d) => d.data())
                      .where((m) => pickDate(m) != null)
                      .toList()
                    ..sort((a, b) => pickDate(a)!.compareTo(pickDate(b)!));
                  final next = docs.firstWhere(
                    (m) => pickDate(m)!
                        .isAfter(now.subtract(const Duration(minutes: 1))),
                    orElse: () => const <String, dynamic>{},
                  );
                  if (next.isEmpty) {
                    return const Text('No upcoming appointment',
                        style: TextStyle(color: Colors.black54));
                  }
                  final dt = pickDate(next)!;
                  final title = (next['title'] ?? 'Appointment').toString();
                  final bhw =
                      (next['with'] ?? next['provider'] ?? 'Health Worker')
                          .toString();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('BHW: $bhw'),
                      const SizedBox(height: 2),
                      Text(DateFormat('EEE, MMM d • h:mm a').format(dt),
                          style: const TextStyle(color: Colors.black87)),
                    ],
                  );
                },
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/appointments'),
                  child: const Text('Request Appointment'),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/records'),
                  child: const Text('View Records'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TipRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;
  final Stream<int> stream;
  final String emptyLabel;

  const _KpiCard({
    required this.title,
    required this.icon,
    this.iconColor,
    required this.onTap,
    required this.stream,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(icon, size: 28, color: iconColor ?? cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right,
                      size: 18, color: Colors.black45),
                ],
              ),
              const SizedBox(height: 12),
              StreamBuilder<int>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text('Loading...',
                        style: TextStyle(color: Colors.black54));
                  }
                  final count = snapshot.data ?? 0;
                  return Text(
                    count == 0 ? emptyLabel : '$count',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessagesQuickView extends StatelessWidget {
  final String? uid;
  const _MessagesQuickView({required this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.forum_outlined, color: cs.primary),
                const SizedBox(width: 8),
                Text('Messages',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/chat'),
                  child: const Text('Open chat'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('threads')
                  .where('participants', arrayContains: uid)
                  .where('archived', isEqualTo: false)
                  .orderBy('updatedAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Failed to load',
                      style: TextStyle(color: Colors.redAccent));
                }
                if (!snapshot.hasData) {
                  return const _SkeletonList(count: 3);
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Text('No recent messages',
                      style: TextStyle(color: Colors.black54));
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final d = docs[i].data();
                    final title = (d['title'] ?? 'Conversation') as String;
                    final last = (d['lastMessage'] ?? '') as String;
                    final ts = d['updatedAt'];
                    DateTime? dt;
                    if (ts is Timestamp) dt = ts.toDate();
                    dt ??= DateTime.tryParse('${ts ?? ''}');
                    final when =
                        dt != null ? DateFormat.MMMd().add_jm().format(dt) : '';
                    return ListTile(
                      leading: CircleAvatar(
                          backgroundColor: cs.secondaryContainer,
                          child: const Icon(Icons.forum, color: Colors.white)),
                      title: Text(title,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(last.isEmpty ? 'No messages yet' : last,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Text(when,
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 12)),
                      onTap: () => Navigator.pushNamed(context, '/chat'),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  final int count;
  const _SkeletonList({this.count = 3});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Column(
      children: List.generate(
          count,
          (i) => Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 8.0),
                child: Row(
                  children: [
                    Container(
                        width: 40,
                        height: 40,
                        decoration:
                            BoxDecoration(color: base, shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              height: 12,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  color: base,
                                  borderRadius: BorderRadius.circular(6))),
                          const SizedBox(height: 6),
                          Container(
                              height: 10,
                              width: 180,
                              decoration: BoxDecoration(
                                  color: base,
                                  borderRadius: BorderRadius.circular(6))),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
    );
  }
}

class _DashboardPatientState extends State<DashboardPatient> {
  // Record form removed

  @override
  void dispose() {
    super.dispose();
  }

  // Record-related helper methods removed

  @override
  Widget build(BuildContext context) {
    final isMobile = true;
    int currentIndex = 0; // index within 'pages' only (no Messages slot)
    final pages = <Widget>[
      _buildOverview(isMobile), // 0 -> Home
      _buildAppointments(), // 1 -> Appointments (displayed index 1)
      _buildSettings(), // 2 -> Profile   (displayed index 3)
    ];
    return StatefulBuilder(
      builder: (context, setShellState) {
        return Scaffold(
          appBar: AppBar(
            elevation: 1,
            title: const Text('HealthSphere'),
            actions: [
              IconButton(
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.pushNamed(context, '/notifications');
                },
              ),
              IconButton(
                tooltip: 'Logout',
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                      this.context, '/login', (r) => false);
                },
              ),
            ],
          ),
          body: pages[currentIndex],
          bottomNavigationBar: CurvyBottomNav(
            currentIndex: currentIndex < 2 ? currentIndex : currentIndex + 1,
            items: const [
              CurvyNavItem(icon: Icons.home_outlined, label: 'Home'),
              CurvyNavItem(icon: Icons.event_note, label: 'Appointments'),
              CurvyNavItem(icon: Icons.forum_outlined, label: 'Messages'),
              CurvyNavItem(icon: Icons.person_outline, label: 'Profile'),
            ],
            onSelected: (i) {
              if (i == 2) {
                Navigator.pushNamed(context, '/chat');
                return;
              }
              final mapped = i < 2 ? i : i - 1;
              setShellState(() => currentIndex = mapped);
            },
          ),
        );
      },
    );
  }
}

extension on _DashboardPatientState {
  Widget _buildOverview(bool isMobile) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    final String displayName =
        FirebaseAuth.instance.currentUser?.displayName?.trim() ?? 'Patient';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CreativeHeader(
            title: 'Hello, $displayName',
            subtitle:
                'Here is your day at a glance — appointments, messages and tips',
            leadingIcon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          _NextAppointmentHero(uid: uid),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, cons) {
              final maxW = cons.maxWidth;
              double tileWidth;

              // Prefer two KPI tiles per row on most widths; fall back to one
              // column only on very narrow screens to avoid overflow.
              if (maxW >= 380) {
                tileWidth = (maxW - 12) / 2; // two columns
              } else {
                tileWidth = maxW; // single column for extra-narrow
              }

              tileWidth = tileWidth.clamp(200, 480);
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: tileWidth,
                    child: _KpiCard(
                      title: 'Upcoming Appointments',
                      icon: Icons.calendar_today,
                      onTap: () =>
                          Navigator.pushNamed(context, '/appointments'),
                      stream: uid == null
                          ? const Stream<int>.empty()
                          : FirebaseFirestore.instance
                              .collection('appointments')
                              .where('createdBy', isEqualTo: uid)
                              .snapshots()
                              .map((s) => s.docs.where((d) {
                                    final st = (d.data()['status'] ?? 'pending')
                                        as String;
                                    return st == 'pending' || st == 'confirmed';
                                  }).length),
                      emptyLabel: 'No upcoming',
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _KpiCard(
                      title: 'Health Updates',
                      icon: Icons.favorite,
                      iconColor: Colors.redAccent,
                      onTap: () =>
                          Navigator.pushNamed(context, '/notifications'),
                      stream: uid == null
                          ? const Stream<int>.empty()
                          : FirebaseFirestore.instance
                              .collection('patient_updates')
                              .where('recipientId', isEqualTo: uid)
                              .where('read', isEqualTo: false)
                              .snapshots()
                              .map((s) => s.size),
                      emptyLabel: 'No new alerts',
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          _MessagesQuickView(uid: uid),
          const SizedBox(height: 20),
          // CHRMS Alerts summary (community alerts from chrms_alerts)
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: ChrmsAlertsService().streamActiveAlerts(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const SizedBox.shrink();
              }
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.campaign,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'No community alerts at the moment.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              Color colorForCategory(String category) {
                switch (category) {
                  case 'HEALTH_ADVISORY':
                    return const Color(0xFF66BB6A); // green
                  case 'IMMUNIZATION':
                    return const Color(0xFF42A5F5); // blue
                  case 'EMERGENCY':
                    return const Color(0xFFFF3B3B); // red
                  case 'BARANGAY':
                    return const Color(0xFFFFEB3B); // yellow
                  case 'MEDICINE':
                    return const Color(0xFFAB47BC); // purple
                  case 'WORKER':
                    return const Color(0xFF9E9E9E); // grey
                  case 'APPOINTMENT':
                    return Theme.of(context).colorScheme.primary;
                  default:
                    return Theme.of(context).colorScheme.primary;
                }
              }

              String labelForCategory(String category) {
                switch (category) {
                  case 'HEALTH_ADVISORY':
                    return 'Health Advisory';
                  case 'IMMUNIZATION':
                    return 'Immunization';
                  case 'EMERGENCY':
                    return 'Emergency Alert';
                  case 'BARANGAY':
                    return 'Barangay Announcement';
                  case 'MEDICINE':
                    return 'Medicine Pickup';
                  case 'WORKER':
                    return 'Worker Notification';
                  case 'APPOINTMENT':
                    return 'Follow-up Appointment';
                  default:
                    return 'Alert';
                }
              }

              final items = docs.take(5).toList();

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.campaign,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'CHRMS Alerts',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 12),
                        itemBuilder: (context, i) {
                          final d = items[i].data();
                          final category =
                              (d['category'] ?? 'HEALTH_ADVISORY').toString();
                          final title =
                              (d['title'] ?? 'Health Alert').toString();
                          final message = (d['message'] ?? '').toString();
                          final priority =
                              (d['priority'] ?? 'NORMAL').toString();
                          final createdAt = d['createdAt'];
                          DateTime createdTime;
                          if (createdAt is Timestamp) {
                            createdTime = createdAt.toDate();
                          } else {
                            createdTime = DateTime.now();
                          }

                          final baseColor = colorForCategory(category);
                          Color priorityColor;
                          switch (priority) {
                            case 'URGENT':
                              priorityColor = const Color(0xFFFF3B3B);
                              break;
                            case 'IMPORTANT':
                              priorityColor = const Color(0xFFFFA726);
                              break;
                            case 'NORMAL':
                            default:
                              priorityColor = baseColor;
                          }

                          final dateLabel = DateFormat('MMM d, yyyy • h:mm a')
                              .format(createdTime);

                          return Container(
                            decoration: BoxDecoration(
                              color: baseColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: baseColor.withValues(alpha: 0.3)),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color:
                                            baseColor.withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        labelForCategory(category),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: baseColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: priorityColor.withValues(
                                            alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        priority,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: priorityColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                if (message.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    message,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dateLabel,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: Text(title),
                                            content: SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    labelForCategory(category),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: baseColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Priority: $priority',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    dateLabel,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.black45,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(message),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx),
                                                child: const Text('Close'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: const Text('View Details'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // Notifications summary (personal patient updates only)
          FutureBuilder<List<AppNotification>>(
            future: NotificationsService().fetchNotifications(role: 'patient'),
            builder: (context, notifSnap) {
              if (notifSnap.connectionState == ConnectionState.waiting) {
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 12),
                      Text('Loading notifications...')
                    ]),
                  ),
                );
              }

              final notifs = notifSnap.data ?? const <AppNotification>[];
              final top = notifs.take(5).toList();

              if (top.isEmpty) {
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.notifications_none,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'No notifications yet.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/notifications'),
                          child: const Text('View all'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.notifications_active,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Notifications',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/notifications'),
                            child: const Text('View all'),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: top.length,
                        separatorBuilder: (_, __) => const Divider(height: 12),
                        itemBuilder: (context, i) {
                          final n = top[i];
                          final baseColor =
                              Theme.of(context).colorScheme.primary;
                          final dateLabel =
                              DateFormat('MMM d, yyyy • h:mm a').format(n.time);
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              final msgLower = n.message.toLowerCase();
                              if (msgLower.contains('appointment')) {
                                Navigator.pushNamed(context, '/appointments');
                              } else {
                                Navigator.pushNamed(context, '/notifications');
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: baseColor.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: baseColor.withValues(alpha: 0.2)),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color:
                                              baseColor.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          n.read
                                              ? Icons.notifications_none
                                              : Icons.notifications_active,
                                          size: 18,
                                          color: baseColor,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    n.message,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                                if (!n.read) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Colors.redAccent,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              dateLabel,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            "Health Tips",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TipRow(
                      icon: Icons.opacity,
                      text:
                          'Stay hydrated! Aim to drink 8 glasses of water daily.'),
                  SizedBox(height: 12),
                  _TipRow(
                      icon: Icons.local_florist,
                      text:
                          'Maintain a balanced diet rich in fruits and vegetables.'),
                  SizedBox(height: 12),
                  _TipRow(
                      icon: Icons.bedtime,
                      text: 'Get enough sleep — at least 7–8 hours per night.'),
                  SizedBox(height: 12),
                  _TipRow(
                      icon: Icons.fitness_center,
                      text:
                          'Exercise regularly to improve your immune system.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointments() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Not signed in'));
    }
    final cs = Theme.of(context).colorScheme;

    Color chipColor(String s) {
      final v = s.toLowerCase();
      if (v.contains('approve') || v.contains('confirm')) return Colors.green;
      if (v.contains('pending')) return Colors.orange;
      if (v.contains('cancel')) return Colors.redAccent;
      return cs.primary;
    }

    Widget buildLeading(DateTime dt) {
      final m = DateFormat('MMM').format(dt).toUpperCase();
      final d = DateFormat('dd').format(dt);
      final t = DateFormat('hh:mm a').format(dt);
      return Container(
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: cs.surfaceContainerHighest,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(m,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            Text(d,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(t,
                style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: SafeArea(
        top: false,
        bottom: true,
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 8),
                TabBar(
                  labelColor: cs.primary,
                  tabs: const [
                    Tab(text: 'Upcoming'),
                    Tab(text: 'Past'),
                  ],
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('appointments')
                        .where('createdBy', isEqualTo: uid)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Unable to load appointments',
                                style: TextStyle(color: Colors.black54)),
                          ),
                        );
                      }
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      DateTime? toDate(Map<String, dynamic> m) {
                        final ts = m['dateTs'];
                        if (ts is Timestamp) return ts.toDate();
                        final raw = m['date'];
                        if (raw is Timestamp) return raw.toDate();
                        return DateTime.tryParse('${raw ?? ''}');
                      }

                      final all = snap.data!.docs
                          .map((d) => d.data())
                          .whereType<Map<String, dynamic>>()
                          .where((m) => toDate(m) != null)
                          .toList()
                        ..sort((a, b) => toDate(a)!.compareTo(toDate(b)!));
                      final now = DateTime.now();
                      final upcoming = all
                          .where((m) => toDate(m)!.isAfter(
                              now.subtract(const Duration(minutes: 1))))
                          .toList();
                      final past =
                          all.where((m) => toDate(m)!.isBefore(now)).toList();

                      Widget buildListWidget(List<Map<String, dynamic>> list) {
                        if (list.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('No items',
                                  style: TextStyle(color: Colors.black54)),
                            ),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final m = list[i];
                            final dt = toDate(m)!;
                            final title =
                                (m['title'] ?? 'General Check-up').toString();
                            final provider =
                                (m['with'] ?? m['provider'] ?? 'BHW')
                                    .toString();
                            final status =
                                (m['status'] ?? 'Pending').toString();
                            return ListTile(
                              leading: buildLeading(dt),
                              title: Text(title),
                              subtitle: Text('BHW: $provider'),
                              trailing: Chip(
                                label: Text(status),
                                backgroundColor:
                                    chipColor(status).withValues(alpha: 0.12),
                                labelStyle: TextStyle(color: chipColor(status)),
                              ),
                              onTap: () =>
                                  Navigator.pushNamed(context, '/appointments'),
                            );
                          },
                        );
                      }

                      return TabBarView(
                        children: [
                          buildListWidget(upcoming),
                          buildListWidget(past.reversed.toList()),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.extended(
                onPressed: () => Navigator.pushNamed(context, '/appointments'),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Request Appointment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // _buildMessages removed per request

  Widget _buildSettings() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return SingleChildScrollView(
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
                  const Text('Profile Settings',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (uid == null)
                    const Text('Not signed in',
                        style: TextStyle(color: Colors.black54))
                  else
                    FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future:
                          FirebaseFirestore.instance.doc('users/$uid').get(),
                      builder: (context, snap) {
                        final data =
                            snap.data?.data() ?? const <String, dynamic>{};
                        final nameCtrl = TextEditingController(
                            text: (data['name'] ?? '') as String);
                        final emailCtrl = TextEditingController(
                            text: (data['email'] ??
                                FirebaseAuth.instance.currentUser?.email ??
                                '') as String);
                        final phoneCtrl = TextEditingController(
                            text: (data['phone'] ?? '') as String);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                                controller: nameCtrl,
                                decoration: const InputDecoration(
                                    labelText: 'Full Name',
                                    border: OutlineInputBorder())),
                            const SizedBox(height: 12),
                            TextField(
                                controller: emailCtrl,
                                readOnly: true,
                                decoration: const InputDecoration(
                                    labelText: 'Email (read-only)',
                                    border: OutlineInputBorder())),
                            const SizedBox(height: 12),
                            TextField(
                                controller: phoneCtrl,
                                decoration: const InputDecoration(
                                    labelText: 'Phone',
                                    border: OutlineInputBorder())),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    final oldCtrl = TextEditingController();
                                    final newCtrl = TextEditingController();
                                    final cfmCtrl = TextEditingController();
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (ctx) => Padding(
                                        padding: EdgeInsets.only(
                                          left: 16,
                                          right: 16,
                                          bottom: MediaQuery.of(ctx)
                                                  .viewInsets
                                                  .bottom +
                                              16,
                                          top: 16,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('Change Password',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(height: 12),
                                            TextField(
                                                controller: oldCtrl,
                                                obscureText: true,
                                                decoration:
                                                    const InputDecoration(
                                                        labelText:
                                                            'Current Password')),
                                            const SizedBox(height: 12),
                                            TextField(
                                                controller: newCtrl,
                                                obscureText: true,
                                                decoration:
                                                    const InputDecoration(
                                                        labelText:
                                                            'New Password')),
                                            const SizedBox(height: 12),
                                            TextField(
                                                controller: cfmCtrl,
                                                obscureText: true,
                                                decoration: const InputDecoration(
                                                    labelText:
                                                        'Confirm New Password')),
                                            const SizedBox(height: 12),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  if (newCtrl.text
                                                          .trim()
                                                          .isEmpty ||
                                                      newCtrl.text !=
                                                          cfmCtrl.text) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content: Text(
                                                              'Passwords do not match')),
                                                    );
                                                    return;
                                                  }
                                                  Navigator.pop(ctx);
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                        content: Text(
                                                            'Password changed')),
                                                  );
                                                },
                                                child: const Text('Save'),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Change Password'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      await FirebaseFirestore.instance
                                          .doc('users/$uid')
                                          .set({
                                        'name': nameCtrl.text.trim(),
                                        'phone': phoneCtrl.text.trim(),
                                        'email': emailCtrl.text.trim(),
                                      }, SetOptions(merge: true));
                                      if (!mounted) return;
                                      // ignore: use_build_context_synchronously
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('Profile updated')),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      // ignore: use_build_context_synchronously
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content:
                                                Text('Failed to update: $e')),
                                      );
                                    }
                                  },
                                  child: const Text('Save Changes'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton(
                                onPressed: () => Navigator.pushReplacementNamed(
                                    context, '/login'),
                                child: const Text('Log out'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
