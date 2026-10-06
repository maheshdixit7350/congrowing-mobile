import 'package:flutter_test/flutter_test.dart';
import 'package:congrowing/main.dart';

void main() {
  testWidgets('ConGrowing app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ConGrowingApp());
    expect(find.byType(ConGrowingApp), findsOneWidget);
    // Advance time to bypass the splash screen delayed navigation
    await tester.pump(const Duration(milliseconds: 3000));
    // Pump one more frame to trigger the transition
    await tester.pump();
  });
}
