import 'package:edu_advising/models/class_slot.dart';
import 'package:edu_advising/models/course.dart';
import 'package:edu_advising/models/portal.dart';
import 'package:edu_advising/models/student.dart';
import 'package:edu_advising/services/advising_rules.dart';
import 'package:edu_advising/services/catalog.dart';
import 'package:edu_advising/utils/faq_matcher.dart';
import 'package:edu_advising/widgets/routine_views.dart';
import 'package:flutter_test/flutter_test.dart';

ClassSlot slot(String day, String time) {
  final (start, end) = ClassSlot.parseTime(time);
  return ClassSlot(
    day: day,
    isLab: false,
    time: time,
    startMinute: start,
    endMinute: end,
    room: '101',
    courseCode: 'CSE 000',
    sectionNo: 1,
    faculty: 'X',
  );
}

void main() {
  group('clearance rules', () {
    test('no dues -> cleared (auto)', () {
      expect(
        ClearanceRules.evaluate(dues: 0, specialConsideration: false, paid: 0, requiredAmount: 0),
        (ClearanceStatus.cleared, ClearanceType.auto),
      );
    });
    test('special consideration and paid enough -> special (paid)', () {
      expect(
        ClearanceRules.evaluate(
            dues: 5000, specialConsideration: true, paid: 30000, requiredAmount: 25000),
        (ClearanceStatus.special, ClearanceType.paid),
      );
    });
    test('special consideration but paid too little -> not cleared', () {
      final (status, _) = ClearanceRules.evaluate(
          dues: 5000, specialConsideration: true, paid: 10000, requiredAmount: 25000);
      expect(status, ClearanceStatus.notCleared);
      expect(status.canAdvise, isFalse);
    });
  });

  test('seat badge levels', () {
    CourseSection section(int cap, int taken) => CourseSection(
          id: 'x',
          courseCode: 'CSE 443',
          title: 't',
          credits: 3,
          semesterNo: 10,
          groupNo: 1,
          parts: [SectionPart(sectionNo: 1, capacity: cap, enrolled: taken)],
        );
    expect(section(28, 28).seatLevel, SeatLevel.full);
    expect(section(28, 23).seatLevel, SeatLevel.low);
    expect(section(28, 10).seatLevel, SeatLevel.open);
    expect(section(28, 10).label, 'CSE 443.1');
  });

  test('routine times: afternoon hours are after noon', () {
    expect(ClassSlot.parseTime('8.30-10.00'), (510, 600));
    expect(ClassSlot.parseTime('11.30-1.00'), (690, 780));
    expect(ClassSlot.parseTime('3.30-5.30'), (930, 1050));
  });

  test('time clash detection', () {
    final existing = {'CSE 443.1': [slot('Sunday', '10.00-11.30')]};
    expect(AdvisingRules.clashError(existing, {'CSE 459.2': [slot('Sunday', '11.30-1.00')]}),
        isNull);
    expect(AdvisingRules.clashError(existing, {'CSE 459.2': [slot('Monday', '10.00-11.30')]}),
        isNull);
    expect(AdvisingRules.clashError(existing, {'CSE 459.2': [slot('Sunday', '9.30-11.30')]}),
        contains('CSE 443.1'));
  });

  test('every clash is listed once per pair of sections', () {
    final existing = {
      'CSE 443.1': [slot('Sunday', '10.00-11.30')],
      'CSE 463.2': [slot('Sunday', '10.30-12.00')],
    };
    final adding = {'CSE 459.2': [slot('Sunday', '11.00-12.30')]};
    final clashes = AdvisingRules.timeClashes(existing, adding);
    expect(clashes, hasLength(2));
    expect(clashes.every((c) => c.startsWith('Class time:')), isTrue);
    expect(AdvisingRules.timeClashes(existing, {'CSE 459.2': [slot('Monday', '10.00-11.30')]}),
        isEmpty);
  });

  test('courses with exams on the same day clash', () {
    expect(AdvisingRules.examClashes({'CSE 443': 5}, {'CSE 459': 3}), isEmpty);
    final clashes = AdvisingRules.examClashes({'CSE 443': 5, 'HUM 203': 4}, {'CSE 225': 4});
    expect(clashes, ['Exam day: CSE 225 and HUM 203 are both on Day 4.']);
    expect(AdvisingRules.examClashes({}, {'A 1': 2, 'B 2': 2}), hasLength(1));
  });

  test('exam days come from the exam routine', () {
    expect(Catalog.instance.examDay('CSE 443', 10), 5);
    expect(Catalog.instance.examDay('HUM 203', 11), 4);
    expect(Catalog.instance.examDay('CSE 464', 11), isNull);
  });

  test('CSE 464 and CSE 466 have no prerequisite', () {
    expect(Catalog.instance.prerequisitesOf('CSE 464'), isEmpty);
    expect(Catalog.instance.prerequisitesOf('CSE 466'), isEmpty);
  });

  test('prerequisites follow the official course catalog', () {
    final c = Catalog.instance;
    expect(c.prerequisitesOf('CSE 327'), ['CSE 115', 'CSE 221', 'CSE 315']);
    expect(c.prerequisitesOf('CSE 443'), ['CSE 327']);
    expect(c.prerequisitesOf('CSE 301'), ['CSE 325', 'CSE 311', 'CSE 225']);
    expect(c.prerequisitesOf('CSE 111'), isEmpty);
    expect(c.prerequisitesOf('CSE 215'), isEmpty);
  });

  test('room capacity is 35 for theory and 28 for labs', () {
    expect(Catalog.instance.roomCapacity('CSE 443', 3), 35);
    expect(Catalog.instance.roomCapacity('CSE 112', 2), 28);
  });

  test('FAQ bot matches by keyword and falls back politely', () {
    const faqs = [
      Faq(id: '1', question: 'The section is full. What now?', answer: 'Join the waitlist.',
          category: 'Advising', keywords: ['full', 'waitlist']),
      Faq(id: '2', question: 'How do I pay my fees?', answer: 'E-payment.',
          category: 'Accounts', keywords: ['fee', 'pay']),
    ];
    expect(FaqMatcher.bestMatch(faqs, 'my section is full')!.id, '1');
    expect(FaqMatcher.bestMatch(faqs, 'how can I pay?')!.id, '2');
    expect(FaqMatcher.bestMatch(faqs, 'what is the cafeteria menu'), isNull);
  });

  test('overlapping classes share a day column; others keep the full width', () {
    final a = slot('Sunday', '9.30-11.30');
    final b = slot('Sunday', '10.00-12.00');
    final c = slot('Sunday', '1.00-2.00');
    final d = slot('Monday', '9.30-11.30');
    final lanes = layoutRoutineLanes([a, b, c, d]);
    expect(lanes[a], (0, 2));
    expect(lanes[b], (1, 2));
    expect(lanes[c], (0, 1));
    expect(lanes[d], (0, 1));
    final e = slot('Sunday', '11.30-1.00');
    final more = layoutRoutineLanes([a, b, e]);
    expect(more[e]!.$2, 2);
  });
}
