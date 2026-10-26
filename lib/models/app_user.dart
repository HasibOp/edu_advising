enum UserRole {
  student('Student'),
  instructor('Instructor'),
  admin('Administrator');

  const UserRole(this.label);
  final String label;
}

/// The signed-in account. The role decides which shell opens after login.
class AppUser {
  const AppUser({
    required this.id,
    required this.role,
    required this.name,
    this.isDean = false,
    this.shortName,
  });

  /// Login ID: the student ID, the faculty short form, or "admin".
  final String id;
  final UserRole role;
  final String name;

  /// Dr. MK signs in as an instructor and gets the Dean tools on top.
  final bool isDean;

  /// Faculty short form as written in the routine, e.g. "TRINA".
  final String? shortName;

  bool get isStudent => role == UserRole.student;
  bool get isStaff => role == UserRole.instructor;
  bool get isAdmin => role == UserRole.admin;

  /// Role label shown in the UI and the audit log.
  String get roleLabel => isDean ? 'Dean' : role.label;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        role: UserRole.values.byName(json['role'] as String),
        name: json['name'] as String,
        isDean: json['isDean'] as bool? ?? false,
        shortName: json['shortName'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'name': name,
        'isDean': isDean,
        'shortName': shortName,
      };
}
