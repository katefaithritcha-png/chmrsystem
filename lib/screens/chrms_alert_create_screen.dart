import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/chrms_alerts_service.dart';

class ChrmsAlertCreateScreen extends StatefulWidget {
  const ChrmsAlertCreateScreen({super.key});

  @override
  State<ChrmsAlertCreateScreen> createState() => _ChrmsAlertCreateScreenState();
}

class _ChrmsAlertCreateScreenState extends State<ChrmsAlertCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _attachmentCtrl = TextEditingController();

  String _category = 'HEALTH_ADVISORY';
  String _priority = 'NORMAL';
  String _targetMode = 'ALL';
  final Set<String> _targetGroups = <String>{};

  DateTime _startAt = DateTime.now();
  DateTime? _expiresAt;
  bool _sending = false;

  final _service = ChrmsAlertsService();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    _attachmentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startAt,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startAt),
    );
    if (time == null) return;
    if (!mounted) return;
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
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_expiresAt ?? now),
    );
    if (time == null) return;
    if (!mounted) return;
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

      final attachments = _attachmentCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      await _service.createAlert({
        'title': _titleCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        'category': _category,
        'priority': _priority,
        'targetMode': _targetMode,
        'targetGroups': _targetGroups.toList(),
        // Future: targetHouseholdId, targetUserIds
        'expiresAt': _expiresAt != null
            ? Timestamp.fromDate(_expiresAt!)
            : Timestamp.fromDate(_startAt.add(const Duration(days: 30))),
        'startAt': Timestamp.fromDate(_startAt),
        'attachments': attachments,
        'createdByRole': role,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert created and sent')),
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
        title: const Text('New CHRMS Alert'),
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
                  labelText: 'Message / Description',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    dropdownColor: Colors.white,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'HEALTH_ADVISORY',
                          child: Text('Health Advisory')),
                      DropdownMenuItem(
                          value: 'IMMUNIZATION',
                          child: Text('Immunization Schedule')),
                      DropdownMenuItem(
                          value: 'MEDICINE', child: Text('Medicine Pickup')),
                      DropdownMenuItem(
                          value: 'BARANGAY',
                          child: Text('Barangay Announcement')),
                      DropdownMenuItem(
                          value: 'EMERGENCY', child: Text('Emergency Alert')),
                      DropdownMenuItem(
                          value: 'APPOINTMENT',
                          child: Text('Follow-up Appointment')),
                      DropdownMenuItem(
                          value: 'WORKER',
                          child: Text('Worker Notification (internal)')),
                    ],
                    onChanged: (v) =>
                        setState(() => _category = v ?? 'HEALTH_ADVISORY'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _priority,
                    dropdownColor: Colors.white,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'NORMAL', child: Text('Normal')),
                      DropdownMenuItem(
                          value: 'IMPORTANT', child: Text('Important')),
                      DropdownMenuItem(value: 'URGENT', child: Text('Urgent')),
                    ],
                    onChanged: (v) => setState(() => _priority = v ?? 'NORMAL'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Target Audience',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ChoiceChip(
                    label: const Text('All Patients'),
                    selected: _targetMode == 'ALL',
                    onSelected: (_) => setState(() => _targetMode = 'ALL'),
                  ),
                  ChoiceChip(
                    label: const Text('Specific Group'),
                    selected: _targetMode == 'GROUP',
                    onSelected: (_) => setState(() => _targetMode = 'GROUP'),
                  ),
                  ChoiceChip(
                    label: const Text('Specific Household'),
                    selected: _targetMode == 'HOUSEHOLD',
                    onSelected: (_) =>
                        setState(() => _targetMode = 'HOUSEHOLD'),
                  ),
                  ChoiceChip(
                    label: const Text('Specific Individual'),
                    selected: _targetMode == 'INDIVIDUAL',
                    onSelected: (_) =>
                        setState(() => _targetMode = 'INDIVIDUAL'),
                  ),
                  ChoiceChip(
                    label: const Text('Health Workers Only'),
                    selected: _targetMode == 'WORKERS',
                    onSelected: (_) => setState(() => _targetMode = 'WORKERS'),
                  ),
                ],
              ),
              if (_targetMode == 'GROUP') ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _groupChip('SENIORS', 'Seniors'),
                    _groupChip('PREGNANT', 'Pregnant Women'),
                    _groupChip('CHILDREN', 'Children'),
                  ],
                ),
              ],
              const SizedBox(height: 16),
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
                            ? 'No expiry (defaults to +30 days)'
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _attachmentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Attachments (URLs, comma-separated)',
                  border: OutlineInputBorder(),
                ),
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

  Widget _groupChip(String value, String label) {
    final selected = _targetGroups.contains(value);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) {
        setState(() {
          if (v) {
            _targetGroups.add(value);
          } else {
            _targetGroups.remove(value);
          }
        });
      },
    );
  }
}
