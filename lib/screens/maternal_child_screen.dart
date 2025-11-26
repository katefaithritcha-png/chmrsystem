import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MaternalChildScreen extends StatefulWidget {
  const MaternalChildScreen({super.key});

  @override
  State<MaternalChildScreen> createState() => _MaternalChildScreenState();
}

class _MaternalChildScreenState extends State<MaternalChildScreen> {
  String _visitCat = 'All'; // All, Prenatal, Postnatal, Classes

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Maternal & Child Health')),
      backgroundColor: const Color(0xFFF5F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, cons) {
                final isMobile = cons.maxWidth < 800;
                Widget prenatal = StreamBuilder<int>(
                  stream: FirebaseFirestore.instance
                      .collection('maternal_child_activities')
                      .where('type', isEqualTo: 'Prenatal')
                      .snapshots()
                      .map((s) => s.size),
                  builder: (context, snap) {
                    final v = snap.data ?? 0;
                    return _Kpi(
                      label: 'Prenatal Visits',
                      value: '$v',
                      icon: Icons.pregnant_woman,
                      color: Colors.pinkAccent,
                      onTap: () => Navigator.pushNamed(context, '/patients'),
                      expanded: !isMobile,
                    );
                  },
                );
                Widget postnatal = StreamBuilder<int>(
                  stream: FirebaseFirestore.instance
                      .collection('maternal_child_activities')
                      .where('type', isEqualTo: 'Postnatal')
                      .snapshots()
                      .map((s) => s.size),
                  builder: (context, snap) {
                    final v = snap.data ?? 0;
                    return _Kpi(
                      label: 'Postnatal Visits',
                      value: '$v',
                      icon: Icons.child_care,
                      color: Colors.deepPurple,
                      onTap: () => Navigator.pushNamed(context, '/patients'),
                      expanded: !isMobile,
                    );
                  },
                );
                Widget fullyImm = StreamBuilder<int>(
                  stream: FirebaseFirestore.instance
                      .collection('immunizations')
                      .where('under1Fully', isEqualTo: true)
                      .snapshots()
                      .map((s) => s.size),
                  builder: (context, snap) {
                    final v = snap.data ?? 0;
                    return _Kpi(
                      label: 'Fully Immunized <1y',
                      value: '$v',
                      icon: Icons.vaccines,
                      color: Colors.teal,
                      onTap: () =>
                          Navigator.pushNamed(context, '/immunization'),
                      expanded: !isMobile,
                    );
                  },
                );
                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      prenatal,
                      const SizedBox(height: 12),
                      postnatal,
                      const SizedBox(height: 12),
                      fullyImm,
                    ],
                  );
                }
                return Row(children: [
                  prenatal,
                  const SizedBox(width: 12),
                  postnatal,
                  const SizedBox(width: 12),
                  fullyImm
                ]);
              },
            ),
            const SizedBox(height: 16),

            // Category chips
            Wrap(
              spacing: 8,
              children: [
                for (final c in const [
                  'All',
                  'Prenatal',
                  'Postnatal',
                  'Classes'
                ])
                  ChoiceChip(
                    label: Text(c),
                    selected: _visitCat == c,
                    onSelected: (_) => setState(() => _visitCat = c),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recent Activities',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: (_visitCat == 'All')
                        ? FirebaseFirestore.instance
                            .collection('maternal_child_activities')
                            .orderBy('createdAt', descending: true)
                            .limit(20)
                            .snapshots()
                        : FirebaseFirestore.instance
                            .collection('maternal_child_activities')
                            .where('type', isEqualTo: _visitCat)
                            .orderBy('createdAt', descending: true)
                            .limit(20)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Text('Failed to load',
                            style: TextStyle(color: Colors.black54));
                      }
                      if (!snapshot.hasData) {
                        return const Text('Loading...',
                            style: TextStyle(color: Colors.black54));
                      }
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Text('No activities yet',
                            style: TextStyle(color: Colors.black54));
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final d = docs[i].data();
                          final t = (d['title'] ?? 'Activity') as String;
                          final sub = (d['subtitle'] ?? '') as String;
                          return ListTile(
                            leading: Icon(Icons.event_available,
                                color: Theme.of(context).colorScheme.primary),
                            title: Text(t),
                            subtitle: Text(sub),
                          );
                        },
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

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool expanded;
  const _Kpi(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      this.onTap,
      this.expanded = true});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(
                  text: value,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, height: 1.1)),
              const TextSpan(text: ' '),
              TextSpan(
                  text: label,
                  style: const TextStyle(color: Colors.black54, fontSize: 14)),
            ]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
    final child = onTap == null ? card : InkWell(onTap: onTap, child: card);
    return expanded ? Expanded(child: child) : child;
  }
}
