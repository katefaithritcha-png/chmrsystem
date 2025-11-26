import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/appointment_service.dart';
import 'checkup_results_form.dart';

class PatientHealthRecordsScreen extends StatelessWidget {
  const PatientHealthRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }

    final recordsQuery = FirebaseFirestore.instance
        .collection('patient_health_records')
        .where('patientId', isEqualTo: uid)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Records'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: recordsQuery.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('No health records yet.'));
          }

          final docs = snap.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final m = docs[i].data();
              final type = (m['type'] ?? 'checkup').toString();
              final date = (m['date'] ?? '').toString();
              final summary = (m['summary'] ?? '').toString();
              final resultRef = (m['resultRef'] ?? '').toString();
              final apptId = (m['appointmentId'] ?? '').toString();

              return ListTile(
                leading: Icon(
                  type == 'checkup' ? Icons.medical_information : Icons.note,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(date.isEmpty ? 'Check-up' : date),
                subtitle: Text(
                  summary.isEmpty ? 'Check-up result' : summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openRecordDetails(
                  context,
                  appointmentId: apptId,
                  resultRef: resultRef,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openRecordDetails(
    BuildContext context, {
    required String appointmentId,
    required String resultRef,
  }) async {
    if (appointmentId.isEmpty) return;

    final apptDoc = await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .get();
    final apptData = apptDoc.data();
    if (apptData == null) return;

    final appointment = Appointment(
      id: appointmentId,
      date: (apptData['date'] ?? '').toString(),
      purpose: (apptData['purpose'] ?? '').toString(),
      status: ApptStatus.completed,
      patientName: (apptData['patientName'] ?? '').toString(),
    );

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).canvasColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        builder: (_, scroll) => CheckupResultsForm(
          appointment: appointment,
          readOnly: true,
          scrollController: scroll,
          patientId: (apptData['createdBy'] ?? '').toString(),
        ),
      ),
    );
  }
}
