import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DiseaseControlScreen extends StatelessWidget {
  const DiseaseControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Disease Prevention & Control')),
      backgroundColor: const Color(0xFFF5F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, cons) {
                final isMobile = cons.maxWidth < 800;
                final kpi = StreamBuilder<int>(
                  stream: FirebaseFirestore.instance
                      .collection('disease_activities')
                      .where('type', isEqualTo: 'TB_DOTS')
                      .snapshots()
                      .map((s) => s.size),
                  builder: (context, snap) {
                    final v = snap.data ?? 0;
                    return _Kpi(
                      label: 'TB Patients on DOTS',
                      value: '$v',
                      icon: Icons.biotech_outlined,
                      color: Colors.deepPurple,
                      onTap: () => Navigator.pushNamed(context, '/patients'),
                      expanded: !isMobile,
                    );
                  },
                );
                if (isMobile) {
                  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [kpi]);
                }
                return Row(children: [kpi]);
              },
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recent Activities', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('disease_activities')
                        .orderBy('createdAt', descending: true)
                        .limit(20)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Text('Failed to load', style: TextStyle(color: Colors.black54));
                      }
                      if (!snapshot.hasData) {
                        return const Text('Loading...', style: TextStyle(color: Colors.black54));
                      }
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Text('No activities yet', style: TextStyle(color: Colors.black54));
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
                            leading: Icon(Icons.biotech_outlined, color: Theme.of(context).colorScheme.primary),
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
              TextSpan(text: value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.1)),
              const TextSpan(text: ' '),
              TextSpan(text: label, style: const TextStyle(color: Colors.black54, fontSize: 14)),
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
