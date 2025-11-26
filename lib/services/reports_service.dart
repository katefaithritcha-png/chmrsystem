import 'dart:async';
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import '../models/common_models.dart';

class ReportsService {
  final List<ReportSummary> _reports = [];

  Future<List<ReportSummary>> fetchReports({String range = 'week'}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List<ReportSummary>.from(_reports);
  }

  Future<ReportSummary> generateReport({String range = 'week'}) async {
    await Future.delayed(const Duration(seconds: 1));
    final id = 'R-${1000 + _reports.length + 1}';
    final now = DateTime.now();
    // Very simple synthesized metrics; in real app, aggregate from services/DB
    final base = _reports.length;
    final mul = range == 'day' ? 1 : range == 'week' ? 5 : 20;
    final rep = ReportSummary(
        id: id,
        title: '${range[0].toUpperCase()}${range.substring(1)} Report',
        createdAt: now,
        metrics: {
          'New Patients': 5 * mul + base,
          'Appointments': 12 * mul + base * 3,
          'Admissions': 1 * mul + (base % 4),
          'Discharges': 1 * mul + (base % 5),
          'Pending Approvals': (base % 6) + (range == 'day' ? 2 : 4),
          'Immunizations Due': 2 * mul + (base % 7),
          'Notifications Sent': 10 * mul + base * 2,
          'Unread Messages': (base % 10) + (range == 'day' ? 5 : 12),
          'Audit Actions': 6 * mul + (base % 8),
          'Backups Completed': range == 'month' ? 4 : range == 'week' ? 1 : 0,
          'Outbreak Alerts': base % (range == 'day' ? 2 : 3),
          'Follow-ups Scheduled': 3 * mul + (base % 9),
          'Visits Today': range == 'day' ? 30 + base : 6 * mul + base,
        });
    _reports.insert(0, rep);
    return rep;
  }

  // ---- Exports ----
  Future<Uint8List> exportReportPdf(ReportSummary rep) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (ctx) => [
          pw.Text(rep.title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text('Created: ${rep.createdAt}'),
          pw.SizedBox(height: 16),
          pw.Text('Key Metrics', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const ['Metric', 'Value'],
            data: rep.metrics.entries.map((e) => [e.key, e.value.toString()]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );
    return doc.save();
  }

  Future<Uint8List> exportReportCsv(ReportSummary rep) async {
    final buf = StringBuffer();
    buf.writeln('Title,${_escape(rep.title)}');
    buf.writeln('Created,${rep.createdAt.toIso8601String()}');
    buf.writeln();
    buf.writeln('Metric,Value');
    for (final e in rep.metrics.entries) {
      buf.writeln('${_escape(e.key)},${_escape(e.value.toString())}');
    }
    return Uint8List.fromList(buf.toString().codeUnits);
  }

  String _escape(String s) {
    final needs = s.contains(',') || s.contains('"') || s.contains('\n');
    if (!needs) return s;
    return '"${s.replaceAll('"', '""')}"';
  }
}
