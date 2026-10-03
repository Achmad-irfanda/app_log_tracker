import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../domain/track_event.dart';
import '../domain/track_storage.dart';

/// Storage persist pakai sqflite. Aman untuk <500 event per user,
/// support dedup via UNIQUE(dedup_key), query by key_event/status.
class SqfliteTrackStorage implements TrackStorage {
  SqfliteTrackStorage({this.dbName = 'app_log_tracker.db'});

  final String dbName;
  Database? _db;

  Future<Database> get _database async {
    final existing = _db;
    if (existing != null) return existing;
    final dir = await getDatabasesPath();
    final db = await openDatabase(
      p.join(dir, dbName),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE events(
            event_id TEXT PRIMARY KEY,
            dedup_key TEXT UNIQUE,
            key_event TEXT NOT NULL,
            entity_id TEXT NOT NULL,
            status TEXT NOT NULL,
            data TEXT NOT NULL,
            created_at TEXT NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_events_key ON events(key_event, synced)',
        );
      },
    );
    _db = db;
    return db;
  }

  @override
  Future<bool> containsDedupKey(String dedupKey) async {
    final db = await _database;
    final rows = await db.query(
      'events',
      columns: ['event_id'],
      where: 'dedup_key = ?',
      limit: 1,
      whereArgs: [dedupKey],
    );
    return rows.isNotEmpty;
  }

  @override
  Future<void> save(TrackEvent event) async {
    final db = await _database;
    await db.insert(
      'events',
      {
        'event_id': event.eventId,
        'dedup_key': event.dedupKey,
        'key_event': event.keyEvent,
        'entity_id': event.entityId,
        'status': event.status.name,
        'data': jsonEncode(event.data),
        'created_at': event.createdAt.toIso8601String(),
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore, // dedup: sama -> skip
    );
  }

  TrackEvent _rowToEvent(Map<String, Object?> row) {
    return TrackEvent(
      eventId: row['event_id'] as String,
      keyEvent: row['key_event'] as String,
      entityId: row['entity_id'] as String,
      status: (row['status'] as String) == 'failed'
          ? TrackStatus.failed
          : TrackStatus.success,
      data: Map<String, dynamic>.from(jsonDecode(row['data'] as String) as Map),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  @override
  Future<List<TrackEvent>> getUnsynced({int limit = 100}) async {
    final db = await _database;
    final rows = await db.query(
      'events',
      where: 'synced = 0',
      orderBy: 'created_at ASC',
      limit: limit,
    );
    return rows.map(_rowToEvent).toList();
  }

  @override
  Future<void> markSynced(List<String> eventIds) async {
    if (eventIds.isEmpty) return;
    final db = await _database;
    final placeholders = List.filled(eventIds.length, '?').join(',');
    await db.delete(
      'events',
      where: 'event_id IN ($placeholders)',
      whereArgs: eventIds,
    );
  }

  @override
  Future<void> trimExcess(int maxQueue) async {
    final db = await _database;
    final total = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM events'),
    );
    if (total == null || total <= maxQueue) return;
    final toDelete = total - maxQueue;
    await db.execute('''
      DELETE FROM events WHERE event_id IN (
        SELECT event_id FROM events ORDER BY created_at ASC LIMIT $toDelete
      )
    ''');
  }

  @override
  Future<List<TrackEvent>> query({
    String? keyEvent,
    TrackStatus? status,
    int limit = 100,
  }) async {
    final db = await _database;
    final where = <String>[];
    final args = <Object?>[];
    if (keyEvent != null) {
      where.add('key_event = ?');
      args.add(keyEvent);
    }
    if (status != null) {
      where.add('status = ?');
      args.add(status.name);
    }
    final rows = await db.query(
      'events',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(_rowToEvent).toList();
  }

  @override
  Future<int> count() async {
    final db = await _database;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM events'),
        ) ??
        0;
  }

  @override
  Future<void> clear() async {
    final db = await _database;
    await db.delete('events');
  }
}
