import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/appointment_service.dart';
import '../services/appointment_results_service.dart';

class CheckupResultsForm extends StatefulWidget {
  const CheckupResultsForm({
    super.key,
    required this.appointment,
    required this.readOnly,
    this.scrollController,
    required this.patientId,
  });

  final Appointment appointment;
  final bool readOnly;
  final ScrollController? scrollController;
  final String patientId;

  @override
  State<CheckupResultsForm> createState() => _CheckupResultsFormState();
}

class _CheckupResultsFormState extends State<CheckupResultsForm> {
  final _formKey = GlobalKey<FormState>();

  // Vital signs
  final _bpCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _pulseCtrl = TextEditingController();
  final _respCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _spo2Ctrl = TextEditingController();

  // Case info
  final _symptomsCtrl = TextEditingController();
  final _findingsCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // Treatment
  final _medsCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _followUpCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final existing = await AppointmentResultsService.instance
        .getByAppointmentId(widget.appointment.id);
    if (existing != null) {
      _bpCtrl.text = existing.bp ?? '';
      _tempCtrl.text =
          existing.temperature != null ? existing.temperature.toString() : '';
      _pulseCtrl.text = existing.pulse?.toString() ?? '';
      _respCtrl.text = existing.respiratoryRate?.toString() ?? '';
      _weightCtrl.text =
          existing.weight != null ? existing.weight.toString() : '';
      _heightCtrl.text =
          existing.height != null ? existing.height.toString() : '';
      _spo2Ctrl.text = existing.spo2?.toString() ?? '';

      _symptomsCtrl.text = existing.symptoms ?? '';
      _findingsCtrl.text = existing.clinicalFindings ?? '';
      _diagnosisCtrl.text = existing.diagnosis ?? '';
      _notesCtrl.text = existing.notes ?? '';

      _medsCtrl.text = existing.medications ?? '';
      _dosageCtrl.text = existing.dosage ?? '';
      _instructionsCtrl.text = existing.instructions ?? '';
      _followUpCtrl.text = existing.followUpDate ?? '';
      _referralCtrl.text = existing.referral ?? '';
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _bpCtrl.dispose();
    _tempCtrl.dispose();
    _pulseCtrl.dispose();
    _respCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _spo2Ctrl.dispose();
    _symptomsCtrl.dispose();
    _findingsCtrl.dispose();
    _diagnosisCtrl.dispose();
    _notesCtrl.dispose();
    _medsCtrl.dispose();
    _dosageCtrl.dispose();
    _instructionsCtrl.dispose();
    _followUpCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFollowUpDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: now.add(const Duration(days: 7)),
    );
    if (picked != null) {
      _followUpCtrl.text = picked.toLocal().toString().split(' ').first;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final workerId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

    final result = AppointmentResult(
      appointmentId: widget.appointment.id,
      patientId: widget.patientId,
      patientName: widget.appointment.patientName,
      workerId: workerId,
      dateTime: widget.appointment.date,
      bp: _bpCtrl.text.trim().isEmpty ? null : _bpCtrl.text.trim(),
      temperature: double.tryParse(_tempCtrl.text.trim()),
      pulse: int.tryParse(_pulseCtrl.text.trim()),
      respiratoryRate: int.tryParse(_respCtrl.text.trim()),
      weight: double.tryParse(_weightCtrl.text.trim()),
      height: double.tryParse(_heightCtrl.text.trim()),
      spo2: int.tryParse(_spo2Ctrl.text.trim()),
      symptoms:
          _symptomsCtrl.text.trim().isEmpty ? null : _symptomsCtrl.text.trim(),
      clinicalFindings:
          _findingsCtrl.text.trim().isEmpty ? null : _findingsCtrl.text.trim(),
      diagnosis: _diagnosisCtrl.text.trim().isEmpty
          ? null
          : _diagnosisCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      medications: _medsCtrl.text.trim().isEmpty ? null : _medsCtrl.text.trim(),
      dosage: _dosageCtrl.text.trim().isEmpty ? null : _dosageCtrl.text.trim(),
      instructions: _instructionsCtrl.text.trim().isEmpty
          ? null
          : _instructionsCtrl.text.trim(),
      followUpDate:
          _followUpCtrl.text.trim().isEmpty ? null : _followUpCtrl.text.trim(),
      referral:
          _referralCtrl.text.trim().isEmpty ? null : _referralCtrl.text.trim(),
    );

    await AppointmentResultsService.instance.saveForAppointment(result);

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Results saved and appointment completed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final readOnly = widget.readOnly;

    return SafeArea(
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                readOnly ? 'Check-Up Results' : 'Add Check-Up Results',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Appointment ID: ${widget.appointment.id}',
                  style: TextStyle(color: Theme.of(context).hintColor)),
              Text('Patient: ${widget.appointment.patientName}'),
              Text('Date & Time: ${widget.appointment.date}'),
              Text(
                  'Worker ID: ${FirebaseAuth.instance.currentUser?.uid ?? ''}'),
              const SizedBox(height: 16),

              // Vital Signs
              Text('Vital Signs',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 150,
                    child: TextFormField(
                      controller: _bpCtrl,
                      enabled: !readOnly,
                      decoration:
                          const InputDecoration(labelText: 'Blood Pressure'),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: TextFormField(
                      controller: _tempCtrl,
                      enabled: !readOnly,
                      decoration: const InputDecoration(labelText: 'Temp (°C)'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: TextFormField(
                      controller: _pulseCtrl,
                      enabled: !readOnly,
                      decoration:
                          const InputDecoration(labelText: 'Pulse (bpm)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: TextFormField(
                      controller: _respCtrl,
                      enabled: !readOnly,
                      decoration:
                          const InputDecoration(labelText: 'Respiratory Rate'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: TextFormField(
                      controller: _weightCtrl,
                      enabled: !readOnly,
                      decoration:
                          const InputDecoration(labelText: 'Weight (kg)'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: TextFormField(
                      controller: _heightCtrl,
                      enabled: !readOnly,
                      decoration:
                          const InputDecoration(labelText: 'Height (cm)'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: TextFormField(
                      controller: _spo2Ctrl,
                      enabled: !readOnly,
                      decoration: const InputDecoration(labelText: 'SpO₂ (%)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Case Info
              Text('Patient Case Information',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _symptomsCtrl,
                enabled: !readOnly,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Symptoms'),
              ),
              TextFormField(
                controller: _findingsCtrl,
                enabled: !readOnly,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Clinical Findings'),
              ),
              TextFormField(
                controller: _diagnosisCtrl,
                enabled: !readOnly,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Diagnosis'),
              ),
              TextFormField(
                controller: _notesCtrl,
                enabled: !readOnly,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes / Remarks'),
              ),

              const SizedBox(height: 16),

              // Treatment
              Text('Treatment / Plan',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _medsCtrl,
                enabled: !readOnly,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Prescribed medications'),
              ),
              TextFormField(
                controller: _dosageCtrl,
                enabled: !readOnly,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Dosage'),
              ),
              TextFormField(
                controller: _instructionsCtrl,
                enabled: !readOnly,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Instructions'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _followUpCtrl,
                      enabled: !readOnly,
                      readOnly: true,
                      decoration: const InputDecoration(
                          labelText: 'Follow-up date (optional)'),
                      onTap: readOnly ? null : _pickFollowUpDate,
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _referralCtrl,
                enabled: !readOnly,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Referral (optional)'),
              ),

              const SizedBox(height: 16),

              // Uploads (UI only, file handling to be wired later)
              Text('Uploads', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (!readOnly) ...[
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: hook to file picker + storage
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Upload lab results'),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Upload prescriptions'),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.image),
                  label: const Text('Upload medical images'),
                ),
              ],

              const SizedBox(height: 20),
              if (!readOnly)
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Save Results'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
