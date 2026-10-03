import '../domain/track_event.dart';
import '../domain/track_storage.dart';

/// Storage in-memory. Buat unit test & fallback tanpa native.
class InMemoryTrackStorage implements TrackStorage {
  final Map<String, TrackEvent> _byDedup = {};
  final List<String> _order = [];
  final Set<String> _synced = {};

  @override
  Future<bool> containsDedupKey(String dedupKey) async =>
      _byDedup.containsKey(dedupKey);

  @override
  Future<void> save(TrackEvent event) async {
    if (_byDedup.containsKey(event.dedupKey)) return;
    _byDedup[event.dedupKey] = event;
    _order.add(event.dedupKey);
  }

  @override
  Future<List<TrackEvent>> getUnsynced({int limit = 100}) async {
    final out = <TrackEvent>[];
    for (final k in _order) {
      final e = _byDedup[k]!;
      if (!_synced.contains(e.eventId)) {
        out.add(e);
        if (out.length >= limit) break;
      }
    }
    return out;
  }

  @override
  Future<void> markSynced(List<String> eventIds) async {
    // Hapus langsung biar queue tidak bengkak (<500 target).
    final ids = eventIds.toSet();
    _byDedup.removeWhere((_, e) => ids.contains(e.eventId));
    _order.removeWhere((k) => !_byDedup.containsKey(k));
    _synced.removeAll(ids);
  }

  @override
  Future<void> trimExcess(int maxQueue) async {
    while (_order.length > maxQueue) {
      final oldest = _order.removeAt(0);
      _byDedup.remove(oldest);
    }
  }

  @override
  Future<List<TrackEvent>> query({
    String? keyEvent,
    TrackStatus? status,
    int limit = 100,
  }) async {
    return _order
        .map((k) => _byDedup[k]!)
        .where(
          (e) =>
              (keyEvent == null || e.keyEvent == keyEvent) &&
              (status == null || e.status == status),
        )
        .take(limit)
        .toList();
  }

  @override
  Future<int> count() async => _byDedup.length;

  @override
  Future<void> clear() async {
    _byDedup.clear();
    _order.clear();
    _synced.clear();
  }
}
