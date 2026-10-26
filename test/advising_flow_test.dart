import 'package:edu_advising/models/app_user.dart';
import 'package:edu_advising/models/course.dart';
import 'package:edu_advising/models/enrollment.dart';
import 'package:edu_advising/models/extra_request.dart';
import 'package:edu_advising/models/portal.dart';
import 'package:edu_advising/models/student.dart';
import 'package:edu_advising/services/api_service.dart';
import 'package:edu_advising/services/mock_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// The testing checklist of the plan (section 19), run against the mock.
void main() {
  late MockApiService api;
  const dean = AppUser(
      id: 'Dr. MK', role: UserRole.instructor, name: 'Dr. MK', isDean: true, shortName: 'Dr. MK');
  const trina =
      AppUser(id: 'TRINA', role: UserRole.instructor, name: 'Trina', shortName: 'TRINA');
  const admin = AppUser(id: 'admin', role: UserRole.admin, name: 'Administrator');

  setUp(() => api = MockApiService(latency: Duration.zero));

  Future<List<CourseSection>> group(int sem, int g) async =>
      (await api.fetchSections(semesterNo: sem)).where((s) => s.groupNo == g).toList();

  Future<CourseSection> section(String code, int sem, int g) async =>
      (await group(sem, g)).firstWhere((s) => s.courseCode == code);

  test('login checks the role and finds the Dean by short form', () async {
    expect((await api.login('233000001', 'x', UserRole.student)).name, 'Ayesha Siddika');
    expect(() => api.login('233000001', 'x', UserRole.instructor), throwsA(isA<ApiException>()));
    final mk = await api.login('dr mk', 'x', UserRole.instructor);
    expect(mk.isDean, isTrue);
    expect((await api.login('TRINA', 'x', UserRole.instructor)).isDean, isFalse);
  });

  test('select all + confirm enrols every course and locks the section', () async {
    final sections = await group(10, 3);
    final before = {for (final s in sections) s.id: s.enrolled};
    final result = await api.enrollSelected('233000001', [for (final s in sections) s.id]);
    expect(result.length, sections.length);

    final after = await group(10, 3);
    for (final s in after) {
      expect(s.enrolled, before[s.id]! + 1);
    }
    final student = await api.fetchStudent('233000001');
    expect(student.lockedGroup, 3);
    expect(student.advisingDone, isTrue);

    // Other sections are now view-only.
    final other = await section('CSE 443', 10, 5);
    expect(() => api.enrollSelected('233000001', [other.id]), throwsA(isA<ApiException>()));
  });

  test('a duplicate tap cannot enrol twice', () async {
    final s = await section('CSE 459', 10, 3);
    await api.enrollSelected('233000001', [s.id]);
    expect(() => api.enrollSelected('233000001', [s.id]), throwsA(isA<ApiException>()));
    expect((await api.fetchEnrollments('233000001')).length, 1);
    expect((await section('CSE 459', 10, 3)).enrolled, s.enrolled + 1);
  });

  test('enrolment is all-or-nothing (prerequisite failure)', () async {
    // 233000005 failed CSE 327, the prerequisite of CSE 443 and CSE 463.
    final sections = await group(10, 3);
    final before = {for (final s in sections) s.id: s.enrolled};
    await expectLater(
      api.enrollSelected('233000005', [for (final s in sections) s.id]),
      throwsA(predicate((e) => e.toString().contains('CSE 327'))),
    );
    expect(await api.fetchEnrollments('233000005'), isEmpty);
    for (final s in await group(10, 3)) {
      expect(s.enrolled, before[s.id]);
    }
  });

  test('full section -> join waitlist; a freed seat promotes the first in line', () async {
    final full = await section('CSE 443', 10, 1);
    expect(full.isFull, isTrue);
    expect(() => api.enrollSelected('233000001', [full.id]), throwsA(isA<ApiException>()));

    final w = await api.joinWaitlist('233000001', full.id);
    expect(w.position, 2); // 233000012 was first.

    // Dean adds a seat: the first student on the waitlist gets it.
    await api.changeSeats(dean, full.id, full.capacity + 1);
    final rumana = await api.fetchEnrollments('233000012');
    expect(rumana.map((e) => e.label), contains('CSE 443.1'));
    expect((await api.fetchWaitlist('233000001')).single.position, 1);
  });

  test('students cannot drop; faculty drop own courses only; Dean any', () async {
    final tanvir = await api.fetchEnrollments('233000002');
    final e443 = tanvir.firstWhere((e) => e.courseCode == 'CSE 443');
    final e463 = tanvir.firstWhere((e) => e.courseCode == 'CSE 463');

    const student = AppUser(id: '233000002', role: UserRole.student, name: 'Tanvir');
    expect(() => api.staffDrop(student, e443.id), throwsA(isA<ApiException>()));
    expect(() => api.staffDrop(trina, e443.id), throwsA(isA<ApiException>()));

    await api.staffDrop(trina, e463.id); // TRINA teaches CSE 463.2
    await api.staffDrop(dean, e443.id);
    final left = await api.fetchEnrollments('233000002');
    expect(left.map((e) => e.courseCode), ['CSE 439']);
  });

  test('a full drop clears the section lock', () async {
    for (final e in await api.fetchEnrollments('233000002')) {
      await api.staffDrop(dean, e.id);
    }
    final s = await api.fetchStudent('233000002');
    expect(s.lockedGroup, isNull);
    expect(s.advisingDone, isFalse);
  });

  test('not cleared students cannot advise; admin Give clearance fixes it', () async {
    final s = await section('CSE 459', 10, 2);
    expect(() => api.enrollSelected('233000004', [s.id]), throwsA(isA<ApiException>()));
    expect(() => api.staffAdvise(trina, '233000004', [s.id]), throwsA(isA<ApiException>()));

    final updated = await api.setClearance(admin, '233000004', ClearanceAction.give);
    expect(updated.clearanceStatus, ClearanceStatus.cleared);
    expect(updated.clearanceType, ClearanceType.adminOverride);
    expect(await api.enrollSelected('233000004', [s.id]), hasLength(1));
  });

  test('Dean advises without clearance and the bypass is logged', () async {
    final s = await section('CSE 459', 10, 2);
    await api.staffAdvise(dean, '233000009', [s.id]);
    final logs = await api.fetchAuditLogs();
    expect(logs.any((l) => l.action == AuditAction.deanBypass && l.targetId == '233000009'),
        isTrue);
  });

  test('faculty can only add their own courses', () async {
    final mine = await section('CSE 463', 10, 3);
    final notMine = await section('CSE 443', 10, 3);
    expect(() => api.staffAdvise(trina, '233000001', [notMine.id]), throwsA(isA<ApiException>()));
    final added = await api.staffAdvise(trina, '233000001', [mine.id]);
    expect(added.single.type, EnrollmentType.regular);
  });

  test('closed windows block advising and extra requests', () async {
    final w = await api.fetchWindows();
    await api.updateWindows(admin, w.copyWith(regularOpen: false, extraOpen: false));
    final s = await section('CSE 459', 10, 3);
    expect(() => api.enrollSelected('233000001', [s.id]), throwsA(isA<ApiException>()));
    final other = await section('CSE 321', 9, 2);
    expect(
      () => api.createExtraRequest(
          studentId: '233000001',
          sectionId: other.id,
          kind: RequestKind.add,
          reason: RequestReason.retake),
      throwsA(isA<ApiException>()),
    );
  });

  test('extra request: one per course, withdraw while pending, approval enrols', () async {
    final s = await section('CSE 225', 5, 6);
    final r = await api.createExtraRequest(
        studentId: '233000006', sectionId: s.id, kind: RequestKind.add, reason: RequestReason.retake);
    expect(r.status, RequestStatus.pending);
    expect(
      () => api.createExtraRequest(
          studentId: '233000006', sectionId: s.id, kind: RequestKind.add, reason: RequestReason.other),
      throwsA(isA<ApiException>()),
    );

    await api.withdrawExtraRequest(r.id);
    expect(() => api.withdrawExtraRequest(r.id), throwsA(isA<ApiException>()));
    final again = await api.createExtraRequest(
        studentId: '233000006', sectionId: s.id, kind: RequestKind.add, reason: RequestReason.retake);

    expect((await api.fetchRequestsFor(trina)).map((x) => x.id), contains(again.id));
    final decided = await api.decideExtraRequest(trina, again.id, true, 'OK');
    expect(decided.status, RequestStatus.enrolled);
    final e = (await api.fetchEnrollments('233000006')).single;
    expect(e.type, EnrollmentType.extra);
    expect(e.label, 'CSE 225.6');
  });

  test('seat change stays between enrolment and room capacity', () async {
    final s = await section('CSE 463', 10, 3);
    expect(() => api.changeSeats(trina, s.id, s.parts.first.enrolled - 1),
        throwsA(isA<ApiException>()));
    expect(() => api.changeSeats(trina, s.id, 500), throwsA(isA<ApiException>()));
    final other = await section('CSE 443', 10, 3);
    expect(() => api.changeSeats(trina, other.id, 30), throwsA(isA<ApiException>()));
    final changed = await api.changeSeats(trina, s.id, 30);
    expect(changed.capacity, 30);
  });
}
