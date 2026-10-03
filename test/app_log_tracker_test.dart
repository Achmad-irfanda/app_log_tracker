import 'package:flutter_test/flutter_test.dart';

import 'package:app_log_tracker/app_log_tracker.dart';

void main() {
  test('dedup: same keyEvent+id+data -> skipped', () async {
    final tracker = LogTracker();
    final first = await tracker.track(
      keyEvent: 'errorApiRegistrasi',
      id: 'user_123',
      status: TrackStatus.failed,
      data: {'code': 'EMAIL_TAKEN'},
    );
    final second = await tracker.track(
      keyEvent: 'errorApiRegistrasi',
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
      keyEvent: 'errorApiRegistrasi',
      id: 'user_123',
      status: TrackStatus.failed,
      data: {'code': 'EMAIL_TAKEN'},
    );
    final added = await tracker.track(
      keyEvent: 'errorApiRegistrasi',
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
}
