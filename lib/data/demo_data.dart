class DemoStudent {
  const DemoStudent({
    required this.id,
    required this.name,
    required this.semesterNo,
    required this.gender,
    required this.semesterFee,
    required this.waiver,
    required this.paid,
    this.previousDues = 0,
    this.specialConsideration = false,
    this.requiredAmount = 0,
    this.failed = const [],
    this.note = '',
  });

  final String id;
  final String name;
  final int semesterNo;

  final String gender;
  final double semesterFee;
  final double waiver;
  final double paid;
  final double previousDues;
  final bool specialConsideration;
  final double requiredAmount;

  final List<String> failed;

  final String note;
}

const List<DemoStudent> kDemoStudents = [
  DemoStudent(
    id: '233000001',
    name: 'Ayesha Siddika',
    semesterNo: 10,
    gender: 'F',
    semesterFee: 52000,
    waiver: 10400,
    paid: 41600,
    note: 'Semester 10, cleared, not advised yet',
  ),
  DemoStudent(
    id: '233000002',
    name: 'Tanvir Ahmed',
    semesterNo: 10,
    gender: 'M',
    semesterFee: 52000,
    waiver: 0,
    paid: 52000,
    note: 'Already enrolled in Section 2 (locked)',
  ),
  DemoStudent(
    id: '233000003',
    name: 'Farhana Akter',
    semesterNo: 10,
    gender: 'F',
    semesterFee: 52000,
    waiver: 0,
    paid: 30000,
    specialConsideration: true,
    requiredAmount: 25000,
    note: 'Special consideration',
  ),
  DemoStudent(
    id: '233000004',
    name: 'Rakibul Hasan',
    semesterNo: 10,
    gender: 'M',
    semesterFee: 52000,
    waiver: 5200,
    paid: 20000,
    previousDues: 4500,
    note: 'Not cleared (dues)',
  ),
  DemoStudent(
    id: '233000005',
    name: 'Mahmudul Karim',
    semesterNo: 10,
    gender: 'M',
    semesterFee: 52000,
    waiver: 0,
    paid: 52000,
    failed: ['CSE 327'],
    note: 'Failed CSE 327 (prerequisite block)',
  ),
  DemoStudent(
    id: '233000006',
    name: 'Sumaiya Chowdhury',
    semesterNo: 11,
    gender: 'F',
    semesterFee: 48000,
    waiver: 9600,
    paid: 38400,
    note: 'Semester 11, cleared',
  ),
  DemoStudent(
    id: '233000007',
    name: 'Arif Hossain',
    semesterNo: 7,
    gender: 'M',
    semesterFee: 55000,
    waiver: 0,
    paid: 30000,
    specialConsideration: true,
    requiredAmount: 27500,
    note: 'Semester 7, special consideration',
  ),
  DemoStudent(
    id: '233000008',
    name: 'Nadia Sultana',
    semesterNo: 4,
    gender: 'F',
    semesterFee: 55000,
    waiver: 13750,
    paid: 41250,
    note: 'Semester 4, cleared',
  ),
  DemoStudent(
    id: '233000009',
    name: 'Imran Mahmud',
    semesterNo: 10,
    gender: 'M',
    semesterFee: 52000,
    waiver: 0,
    paid: 15000,
    specialConsideration: true,
    requiredAmount: 26000,
    note: 'Special consideration, not enough paid',
  ),
  DemoStudent(
    id: '233000010',
    name: 'Tasnim Ferdous',
    semesterNo: 2,
    gender: 'F',
    semesterFee: 58000,
    waiver: 0,
    paid: 58000,
    note: 'Semester 2, cleared',
  ),
  DemoStudent(
    id: '233000011',
    name: 'Shakil Uddin',
    semesterNo: 9,
    gender: 'M',
    semesterFee: 52000,
    waiver: 5200,
    paid: 46800,
    note: 'Semester 9, pending extra request',
  ),
  DemoStudent(
    id: '233000012',
    name: 'Rumana Islam',
    semesterNo: 10,
    gender: 'F',
    semesterFee: 52000,
    waiver: 0,
    paid: 52000,
    note: 'On the waitlist for CSE 443.1',
  ),
];

const List<String> kDemoFathers = [
  'Abdul Karim', 'Mohammad Ali', 'Nurul Islam', 'Abul Kalam', 'Jamal Uddin',
  'Rafiqul Alam', 'Shahadat Hossain',
];
const List<String> kDemoMothers = [
  'Rokeya Begum', 'Salma Khatun', 'Hasina Akter', 'Kohinoor Begum',
  'Shirin Sultana', 'Parveen Akter', 'Jahanara Begum',
];
const List<String> kDemoAreas = [
  'Agrabad, Chattogram', 'Nasirabad, Chattogram', 'Halishahar, Chattogram',
  'Bahaddarhat, Chattogram', 'GEC Circle, Chattogram', 'Patenga, Chattogram',
  'Khulshi, Chattogram',
];
const List<String> kDemoHomeTowns = [
  'Cumilla', 'Feni', "Cox's Bazar", 'Noakhali', 'Rangamati', 'Sylhet', 'Bogura',
];
const List<String> kBloodGroups = ['A+', 'B+', 'O+', 'AB+', 'A-', 'O-', 'B-'];
