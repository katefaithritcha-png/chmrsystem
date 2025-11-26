import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../services/health_alerts_service.dart';

class HealthAlertCreateScreen extends StatefulWidget {
  const HealthAlertCreateScreen({super.key});

  @override
  State<HealthAlertCreateScreen> createState() =>
      _HealthAlertCreateScreenState();
}

class _HealthAlertCreateScreenState extends State<HealthAlertCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _type = 'ADVISORY';
  String _priority = 'MEDIUM';
  bool _sending = false;
  DateTime _startAt = DateTime.now();
  DateTime? _expiresAt;

  final _service = HealthAlertsService();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startAt,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (!context.mounted) return;
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startAt),
    );
    if (!context.mounted) return;
    if (time == null) return;
    setState(() {
      _startAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (!context.mounted) return;
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_expiresAt ?? now),
    );
    if (!context.mounted) return;
    if (time == null) return;
    setState(() {
      _expiresAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      final auth = context.read<AuthProvider?>();
      final role = auth?.role ?? 'worker';
      await _service.createAlert({
        'title': _titleCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        'type': _type,
        'priority': _priority,
        'startAt': Timestamp.fromDate(_startAt),
        if (_expiresAt != null) 'expiresAt': Timestamp.fromDate(_expiresAt!),
        'status': 'ACTIVE',
        'targetMode': 'ALL',
        'targetGroups': <String>[],
        'targetZones': <String>[],
        'targetUserIds': <String>[],
        'createdByRole': role,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Health alert created')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create alert: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Health Alert'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _type,
                      dropdownColor: Theme.of(context).cardColor,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'EMERGENCY', child: Text('Emergency')),
                        DropdownMenuItem(
                            value: 'ADVISORY', child: Text('Advisory')),
                        DropdownMenuItem(
                            value: 'REMINDER', child: Text('Reminder')),
                        DropdownMenuItem(
                            value: 'HEALTH_TIP', child: Text('Health Tip')),
                      ],
                      onChanged: (v) => setState(() => _type = v ?? 'ADVISORY'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _priority,
                      dropdownColor: Theme.of(context).cardColor,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'LOW', child: Text('Low')),
                        DropdownMenuItem(
                            value: 'MEDIUM', child: Text('Medium')),
                        DropdownMenuItem(value: 'HIGH', child: Text('High')),
                      ],
                      onChanged: (v) =>
                          setState(() => _priority = v ?? 'MEDIUM'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickStart,
                      icon: const Icon(Icons.schedule),
                      label: Text(
                          'Start: ${_startAt.toString().split('.').first}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickExpiry,
                      icon: const Icon(Icons.event_busy),
                      label: Text(
                        _expiresAt == null
                            ? 'No expiry'
                            : 'Expires: ${_expiresAt.toString().split('.').first}',
                      ),
                    ),
                  ),
                  if (_expiresAt != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Clear expiry',
                      onPressed: () => setState(() => _expiresAt = null),
                      icon: const Icon(Icons.clear),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sending ? null : _submit,
                  icon: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(_sending ? 'Sending...' : 'Send Alert'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
