import 'package:flutter_test/flutter_test.dart';
import 'package:physics_platform_mobile/main.dart';

void main() {
  testWidgets('Physics login screen loads', (tester) async {
    await tester.pumpWidget(const PhysicsApp());

    expect(find.text('Physics'), findsOneWidget);
    expect(find.text('Eng. Ahmed Rabie'), findsOneWidget);
    expect(find.text('دخول إلى المنصة'), findsOneWidget);
  });
}
