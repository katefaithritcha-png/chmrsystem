import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/appointment_service.dart';
import '../core/responsive/responsive_helper.dart';
import '../core/responsive/responsive_text.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _PurposeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _PurposeTile(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        child: Icon(icon),
      ),
      title: Text(label),
      trailing: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: selected ? cs.primary : null),
      onTap: onTap,
    );
  }
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  String _filter = 'All'; // All, Pending, Confirmed, Completed

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AppointmentService>();
    final items = service.items;
    final responsivePadding = ResponsiveHelper.getResponsivePadding(context);
    final responsiveSpacing = ResponsiveHelper.getResponsiveSpacing(context);

    final filtered = items.where((e) {
      switch (_filter) {
        case 'Pending':
          return e.status == ApptStatus.pending;
        case 'Confirmed':
          return e.status == ApptStatus.confirmed;
        case 'Completed':
          return e.status == ApptStatus.completed;
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const ResponsiveHeading2('Appointments'),
        actions: [
          IconButton(
            tooltip: 'New appointment',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showCreateAppointmentSheet(
              context,
              onAdd: (date, purpose, notes) {
                context.read<AppointmentService>().create(
                      date: date,
                      purpose: purpose,
                      patientName: 'Patient',
                      notes: notes,
                    );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: responsivePadding,
            child: Wrap(
              spacing: responsiveSpacing,
              children: [
                for (final f in const [
                  'All',
                  'Pending',
                  'Confirmed',
                  'Completed'
                ])
                  ChoiceChip(
                    label: Text(f),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: responsivePadding,
              itemBuilder: (_, i) {
                final it = filtered[i];
                return ListTile(
                  leading:
                      const Icon(Icons.event_note, color: Colors.blueAccent),
                  title: Text(it.date),
                  subtitle: Text(it.purpose),
                  trailing: _statusChip(it.status),
                  onTap: () => _openDetails(it),
                );
              },
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemCount: filtered.length,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateAppointmentSheet(
          context,
          onAdd: (date, purpose, notes) {
            context.read<AppointmentService>().create(
                  date: date,
                  purpose: purpose,
                  patientName: 'Patient',
                  notes: notes,
                );
          },
        ),
        icon: const Icon(Icons.event_available),
        label: const Text('Create'),
      ),
    );
  }

  Widget _statusChip(ApptStatus status) {
    switch (status) {
      case ApptStatus.pending:
        return const Chip(label: Text('Pending'));
      case ApptStatus.confirmed:
        return const Chip(label: Text('Confirmed'));
      case ApptStatus.completed:
        return const Chip(label: Text('Completed'));
      case ApptStatus.declined:
        return const Chip(label: Text('Declined'));
    }
  }

  void _openDetails(Appointment it) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Appointment Details',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Date & Time: ${it.date}'),
            Text('Purpose: ${it.purpose}'),
            Text('Status: ${it.status.name}'),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Patient view is read-only for status transitions
              ],
            )
          ],
        ),
      ),
    );
  }
}

