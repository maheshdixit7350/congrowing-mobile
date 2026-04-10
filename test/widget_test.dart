import 'package:flutter_test/flutter_test.dart';
import 'package:congrowing/main.dart';

void main() {
  testWidgets('ConGrowing app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ConGrowingApp());
    expect(find.byType(ConGrowingApp), findsOneWidget);
  });
}
