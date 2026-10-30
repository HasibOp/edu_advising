import 'package:edu_advising/data/offer_data.dart';
import 'package:edu_advising/services/catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final catalog = Catalog.instance;

  test('offer list has all 11 semesters with sections', () {
    expect(catalog.semesters, List.generate(11, (i) => i + 1));
    expect(catalog.groupCount(10), 8);
    expect(catalog.groupCount(2), 10);
    expect(catalog.titleOf('CSE 443'), 'Neural Network and Fuzzy Logic');
    expect(catalog.titleOf('CSE 464'), 'Mobile App Development');
  });

  test('every course has a section in every group', () {
    for (final entry in kOffer.entries) {
      for (final c in entry.value.c) {
        final groups = entry.value.s[c.$1]!;
        expect(groups.length, entry.value.n, reason: '${c.$1} sem ${entry.key}');
        expect(groups.every((g) => g.isNotEmpty), isTrue, reason: '${c.$1} sem ${entry.key}');
      }
    }
  });

  test('routine includes theory and lab slots, keyed by section number', () {
    final labs = catalog.allSlots.where((s) => s.isLab).length;
    expect(catalog.allSlots.length, greaterThan(600));
    expect(labs, greaterThan(150));
    final slots = catalog.slotsFor('CSE 463', 3);
    expect(slots, isNotEmpty);
    expect(slots.every((s) => s.sectionNo == 3 && s.faculty == 'TRINA'), isTrue);
    expect(catalog.days, ['Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday']);
  });

  test('exam routine covers all 11 semesters with real courses', () {
    for (final sem in catalog.semesters) {
      final exams = catalog.examsOf(sem);
      expect(exams, isNotEmpty, reason: 'semester $sem');
      for (final (day, code) in exams) {
        expect(day, inInclusiveRange(1, 8));
        expect(catalog.course(code), isNotNull, reason: code);
      }
    }
  });

  test('55 faculty, including the Dean Dr. MK', () {
    expect(catalog.faculty.length, 55);
    expect(catalog.facultyByShort('dr mk')!.name, 'Dr. K.M. Mohibul Kabir');
    expect(catalog.facultyByShort('TRINA')!.name, 'Ms. Trina Chakroborty');
  });

  test('prerequisites only point to courses that exist', () {
    for (final sem in catalog.semesters) {
      for (final c in catalog.coursesOf(sem)) {
        for (final p in catalog.prerequisitesOf(c.code)) {
          expect(catalog.course(p), isNotNull, reason: '${c.code} needs $p');
        }
      }
    }
  });
}
