import 'package:app_log_tracker_example/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Drives the demo for screenshots (captured externally via simctl).
/// Markers on stdout tell the capture script when to shoot.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('drive demo for screenshots', (tester) async {
    await tester.pumpWidget(const TrackerDemoApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Track errorApiRegistrasi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Track errorApiRegistrasi'));
    await tester.pumpAndSettle(); // second tap = dedup hit
    await tester.tap(find.text('Track notif_read'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview payload'));
    await tester.pumpAndSettle();
    debugPrint('MARKER_HOME');
    await Future<void>.delayed(const Duration(seconds: 10));

    await tester.tap(find.text('Buka overlay log'));
    await tester.pumpAndSettle();
    debugPrint('MARKER_OVERLAY');
    await Future<void>.delayed(const Duration(seconds: 10));
  });
}
