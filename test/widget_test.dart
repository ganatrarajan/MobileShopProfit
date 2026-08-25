import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_repair/main.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    await tester.pumpWidget(const MobileShopProfitApp());
    expect(find.byType(MobileShopProfitApp), findsOneWidget);
  });
}
