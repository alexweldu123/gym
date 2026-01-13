class SubscriptionPackage {
  final int id;
  final String name;
  final int durationDays;
  final double price;

  SubscriptionPackage({
    required this.id,
    required this.name,
    required this.durationDays,
    required this.price,
  });

  factory SubscriptionPackage.fromJson(Map<String, dynamic> json) {
    return SubscriptionPackage(
      id: json['id'],
      name: json['name'],
      durationDays: json['duration_days'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class User {
  final int id;
  final String name;
  final String email;
  final String role;

  final int? assignedTrainerId;
  final String? membershipStatus;
  final String? profilePicture;
  final SubscriptionPackage? package;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.assignedTrainerId,
    this.membershipStatus,
    this.profilePicture,
    this.package,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      assignedTrainerId: json['assigned_trainer_id'],
      membershipStatus: json['membership_status'],
      profilePicture: json['profile_picture'],
      package: json['package'] != null
          ? SubscriptionPackage.fromJson(json['package'])
          : null,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff';
  bool get isTrainer => role == 'trainer';
  bool get isMember => role == 'member';
}
