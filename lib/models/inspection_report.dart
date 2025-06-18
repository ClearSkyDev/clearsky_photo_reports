import 'photo_entry.dart';

class InspectionReport {
  String jobName;
  String address;
  DateTime date;
  bool synced;
  List<PhotoEntry> photos;

  InspectionReport({
    required this.jobName,
    required this.address,
    required this.date,
    this.synced = false,
    this.photos = const [],
  });
}
