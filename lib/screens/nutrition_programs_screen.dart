import 'package:flutter/material.dart';
import '../core/responsive/responsive_helper.dart';
import '../core/responsive/responsive_text.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NutritionProgramsScreen extends StatefulWidget {
  const NutritionProgramsScreen({super.key});

  @override
  State<NutritionProgramsScreen> createState() =>
      _NutritionProgramsScreenState();
}

class _NutritionProgramsScreenState extends State<NutritionProgramsScreen> {
  bool _underOnly = false;
  String _section = 'all';

  bool _isUnderweight(double heightM, double weightKg) {
    final bmi = weightKg / (heightM * heightM);
    return bmi < 18.5; // demo threshold
  }

  void _addSupplement({String? presetName}) {
    final who = TextEditingController(text: presetName ?? '');
    final what = TextEditingController();
    final qty = TextEditingController(text: '1');
    final date = TextEditingController();
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
              const Text('Record Supplement Given',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                  controller: who,
                  decoration: const InputDecoration(
                      labelText: 'Beneficiary', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(
                  controller: what,
                  decoration: const InputDecoration(
                      labelText: 'Supplement', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(
                  controller: qty,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Quantity', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(
                  controller: date,
                  decoration: const InputDecoration(
                      labelText: 'Date (YYYY-MM-DD)',
                      border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('nutrition_supplements')
                        .add({
                      'who': who.text.trim(),
                      'what': what.text.trim(),
                      'qty': int.tryParse(qty.text.trim()) ?? 1,
                      'date': date.text.trim(),
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (!ctx.mounted) return;
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

  void _addBeneficiary() {
    final name = TextEditingController();
    final age = TextEditingController();
    final height = TextEditingController();
    final weight = TextEditingController();
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
              const Text('Add Beneficiary',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                  controller: name,
                  decoration: const InputDecoration(
                      labelText: 'Name', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(
                  controller: age,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Age (years)', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(
                  controller: height,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Height (meters)',
                      border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(
                  controller: weight,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Weight (kg)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('nutrition_beneficiaries')
                        .add({
                      'name': name.text.trim(),
                      'age': int.tryParse(age.text.trim()) ?? 0,
                      'heightM': double.tryParse(height.text.trim()) ?? 0,
                      'weightKg': double.tryParse(weight.text.trim()) ?? 0,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (!ctx.mounted) return;
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
    final role = context.read<AuthProvider?>()?.role ?? 'patient';
    final isPatient = role == 'patient';
    // Counts are derived via streams below

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Programs'),
        actions: [
          if (!isPatient)
            IconButton(
                onPressed: _addBeneficiary,
                tooltip: 'Add Beneficiary',
                icon: const Icon(Icons.person_add_alt_1)),
        ],
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, cons) {
                final isMobile = cons.maxWidth < 800;
                Widget kpiBeneficiaries = StreamBuilder<int>(
                  stream: FirebaseFirestore.instance
                      .collection('nutrition_beneficiaries')
                      .snapshots()
                      .map((s) => s.size),
                  builder: (context, snap) => _Kpi(
                    label: 'Beneficiaries',
                    value: '${snap.data ?? 0}',
                    icon: Icons.group,
                    color: Colors.blue,
                    onTap: () => setState(() {
                      _underOnly = false;
                      _section = 'beneficiaries';
                    }),
                    expanded: !isMobile,
                  ),
                );
                Widget kpiUnder = StreamBuilder<int>(
                  stream: FirebaseFirestore.instance
                      .collection('nutrition_beneficiaries')
                      .snapshots()
                      .map((s) => s.docs.where((d) {
                            final h = (d.data()['heightM'] ?? 0).toDouble();
                            final w = (d.data()['weightKg'] ?? 0).toDouble();
                            return _isUnderweight(h, w);
                          }).length),
                  builder: (context, snap) => _Kpi(
                    label: 'Underweight Cases',
                    value: '${snap.data ?? 0}',
                    icon: Icons.scale_outlined,
                    color: Colors.orange,
                    onTap: () => setState(() {
                      _underOnly = true;
                      _section = 'underweight';
                    }),
                    expanded: !isMobile,
                  ),
                );
                Widget kpiSupp = StreamBuilder<int>(
                  stream: FirebaseFirestore.instance
                      .collection('nutrition_supplements')
                      .snapshots()
                      .map((s) => s.docs.fold<int>(0,
                          (acc, e) => acc + ((e.data()['qty'] ?? 0) as int))),
                  builder: (context, snap) => _Kpi(
                    label: 'Supplements Given',
                    value: '${snap.data ?? 0}',
                    icon: Icons.local_pharmacy_outlined,
                    color: Colors.green,
                    onTap: () => setState(() {
                      _section = 'supplements';
                    }),
                    expanded: !isMobile,
                  ),
                );
                if (isMobile) {
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        kpiBeneficiaries,
                        const SizedBox(height: 12),
                        kpiUnder,
                        const SizedBox(height: 12),
                        kpiSupp,
                      ]);
                }
                return Row(children: [
                  kpiBeneficiaries,
                  const SizedBox(width: 12),
                  kpiUnder,
                  const SizedBox(width: 12),
                  kpiSupp
                ]);
              },
            ),
            const SizedBox(height: 16),
            if (_section == 'all' ||
                _section == 'beneficiaries' ||
                _section == 'underweight')
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Beneficiaries',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        FilterChip(
                          label: const Text('Underweight only'),
                          selected:
                              _section == 'underweight' ? true : _underOnly,
                          onSelected: (v) => setState(() {
                            _underOnly = v;
                            _section = v ? 'underweight' : 'beneficiaries';
                          }),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('nutrition_beneficiaries')
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
                        var docs = snap.data!.docs;
                        if (_section == 'underweight' || _underOnly) {
                          docs = docs.where((d) {
                            final h = (d.data()['heightM'] ?? 0).toDouble();
                            final w = (d.data()['weightKg'] ?? 0).toDouble();
                            return _isUnderweight(h, w);
                          }).toList();
                        }
                        if (docs.isEmpty) {
                          return const Text('No beneficiaries yet',
                              style: TextStyle(color: Colors.black54));
                        }
                        return Column(children: [
                          ...docs.map((doc) {
                            final b = doc.data();
                            final name = (b['name'] ?? '') as String;
                            final age = (b['age'] ?? 0).toString();
                            final h = (b['heightM'] ?? 0).toDouble();
                            final w = (b['weightKg'] ?? 0).toDouble();
                            final bmi = h > 0 ? w / (h * h) : 0.0;
                            final uw = _isUnderweight(h, w);
                            return Column(children: [
                              ListTile(
                                leading: CircleAvatar(
                                    child: Text(name.isEmpty
                                        ? '?'
                                        : name.substring(0, 1))),
                                title: Text(name),
                                subtitle: Text(
                                    'Age: $age  •  BMI: ${bmi.toStringAsFixed(1)}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (uw)
                                      const Chip(
                                          label: Text('Underweight'),
                                          backgroundColor: Color(0xFFFFF3E0)),
                                    if (!isPatient)
                                      IconButton(
                                        tooltip: 'Give supplement',
                                        icon: const Icon(
                                            Icons.local_pharmacy_outlined,
                                            color: Colors.green),
                                        onPressed: () =>
                                            _addSupplement(presetName: name),
                                      ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                            ]);
                          }),
                        ]);
                      },
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (_section == 'all')
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.all(16),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent Activities',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('No recent activities yet',
                        style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (_section == 'all' || _section == 'supplements')
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Supplements Given',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('nutrition_supplements')
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
                        final docs = snap.data!.docs;
                        if (docs.isEmpty) {
                          return const Text('No supplements recorded',
                              style: TextStyle(color: Colors.black54));
                        }
                        return Column(children: [
                          ...docs.map((d) {
                            final s = d.data();
                            return Column(children: [
                              ListTile(
                                leading: const Icon(Icons.local_pharmacy,
                                    color: Colors.green),
                                title: Text('${s['what']} x${s['qty']}'),
                                subtitle: Text('${s['who']} • ${s['date']}'),
                              ),
                              const Divider(height: 1),
                            ]);
                          }),
                        ]);
                      },
                    ),
                    const SizedBox(height: 8),
                    if (!isPatient)
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => _addSupplement(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Entry'),
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
