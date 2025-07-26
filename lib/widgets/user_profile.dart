class UserProfile {
  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime createdAt;
  final String department;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.department,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      createdAt: DateTime.parse(json['created_at']),
      department: json['department'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'department': department,
    };
  }
}
