import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../services/health_record_service.dart';

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({super.key});

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  final _service = HealthRecordService();

  Future<void> _addRecord({String? patientId}) async {
    final title = TextEditingController();
    final notes = TextEditingController();
    String type = 'Consultation';
    DateTime? date;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Health Record'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: type,
                items: const [
                  DropdownMenuItem(
                      value: 'Consultation', child: Text('Consultation')),
                  DropdownMenuItem(value: 'Lab', child: Text('Lab')),
                  DropdownMenuItem(value: 'Imaging', child: Text('Imaging')),
                  DropdownMenuItem(
                      value: 'Medication', child: Text('Medication')),
                ],
                onChanged: (v) => type = v ?? type,
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event),
                      label: Text(date == null
                          ? 'Pick date'
                          : '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}'),
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: now,
                          firstDate: DateTime(now.year - 5),
                          lastDate: DateTime(now.year + 5),
                        );
                        if (picked != null) {
                          setState(() => date = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notes,
                decoration: const InputDecoration(labelText: 'Notes'),
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
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
      final payload = {
        'title': title.text.trim(),
        'type': type,
        'date': date,
        'notes': notes.text.trim(),
      };
      await _service.addRecord(record: payload, patientId: patientId);
    }
  }

  Future<void> _editRecord(String id, Map<String, dynamic> data) async {
    final title = TextEditingController(text: (data['title'] ?? '') as String);
    final notes = TextEditingController(text: (data['notes'] ?? '') as String);
    String type = (data['type'] ?? 'Consultation') as String;
    DateTime? date = (data['date'] as Timestamp?)?.toDate();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Record'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: type,
                items: const [
                  DropdownMenuItem(
                      value: 'Consultation', child: Text('Consultation')),
                  DropdownMenuItem(value: 'Lab', child: Text('Lab')),
                  DropdownMenuItem(value: 'Imaging', child: Text('Imaging')),
                  DropdownMenuItem(
                      value: 'Medication', child: Text('Medication')),
                ],
                onChanged: (v) => type = v ?? type,
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event),
                      label: Text(date == null
                          ? 'Pick date'
                          : '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}'),
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: date ?? now,
                          firstDate: DateTime(now.year - 5),
                          lastDate: DateTime(now.year + 5),
                        );
                        if (picked != null) {
                          setState(() => date = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notes,
                decoration: const InputDecoration(labelText: 'Notes'),
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
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
      final updates = {
        'title': title.text.trim(),
        'type': type,
        'date': date,
        'notes': notes.text.trim(),
      };
      await _service.updateRecord(id, updates);
    }
  }

  Future<void> _deleteRecord(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this record?'),
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
      await _service.deleteRecord(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<app_auth.AuthProvider>().role ?? 'patient';
    final isPatient = role == 'patient';
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final stream = isPatient
        ? _service.streamMyRecords(limit: 300)
        : _service.streamAllRecords(limit: 300);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Records'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (isPatient) {
            await _addRecord();
          } else {
            final pidCtrl = TextEditingController();
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Target Patient UID'),
                content: TextField(
                    controller: pidCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Patient UID')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Continue')),
                ],
              ),
            );
            if (ok == true && pidCtrl.text.trim().isNotEmpty) {
              await _addRecord(patientId: pidCtrl.text.trim());
            }
          }
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('Failed to load records'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No records'));
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data();
              final title = (data['title'] ?? 'Record') as String;
              final type = (data['type'] ?? '') as String;
              final notes = (data['notes'] ?? '') as String;
              final ts = (data['date'] as Timestamp?)?.toDate();
              final patientId = (data['patientId'] ?? '') as String;
              final canEditOrDelete =
                  (!isPatient) || (patientId.isNotEmpty && patientId == uid);
              return ListTile(
                leading: Icon(Icons.folder,
                    color: Theme.of(context).colorScheme.primary),
                title: Text(title),
                subtitle: Text(
                    '${type.isNotEmpty ? '$type • ' : ''}${ts != null ? '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}' : ''}\n$notes'
                        .trim()),
                isThreeLine: notes.isNotEmpty,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isPatient)
                      Tooltip(
                        message: 'Patient: $patientId',
                        child: const Icon(Icons.badge),
                      ),
                    if (canEditOrDelete)
                      IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editRecord(d.id, data)),
                    if (canEditOrDelete)
                      IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteRecord(d.id)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
