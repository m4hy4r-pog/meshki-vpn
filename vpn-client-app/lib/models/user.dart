// lib/models/user.dart
class User {
  final String username;
  final String status;        // "Active", "Expired", etc.
  final int? expiryTimestamp; // Unix timestamp
  final String? downloadUsed;
  final String? uploadUsed;
  final String? totalUsed;
  final String? totalQuota;

  User({
    required this.username,
    required this.status,
    this.expiryTimestamp,
    this.downloadUsed,
    this.uploadUsed,
    this.totalUsed,
    this.totalQuota,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'],
      status: json['status'] ?? 'Unknown',
      expiryTimestamp: json['expiry'],
      downloadUsed: json['download'],
      uploadUsed: json['upload'],
      totalUsed: json['total_used'],
      totalQuota: json['total_quota'],
    );
  }

  String get expiryText {
    if (expiryTimestamp == null) return 'No expiry';
    final date = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp! * 1000);
    return '${date.day}/${date.month}/${date.year}';
  }
}
