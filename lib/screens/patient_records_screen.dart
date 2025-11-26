import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../services/patient_service.dart';
import '../services/consultation_service.dart';
import '../services/appointment_service.dart';
import '../models/common_models.dart';
import 'checkup_results_form.dart';

class PatientRecordsScreen extends StatefulWidget {
  const PatientRecordsScreen({super.key});

  @override
  State<PatientRecordsScreen> createState() => _PatientRecordsScreenState();
}

class _PatientRecordsScreenState extends State<PatientRecordsScreen> {
  final _service = PatientService();
  String _query = '';
  String _sexFilter = 'All'; // All, F, M
  String _sort = 'Name'; // Name, Age
  String _diagCat = 'All'; // Diagnosis category filter
  int? _minAge;
  int? _maxAge;

  @override
  void initState() {
    super.initState();
  }

  void _showDetails(PatientRecord p, {bool isPatient = false}) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          top: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  foregroundColor: cs.onPrimaryContainer,
                  child: Text(p.name.isNotEmpty ? p.name[0] : '?'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(p.id,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.onSurface.withAlpha(140))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(label: Text('Age ${p.age}')),
                Chip(label: Text('Sex ${p.sex}')),
                Chip(label: Text(p.diagnosis)),
              ],
            ),
            const SizedBox(height: 16),
            if (!isPatient)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.playlist_add),
                      label: const Text('Queue consult'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _queueConsult(p);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: 'Edit',
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showEditDialog(p);
                    },
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDelete(p);
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _refresh() {
    // Force rebuild; real-time stream will deliver latest data automatically
    setState(() {});
  }

  Future<void> _queueConsult(PatientRecord p) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Queue Consultation'),
        content: TextField(
          controller: reason,
          decoration:
              const InputDecoration(labelText: 'Reason/Chief complaint'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add to Queue')),
        ],
      ),
    );
    if (ok == true) {
      await ConsultationService().addToQueue(
        patientId: p.id,
        patientName: p.name,
        reason:
            reason.text.trim().isEmpty ? 'Consultation' : reason.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to consultation queue')));
    }
  }

  Future<void> _showAddDialog() async {
    final name = TextEditingController();
    final diagnosis = TextEditingController();
    final age = TextEditingController();
    String sex = 'F';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Patient'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name')),
            TextField(
                controller: age,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number),
            DropdownButtonFormField<String>(
              initialValue: sex,
              items: const [
                DropdownMenuItem(value: 'F', child: Text('Female')),
                DropdownMenuItem(value: 'M', child: Text('Male')),
              ],
              onChanged: (v) => sex = v ?? sex,
              decoration: const InputDecoration(labelText: 'Sex'),
            ),
            TextField(
                controller: diagnosis,
                decoration: const InputDecoration(labelText: 'Diagnosis')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add')),
        ],
      ),
    );
    if (ok == true) {
      await _service.addPatient(name.text.trim(),
          int.tryParse(age.text.trim()) ?? 0, sex, diagnosis.text.trim());
      _refresh();
    }
  }

  Future<void> _showEditDialog(PatientRecord r) async {
    final name = TextEditingController(text: r.name);
    final diagnosis = TextEditingController(text: r.diagnosis);
    final age = TextEditingController(text: r.age.toString());
    String sex = r.sex;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Patient'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name')),
            TextField(
                controller: age,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number),
            DropdownButtonFormField<String>(
              initialValue: sex,
              items: const [
                DropdownMenuItem(value: 'F', child: Text('Female')),
                DropdownMenuItem(value: 'M', child: Text('Male')),
              ],
              onChanged: (v) => sex = v ?? sex,
              decoration: const InputDecoration(labelText: 'Sex'),
            ),
            TextField(
                controller: diagnosis,
                decoration: const InputDecoration(labelText: 'Diagnosis')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) {
      await _service.updatePatient(r.id,
          name: name.text.trim(),
          age: int.tryParse(age.text.trim()) ?? r.age,
          sex: sex,
          diagnosis: diagnosis.text.trim());
      _refresh();
    }
  }

  Future<void> _confirmDelete(PatientRecord r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Patient'),
        content: Text('Delete ${r.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await _service.deletePatient(r.id);
      _refresh();
    }
  }

  Future<void> _openCheckupForm(PatientRecord p) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('appointments')
          .where('patientRecordId', isEqualTo: p.id)
          .orderBy('dateTs', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No linked appointment found for this patient.')),
        );
        return;
      }
      final d = snap.docs.first;
      final m = d.data();
      final statusStr = (m['status'] ?? 'pending').toString();
      ApptStatus status;
      switch (statusStr) {
        case 'confirmed':
          status = ApptStatus.confirmed;
          break;
        case 'completed':
          status = ApptStatus.completed;
          break;
        case 'declined':
          status = ApptStatus.declined;
          break;
        default:
          status = ApptStatus.pending;
      }
      final appt = Appointment(
        id: d.id,
        date: (m['date'] ?? '').toString(),
        purpose: (m['purpose'] ?? '').toString(),
        status: status,
        patientName: (m['patientName'] ?? p.name).toString(),
      );
      final patientId = (m['createdBy'] ?? '').toString();

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        builder: (ctx) => DraggableScrollableSheet(
          expand: false,
          builder: (_, scroll) => CheckupResultsForm(
            appointment: appt,
            readOnly: status == ApptStatus.completed,
            scrollController: scroll,
            patientId: patientId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open check-up form: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.read<AuthProvider?>()?.role ?? 'patient';
    final isPatient = role == 'patient';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Records'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
          PopupMenuButton<String>(
            tooltip: 'Sort',
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'Name', child: Text('Sort by Name')),
              PopupMenuItem(value: 'Age', child: Text('Sort by Age')),
            ],
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      floatingActionButton: isPatient
          ? null
          : FloatingActionButton(
              onPressed: _showAddDialog,
              child: const Icon(Icons.person_add),
            ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('patients').snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('Failed to load patients'));
          }
          if (!snap.hasData) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Loading patient records...'),
                ],
              ),
            );
          }
          final items = snap.data!.docs.map((d) {
            final data = d.data();
            return PatientRecord.fromJson({
              'id': (data['id'] ?? d.id) as String,
              'name': (data['name'] ?? '') as String,
              'age': (data['age'] ?? 0) as int,
              'sex': (data['sex'] ?? '') as String,
              'diagnosis': (data['diagnosis'] ?? '') as String,
            });
          }).toList();
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline,
                      size: 48, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  const Text('No patient records'),
                  const SizedBox(height: 8),
                  if (!isPatient)
                    ElevatedButton.icon(
                      onPressed: _showAddDialog,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add first patient'),
                    ),
                ],
              ),
            );
          }
          // Vaccination demo auto-open removed
          // Filters + search
          String catOf(String dx) {
            final d = dx.toLowerCase();
            if (d.contains('hypert') ||
                d.contains('cvd') ||
                d.contains('cardio')) {
              return 'Cardiovascular';
            }
            if (d.contains('dm') ||
                d.contains('diab') ||
                d.contains('thyroid')) {
              return 'Endocrine';
            }
            if (d.contains('asthma') ||
                d.contains('pneum') ||
                d.contains('copd') ||
                d.contains('resp')) {
              return 'Respiratory';
            }
            if (d.contains('tb') ||
                d.contains('dengue') ||
                d.contains('flu') ||
                d.contains('infect')) {
              return 'Infectious';
            }
            if (d.contains('preg') ||
                d.contains('prenat') ||
                d.contains('postnat')) {
              return 'Maternal/Child';
            }
            return 'Others';
          }

          final filtered = items.where((p) {
            final q = _query.toLowerCase();
            final matchesQ = q.isEmpty ||
                p.name.toLowerCase().contains(q) ||
                p.id.toLowerCase().contains(q) ||
                p.diagnosis.toLowerCase().contains(q);
            final matchesSex =
                _sexFilter == 'All' || p.sex.toUpperCase() == _sexFilter;
            final matchesCat =
                _diagCat == 'All' || catOf(p.diagnosis) == _diagCat;
            final matchesMin = _minAge == null || p.age >= _minAge!;
            final matchesMax = _maxAge == null || p.age <= _maxAge!;
            return matchesQ &&
                matchesSex &&
                matchesCat &&
                matchesMin &&
                matchesMax;
          }).toList();
          if (_sort == 'Name') {
            filtered.sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          } else {
            filtered.sort((a, b) => a.age.compareTo(b.age));
          }

          // Basic renderer with responsive switch
          Widget buildList(List<PatientRecord> list, bool grid) {
            if (!grid) {
              return ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final p = list[i];
                  final cs = Theme.of(context).colorScheme;
                  return ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: cs.primaryContainer,
                      foregroundColor: cs.onPrimaryContainer,
                      child: Text(p.name.isNotEmpty ? p.name[0] : '?'),
                    ),
                    title: Text('${p.name} (${p.id})'),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Chip(
                            label: Text('Age ${p.age}'),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            backgroundColor: cs.secondaryContainer,
                          ),
                          Chip(
                            label: Text('Sex ${p.sex}'),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            backgroundColor: cs.secondaryContainer,
                          ),
                          Chip(
                            label: Text(p.diagnosis),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            backgroundColor: cs.surfaceContainerHighest,
                          ),
                        ],
                      ),
                    ),
                    trailing: isPatient
                        ? const SizedBox.shrink()
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Check-up results',
                                icon: const Icon(Icons.medical_information),
                                onPressed: () => _openCheckupForm(p),
                              ),
                              IconButton(
                                tooltip: 'Queue consult',
                                icon: const Icon(Icons.playlist_add),
                                onPressed: () => _queueConsult(p),
                              ),
                              IconButton(
                                tooltip: 'Edit',
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditDialog(p),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDelete(p),
                              ),
                            ],
                          ),
                    onTap: () => _showDetails(p, isPatient: isPatient),
                  );
                },
              );
            }
            // Grid cards on wide layout
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 3.2,
              ),
              itemCount: list.length,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemBuilder: (context, i) {
                final p = list[i];
                return InkWell(
                  onTap: () => _showDetails(p, isPatient: isPatient),
                  child: _PatientCard(
                    record: p,
                    isPatient: isPatient,
                    onQueue: () => _queueConsult(p),
                    onEdit: () => _showEditDialog(p),
                    onDelete: () => _confirmDelete(p),
                  ),
                );
              },
            );
          }

          // Category grouping removed per request; show one flat list

          return Column(
            children: [
              _FiltersBar(
                initialQuery: _query,
                sexFilter: _sexFilter,
                diagCategory: _diagCat,
                minAge: _minAge,
                maxAge: _maxAge,
                onQueryChanged: (v) => setState(() => _query = v),
                onSexChanged: (v) => setState(() => _sexFilter = v),
                onDiagCategoryChanged: (v) => setState(() => _diagCat = v),
                onAgeChanged: (min, max) => setState(() {
                  _minAge = min;
                  _maxAge = max;
                }),
                total: items.length,
                shown: filtered.length,
              ),
              const Divider(height: 1),
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, c) {
                    final isWide = c.maxWidth >= 900;
                    return RefreshIndicator(
                      onRefresh: () async => _refresh(),
                      child: buildList(filtered, isWide),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Vaccination demo UI removed per request.

class _PatientCard extends StatelessWidget {
  final PatientRecord record;
  final bool isPatient;
  final VoidCallback onQueue;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PatientCard({
    required this.record,
    required this.isPatient,
    required this.onQueue,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              child: Text(record.name.isNotEmpty ? record.name[0] : '?'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${record.name} (${record.id})',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Chip(
                        label: Text('Age ${record.age}'),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        backgroundColor: cs.secondaryContainer,
                      ),
                      Chip(
                        label: Text('Sex ${record.sex}'),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        backgroundColor: cs.secondaryContainer,
                      ),
                      Chip(
                        label: Text(record.diagnosis),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        backgroundColor: cs.surfaceContainerHighest,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isPatient) ...[
              IconButton(
                tooltip: 'Queue consult',
                icon: const Icon(Icons.playlist_add),
                onPressed: onQueue,
              ),
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FiltersBar extends StatefulWidget {
  final String initialQuery;
  final String sexFilter;
  final String diagCategory;
  final int? minAge;
  final int? maxAge;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onSexChanged;
  final ValueChanged<String> onDiagCategoryChanged;
  final void Function(int? min, int? max) onAgeChanged;
  final int total;
  final int shown;
  const _FiltersBar({
    required this.initialQuery,
    required this.sexFilter,
    required this.diagCategory,
    required this.minAge,
    required this.maxAge,
    required this.onQueryChanged,
    required this.onSexChanged,
    required this.onDiagCategoryChanged,
    required this.onAgeChanged,
    required this.total,
    required this.shown,
  });

  @override
  State<_FiltersBar> createState() => _FiltersBarState();
}

class _FiltersBarState extends State<_FiltersBar> {
  late final TextEditingController _ctrl;
  late final TextEditingController _minAgeCtrl;
  late final TextEditingController _maxAgeCtrl;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialQuery);
    _minAgeCtrl = TextEditingController(text: widget.minAge?.toString() ?? '');
    _maxAgeCtrl = TextEditingController(text: widget.maxAge?.toString() ?? '');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _minAgeCtrl.dispose();
    _maxAgeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(
                    hintText: 'Search name, ID, diagnosis...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (v) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 250), () {
                      widget.onQueryChanged(v);
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              ToggleButtons(
                borderRadius: BorderRadius.circular(8),
                isSelected: [
                  widget.sexFilter == 'All',
                  widget.sexFilter == 'F',
                  widget.sexFilter == 'M'
                ],
                onPressed: (i) {
                  final v = ['All', 'F', 'M'][i];
                  widget.onSexChanged(v);
                  setState(() {});
                },
                children: const [
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('All')),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('F')),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('M')),
                ],
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _minAgeCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(hintText: 'Min', isDense: true),
                  onChanged: (_) {
                    final min = int.tryParse(_minAgeCtrl.text.trim());
                    final max = int.tryParse(_maxAgeCtrl.text.trim());
                    widget.onAgeChanged(min, max);
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _maxAgeCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(hintText: 'Max', isDense: true),
                  onChanged: (_) {
                    final min = int.tryParse(_minAgeCtrl.text.trim());
                    final max = int.tryParse(_maxAgeCtrl.text.trim());
                    widget.onAgeChanged(min, max);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Builder(
                builder: (context) {
                  final hasFilters = _ctrl.text.isNotEmpty ||
                      widget.sexFilter != 'All' ||
                      widget.diagCategory != 'All' ||
                      _minAgeCtrl.text.isNotEmpty ||
                      _maxAgeCtrl.text.isNotEmpty;
                  if (!hasFilters) return const SizedBox.shrink();
                  return TextButton(
                    onPressed: () {
                      _ctrl.text = '';
                      _minAgeCtrl.text = '';
                      _maxAgeCtrl.text = '';
                      widget.onQueryChanged('');
                      widget.onSexChanged('All');
                      widget.onDiagCategoryChanged('All');
                      widget.onAgeChanged(null, null);
                      setState(() {});
                    },
                    child: const Text('Clear'),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final cat in const [
                'All',
                'Cardiovascular',
                'Endocrine',
                'Respiratory',
                'Infectious',
                'Maternal/Child',
              ])
                ChoiceChip(
                  label: Text(cat),
                  selected: widget.diagCategory == cat,
                  onSelected: (_) {
                    widget.onDiagCategoryChanged(cat);
                    setState(() {});
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Showing ${widget.shown} of ${widget.total} records',
              style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
