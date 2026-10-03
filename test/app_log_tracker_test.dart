import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_log_tracker/app_log_tracker.dart';

void main() {
  test('dedup: same keyEvent+id+data -> skipped', () async {
    final tracker = LogTracker();
    final first = await tracker.track(
      keyEvent: 'errorApi',
      id: 'user_123',
      status: TrackStatus.failed,
      data: {'code': 'EMAIL_TAKEN'},
    );
    final second = await tracker.track(
      keyEvent: 'errorApi',
      id: 'user_123',
      status: TrackStatus.failed,
      data: {'code': 'EMAIL_TAKEN'},
    );
    expect(first, true);
    expect(second, false);
    expect(await tracker.storage.count(), 1);
  });

  test('different data -> added', () async {
    final tracker = LogTracker();
    await tracker.track(
      keyEvent: 'errorApi',
      id: 'user_123',
      status: TrackStatus.failed,
      data: {'code': 'EMAIL_TAKEN'},
    );
    final added = await tracker.track(
      keyEvent: 'errorApi',
      id: 'user_123',
      status: TrackStatus.failed,
      data: {'code': 'PHONE_TAKEN'},
    );
    expect(added, true);
    expect(await tracker.storage.count(), 2);
  });

  test('buildPayload wraps events with batch_id', () async {
    final tracker = LogTracker();
    await tracker.track(
      keyEvent: 'notif_read',
      id: 'notif_1',
      status: TrackStatus.success,
      data: {'read': true},
    );
    final payload = await tracker.buildPayload();
    expect(payload.containsKey('batch_id'), true);
    expect(payload.containsKey('sent_at'), true);
    expect((payload['events'] as List).length, 1);
  });

  test('flush success clears queue', () async {
    final tracker = LogTracker();
    await tracker.track(
      keyEvent: 'notif_read',
      id: 'notif_1',
      status: TrackStatus.success,
      data: {'read': true},
    );
    final result = await tracker.flush((_) async {});
    expect(result.success, true);
    expect(result.sentCount, 1);
    expect(await tracker.storage.count(), 0);
  });

  test('deleteEvents removes only given ids', () async {
    final tracker = LogTracker();
    await tracker.track(
      keyEvent: 'errorApi',
      id: 'a',
      status: TrackStatus.failed,
      data: const {},
    );
    await tracker.track(
      keyEvent: 'errorApi',
      id: 'b',
      status: TrackStatus.failed,
      data: const {},
    );
    final events = await tracker.storage.getUnsynced();
    expect(events.length, 2);
    await tracker.deleteEvents([events.first.eventId]);
    expect(await tracker.storage.count(), 1);
  });

  test('auto-export sends and clears on interval', () async {
    final tracker = LogTracker();
    await tracker.track(
      keyEvent: 'notif_read',
      id: 'n1',
      status: TrackStatus.success,
      data: const {'read': true},
    );
    var sent = 0;
    tracker.startAutoExport(
      (_) async => sent++,
      interval: const Duration(milliseconds: 50),
    );
    expect(tracker.isAutoExportRunning, true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    tracker.stopAutoExport();
    expect(sent, greaterThanOrEqualTo(1));
    expect(await tracker.storage.count(), 0);
    expect(tracker.isAutoExportRunning, false);
  });

  test('strings ID & EN terisi semua', () {
    for (final lang in TrackerLanguage.values) {
      final s = TrackerStrings.of(lang);
      for (final v in [
        s.searchHint,
        s.filterAll,
        s.filterSuccess,
        s.filterFailed,
        s.emptyTitle,
        s.emptySubtitle,
        s.clearTooltip,
        s.close,
        s.openLogTooltip,
      ]) {
        expect(v.isNotEmpty, true, reason: '$lang has empty string');
      }
    }
    expect(
      TrackerStrings.of(TrackerLanguage.indonesian).searchHint,
      isNot(TrackerStrings.of(TrackerLanguage.english).searchHint),
    );
  });

  testWidgets('overlay English renders English strings', (tester) async {
    final tracker = LogTracker();
    await tracker.track(
      keyEvent: 'errorApi',
      id: 'u1',
      status: TrackStatus.failed,
      data: const {},
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TrackerLogPage(
          tracker: tracker,
          language: TrackerLanguage.english,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Track Log'), findsOneWidget);
    expect(find.text('Search keyEvent / id...'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('errorApi'), findsOneWidget);
  });

  testWidgets('overlay Indonesian renders Indonesian strings', (tester) async {
    final tracker = LogTracker();
    await tester.pumpWidget(
      MaterialApp(home: TrackerLogPage(tracker: tracker)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Track Log'), findsOneWidget);
    expect(find.text('Cari keyEvent / id...'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.textContaining('Belum ada log.'), findsOneWidget);
  });
}
