import 'dart:async';
import '../models/common_models.dart';

class BackupService {
  BackupStatus _status = BackupStatus(lastBackup: DateTime.now().subtract(const Duration(days: 3)), inProgress: false, progress: 0);

  Future<BackupStatus> getStatus() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _status;
  }

  Stream<BackupStatus> startBackup() async* {
    if (_status.inProgress) {
      yield _status;
      return;
    }
    _status = BackupStatus(lastBackup: _status.lastBackup, inProgress: true, progress: 0);
    yield _status;
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      _status = BackupStatus(lastBackup: _status.lastBackup, inProgress: true, progress: i / 10);
      yield _status;
    }
    _status = BackupStatus(lastBackup: DateTime.now(), inProgress: false, progress: 1);
    yield _status;
  }
}
