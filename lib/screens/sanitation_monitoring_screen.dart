import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SanitationMonitoringScreen extends StatefulWidget {
  const SanitationMonitoringScreen({super.key});

  @override
  State<SanitationMonitoringScreen> createState() =>
      _SanitationMonitoringScreenState();
}

class _SanitationMonitoringScreenState
    extends State<SanitationMonitoringScreen> {
  String _section = 'all'; // all | households | water | toilet

  void _addInspection() {
    final hh = TextEditingController();
    bool water = false;
    bool toilet = false;
    final notes = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New Household Inspection',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: hh,
                decoration: const InputDecoration(
                    labelText: 'Household / Address',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  StatefulBuilder(builder: (c, setS) {
                    return Checkbox(
                        value: water,
                        onChanged: (v) => setS(() => water = v ?? false));
                  }),
                  const Text('Safe water'),
                  const SizedBox(width: 16),
                  StatefulBuilder(builder: (c, setS) {
                    return Checkbox(
                        value: toilet,
                        onChanged: (v) => setS(() => toilet = v ?? false));
                  }),
                  const Text('Functional toilet'),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notes,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Notes', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('sanitation_inspections')
                        .add({
                      'hh': hh.text.trim(),
                      'water': water,
                      'toilet': toilet,
                      'notes': notes.text.trim(),
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (!mounted) return;
                    // ignore: use_build_context_synchronously
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Environmental & Sanitation'),
        actions: [
          IconButton(
              onPressed: _addInspection,
              tooltip: 'Add Inspection',
              icon: const Icon(Icons.add_task)),
        ],
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPIs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                SizedBox(
                  width: 240,
                  child: _Kpi(
                    label: 'Households Inspected',
                    value: '',
                    icon: Icons.home_outlined,
                    color: Colors.blue,
                    expanded: false,
                    onTap: () => setState(() => _section = 'households'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 240,
                  child: _Kpi(
                    label: 'Safe Water',
                    value: '',
                    icon: Icons.water_drop_outlined,
                    color: Colors.teal,
                    expanded: false,
                    onTap: () => setState(() => _section = 'water'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 240,
                  child: _Kpi(
                    label: 'Functional Toilets',
                    value: '',
                    icon: Icons.wc,
                    color: Colors.green,
                    expanded: false,
                    onTap: () => setState(() => _section = 'toilet'),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // Checklist
            Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Household Inspections',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      if (_section != 'all')
                        TextButton(
                          onPressed: () => setState(() => _section = 'all'),
                          child: const Text('Show All'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('sanitation_inspections')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return const Text('Failed to load',
                            style: TextStyle(color: Colors.black54));
                      }
                      if (!snap.hasData) {
                        return const Text('Loading...',
                            style: TextStyle(color: Colors.black54));
                      }
                      final all = snap.data!.docs.map((d) => d.data()).toList();
                      Iterable<Map<String, dynamic>> filtered = all;
                      if (_section == 'water') {
                        filtered = filtered.where((e) => e['water'] == true);
                      } else if (_section == 'toilet') {
                        filtered = filtered.where((e) => e['toilet'] == true);
                      }
                      if (filtered.isEmpty) {
                        return const Text('No inspections yet',
                            style: TextStyle(color: Colors.black54));
                      }
                      return Column(
                        children: [
                          ...filtered.map((e) => Column(children: [
                                ListTile(
                                  leading: Icon(Icons.home_outlined,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  title: Text(e['hh'] as String? ?? ''),
                                  subtitle: Text(
                                      '${(e['water'] == true) ? 'Safe water' : 'No safe water'} • ${(e['toilet'] == true) ? 'Functional toilet' : 'No toilet'}\n${e['notes'] ?? ''}'),
                                  isThreeLine: true,
                                ),
                                const Divider(height: 1),
                              ])),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: _addInspection,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Inspection'),
                    ),
                  )
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
  final bool expanded;
  final VoidCallback? onTap;
  const _Kpi(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      this.expanded = true,
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
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ]),
        ],
      ),
    );
    final child = onTap == null ? card : InkWell(onTap: onTap, child: card);
    return expanded ? Expanded(child: child) : child;
  }
}
