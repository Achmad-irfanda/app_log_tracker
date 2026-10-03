## 0.1.0

* Initial release.
* Custom `track(keyEvent, id, status, data)` dengan dedup
  (`keyEvent + entityId + payload hash`): sama -> skip, beda -> tambah.
* Payload batch `{batch_id, sent_at, events}` dengan `batch_id` uuid
  sebagai idempotency key.
* `flush(send)` dengan timeout 15s, bedain 4xx terminal vs 5xx retryable.
* `TrackerDioInterceptor` + `TrackedHttpClient` untuk auto `api_log`.
* `SqfliteTrackStorage` (persist, UNIQUE dedup_key, FIFO trim)
  + `InMemoryTrackStorage` (test).
* Overlay debug: `TrackerLogPage` (search, filter, detail) + `TrackerBubble`.
* `LogTrackerConfig(maxQueue: 500, batchSize: 50)` + `clear()` untuk logout.
