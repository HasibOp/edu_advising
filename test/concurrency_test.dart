import 'package:edu_advising/data/demo_data.dart';
import 'package:edu_advising/models/app_user.dart';
import 'package:edu_advising/models/course.dart';
import 'package:edu_advising/services/mock_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Plan section 6: 50 simultaneous requests at a 40-seat section must give
/// exactly 40 enrolments. The Firestore transaction must pass the same test.
void main() {
  test('50 parallel enrol requests on a 40-seat section -> exactly 40 succeed', () async {
    final api = MockApiService(
      latency: const Duration(milliseconds: 5),
      simulateSeats: false,
      seedDemo: false,
    );
    for (var i = 0; i < 50; i++) {
      api.addDemoStudent(DemoStudent(
        id: '2400${i.toString().padLeft(5, '0')}',
        name: 'Student $i',
        semesterNo: 1,
        gender: 'M',
        semesterFee: 50000,
        waiver: 0,
        paid: 50000,
      ));
    }
    const dean = AppUser(
        id: 'Dr. MK', role: UserRole.instructor, name: 'Dean', isDean: true, shortName: 'Dr. MK');
    final sectionId = CourseSection.makeId('CSE 111', 1, 1);
    await api.changeSeats(dean, sectionId, 40);

    final results = await Future.wait([
      for (var i = 0; i < 50; i++)
        api
            .enrollSelected('2400${i.toString().padLeft(5, '0')}', [sectionId])
            .then((_) => true)
            .catchError((_) => false),
    ]);

    expect(results.where((ok) => ok).length, 40);
    final section = (await api.fetchSections(semesterNo: 1)).firstWhere((s) => s.id == sectionId);
    expect(section.enrolled, 40);
    expect(section.isFull, isTrue);
    expect((await api.fetchSectionEnrollments(sectionId)).length, 40);
  });
}
