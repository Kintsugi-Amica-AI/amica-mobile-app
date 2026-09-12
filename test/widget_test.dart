import 'package:amica_mobile_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('primary command is accessible and invokes its action',
      (tester) async {
    var presses = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PrimaryButton(
      label: 'Save contact',
      onPressed: () => presses++,
    ))));
    expect(find.text('Save contact'), findsOneWidget);
    await tester.tap(find.text('Save contact'));
    expect(presses, 1);
  });
}
