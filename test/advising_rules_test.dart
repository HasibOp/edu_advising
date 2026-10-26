import 'package:edu_advising/models/class_slot.dart';
import 'package:edu_advising/models/course.dart';
import 'package:edu_advising/models/portal.dart';
import 'package:edu_advising/models/student.dart';
import 'package:edu_advising/services/advising_rules.dart';
import 'package:edu_advising/utils/faq_matcher.dart';
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

  test('credit limit is 18', () {
    expect(AdvisingRules.creditLimitError(13.5, 3), isNull);
    expect(AdvisingRules.creditLimitError(16.5, 3), isNotNull);
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
}
