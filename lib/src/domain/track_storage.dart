import 'track_event.dart';

/// Interface storage. Domain tidak tau sqflite / memory / hive.
/// Implementasi default: InMemory (test) + Sqflite (persist).
abstract class TrackStorage {
  Future<bool> containsDedupKey(String dedupKey);
  Future<void> save(TrackEvent event);
  Future<List<TrackEvent>> getUnsynced({int limit = 100});
  Future<void> markSynced(List<String> eventIds);
  Future<void> trimExcess(int maxQueue);
  Future<List<TrackEvent>> query({
    String? keyEvent,
    TrackStatus? status,
    int limit = 100,
  });
  Future<int> count();
  Future<void> clear();
}
