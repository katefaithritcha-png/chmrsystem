import 'package:flutter/material.dart';
import '../core/responsive/responsive_helper.dart';
import '../core/responsive/responsive_text.dart';
import '../services/consultation_service.dart';

class ConsultationFormScreen extends StatelessWidget {
  const ConsultationFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final complaintCtrl = TextEditingController();
    final vitalsCtrl = TextEditingController();
    final assessmentCtrl = TextEditingController();
    final planCtrl = TextEditingController();

    Future<void> save() async {
      final args = ModalRoute.of(context)?.settings.arguments;
      final id = (args is Map && args['docId'] is String)
          ? args['docId'] as String
          : null;
      final dx = assessmentCtrl.text.trim().isEmpty
          ? 'N/A'
          : assessmentCtrl.text.trim();
      try {
        if (id != null) {
          await ConsultationService().completeConsultation(
            id,
            diagnosis: dx,
            complaint: complaintCtrl.text.trim(),
            vitals: vitalsCtrl.text.trim(),
            plan: planCtrl.text.trim(),
          );
        }
        if (!context.mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consultation saved')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Consultation'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: save),
        ],
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chief Complaint',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
                controller: complaintCtrl,
                minLines: 1,
                maxLines: 3,
                decoration:
                    const InputDecoration(border: OutlineInputBorder())),
            const SizedBox(height: 12),
            const Text('Vitals', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
                controller: vitalsCtrl,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                    hintText: 'BP, HR, Temp, RR',
                    border: OutlineInputBorder())),
            const SizedBox(height: 12),
            const Text('Assessment',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
                controller: assessmentCtrl,
                minLines: 2,
                maxLines: 5,
                decoration:
                    const InputDecoration(border: OutlineInputBorder())),
            const SizedBox(height: 12),
            const Text('Plan/Orders',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
                controller: planCtrl,
                minLines: 2,
                maxLines: 5,
                decoration:
                    const InputDecoration(border: OutlineInputBorder())),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                  onPressed: save,
                  icon: const Icon(Icons.save),
                  label: const Text('Save')),
            ),
          ],
        ),
      ),
    );
  }
}
