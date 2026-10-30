import 'package:edu_advising/main.dart';
import 'package:edu_advising/models/course.dart';
import 'package:edu_advising/services/advising_rules.dart';
import 'package:edu_advising/services/catalog.dart';
import 'package:edu_advising/services/mock_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> start(WidgetTester tester, {MockApiService? api}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(EduAdvisingApp(api: api ?? MockApiService(latency: Duration.zero)));
    await tester.pumpAndSettle();
  }

  Future<void> login(WidgetTester tester, String role, String username) async {
    await tester.tap(find.text(role));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), username);
    await tester.enterText(find.byType(TextField).at(1), 'demo');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
  }

  Future<void> back(WidgetTester tester) async {
    await tester.pageBack();
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    final vertical = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down);
    await tester.scrollUntilVisible(finder, 150, scrollable: vertical.last);
    await tester.pumpAndSettle();
  }

  Future<void> openMenu(WidgetTester tester, String title) async {
    final item = find.text(title);
    await scrollTo(tester, item);
    await tester.tap(item);
    await tester.pumpAndSettle();
  }

  testWidgets('student: home, advising flow and every menu page', (tester) async {
    await start(tester);
    await login(tester, 'Student', '233000001');
    expect(find.text('Ayesha Siddika'), findsOneWidget);

    await tester.tap(find.text('Start advising'));
    await tester.pumpAndSettle();
    expect(find.textContaining('May proceed for advising', findRichText: true), findsWidgets);
    await tester.tap(find.text('Proceed to Advising'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Section 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm').last);
    await tester.pumpAndSettle();
    expect(find.text('Advising confirmed'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await back(tester);
    expect(find.text('Locked to Section 3'), findsOneWidget);

    await tester.tap(find.text('Extra course'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Waitlist ('));
    await tester.pumpAndSettle();
    await back(tester);
    await back(tester);

    await tester.tap(find.text('Menu').last);
    await tester.pumpAndSettle();
    for (final title in [
      'Course offer list',
      'My classes',
      'Class routine',
      'Exam routine',
      'Transcript',
      'Finance summary',
      'Notice board',
      'FAQ chatbot',
      'Prerequisite checker',
      'Faculty directory',
    ]) {
      await openMenu(tester, title);
      await back(tester);
    }

    await openMenu(tester, 'Class routine');
    await tester.tap(find.text('By section'));
    await tester.pumpAndSettle();
    await back(tester);
    await openMenu(tester, 'FAQ chatbot');
    await tester.enterText(find.byType(TextField), 'my section is full');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
    expect(find.textContaining('waitlist'), findsWidgets);
    await back(tester);
    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    await back(tester);
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ayesha Siddika'));
    await tester.pumpAndSettle();
    expect(find.text('My Profile'), findsOneWidget);
  });

  testWidgets('student 233000002 has courses but no Drop button', (tester) async {
    await start(tester);
    await login(tester, 'Student', '233000002');
    await tester.tap(find.text('Menu').last);
    await tester.pumpAndSettle();
    await openMenu(tester, 'My classes');
    expect(find.textContaining('CSE 4'), findsWidgets);
    expect(find.textContaining(RegExp('^Drop', caseSensitive: false)), findsNothing);
    expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
  });

  testWidgets('extra request cannot be sent without a reason', (tester) async {
    await start(tester);
    await login(tester, 'Student', '233000001');
    await tester.tap(find.text('Start advising'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proceed to Advising'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Extra course'));
    await tester.pumpAndSettle();
    final request = find.widgetWithText(FilledButton, 'Request');
    await scrollTo(tester, request.first);
    await tester.tap(request.first);
    await tester.pumpAndSettle();

    FilledButton send() => tester.widget<FilledButton>(
        find.ancestor(of: find.text('Send request'), matching: find.byWidgetPredicate((w) => w is FilledButton)));
    expect(send().onPressed, isNull);
    await tester.tap(find.text('Retake'));
    await tester.pumpAndSettle();
    expect(send().onPressed, isNotNull);
  });

  testWidgets('exam routine PDF needs one semester', (tester) async {
    await start(tester);
    await login(tester, 'Student', '233000001');
    await tester.tap(find.text('Menu').last);
    await tester.pumpAndSettle();
    await openMenu(tester, 'Exam routine');
    IconButton pdf() => tester.widget<IconButton>(find.ancestor(
        of: find.byIcon(Icons.picture_as_pdf_outlined), matching: find.byType(IconButton)));
    expect(pdf().onPressed, isNotNull);
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(pdf().onPressed, isNull);
  });

  testWidgets('inputs stay readable when the phone is in dark mode', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await start(tester);
    await tester.enterText(find.byType(TextField).at(0), '233000001');
    await tester.pump();
    for (final field in tester.widgetList<EditableText>(find.byType(EditableText))) {
      final color = field.style.color!;
      expect(color.computeLuminance(), lessThan(0.2), reason: 'input text must be dark on white');
    }
    final context = tester.element(find.byType(TextField).first);
    expect(Theme.of(context).brightness, Brightness.light);
  });

  testWidgets('not cleared student sees the red remark', (tester) async {
    await start(tester);
    await login(tester, 'Student', '233000004');
    await tester.tap(find.text('Start advising'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Advising is locked'));
    expect(find.text('Advising is locked'), findsOneWidget);
  });

  testWidgets('dean: courses, student search, requests, dean panel, more', (tester) async {
    await start(tester);
    await login(tester, 'Instructor', 'Dr. MK');
    expect(find.text('Dean'), findsWidgets);
    await tester.tap(find.text('CSE 215.1'));
    await tester.pumpAndSettle();
    await back(tester);

    await tester.tap(find.text('Students'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('233000004'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Start advising for this student'));
    expect(find.text('Dean bypass'), findsOneWidget);
    await tester.tap(find.text('Start advising for this student'));
    await tester.pumpAndSettle();
    await back(tester);

    await tester.tap(find.text('Requests').last);
    await tester.pumpAndSettle();
    expect(find.text('Approve'), findsWidgets);
    await tester.tap(find.text('Dean').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Audit log'));
    await tester.pumpAndSettle();
    await back(tester);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
  });

  testWidgets('instructor TRINA approves a request', (tester) async {
    await start(tester);
    await login(tester, 'Instructor', 'TRINA');
    await tester.tap(find.text('Requests').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Approve').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Approve').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Approved'), findsWidgets);
  });

  testWidgets('admin: every tab, give clearance', (tester) async {
    await start(tester);
    await login(tester, 'Admin', 'admin');
    final give = find.widgetWithText(FilledButton, 'Give clearance');
    await scrollTo(tester, give.first);
    await tester.tap(give.first);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Give clearance')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Give clearance done'), findsOneWidget);
    for (final tab in ['Windows', 'Content', 'Courses', 'Audit']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      if (tab == 'Content') {
        await tester.tap(find.text('FAQ'));
        await tester.pumpAndSettle();
      }
    }
  });

  Future<(CourseSection, CourseSection)> clashingPair(MockApiService api) async {
    final all = await api.fetchSections();
    for (final a in all.where((s) => s.semesterNo == 10 && s.groupNo == 3)) {
      for (final b in all.where((s) => s.semesterNo != 10 && !s.isFull)) {
        final clash = AdvisingRules.clashError(
          {a.label: Catalog.instance.slotsFor(a.courseCode, a.parts.first.sectionNo)},
          {b.label: Catalog.instance.slotsFor(b.courseCode, b.parts.first.sectionNo)},
        );
        if (clash != null) return (a, b);
      }
    }
    fail('no clashing pair in the demo data');
  }

  Future<void> sendExtraRequest(WidgetTester tester, CourseSection b) async {
    await tester.tap(find.text('View advising'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go to Advising'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Extra course'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sem ${b.semesterNo}'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, b.label);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Request').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retake'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send request'));
    await tester.pumpAndSettle();
  }

  testWidgets('student: a class-time clash shows an alert and can be accepted', (tester) async {
    final api = MockApiService(latency: Duration.zero);
    final (a, b) = (await tester.runAsync(() async {
      final pair = await clashingPair(api);
      await api.enrollSelected('233000001', [pair.$1.id]);
      return pair;
    }))!;
    await start(tester, api: api);
    await login(tester, 'Student', '233000001');
    await sendExtraRequest(tester, b);

    expect(find.text('Clash found'), findsOneWidget);
    expect(find.textContaining('Class time:'), findsWidgets);
    expect(find.text('Take anyway'), findsOneWidget);
    expect(await tester.runAsync(() => api.fetchMyRequests('233000001')), isEmpty);

    await tester.tap(find.text('Take anyway'));
    await tester.pumpAndSettle();
    expect(find.text('Clash found'), findsNothing);
    expect(find.textContaining('Request sent'), findsOneWidget);
    expect(await tester.runAsync(() => api.fetchMyRequests('233000001')), hasLength(1));
  });

  testWidgets('student: going back from a clash alert sends nothing', (tester) async {
    final api = MockApiService(latency: Duration.zero);
    final (a, b) = (await tester.runAsync(() async {
      final pair = await clashingPair(api);
      await api.enrollSelected('233000001', [pair.$1.id]);
      return pair;
    }))!;
    await start(tester, api: api);
    await login(tester, 'Student', '233000001');
    await sendExtraRequest(tester, b);

    expect(find.text('Clash found'), findsOneWidget);
    await tester.tap(find.text('Go back'));
    await tester.pumpAndSettle();
    expect(find.text('Clash found'), findsNothing);
    expect(await tester.runAsync(() => api.fetchMyRequests('233000001')), isEmpty);
  });

  testWidgets('class routine by section lists every part of a split lab', (tester) async {
    await start(tester);
    await login(tester, 'Student', '233000001');
    await tester.tap(find.text('Menu').last);
    await tester.pumpAndSettle();
    await openMenu(tester, 'Class routine');
    await tester.tap(find.text('By section'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Semester 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Day list'));
    await tester.pumpAndSettle();
    expect(find.textContaining('PHY 102.1  '), findsWidgets);
    expect(find.textContaining('PHY 102.11'), findsWidgets);
  });
}
