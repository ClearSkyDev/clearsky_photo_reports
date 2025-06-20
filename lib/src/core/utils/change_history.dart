import '../models/report_change.dart';

class ChangeHistory {
  final List<ReportChange> _changes = [];

  List<ReportChange> get changes => List.unmodifiable(_changes);

  void add(ReportChange change) {
    _changes.add(change);
  }

  ReportChange? undo() {
    if (_changes.isEmpty) return null;
    return _changes.removeLast();
  }

  void clear() => _changes.clear();
}

final ChangeHistory changeHistory = ChangeHistory();
