import 'package:flutter_test/flutter_test.dart';

import 'package:qr_scanner/main.dart';

void main() {
  testWidgets('Shows good / bad experience choices', (WidgetTester tester) async {
    await tester.pumpWidget(const ReckoApp());

    expect(find.text('Recko Restaurant'), findsOneWidget);
    expect(find.text('😊  I had a great experience'), findsOneWidget);

    await tester.tap(find.text('😞  I had a bad experience'));
    await tester.pump();

    expect(find.text('Send via WhatsApp'), findsOneWidget);
    expect(find.text('Send as SMS'), findsOneWidget);
  });
}
