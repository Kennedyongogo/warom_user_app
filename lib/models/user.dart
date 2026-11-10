class User {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String role;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? departmentId;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.role,
    this.isActive = true,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
    this.departmentId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['ID']?.toString() ?? json['id']?.toString() ?? '',
      name: json['Name'] ?? json['name'] ?? '',
      email: json['Email'] ?? json['email'] ?? '',
      phoneNumber: json['PhoneNumber'] ?? json['phoneNumber'],
      role: json['Role'] ?? json['role'] ?? 'Public User',
      isActive: json['IsActive'] ?? json['isActive'] ?? true,
      lastLogin: json['LastLogin'] != null
          ? DateTime.parse(json['LastLogin'])
          : (json['lastLogin'] != null
              ? DateTime.parse(json['lastLogin'])
              : null),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      departmentId:
          json['DepartmentID']?.toString() ?? json['departmentId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'Name': name,
      'Email': email,
      'PhoneNumber': phoneNumber,
      'Role': role,
      'IsActive': isActive,
      'LastLogin': lastLogin?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'DepartmentID': departmentId,
    };
  }
}
