import 'package:app_log_tracker_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Drives the demo for screenshots (captured externally via simctl).
/// Markers on stdout tell the capture script when to shoot.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('drive demo for screenshots', (tester) async {
    await tester.pumpWidget(const TrackerDemoApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Track errorApi (gagal)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Track errorApi (gagal)'));
    await tester.pumpAndSettle(); // tap kedua = dedup hit
    await tester.tap(find.text('Track notif_read (sukses)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview payload'));
    await tester.pumpAndSettle();
    debugPrint('MARKER_HOME');
    await Future<void>.delayed(const Duration(seconds: 10));

    // Buka Track Log lewat bubble pojok kanan bawah.
    await tester.tap(find.byIcon(Icons.bug_report_outlined));
    await tester.pumpAndSettle();
    debugPrint('MARKER_OVERLAY');
    await Future<void>.delayed(const Duration(seconds: 10));
  });
}
