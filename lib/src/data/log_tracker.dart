import 'dart:async';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../domain/track_event.dart';
import '../domain/track_storage.dart';
import 'in_memory_storage.dart';

class LogTrackerConfig {
  const LogTrackerConfig({this.maxQueue = 500, this.batchSize = 50});

  /// Maksimal event tersimpan per device (FIFO).
  final int maxQueue;

  /// Jumlah event per sekali kirim ke server.
  final int batchSize;
}

class FlushResult {
  const FlushResult({
    required this.success,
    required this.sentCount,
    required this.retryable,
    this.error,
  });

  final bool success;
  final int sentCount;
  final bool retryable;
  final Object? error;
}

/// Entry point package. Thread aman untuk <500 event per user.
class LogTracker {
  LogTracker({TrackStorage? storage, this.config = const LogTrackerConfig()})
    : storage = storage ?? InMemoryTrackStorage();

  final TrackStorage storage;
  final LogTrackerConfig config;
  final _uuid = const Uuid();

  /// Track event custom. Contoh:
  /// `track(keyEvent: 'errorApi', id: userId, status: failed, data: {...})`
  ///
  /// Return `false` kalau duplicate (sama keyEvent+id+data) -> tidak ditambah.
  Future<bool> track({
    required String keyEvent,
    required String id,
    required TrackStatus status,
    Map<String, dynamic> data = const {},
  }) async {
    final event = TrackEvent(
      eventId: _uuid.v4(),
      keyEvent: keyEvent,
      entityId: id,
      status: status,
      data: Map<String, dynamic>.from(data),
      createdAt: DateTime.now(),
    );
    if (await storage.containsDedupKey(event.dedupKey)) return false;
    await storage.save(event);
    await storage.trimExcess(config.maxQueue);
    return true;
  }

  /// Bangun payload siap kirim: `{batch_id, sent_at, events: [...]}`.
  /// `batch_id` adalah idempotency key: generate sekali per payload.
  Future<Map<String, dynamic>> buildPayload({int? limit}) async {
    final events = await storage.getUnsynced(limit: limit ?? config.batchSize);
    return {
      'batch_id': _uuid.v4(),
      'sent_at': DateTime.now().toIso8601String(),
      'events': events.map((e) => e.toJson()).toList(),
    };
  }

  /// Kirim batch via [send]. Sukses -> hapus dari local.
  /// 4xx -> terminal (retryable=false), 5xx/timeout -> retryable=true.
  Future<FlushResult> flush(
    Future<void> Function(Map<String, dynamic> payload) send,
  ) async {
    final events = await storage.getUnsynced(limit: config.batchSize);
    if (events.isEmpty) {
      return const FlushResult(success: true, sentCount: 0, retryable: false);
    }
    final payload = {
      'batch_id': _uuid.v4(),
      'sent_at': DateTime.now().toIso8601String(),
      'events': events.map((e) => e.toJson()).toList(),
    };
    try {
      await send(payload).timeout(const Duration(seconds: 15));
      await storage.markSynced(events.map((e) => e.eventId).toList());
      return FlushResult(
        success: true,
        sentCount: events.length,
        retryable: false,
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 0;
      final terminal = code >= 400 && code < 500;
      return FlushResult(
        success: false,
        sentCount: 0,
        retryable: !terminal,
        error: e,
      );
    } catch (e) {
      return FlushResult(
        success: false,
        sentCount: 0,
        retryable: true,
        error: e,
      );
    }
  }

  /// Hapus event tertentu pakai `event_id`-nya.
  /// Dipakai kalau consumer sudah sync manual via [buildPayload].
  Future<void> deleteEvents(List<String> eventIds) =>
      storage.markSynced(eventIds);

  /// Export otomatis tiap [interval]:
  /// ambil batch -> kirim via [send] -> sukses = hapus dari local
  /// (device lanjut nge-log data fresh), gagal = coba lagi interval berikut.
  /// Tidak tumpuk: kalau flush sebelumnya belum selesai, interval dilewati.
  void startAutoExport(
    Future<void> Function(Map<String, dynamic> payload) send, {
    Duration interval = const Duration(minutes: 5),
    void Function(FlushResult result)? onResult,
  }) {
    stopAutoExport();
    _timer = Timer.periodic(interval, (_) async {
      if (_flushing) return;
      _flushing = true;
      try {
        final result = await flush(send);
        onResult?.call(result);
      } finally {
        _flushing = false;
      }
    });
  }

  /// Hentikan export otomatis. Panggil di `dispose` atau saat logout.
  void stopAutoExport() {
    _timer?.cancel();
    _timer = null;
  }

  bool get isAutoExportRunning => _timer?.isActive ?? false;

  Timer? _timer;
  bool _flushing = false;

  /// Wajib dipanggil saat logout biar data user tidak bocor.
  /// Matikan juga auto-export supaya tidak kirim data akun lama.
  Future<void> clear() async {
    stopAutoExport();
    await storage.clear();
  }
}