void _showCreateAppointmentSheet(BuildContext context,
    {required void Function(String date, String purpose, String notes) onAdd}) {
  // Step state
  int step = 0; // 0: purpose, 1: date/time, 2: summary
  final purposeCtrl = TextEditingController(text: 'General Check-up');
  final notesCtrl = TextEditingController();
  String selectedPurpose = 'General Check-up';
  DateTime today = DateTime.now();
  DateTime firstDay = DateTime(today.year, today.month, today.day);
  DateTime lastDay = firstDay.add(const Duration(days: 180));
  DateTime? selectedDate = firstDay;
  String? selectedSlot;
  final slots = <String>[
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '01:00 PM',
    '01:30 PM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
  ];
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    clipBehavior: Clip.antiAlias,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 12,
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.85,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 8),
                      const Text('Request an Appointment',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Step indicator
                  Row(
                    children: [
                      Expanded(
                          child:
                              LinearProgressIndicator(value: (step + 1) / 3)),
                      const SizedBox(width: 12),
                      Text('Step ${step + 1} of 3',
                          style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Step content
                  if (step == 0) ...[
                    const Row(
                      children: [
                        Icon(Icons.assignment_outlined, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Step 1: Select Purpose',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _PurposeTile(
                            label: 'General Check-up',
                            icon: Icons.medical_services_outlined,
                            selected: selectedPurpose == 'General Check-up',
                            onTap: () => setLocal(() {
                              selectedPurpose = 'General Check-up';
                              purposeCtrl.text = selectedPurpose;
                            }),
                          ),
                          _PurposeTile(
                            label: 'Immunization',
                            icon: Icons.vaccines_outlined,
                            selected: selectedPurpose == 'Immunization',
                            onTap: () => setLocal(() {
                              selectedPurpose = 'Immunization';
                              purposeCtrl.text = selectedPurpose;
                            }),
                          ),
                          _PurposeTile(
                            label: 'Prenatal Care',
                            icon: Icons.pregnant_woman,
                            selected: selectedPurpose == 'Prenatal Care',
                            onTap: () => setLocal(() {
                              selectedPurpose = 'Prenatal Care';
                              purposeCtrl.text = selectedPurpose;
                            }),
                          ),
                          _PurposeTile(
                            label: 'BP Monitoring',
                            icon: Icons.favorite_outline,
                            selected: selectedPurpose == 'BP Monitoring',
                            onTap: () => setLocal(() {
                              selectedPurpose = 'BP Monitoring';
                              purposeCtrl.text = selectedPurpose;
                            }),
                          ),
                          _PurposeTile(
                            label: 'Follow-up Visit',
                            icon: Icons.autorenew,
                            selected: selectedPurpose == 'Follow-up Visit',
                            onTap: () => setLocal(() {
                              selectedPurpose = 'Follow-up Visit';
                              purposeCtrl.text = selectedPurpose;
                            }),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.more_horiz),
                            title: const Text('Other'),
                            trailing: Icon(selectedPurpose == 'Other'
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked),
                            onTap: () =>
                                setLocal(() => selectedPurpose = 'Other'),
                          ),
                          if (selectedPurpose == 'Other')
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: TextField(
                                controller: purposeCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Enter purpose',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ] else if (step == 1) ...[
                    const Row(
                      children: [
                        Icon(Icons.event_available, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Choose a Date',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: CalendarDatePicker(
                        initialDate: selectedDate ?? firstDay,
                        firstDate: firstDay,
                        lastDate: lastDay,
                        onDateChanged: (d) => setLocal(() => selectedDate = d),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Select an Available Time',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final s in slots)
                            ChoiceChip(
                              label: Text(s),
                              selected: selectedSlot == s,
                              onSelected: (sel) =>
                                  setLocal(() => selectedSlot = sel ? s : null),
                            ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Review & Confirm',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Purpose: ${purposeCtrl.text}'),
                          const SizedBox(height: 6),
                          Text(
                              'Date: ${selectedDate == null ? '-' : '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'}'),
                          const SizedBox(height: 6),
                          Text('Time: ${selectedSlot ?? '-'}'),
                          const SizedBox(height: 12),
                          TextField(
                            controller: notesCtrl,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Additional Notes (Optional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (step > 0)
                        OutlinedButton(
                          onPressed: () => setLocal(() => step -= 1),
                          child: const Text('Back'),
                        ),
                      if (step > 0) const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            if (step == 0) {
                              if ((selectedPurpose != 'Other' &&
                                      selectedPurpose.isEmpty) ||
                                  (selectedPurpose == 'Other' &&
                                      purposeCtrl.text.trim().isEmpty)) {
                                return;
                              }
                              setLocal(() => step = 1);
                            } else if (step == 1) {
                              if (selectedDate == null ||
                                  selectedSlot == null) {
                                return;
                              }
                              setLocal(() => step = 2);
                            } else {
                              if (selectedDate == null ||
                                  selectedSlot == null) {
                                return;
                              }
                              final dateStr =
                                  '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')} $selectedSlot';
                              Navigator.pop(ctx);
                              onAdd(dateStr, purposeCtrl.text.trim(),
                                  notesCtrl.text.trim());
                            }
                          },
                          child: Text(step < 2 ? 'Next' : 'Confirm Request'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
