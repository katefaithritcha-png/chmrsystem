import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import '../services/audit_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _db = FirebaseFirestore.instance;
  final _collections = <String>{
    'users',
    'patients',
    'consultations',
    'threads',
    'patient_updates',
    'audit',
  };
  final _selected = <String>{'users', 'patients', 'consultations'};
  DateTime? _start;
  DateTime? _end;
  bool _busy = false;
  String? _status;

  // Import state
  final _importJsonCtrl = TextEditingController();
  String _importTarget = 'patients';
  bool _dryRun = true;

  @override
  void dispose() {
    _importJsonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDate: (isStart ? _start : _end) ?? now,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = DateTime(picked.year, picked.month, picked.day);
        } else {
          _end = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
    }
  }

  Future<void> _saveBytes(Uint8List bytes, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$filename';
    final f = File(path);
    await f.writeAsBytes(bytes, flush: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved: $path')));
  }

  Future<List<Map<String, dynamic>>> _fetchCollection(String name) async {
    Query<Map<String, dynamic>> q = _db.collection(name);
    // Try common timestamp fields for date filtering
    if (_start != null) {
      q = q.where(_tsField(name), isGreaterThanOrEqualTo: Timestamp.fromDate(_start!));
    }
    if (_end != null) {
      q = q.where(_tsField(name), isLessThanOrEqualTo: Timestamp.fromDate(_end!));
    }
    final snap = await q.limit(2000).get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  String _tsField(String name) {
    // Heuristics for timestamp field names
    if (name == 'audit') return 'at';
    if (name == 'threads') return 'updatedAt';
    return 'createdAt';
  }

  Future<void> _exportJson() async {
    if (_busy) return;
    setState(() { _busy = true; _status = 'Exporting JSON...'; });
    try {
      final out = <String, dynamic>{
        'generatedAt': DateTime.now().toIso8601String(),
        'range': {
          'start': _start?.toIso8601String(),
          'end': _end?.toIso8601String(),
        },
        'data': <String, dynamic>{},
      };
      for (final c in _selected) {
        final rows = await _fetchCollection(c);
        out['data'][c] = rows;
      }
      final bytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(out));
      final fname = 'backup_${DateTime.now().millisecondsSinceEpoch}.json';
      await _saveBytes(Uint8List.fromList(bytes), fname);
      setState(() { _status = 'Exported $fname'; });
      await AuditService().addEvent(actorRole: 'admin', actorId: 'admin', action: 'backup_export', details: 'collections=${_selected.join(',')}');
    } catch (e) {
      setState(() { _status = 'Export failed: $e'; });
    } finally {
      setState(() { _busy = false; });
    }
  }

  Future<void> _exportCsv() async {
    if (_busy) return;
    setState(() { _busy = true; _status = 'Exporting CSV...'; });
    try {
      for (final c in _selected) {
        final rows = await _fetchCollection(c);
        if (rows.isEmpty) continue;
        final headers = rows.first.keys.toList();
        final buf = StringBuffer();
        buf.writeln(headers.join(','));
        for (final r in rows) {
          buf.writeln(headers.map((h) => _csvEscape(r[h])).join(','));
        }
        final bytes = utf8.encode(buf.toString());
        final fname = 'backup_${c}_${DateTime.now().millisecondsSinceEpoch}.csv';
        await _saveBytes(Uint8List.fromList(bytes), fname);
      }
      setState(() { _status = 'CSV export complete'; });
      await AuditService().addEvent(actorRole: 'admin', actorId: 'admin', action: 'backup_export_csv', details: 'collections=${_selected.join(',')}');
    } catch (e) {
      setState(() { _status = 'Export failed: $e'; });
    } finally {
      setState(() { _busy = false; });
    }
  }

  String _csvEscape(dynamic v) {
    final s = (v ?? '').toString();
    final needs = s.contains(',') || s.contains('"') || s.contains('\n');
    if (!needs) return s;
    return '"${s.replaceAll('"', '""')}"';
  }

  Future<void> _openImportDialog() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Import JSON', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _importTarget,
                items: _collections.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _importTarget = v ?? _importTarget),
              ),
              Row(children: [
                Checkbox(value: _dryRun, onChanged: (v) => setState(() => _dryRun = v ?? true)),
                const Text('Dry-run (no writes)'),
              ]),
              TextField(
                controller: _importJsonCtrl,
                minLines: 6,
                maxLines: 12,
                decoration: const InputDecoration(hintText: 'Paste JSON array of documents, e.g. [{"id":"...","field":"value"}]', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _import,
                  icon: const Icon(Icons.upload),
                  label: const Text('Import'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _import() async {
    final data = _importJsonCtrl.text.trim();
    if (data.isEmpty) return;
    setState(() { _busy = true; _status = 'Parsing import...'; });
    try {
      final parsed = json.decode(data);
      if (parsed is! List) {
        setState(() { _status = 'JSON must be an array of documents'; });
        return;
      }
      final docs = parsed.cast<dynamic>();
      // Preview errors
      int ok = 0; int bad = 0;
      for (final d in docs) {
        if (d is Map && d.containsKey('id')) {
          ok++;
        } else {
          bad++;
        }
      }
      if (_dryRun) {
        setState(() { _status = 'Dry-run: $ok valid, $bad invalid'; });
        return;
      }
      // Write in batches
      setState(() { _status = 'Writing $ok docs to $_importTarget...'; });
      WriteBatch batch = _db.batch();
      int count = 0; int wrote = 0;
      for (final d in docs) {
        if (d is! Map || !d.containsKey('id')) continue;
        final id = d['id'] as String;
        final dataMap = Map<String, dynamic>.from(d)..remove('id');
        batch.set(_db.collection(_importTarget).doc(id), dataMap, SetOptions(merge: true));
        count++; wrote++;
        if (count >= 400) {
          await batch.commit();
          batch = _db.batch();
          count = 0;
        }
      }
      if (count > 0) await batch.commit();
      setState(() { _status = 'Import complete: wrote $wrote docs.'; });
      await AuditService().addEvent(actorRole: 'admin', actorId: 'admin', action: 'backup_import', details: 'target=$_importTarget wrote=$wrote');
    } catch (e) {
      setState(() { _status = 'Import failed: $e'; });
    } finally {
      setState(() { _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Backup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Collections selection
            const Text('Collections', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _collections.map((c) {
                final sel = _selected.contains(c);
                return FilterChip(
                  label: Text(c),
                  selected: sel,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _selected.add(c);
                      } else {
                        _selected.remove(c);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Date range
            const Text('Date Range (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(_start == null ? 'Start date' : _start!.toIso8601String().substring(0,10)),
                onPressed: () => _pickDate(isStart: true),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(_end == null ? 'End date' : _end!.toIso8601String().substring(0,10)),
                onPressed: () => _pickDate(isStart: false),
              ),
            ]),
            const SizedBox(height: 16),
            // Actions
            Row(children: [
              ElevatedButton.icon(
                onPressed: _busy ? null : _exportJson,
                icon: const Icon(Icons.save_alt),
                label: const Text('Export JSON'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _busy ? null : _exportCsv,
                icon: const Icon(Icons.table_chart),
                label: const Text('Export CSVs'),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _busy ? null : _openImportDialog,
                icon: const Icon(Icons.upload_file),
                label: const Text('Import (JSON)'),
              ),
            ]),
            const SizedBox(height: 12),
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            if (_status != null) Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_status!, style: const TextStyle(color: Colors.black87)),
            ),
          ],
        ),
      ),
    );
  }
}
