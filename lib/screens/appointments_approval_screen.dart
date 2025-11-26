import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/appointment_service.dart';

class AppointmentsApprovalScreen extends StatefulWidget {
  const AppointmentsApprovalScreen({super.key});

  @override
  State<AppointmentsApprovalScreen> createState() =>
      _AppointmentsApprovalScreenState();
}

class _AppointmentsApprovalScreenState
    extends State<AppointmentsApprovalScreen> {
  String _filter = 'All'; // All, Pending, Confirmed, Completed, Declined

  DateTime? _parseAppt(String s) {
    try {
      return DateFormat('yyyy-MM-dd h:mm a').parse(s);
    } catch (_) {
      try {
        return DateTime.parse(s);
      } catch (_) {
        return null;
      }
    }
  }

  bool _canComplete(Appointment it) {
    final dt = _parseAppt(it.date);
    if (dt == null) return false;
    final now = DateTime.now();
    return !now.isBefore(dt);
  }

  void _openCompleteConfirm(Appointment it) {
    final can = _canComplete(it);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Complete Appointment',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Patient: ${it.patientName}'),
              Text('Date & Time: ${it.date}'),
              Text('Purpose: ${it.purpose}'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: can
                          ? () {
                              Navigator.pop(ctx);
                              context
                                  .read<AppointmentService>()
                                  .complete(it.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Appointment marked as completed')),
                              );
                            }
                          : null,
                      child: const Text('Mark as completed'),
                    ),
                  ),
                ],
              ),
              if (!can) ...[
                const SizedBox(height: 8),
                Text(
                  'You can only complete after the scheduled time.',
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AppointmentService>();
    final items = service.items;
    final filtered = items.where((e) {
      switch (_filter) {
        case 'Pending':
          return e.status == ApptStatus.pending;
        case 'Confirmed':
          return e.status == ApptStatus.confirmed;
        case 'Completed':
          return e.status == ApptStatus.completed;
        case 'Declined':
          return e.status == ApptStatus.declined;
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Approvals'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in const [
                    'All',
                    'Pending',
                    'Confirmed',
                    'Completed',
                    'Declined'
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: _filter == f,
                        onSelected: (_) => setState(() => _filter = f),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (_, i) {
                final it = filtered[i];
                return ListTile(
                  leading: const Icon(Icons.event, color: Colors.blueAccent),
                  title: Text('${it.patientName} • ${it.date}'),
                  subtitle: Text(it.purpose),
                  trailing: _actionsFor(it),
                  onTap: () => _openDetails(it),
                );
              },
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemCount: filtered.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionsFor(Appointment it) {
    switch (it.status) {
      case ApptStatus.pending:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () {
                context.read<AppointmentService>().approve(it.id);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Appointment approved')));
              },
              child: const Text('Approve'),
            ),
            TextButton(
              onPressed: () {
                context.read<AppointmentService>().decline(it.id);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Appointment declined')));
              },
              child: const Text('Decline'),
            ),
            IconButton(
              tooltip: 'More',
              icon: const Icon(Icons.more_vert),
              onPressed: () => _openMenu(it),
            ),
          ],
        );
      case ApptStatus.confirmed:
        final can = _canComplete(it);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: can ? () => _openCompleteConfirm(it) : null,
              child: const Text('Mark done'),
            ),
            IconButton(
              tooltip: 'More',
              icon: const Icon(Icons.more_vert),
              onPressed: () => _openMenu(it),
            ),
          ],
        );
      case ApptStatus.completed:
        return const Chip(label: Text('Completed'));
      case ApptStatus.declined:
        return const Chip(label: Text('Declined'));
    }
  }

  void _openMenu(Appointment it) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('View details'),
              onTap: () {
                Navigator.pop(ctx);
                _openDetails(it);
              },
            ),
            if (it.status == ApptStatus.confirmed)
              ListTile(
                leading: const Icon(Icons.done_all),
                title: const Text('Mark as completed'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openCompleteConfirm(it);
                },
              ),
            if (it.status == ApptStatus.pending)
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Decline request',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<AppointmentService>().decline(it.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Appointment declined')));
                },
              ),
          ],
        ),
      ),
    );
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
            const Text('Appointment Request',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Patient: ${it.patientName}'),
            Text('Date & Time: ${it.date}'),
            Text('Purpose: ${it.purpose}'),
            Text('Status: ${it.status.name}'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (it.status == ApptStatus.pending) ...[
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.read<AppointmentService>().decline(it.id);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Appointment declined')));
                    },
                    child: const Text('Decline'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.read<AppointmentService>().approve(it.id);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Appointment approved')));
                    },
                    child: const Text('Approve'),
                  ),
                ],
                if (it.status == ApptStatus.confirmed) ...[
                  OutlinedButton(
                    onPressed: _canComplete(it)
                        ? () {
                            Navigator.pop(ctx);
                            _openCompleteConfirm(it);
                          }
                        : null,
                    child: const Text('Mark done'),
                  ),
                ],
              ],
            )
          ],
        ),
      ),
    );
  }
}
