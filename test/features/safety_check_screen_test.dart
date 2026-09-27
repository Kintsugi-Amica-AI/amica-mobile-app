import 'package:amica_mobile_app/features/journey/screens/safety_check_screen.dart';
import 'package:amica_mobile_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps the safety check screen, standing in for the journey timer screen
/// that normally pushes it and awaits the answer.
///
/// Returns the list the popped result lands in, so a test can assert on the
/// decision the screen actually reported rather than only on what it drew.
Future<List<SafetyCheckResult?>> _pumpSafetyCheck(
  WidgetTester tester, {
  SafetyCheckArguments? arguments,
}) async {
  final answers = <SafetyCheckResult?>[];

  await tester.pumpWidget(
    MaterialApp(
      // The screen reads its copy from AppLocalizations, so the test app
      // needs the delegates (English, to match the expected strings).
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            answers.add(
              await Navigator.push<SafetyCheckResult>(
                context,
                MaterialPageRoute(
                  builder: (_) => SafetyCheckScreen(arguments: arguments),
                ),
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

  return answers;
}

void main() {
  const arguments = SafetyCheckArguments(
    destinationName: 'Home',
    journeyId: 'journey-1',
  );

  testWidgets('asks whether the user is safe and names the destination',
      (tester) async {
    await _pumpSafetyCheck(tester, arguments: arguments);

    expect(find.text('Are you safe?'), findsOneWidget);
    expect(find.textContaining('Home'), findsOneWidget);
    expect(find.text('I am safe'), findsOneWidget);
    expect(find.text('Send SOS now'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('"I am safe" reports a safe result', (tester) async {
    final answers = await _pumpSafetyCheck(tester, arguments: arguments);

    await tester.tap(find.text('I am safe'));
    await tester.pumpAndSettle();

    // The screen only reports the decision; the journey timer applies it.
    expect(answers, [SafetyCheckResult.safe]);
    expect(find.text('Are you safe?'), findsNothing);
  });

  testWidgets('"Send SOS now" reports an sos result', (tester) async {
    final answers = await _pumpSafetyCheck(tester, arguments: arguments);

    await tester.tap(find.text('Send SOS now'));
    await tester.pumpAndSettle();

    expect(answers, [SafetyCheckResult.sos]);
    expect(find.text('Are you safe?'), findsNothing);
  });

  testWidgets('reports only the first answer when tapped twice',
      (tester) async {
    final answers = await _pumpSafetyCheck(tester, arguments: arguments);

    // A double tap must not pop the timer screen underneath as well.
    await tester.tap(find.text('I am safe'), warnIfMissed: false);
    await tester.tap(find.text('I am safe'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(answers, [SafetyCheckResult.safe]);
  });

  testWidgets('cannot be dismissed with the back button', (tester) async {
    final answers = await _pumpSafetyCheck(tester, arguments: arguments);

    // An accidental back swipe must never read as a safety confirmation.
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    // The shield keeps pulsing, so this never settles; pump fixed frames.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Are you safe?'), findsOneWidget);
    expect(answers, isEmpty);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('counts down to the automatic emergency-contact alert',
      (tester) async {
    await _pumpSafetyCheck(
      tester,
      arguments: SafetyCheckArguments(
        destinationName: 'Home',
        journeyId: 'journey-1',
        escalationAt: DateTime.now().add(const Duration(seconds: 30)),
      ),
    );

    expect(find.text('Auto-alert in'), findsOneWidget);
    expect(find.textContaining('00:'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shows that the contact was alerted once the deadline passes',
      (tester) async {
    await _pumpSafetyCheck(
      tester,
      arguments: SafetyCheckArguments(
        destinationName: 'Home',
        journeyId: 'journey-1',
        escalationAt: DateTime.now().subtract(const Duration(seconds: 5)),
      ),
    );

    expect(
      find.text('Amica has alerted your emergency contact'),
      findsOneWidget,
    );
    // Both answers stay available after escalation.
    expect(find.text('I am safe'), findsOneWidget);
    expect(find.text('Send SOS now'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('still works without arguments', (tester) async {
    await _pumpSafetyCheck(tester);

    expect(find.text('Are you safe?'), findsOneWidget);
    expect(find.textContaining('your trip'), findsOneWidget);
    expect(find.text('Auto-alert in'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });
}
