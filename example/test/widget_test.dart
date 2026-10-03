// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:app_log_tracker_example/main.dart';

void main() {
  testWidgets('Demo app renders tracker actions', (WidgetTester tester) async {
    await tester.pumpWidget(const TrackerDemoApp());

    expect(find.text('app_log_tracker demo'), findsOneWidget);
    expect(find.text('Track errorApi (gagal)'), findsOneWidget);
    expect(find.text('Track notif_read (sukses)'), findsOneWidget);
    expect(find.text('Flush'), findsOneWidget);
    expect(find.text('Auto-export on/off'), findsOneWidget);
  });
}
