import 'package:amica_mobile_app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Amica app starts on login screen', (tester) async {
    await tester.pumpWidget(const AmicaApp());

    expect(find.text('Amica'), findsOneWidget);
    expect(find.text('Log in'), findsWidgets);
  });
}
