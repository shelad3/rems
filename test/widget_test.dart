import 'package:flutter_test/flutter_test.dart';
import 'package:rems/main.dart';

void main() {
  testWidgets('App renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const REMSApp());
    expect(find.byType(REMSApp), findsOneWidget);
  });
}
