class Attendance {
  final int id;
  final int trainerId;
  final int scannedBy;
  final DateTime scanTime;
  final String date;
  final Map<String, dynamic>? trainer; // Add trainer info
  final Map<String, dynamic>? admin; // Add admin info

  Attendance({
    required this.id,
    required this.trainerId,
    required this.scannedBy,
    required this.scanTime,
    required this.date,
    this.trainer,
    this.admin,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      trainerId: json['trainer_id'],
      scannedBy: json['scanned_by'],
      scanTime: DateTime.parse(json['scan_time']),
      date: json['date'],
      trainer: json['trainer'],
      admin: json['admin'],
    );
  }
}
