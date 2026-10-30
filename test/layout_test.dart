import 'package:edu_advising/main.dart';
import 'package:edu_advising/services/mock_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const setups = <(double, double, double)>[
    (360, 740, 1.0),
    (320, 568, 1.0),
    (360, 740, 1.3),
  ];

  Future<void> start(WidgetTester tester, (double, double, double) setup) async {
    const dpr = 3.0;
    tester.view.physicalSize = Size(setup.$1 * dpr, setup.$2 * dpr);
    tester.view.devicePixelRatio = dpr;
    tester.platformDispatcher.textScaleFactorTestValue = setup.$3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.pumpWidget(EduAdvisingApp(api: MockApiService(latency: Duration.zero)));
    await tester.pumpAndSettle();
  }

  bool present(Finder finder) {
    try {
      return finder.evaluate().isNotEmpty;
    } on StateError {
      return false;
    }
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    final vertical = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down);
    for (var i = 0; i < 40 && !present(finder); i++) {
      await tester.drag(vertical.last, const Offset(0, -200));
      await tester.pumpAndSettle();
    }
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    if (!present(finder)) {
      final lists = find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down);
      if (lists.evaluate().isNotEmpty) {
        await tester.fling(lists.last, const Offset(0, 4000), 4000);
        await tester.pumpAndSettle();
      }
      await scrollTo(tester, finder);
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    final captured = <FlutterErrorDetails>[];
    final original = FlutterError.onError;
    FlutterError.onError = (details) => captured.add(details);
    String? report;
    try {
      await tester.tap(finder);
      await tester.pumpAndSettle();
      if (captured.isNotEmpty) report = captured.first.toString();
    } finally {
      FlutterError.onError = original;
    }
    if (report != null) fail('After tapping ${finder.toString()}:\n$report');
  }

  Future<void> login(WidgetTester tester, String role, String username) async {
    await tap(tester, find.text(role));
    await tester.enterText(find.byType(TextField).at(0), username);
    await tester.enterText(find.byType(TextField).at(1), 'demo');
    await tap(tester, find.text('Sign in'));
  }

  Future<void> back(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }


  Future<void> openMenu(WidgetTester tester, String title) async {
    final item = find.text(title);
    final lists = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down);
    await tester.fling(lists.last, const Offset(0, 4000), 4000);
    await tester.pumpAndSettle();
    await scrollTo(tester, item);
    await tap(tester, item);
  }

  for (final setup in setups) {
    final name = '${setup.$1.toInt()}x${setup.$2.toInt()} at ${setup.$3}x font';

    testWidgets('login screen, $name', (tester) async {
      await start(tester, setup);
      expect(find.text('Sign in'), findsOneWidget);
      await tap(tester, find.text('Demo accounts (any password)'));
    });

    testWidgets('student screens, $name', (tester) async {
      await start(tester, setup);
      await login(tester, 'Student', '233000001');
      await tap(tester, find.text('Start advising'));
      await tap(tester, find.text('Proceed to Advising'));
      await tap(tester, find.text('Section 3'));
      await tap(tester, find.text('Select all'));
      await tap(tester, find.text('Confirm').last);
      await tester.tap(find.text('Confirm').last);
      await tester.pumpAndSettle();
      await tap(tester, find.text('OK'));
      await back(tester);

      await tap(tester, find.text('Extra course'));
      await tap(tester, find.widgetWithText(FilledButton, 'Request').first);
      await tap(tester, find.text('Retake'));
      await back(tester);
      await tap(tester, find.textContaining('Waitlist ('));
      for (var i = 0; i < 5 && !present(find.byType(NavigationBar)); i++) {
        await back(tester);
      }
      if (!present(find.byType(NavigationBar))) {
        final texts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).take(12).toList();
        fail('Not back on the Home tab. Visible texts: $texts');
      }

      await tap(tester, find.text('Menu').last);
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
      await tap(tester, find.text('By section'));
      await tap(tester, find.text('Semester 2'));
      await tap(tester, find.byTooltip('Day list'));
      await tap(tester, find.byTooltip('Week grid'));
      await back(tester);

      await tap(tester, find.byTooltip('Notifications'));
      await back(tester);
      await tap(tester, find.text('Home').last);
      await tap(tester, find.text('Ayesha Siddika'));
      await tap(tester, find.byTooltip('Edit contact details'));
    });

    testWidgets('not cleared student, $name', (tester) async {
      await start(tester, setup);
      await login(tester, 'Student', '233000004');
      await tap(tester, find.text('Start advising'));
      await scrollTo(tester, find.text('Advising is locked'));
    });

    testWidgets('instructor and Dean screens, $name', (tester) async {
      await start(tester, setup);
      await login(tester, 'Instructor', 'Dr. MK');
      await tap(tester, find.text('CSE 215.1'));
      await back(tester);
      await tap(tester, find.text('Students'));
      await tap(tester, find.text('233000004'));
      await scrollTo(tester, find.text('Start advising for this student'));
      await tap(tester, find.text('Start advising for this student'));
      await back(tester);
      await tap(tester, find.text('Requests').last);
      await tap(tester, find.text('Dean').last);
      await tap(tester, find.text('Audit log'));
      await back(tester);
      await tap(tester, find.text('More'));
    });

    testWidgets('administrator screens, $name', (tester) async {
      await start(tester, setup);
      await login(tester, 'Admin', 'admin');
      for (final tab in ['Windows', 'Content', 'Courses', 'Audit']) {
        await tap(tester, find.text(tab).last);
        if (tab == 'Content') {
          await tap(tester, find.text('FAQ'));
        }
      }
    });
  }
}
