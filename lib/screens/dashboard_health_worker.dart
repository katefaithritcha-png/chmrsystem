import 'package:flutter/material.dart';
import '../core/responsive/responsive_helper.dart';
import '../core/responsive/responsive_text.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/creative_dashboard.dart';
import '../widgets/curvy_bottom_nav.dart';

class DashboardHealthWorker extends StatelessWidget {
  const DashboardHealthWorker({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 800;
    // Optional program modules removed
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Row(
          children: [
            Icon(Icons.health_and_safety,
                color: Theme.of(context).colorScheme.onPrimary),
            const SizedBox(width: 8),
            Text(
              "HealthSphere",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const Spacer(),
          ],
        ),
        actions: [
          if (!isMobile)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 320,
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .secondaryContainer
                        .withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: "Search patients...",
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Notifications',
            icon: Icon(Icons.notifications,
                color: Theme.of(context).colorScheme.onPrimary),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: Icon(Icons.logout,
                color: Theme.of(context).colorScheme.onPrimary),
            onPressed: () {
              context.read<app_auth.AuthProvider>().logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (r) => false);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: isMobile
          ? null
          : Drawer(
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Menu',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ListTile(
                      leading: Icon(Icons.dashboard,
                          color: Theme.of(context).colorScheme.primary),
                      title: const Text('Dashboard'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacementNamed(context, '/worker');
                      },
                    ),
                    ExpansionTile(
                      leading: Icon(Icons.people_outline,
                          color: Theme.of(context).colorScheme.primary),
                      title: const Text('Patient Services'),
                      children: [
                        ListTile(
                          leading: Icon(Icons.assignment_add,
                              color: Theme.of(context).colorScheme.primary),
                          title: const Text('Patient Data Entry'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/patients');
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.description,
                              color: Theme.of(context).colorScheme.primary),
                          title: const Text('Consultation Records'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/consultation');
                          },
                        ),
                        // Health Records removed for health workers
                        ListTile(
                          leading: Icon(Icons.inventory_2_outlined,
                              color: Theme.of(context).colorScheme.primary),
                          title: const Text('Medicine Inventory'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/inventory');
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.event_available,
                              color: Theme.of(context).colorScheme.primary),
                          title: const Text('Appointment Approvals'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(
                                context, '/appointments/approvals');
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.people_alt_outlined,
                              color: Theme.of(context).colorScheme.primary),
                          title: const Text('Population Tracking'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/population');
                          },
                        ),
                      ],
                    ),
                    // Programs section removed
                    // Removed Reports & Alerts category from drawer
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
                  const Text("Menu",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        menuItem(context, Icons.dashboard, "Dashboard", () {
                          Navigator.pushReplacementNamed(context, '/worker');
                        }),
                        ExpansionTile(
                          leading: Icon(Icons.people_outline,
                              color: Theme.of(context).colorScheme.primary),
                          title: const Text('Patient Services'),
                          childrenPadding: const EdgeInsets.only(
                              left: 8, right: 8, bottom: 8),
                          children: [
                            menuItem(context, Icons.assignment_add,
                                "Patient Data Entry", () {
                              Navigator.pushNamed(context, '/patients');
                            }),
                            menuItem(context, Icons.description,
                                "Consultation Records", () {
                              Navigator.pushNamed(context, '/consultation');
                            }),
                            // Health Records removed for health workers
                            menuItem(context, Icons.inventory_2_outlined,
                                "Medicine Inventory", () {
                              Navigator.pushNamed(context, '/inventory');
                            }),
                            menuItem(context, Icons.event_available,
                                "Appointment Approvals", () {
                              Navigator.pushNamed(
                                  context, '/appointments/approvals');
                            }),
                            menuItem(context, Icons.people_alt_outlined,
                                "Population Tracking", () {
                              Navigator.pushNamed(context, '/population');
                            }),
                          ],
                        ),
                        // Programs section removed
                        // Removed Reports & Alerts category from sidebar
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
                      shape: const StadiumBorder(),
                    ),
                  ),
                ],
              ),
            ),

