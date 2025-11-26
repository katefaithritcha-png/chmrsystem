// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/dashboard_service.dart';
import '../models/dashboard_models.dart';
import '../widgets/creative_dashboard.dart';
import '../widgets/curvy_bottom_nav.dart';
import '../core/responsive/responsive_helper.dart';

class DashboardAdmin extends StatelessWidget {
  const DashboardAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: const Row(
          children: [
            Icon(Icons.health_and_safety, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "HealthSphere",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Spacer(),
            // No AppBar logout; use sidebar/logout options instead
          ],
        ),
        actions: [
          if (!isMobile)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 360,
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    onSubmitted: (q) async {
                      final service = DashboardService();
                      try {
                        final results = await service.searchPatients(q);
                        if (!context.mounted) return;
                        showModalBottomSheet(
                          context: context,
                          builder: (ctx) {
                            if (results.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No results found'),
                              );
                            }
                            return ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemBuilder: (_, i) {
                                final p = results[i];
                                return ListTile(
                                  leading: const Icon(Icons.person),
                                  title: Text('${p.name} (${p.id})'),
                                  subtitle:
                                      Text('Age: ${p.age}  Sex: ${p.sex}'),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    Navigator.pushNamed(context, '/patients');
                                  },
                                );
                              },
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemCount: results.length,
                            );
                          },
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Search failed: ${e.toString()}')),
                        );
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: "Search patients or records...",
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Search',
              icon: const Icon(Icons.search),
              onPressed: () async {
                final q = await showDialog<String>(
                  context: context,
                  builder: (ctx) {
                    final ctrl = TextEditingController();
                    return AlertDialog(
                      title: const Text('Search'),
                      content: TextField(
                        controller: ctrl,
                        decoration: const InputDecoration(
                            hintText: 'Search patients or records...'),
                      ),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel')),
                        ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, ctrl.text),
                            child: const Text('Search')),
                      ],
                    );
                  },
                );
                if (q == null || q.isEmpty) return;
                final service = DashboardService();
                try {
                  final results = await service.searchPatients(q);
                  if (!context.mounted) return;
                  showModalBottomSheet(
                    context: context,
                    builder: (ctx) {
                      if (results.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No results found'),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (_, i) {
                          final p = results[i];
                          return ListTile(
                            leading: const Icon(Icons.person),
                            title: Text('${p.name} (${p.id})'),
                            subtitle: Text('Age: ${p.age}  Sex: ${p.sex}'),
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.pushNamed(context, '/patients');
                            },
                          );
                        },
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemCount: results.length,
                      );
                    },
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Search failed: ${e.toString()}')),
                  );
                }
              },
            ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (r) => false);
            },
          ),
        ],
      ),
      drawer: isMobile
          ? null
          : Drawer(
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 8),
                    const Text("Menu",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    menuItem(context, Icons.dashboard, "Dashboard", () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/admin');
                    }),
                    ExpansionTile(
                      leading: Icon(Icons.people_outline,
                          color: Theme.of(context).colorScheme.primary),
                      title: const Text('Management'),
                      children: [
                        menuItem(context, Icons.people, "User Management", () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/users');
                        }),
                        menuItem(
                            context, Icons.medical_information, "Consultations",
                            () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/consultation');
                        }),
                        menuItem(
                            context, Icons.folder_shared, "Patient Records",
                            () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/patients');
                        }),
                        // Health Records removed for admin
                      ],
                    ),
                    ExpansionTile(
                      leading: Icon(Icons.settings_applications_outlined,
                          color: Theme.of(context).colorScheme.primary),
                      title: const Text('System'),
                      children: [
                        menuItem(context, Icons.bar_chart, "Reports", () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/reports');
                        }),
                        menuItem(context, Icons.notifications, "Notifications",
                            () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/notifications');
                        }),
                        menuItem(context, Icons.list_alt, "Audit Trail", () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/audit');
                        }),
                        menuItem(context, Icons.backup, "System Backup", () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/backup');
                        }),
                      ],
                    ),
                    const Divider(),
                  ],
                ),
              ),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar
          if (!isMobile)
            Container(
              width: 220,
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),
                  const Text("Menu",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        menuItem(context, Icons.dashboard, "Dashboard", () {
                          Navigator.pushReplacementNamed(context, '/admin');
                        }),
                        ExpansionTile(
                          leading: Icon(Icons.people_outline,
                              color: Theme.of(context).colorScheme.primary),
                          title: const Text('Management'),
                          childrenPadding: const EdgeInsets.only(
                              left: 8, right: 8, bottom: 8),
                          children: [
                            menuItem(context, Icons.people, "User Management",
                                () {
                              Navigator.pushNamed(context, '/users');
                            }),
                            menuItem(context, Icons.medical_information,
                                "Consultations", () {
                              Navigator.pushNamed(context, '/consultation');
                            }),
                            menuItem(
                                context, Icons.folder_shared, "Patient Records",
                                () {
                              Navigator.pushNamed(context, '/patients');
                            }),
                            // Health Records removed for admin
                          ],
                        ),
                        ExpansionTile(
                          leading: Icon(Icons.settings_applications_outlined,
                              color: Theme.of(context).colorScheme.primary),
                          title: const Text('System'),
                          childrenPadding: const EdgeInsets.only(
                              left: 8, right: 8, bottom: 8),
                          children: [
                            menuItem(context, Icons.bar_chart, "Reports", () {
                              Navigator.pushNamed(context, '/reports');
                            }),
                            menuItem(
                                context, Icons.notifications, "Notifications",
                                () {
                              Navigator.pushNamed(context, '/notifications');
                            }),
                            menuItem(context, Icons.list_alt, "Audit Trail",
                                () {
                              Navigator.pushNamed(context, '/audit');
                            }),
                            menuItem(context, Icons.backup, "System Backup",
                                () {
                              Navigator.pushNamed(context, '/backup');
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Logout moved to AppBar action
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cache cleared')),
                      );
                    },
                    icon: Icon(Icons.cleaning_services,
                        color: Theme.of(context).colorScheme.error),
                    label: Text("Clear Cache",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                        shape: const StadiumBorder()),
                  ),
                ],
              ),
            ),

          // Main Dashboard Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CreativeHeader(
                    title: 'Administrator Dashboard',
                    subtitle:
                        'Monitor users, appointments, and system health at a glance.',
                    leadingIcon: Icons.dashboard_customize_rounded,
                  ),
                  const SizedBox(height: 16),

                  // Live KPI Cards (Firestore streams) - 2x2 grid on most widths
                  LayoutBuilder(builder: (context, cons) {
                    final cs = Theme.of(context).colorScheme;
                    final maxW = cons.maxWidth;
                    double tileWidth;

                    // Prefer 2 tiles per row for typical layouts; fall back to 1
                    // only on very narrow screens.
                    if (maxW >= 380) {
                      tileWidth = (maxW - 12) / 2; // 2 per row
                    } else {
                      tileWidth = maxW; // single column for extra-narrow
                    }

                    tileWidth = tileWidth.clamp(160, 420);

                    Widget tile(String title, Stream<int> stream, IconData icon,
                        Color color, VoidCallback onTap) {
                      return SizedBox(
                        width: tileWidth,
                        child: StreamBuilder<int>(
                          stream: stream,
                          builder: (context, snap) {
                            final value = snap.hasData ? '${snap.data}' : '--';
                            const change = '';
                            return statCardBox(context, title, value, change,
                                icon, color, onTap);
                          },
                        ),
                      );
                    }

                    final items = <Widget>[
                      tile(
                        'Total Users',
                        FirebaseFirestore.instance
                            .collection('users')
                            .snapshots()
                            .map((s) => s.size),
                        Icons.people,
                        cs.primary,
                        () => Navigator.pushNamed(context, '/users'),
                      ),
                      tile(
                        'Active Patients',
                        FirebaseFirestore.instance
                            .collection('patients')
                            .snapshots()
                            .map((s) => s.size),
                        Icons.local_hospital,
                        cs.secondary,
                        () => Navigator.pushNamed(context, '/patients'),
                      ),
                      tile(
                        'Reports Generated',
                        FirebaseFirestore.instance
                            .collection('audit')
                            .where('action', whereIn: [
                              'reports.export.csv',
                              'reports.export.pdf'
                            ])
                            .snapshots()
                            .map((s) => s.size),
                        Icons.insert_chart,
                        cs.primary,
                        () => Navigator.pushNamed(context, '/reports'),
                      ),
                      tile(
                        'Pending Approvals',
                        FirebaseFirestore.instance
                            .collection('appointments')
                            .where('status', isEqualTo: 'pending')
                            .snapshots()
                            .map((s) => s.size),
                        Icons.warning,
                        cs.error,
                        () => Navigator.pushNamed(
                            context, '/appointments/approvals'),
                      ),
                    ];

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: items,
                    );
                  }),
                  const SizedBox(height: 25),

                  // Chart + Right Panel
                  LayoutBuilder(
                    builder: (context, cons) {
                      final isNarrow = cons.maxWidth < 1100;
                      final chartPanel = Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Patient Data Insights",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const Text(
                              "Monthly patient registrations and check-ups.",
                              style: TextStyle(
                                  color: Colors.black54, fontSize: 13),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 220,
                              child: FutureBuilder<List<ChartPoint>>(
                                future: DashboardService().fetchPatientChart(),
                                builder: (context, snap) {
                                  if (snap.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }
                                  if (snap.hasError) {
                                    return const Center(
                                        child: Text('Failed to load chart'));
                                  }
                                  final data =
                                      snap.data ?? const <ChartPoint>[];
                                  if (data.isEmpty) {
                                    return const Center(
                                        child: Text('No chart data'));
                                  }
                                  return patientBarChart(context, data);
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                      final rightPanel = Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Management & System",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                SizedBox(
                                  width: 260,
                                  child: actionCard(
                                      context,
                                      "User Management",
                                      "Add or edit user accounts.",
                                      Icons.manage_accounts, () {
                                    Navigator.pushNamed(context, '/users');
                                  }),
                                ),
                                SizedBox(
                                  width: 260,
                                  child: actionCard(
                                      context,
                                      "Consultations",
                                      "Queue and visit records.",
                                      Icons.medical_information, () {
                                    Navigator.pushNamed(
                                        context, '/consultation');
                                  }),
                                ),
                                SizedBox(
                                  width: 260,
                                  child: actionCard(
                                      context,
                                      "Patient Records",
                                      "Browse and update records.",
                                      Icons.folder_shared, () {
                                    Navigator.pushNamed(context, '/patients');
                                  }),
                                ),
                                // Health Records action card removed for admin
                                SizedBox(
                                  width: 260,
                                  child: actionCard(
                                      context,
                                      "Reports",
                                      "Generate and view analytics.",
                                      Icons.bar_chart, () {
                                    Navigator.pushNamed(context, '/reports');
                                  }),
                                ),
                                SizedBox(
                                  width: 260,
                                  child: actionCard(
                                      context,
                                      "Medicine Inventory Reports",
                                      "CSV summaries and logs.",
                                      Icons.inventory_outlined, () {
                                    Navigator.pushNamed(context, '/reports');
                                  }),
                                ),
                                SizedBox(
                                  width: 260,
                                  child: actionCard(
                                      context,
                                      "Notifications",
                                      "System alerts and messages.",
                                      Icons.notifications_active, () {
                                    Navigator.pushNamed(
                                        context, '/notifications');
                                  }),
                                ),
                                SizedBox(
                                  width: 260,
                                  child: actionCard(
                                      context,
                                      "CHRMS Alerts",
                                      "Create health advisories and announcements.",
                                      Icons.campaign, () {
                                    Navigator.pushNamed(
                                        context, '/chrms-alerts/new');
                                  }),
                                ),
                                SizedBox(
                                  width: 260,
                                  child: actionCard(
                                      context,
                                      "Audit Trail",
                                      "Access logs and actions.",
                                      Icons.receipt_long, () {
                                    Navigator.pushNamed(context, '/audit');
                                  }),
                                ),
                                SizedBox(
                                  width: 260,
                                  child: actionCard(
                                      context,
                                      "System Backup",
                                      "Run and review backups.",
                                      Icons.backup, () {
                                    Navigator.pushNamed(context, '/backup');
                                  }),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            chartPanel,
                            const SizedBox(height: 20),
                            rightPanel,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: chartPanel),
                          const SizedBox(width: 20),
                          Expanded(flex: 1, child: rightPanel),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 25),

                  // Activity Log + Backup
                  LayoutBuilder(
                    builder: (context, cons) {
                      final isNarrow = cons.maxWidth < 1100;
                      final left = Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text(
                                    "Recent Access & Activity",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/audit'),
                                  icon: const Icon(Icons.open_in_new),
                                  label: const Text('View all'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance
                                  .collection('audit')
                                  .orderBy('at', descending: true)
                                  .limit(8)
                                  .snapshots(),
                              builder: (context, snap) {
                                if (snap.hasError) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text('Failed to load activity'),
                                  );
                                }
                                if (!snap.hasData) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }
                                final docs = snap.data!.docs;
                                if (docs.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text('No recent activity'),
                                  );
                                }
                                final items = docs.map((d) {
                                  final m = d.data();
                                  final ts = m['at'];
                                  final dt = ts is Timestamp
                                      ? ts.toDate()
                                      : DateTime.now();
                                  return ActivityEntry(
                                    action: (m['action'] ?? '').toString(),
                                    user:
                                        '${m['actorRole'] ?? ''}:${m['actorId'] ?? ''}',
                                    time: dt,
                                  );
                                }).toList();
                                return Column(
                                  children: items
                                      .map((e) => activityRow(
                                            e.action,
                                            e.user,
                                            e.time.toString(),
                                          ))
                                      .toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                      final right = Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("System Backup",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 10),
                            Text("Last backup: July 20, 2024, 4:00 PM",
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                    fontSize: 13)),
                            const SizedBox(height: 15),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/backup');
                              },
                              icon: const Icon(Icons.check_circle,
                                  color: Colors.green),
                              label: const Text("Status: Up to Date",
                                  style: TextStyle(color: Colors.green)),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/backup');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                minimumSize: const Size(double.infinity, 45),
                              ),
                              child: const Text("Initiate New Backup"),
                            ),
                          ],
                        ),
                      );
                      if (isNarrow) {
                        return Column(
                          children: [left, const SizedBox(height: 20), right],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: left),
                          const SizedBox(width: 20),
                          Expanded(flex: 1, child: right),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? CurvyBottomNav(
              currentIndex: 0,
              items: const [
                CurvyNavItem(icon: Icons.dashboard_outlined, label: 'Home'),
                CurvyNavItem(icon: Icons.people, label: 'Users'),
                CurvyNavItem(icon: Icons.verified, label: 'Approvals'),
                CurvyNavItem(icon: Icons.notifications, label: 'Alerts'),
              ],
              onSelected: (i) {
                switch (i) {
                  case 0:
                    break;
                  case 1:
                    Navigator.pushNamed(context, '/users');
                    break;
                  case 2:
                    Navigator.pushNamed(context, '/appointments/approvals');
                    break;
                  case 3:
                    Navigator.pushNamed(context, '/notifications');
                    break;
                }
              },
            )
          : null,
    );
  }

  // Compact stats card (no Expanded) for wrapping layouts
  Widget statCardBox(BuildContext context, String title, String value,
      String change, IconData icon, Color color,
      [VoidCallback? onTap]) {
    final card = Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          Text(value,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(change,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 12)),
        ],
      ),
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }

  // Sidebar Menu Item Widget
  Widget menuItem(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dashboard Stats Card
  Widget statCard(BuildContext context, String title, String value,
      String change, IconData icon, Color color,
      [VoidCallback? onTap]) {
    final card = Container(
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          Text(value,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(change,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 12)),
        ],
      ),
    );
    final wrapped =
        onTap == null ? card : GestureDetector(onTap: onTap, child: card);
    return wrapped;
  }

  // Chart Widget from dynamic data
  Widget patientBarChart(BuildContext context, List<ChartPoint> data) {
    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: true),
        barGroups: List.generate(data.length, (i) {
          final point = data[i];
          return BarChartGroupData(
            x: point.x,
            barRods: [
              BarChartRodData(
                toY: point.y1,
                color: Theme.of(context).colorScheme.primary,
                width: 12,
              ),
              BarChartRodData(
                toY: point.y2,
                color: Theme.of(context).colorScheme.secondary,
                width: 12,
              ),
            ],
          );
        }),
      ),
    );
  }

  // Activity Log Row
  Widget activityRow(String action, String user, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              action,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
          Expanded(
            child: Text(
              user,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
          Expanded(
            child: Text(
              date,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }

  // Action Card
  Widget actionCard(BuildContext context, String title, String desc,
      IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 90),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(height: 8),
            Text(title,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(desc,
                style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
