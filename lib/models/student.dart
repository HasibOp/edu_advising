enum ClearanceStatus {
  cleared('Cleared', 'May proceed for advising'),
  special('Special consideration',
      'You are allowed for advising as you have applied/or have special consideration'),
  notCleared('Not cleared',
      'Your ID may be incorrect, or you have not uploaded your bank deposit. '
          'Please upload it to the Bank deposit upload form and wait at least '
          '15 minutes. If you paid via the E-payment portal, there\'s no need '
          'to upload, but wait at least 30 minutes after payment for Accounts '
          'clearance.');

  const ClearanceStatus(this.label, this.remark);
  final String label;

  final String remark;

  bool get canAdvise => this != ClearanceStatus.notCleared;
}

enum ClearanceType {
  auto('Auto (no dues)'),
  paid('Paid required amount'),
  adminOverride('Set by Administrator'),
  none('Dues outstanding');

  const ClearanceType(this.label);
  final String label;
}

class ClearanceRules {
  ClearanceRules._();

  static (ClearanceStatus, ClearanceType) evaluate({
    required double dues,
    required bool specialConsideration,
    required double paid,
    required double requiredAmount,
  }) {
    if (dues <= 0) return (ClearanceStatus.cleared, ClearanceType.auto);
    if (specialConsideration && paid >= requiredAmount) {
      return (ClearanceStatus.special, ClearanceType.paid);
    }
    return (ClearanceStatus.notCleared, ClearanceType.none);
  }
}

class Student {
  const Student({
    required this.id,
    required this.name,
    required this.semesterNo,
    this.batch = '',
    this.dept = 'CSE',
    this.cgpa = 0,
    this.creditsDone = 0,
    this.clearanceStatus = ClearanceStatus.notCleared,
    this.clearanceType = ClearanceType.none,
    this.specialConsideration = false,
    this.requiredAmount = 0,
    this.paidAmount = 0,
    this.dues = 0,
    this.lockedGroup,
    this.advisingDone = false,
    this.phone = '',
    this.email = '',
    this.dob = '',
    this.bloodGroup = '',
    this.presentAddress = '',
    this.permanentAddress = '',
    this.fatherName = '',
    this.motherName = '',
    this.emergencyContact = '',
    this.photoUrl = '',
  });

  final String id;
  final String name;
  final int semesterNo;
  final String batch;
  final String dept;
  final double cgpa;
  final double creditsDone;

  final ClearanceStatus clearanceStatus;
  final ClearanceType clearanceType;
  final bool specialConsideration;
  final double requiredAmount;
  final double paidAmount;
  final double dues;

  final int? lockedGroup;

  final bool advisingDone;

  final String phone;
  final String email;
  final String dob;
  final String bloodGroup;
  final String presentAddress;
  final String permanentAddress;
  final String fatherName;
  final String motherName;
  final String emergencyContact;

  final String photoUrl;

  String get initials {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }

  Student copyWith({
    ClearanceStatus? clearanceStatus,
    ClearanceType? clearanceType,
    bool? specialConsideration,
    int? Function()? lockedGroup,
    bool? advisingDone,
    String? phone,
    String? email,
    String? presentAddress,
    String? emergencyContact,
    String? photoUrl,
  }) {
    return Student(
      id: id,
      name: name,
      semesterNo: semesterNo,
      batch: batch,
      dept: dept,
      cgpa: cgpa,
      creditsDone: creditsDone,
      clearanceStatus: clearanceStatus ?? this.clearanceStatus,
      clearanceType: clearanceType ?? this.clearanceType,
      specialConsideration: specialConsideration ?? this.specialConsideration,
      requiredAmount: requiredAmount,
      paidAmount: paidAmount,
      dues: dues,
      lockedGroup: lockedGroup != null ? lockedGroup() : this.lockedGroup,
      advisingDone: advisingDone ?? this.advisingDone,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      dob: dob,
      bloodGroup: bloodGroup,
      presentAddress: presentAddress ?? this.presentAddress,
      permanentAddress: permanentAddress,
      fatherName: fatherName,
      motherName: motherName,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'] as String,
        name: json['name'] as String,
        semesterNo: json['semesterNo'] as int,
        batch: json['batch'] as String? ?? '',
        dept: json['dept'] as String? ?? 'CSE',
        cgpa: (json['cgpa'] as num? ?? 0).toDouble(),
        creditsDone: (json['creditsDone'] as num? ?? 0).toDouble(),
        clearanceStatus: ClearanceStatus.values.byName(json['clearanceStatus'] as String),
        clearanceType: ClearanceType.values.byName(json['clearanceType'] as String),
        specialConsideration: json['specialConsideration'] as bool? ?? false,
        requiredAmount: (json['requiredAmount'] as num? ?? 0).toDouble(),
        paidAmount: (json['paidAmount'] as num? ?? 0).toDouble(),
        dues: (json['dues'] as num? ?? 0).toDouble(),
        lockedGroup: json['lockedGroup'] as int?,
        advisingDone: json['advisingDone'] as bool? ?? false,
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        dob: json['dob'] as String? ?? '',
        bloodGroup: json['bloodGroup'] as String? ?? '',
        presentAddress: json['presentAddress'] as String? ?? '',
        permanentAddress: json['permanentAddress'] as String? ?? '',
        fatherName: json['fatherName'] as String? ?? '',
        motherName: json['motherName'] as String? ?? '',
        emergencyContact: json['emergencyContact'] as String? ?? '',
        photoUrl: json['photoUrl'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'semesterNo': semesterNo,
        'batch': batch,
        'dept': dept,
        'cgpa': cgpa,
        'creditsDone': creditsDone,
        'clearanceStatus': clearanceStatus.name,
        'clearanceType': clearanceType.name,
        'specialConsideration': specialConsideration,
        'requiredAmount': requiredAmount,
        'paidAmount': paidAmount,
        'dues': dues,
        'lockedGroup': lockedGroup,
        'advisingDone': advisingDone,
        'phone': phone,
        'email': email,
        'dob': dob,
        'bloodGroup': bloodGroup,
        'presentAddress': presentAddress,
        'permanentAddress': permanentAddress,
        'fatherName': fatherName,
        'motherName': motherName,
        'emergencyContact': emergencyContact,
        'photoUrl': photoUrl,
      };
}