          // MAIN DASHBOARD CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CreativeHeader(
                    title: 'Welcome',
                    subtitle:
                        "Your HealthSphere workspace — view tasks, approvals and patient activity.",
                    leadingIcon: Icons.medical_services_outlined,
                  ),
                  const SizedBox(height: 16),
                  // KPI Cards (live from Firestore) - 2 per row on most widths
                  LayoutBuilder(
                    builder: (context, cons) {
                      final maxW = cons.maxWidth;
                      double tileWidth;

                      // Prefer 2 tiles per row; fall back to 1 only on very
                      // narrow screens to avoid overflow.
                      if (maxW >= 380) {
                        tileWidth = (maxW - 12) / 2; // two tiles per row
                      } else {
                        tileWidth = maxW; // single column for extra-narrow
                      }

                      tileWidth = tileWidth.clamp(160, 460);

                      final tiles = <Widget>[
                        SizedBox(
                          width: tileWidth,
                          child: _kpiCard(
                            context,
                            icon: Icons.event_available,
                            title: 'Pending Approvals',
                            stream: FirebaseFirestore.instance
                                .collection('appointments')
                                .where('status', isEqualTo: 'pending')
                                .snapshots()
                                .map((s) => s.size),
                            onTap: () => Navigator.pushNamed(
                                context, '/appointments/approvals'),
                          ),
                        ),
                        SizedBox(
                          width: tileWidth,
                          child: _kpiCard(
                            context,
                            icon: Icons.people_alt,
                            title: 'Patients',
                            stream: FirebaseFirestore.instance
                                .collection('patients')
                                .snapshots()
                                .map((s) => s.size),
                            onTap: () =>
                                Navigator.pushNamed(context, '/patients'),
                          ),
                        ),
                      ];

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: tiles,
                      );
                    },
                  ),
                  const SizedBox(height: 30),

                  // Quick Access Modules
                  Text("Quick Access Modules",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, cons) {
                      final tileWidth =
                          cons.maxWidth < 800 ? cons.maxWidth : 260.0;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: tileWidth,
                            child: moduleCard(
                                context,
                                Icons.assignment_add,
                                "Patient Data Entry",
                                "Record new patient information and update existing health profiles securely.",
                                onTap: () {
                              Navigator.pushNamed(context, '/patients');
                            }),
                          ),
                          SizedBox(
                            width: tileWidth,
                            child: moduleCard(
                                context,
                                Icons.description,
                                "Consultation Records",
                                "Access and manage detailed records of consultations, diagnoses, and treatment plans.",
                                onTap: () {
                              Navigator.pushNamed(context, '/consultation');
                            }),
                          ),
                          // Health Records module removed for health workers
                          // Program tiles removed
                          SizedBox(
                            width: tileWidth,
                            child: moduleCard(
                              context,
                              Icons.inventory_2_outlined,
                              "Medicine Inventory",
                              "Track stock levels, expirations, and issue medicines to patients.",
                              onTap: () {
                                Navigator.pushNamed(context, '/inventory');
                              },
                            ),
                          ),
                          SizedBox(
                            width: tileWidth,
                            child: moduleCard(
                              context,
                              Icons.people_alt_outlined,
                              "Population Tracking",
                              "View live population stats, manage residents and households.",
                              onTap: () {
                                Navigator.pushNamed(context, '/population');
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // Recent Activity
                  Text("Recent Patient Activity",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('patient_messages')
                        .orderBy('createdAt', descending: true)
                        .limit(5)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _emptyCard(context, 'Failed to load activity');
                      }
                      if (!snapshot.hasData) {
                        return _emptyCard(context, 'Loading activity...');
                      }
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return _emptyCard(
                            context, 'No recent patient activity yet.');
                      }
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.separated(
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (_, i) {
                            final d = docs[i].data();
                            final sub = (d['subject'] ?? 'Message') as String;
                            final email = (d['senderEmail'] ?? '') as String;
                            return ListTile(
                              leading: Icon(Icons.mail,
                                  color: Theme.of(context).colorScheme.primary),
                              title: Text(sub),
                              subtitle: Text(email),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // Removed feature banner footer
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
                CurvyNavItem(icon: Icons.people_outline, label: 'Patients'),
                CurvyNavItem(
                    icon: Icons.chat_bubble_outline, label: 'Messages'),
                CurvyNavItem(icon: Icons.verified, label: 'Approvals'),
              ],
              onSelected: (i) {
                switch (i) {
                  case 0:
                    break;
                  case 1:
                    Navigator.pushNamed(context, '/patients');
                    break;
                  case 2:
                    Navigator.pushNamed(context, '/chat');
                    break;
                  case 3:
                    Navigator.pushNamed(context, '/appointments/approvals');
                    break;
                }
              },
            )
          : null,
    );
  }

  // Sidebar Menu Item
  Widget menuItem(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 14),
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

  // Quick Access Module Card
  Widget moduleCard(
      BuildContext context, IconData icon, String title, String description,
      {VoidCallback? onTap}) {
    final card = Container(
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
          Text(description,
              style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ],
      ),
    );
    if (onTap == null) return card;
    return InkWell(onTap: onTap, child: card);
  }

  // Activity Row (responsive, no overflow)
  Widget activityRow(String name, String action, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, color: color, size: 12),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(
                    text: name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' $action'),
                ],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 72),
            child: Text(
              time,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black45, fontSize: 12),
              overflow: TextOverflow.fade,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _kpiCard(BuildContext context,
    {required IconData icon,
    required String title,
    required Stream<int> stream,
    VoidCallback? onTap}) {
  final card = Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: StreamBuilder<int>(
      stream: stream,
      builder: (context, snap) {
        final value = snap.data ?? 0;
        return Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$value',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(title,
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
  if (onTap == null) return card;
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: card,
  );
}

Widget _emptyCard(BuildContext context, String text) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Center(
      child: Text(text, style: const TextStyle(color: Colors.black54)),
    ),
  );
}

// Update composer removed; messaging now handled in Chat screen directly
