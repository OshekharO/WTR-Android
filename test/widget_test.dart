import 'package:flutter_test/flutter_test.dart';

import 'package:otaku_stream/main.dart';

void main() {
  testWidgets('App smoke test — OtakuStream launches',
      (WidgetTester tester) async {
    await tester.pumpWidget(const OtakuStreamApp());
    expect(find.byType(OtakuStreamApp), findsOneWidget);
  });
}
