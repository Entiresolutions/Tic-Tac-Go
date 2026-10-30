import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_go/main.dart';

void main() {
  testWidgets('CaroApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CaroApp());
    expect(find.byType(CaroApp), findsOneWidget);
  });
}
