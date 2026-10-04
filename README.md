# app_log_tracker

[![pub package](https://img.shields.io/pub/v/app_log_tracker.svg)](https://pub.dev/packages/app_log_tracker)

Event + API log tracker dengan **dedup** dan **offline outbox** untuk Flutter.

<p>
  <img src="https://github.com/Achmad-irfanda/app_log_tracker/raw/main/screenshots/demo-home.png" width="280" alt="Demo app">
  <img src="https://github.com/Achmad-irfanda/app_log_tracker/raw/main/screenshots/overlay-log.png" width="280" alt="Halaman Track Log">
</p>

Bukan cuma HTTP logger. Consumer bisa track event custom apapun
(`errorApi`, `notif_read`, ...), disimpan dulu di local,
di-dedup (`keyEvent + id + data`), lalu dikirim ke server sebagai
satu batch JSON dengan `batch_id` unik.

Cocok untuk: tracking error log, tracking user baca notifikasi multi-case,
positive/negative case, dan API log otomatis (Dio + http).

## Fitur

- `track(keyEvent, id, status, data)` — custom event apapun
- Dedup otomatis: sama persis → skip, beda → tambah
- Auto API log: `TrackerDioInterceptor` + `TrackedHttpClient`
- Outbox: simpan di local dulu, `flush()` / `startAutoExport()` kirim batch ke server
- `deleteEvents(ids)` buat hapus manual, `clear()` wajib saat logout
- `batch_id` (uuid) sebagai idempotency key per payload
- Bahasa UI overlay: Indonesia (default) + English via `TrackerLanguage`
- Storage: `SqfliteTrackStorage` (persist) + `InMemoryTrackStorage` (test)
- Overlay debug: list, search, filter success/failed, detail JSON, clear
- Cap 500 event per device (FIFO), batch 50, timeout 15s, bedain 4xx vs 5xx

## Install

```yaml
dependencies:
  app_log_tracker: ^0.3.1
```

## Usage

### 1. Custom event + dedup

```dart
import 'package:app_log_tracker/app_log_tracker.dart';

final tracker = LogTracker(storage: SqfliteTrackStorage());

final added = await tracker.track(
  keyEvent: 'errorApi',
  id: 'user_123',
  status: TrackStatus.failed,
  data: {'code': 'EMAIL_TAKEN'},
);
// added == false kalau keyEvent+id+data sudah ada -> di-skip
```

### 2. Auto API log (Dio + http)

```dart
final dio = Dio()..interceptors.add(TrackerDioInterceptor(tracker));

final client = TrackedHttpClient(tracker, http.Client());
await client.get(Uri.parse('https://api.lu/users'));
```

### 3. Kirim ke server (outbox)

Payload yang dikirim:

```json
{
  "batch_id": "uuid-v4",
  "sent_at": "2026-10-03T10:00:00+07:00",
  "events": [
    {
      "event_id": "uuid",
      "key_event": "errorApi",
      "entity_id": "user_123",
      "status": "failed",
      "data": {"code": "EMAIL_TAKEN"},
      "created_at": "..."
    }
  ]
}
```

```dart
final result = await tracker.flush((payload) async {
  await dio.post('https://api.lu/logs', data: payload);
});
if (!result.success && result.retryable) {
  // 5xx / timeout -> coba lagi nanti dengan backoff
}
```

### 4. Overlay debug

```dart
// Bubble kecil di pojok (debug only):
TrackerBubble(tracker: tracker)

// Atau full page (bisa pilih bahasa):
Navigator.push(context,
  MaterialPageRoute(builder: (_) => TrackerLogPage(
    tracker: tracker,
    language: TrackerLanguage.english, // atau .indonesian (default)
  )));
```

### 5. Logout

```dart
await tracker.clear(); // wajib, biar data user tidak bocor
```

## Alur kerja: record → export → bersih

```
track() → local (dedup) → export → server → sukses = hapus local
```

| Operasi | API | Keterangan |
|---|---|---|
| Create | `track(keyEvent, id, status, data)` | `false` = duplikat, di-skip |
| Read | `query()` / halaman Track Log | Lihat & filter di device |
| Update | `track()` lagi dengan data baru | Log itu immutable; koreksi = event baru (dedup otomatis bedain) |
| Delete | `flush()` sukses / `deleteEvents(ids)` / `clear()` | Flush sukses langsung hapus local |

### Preview vs Flush vs Auto-export

- **Preview** (`buildPayload`) — cuma INTIP: return JSON tanpa hapus local.
  Buat debug atau sync manual (copy → POST sendiri → `deleteEvents`).
- **Flush** (`flush(send)`) — KIRIM SEKALI + hapus yang sukses dari local.
  Device lanjut nge-log data fresh sesudahnya.
- **Auto-export** (`startAutoExport(send, interval: ...)`) — flush jalan
  sendiri tiap interval (misal 5 menit). Gagal = dicoba lagi interval
  berikutnya. Matikan via `stopAutoExport()` (otomatis mati saat `clear()`).

### Contoh negative case (API gagal)

```dart
try {
  final res = await dio.post('https://api.lu/register', data: form);
  await tracker.track(
    keyEvent: 'register',
    id: userId,
    status: TrackStatus.success,
    data: {'user_id': res.data['id']},
  );
} on DioException catch (e) {
  await tracker.track(
    keyEvent: 'errorApi',
    id: userId,
    status: TrackStatus.failed,
    data: {'code': e.response?.data['code'], 'url': e.requestOptions.path},
  );
}
```

### Kontrak server (tinggal POST payload)

```dart
tracker.startAutoExport(
  (payload) => dio.post('https://api.internal.lu/logs', data: payload),
  interval: const Duration(minutes: 5),
);
```

Server terima `{batch_id, sent_at, events: [...]}`.
Dedup by `event_id`/`batch_id` di server biar retry aman.
Sukses simpan → balas 200 → package otomatis hapus local.

## Konfigurasi

```dart
LogTracker(
  storage: SqfliteTrackStorage(),
  config: const LogTrackerConfig(maxQueue: 500, batchSize: 50),
)
```

- `maxQueue`: maksimal event per device, lebih → FIFO buang paling lama
- `batchSize`: event per sekali `flush()`

## Example

Lihat `example/` untuk demo lengkap:
custom track, Dio GET, http GET, preview payload, flush, overlay.

```sh
cd example
flutter run
```

## Additional information

- Butuh persist antar restart → `SqfliteTrackStorage()`
- Butuh unit test cepat → `InMemoryTrackStorage()`
- Mau engine sendiri (Drift/Hive) → implement `TrackStorage`
- Issue & kontribusi via GitHub repo di pubspec.
