import 'package:edu_advising/main.dart';
import 'package:edu_advising/services/mock_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens every screen of every role on a phone-sized screen. Any layout
/// overflow or exception fails the test.
void main() {
  Future<void> start(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(EduAdvisingApp(api: MockApiService(latency: Duration.zero)));
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

  /// Scrolls the main vertical list until [finder] is built and visible.
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

    // Advising: clearance -> sections -> Section 3 -> select all -> confirm.
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
    await tester.tap(find.text('Confirm').last); // dialog
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

    // Every menu page.
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

    // Routine by section, chatbot answer, profile, notifications.
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
}
