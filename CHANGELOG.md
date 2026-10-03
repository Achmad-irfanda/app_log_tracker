## 0.3.0

* Baru: multi-bahasa overlay via `TrackerLanguage.indonesian` (default,
  friendly) / `.english` — berlaku di `TrackerLogPage` + `TrackerBubble`.
* README: screenshot tampil kecil side-by-side (elegan di pub.dev).
* Example: tombol ganti bahasa ID/EN buat coba overlay dua bahasa.

## 0.2.0

* Rename contoh `errorApiRegistrasi` -> `errorApi` (generik, public-friendly).
* Baru: `startAutoExport(send, interval)` + `stopAutoExport()` — export
  periodik ke server internal, sukses = local dibersihkan otomatis.
* Baru: `deleteEvents(ids)` untuk hapus manual (CRUD lengkap).
* Fix overlay: search + filter pindah ke body (tidak nabrak header),
  tombol Tutup dialog sekarang cuma nutup dialog (pakai dialog context),
  label Bahasa Indonesia yang friendly.
* Example: hapus chip duplikat, tambah hint + tombol auto-export on/off,
  contoh positive (sukses) vs negative (gagal) case.
* README: section alur CRUD + export, flush vs preview, kontrak server.

## 0.1.1

* Add package `topics`, `issue_tracker`, `documentation` links.
* Add real iOS screenshots (demo + overlay) wired to pub.dev.
* Fix example: `Navigator.of` context now under `MaterialApp` (Builder).
* Add `integration_test` driving the demo (also used for screenshots).

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
