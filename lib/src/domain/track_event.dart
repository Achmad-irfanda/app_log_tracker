import 'dart:convert';

/// Positive / negative case dari sebuah event.
enum TrackStatus { success, failed }

/// Satu event log. Bisa dari API otomatis atau custom
/// (`errorApiRegistrasi`, `notif_read`, ...).
class TrackEvent {
  TrackEvent({
    required this.eventId,
    required this.keyEvent,
    required this.entityId,
    required this.status,
    required this.data,
    required this.createdAt,
  });

  final String eventId;
  final String keyEvent;
  final String entityId;
  final TrackStatus status;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  /// Kunci dedup: keyEvent + entityId + hash payload yang stabil.
  /// Sama persis -> skip, beda -> tambah ke list.
  String get dedupKey =>
      '$keyEvent|$entityId|${stableHash(canonicalJson(data))}';

  Map<String, dynamic> toJson() => {
    'event_id': eventId,
    'key_event': keyEvent,
    'entity_id': entityId,
    'status': status.name,
    'data': data,
    'created_at': createdAt.toIso8601String(),
  };

  factory TrackEvent.fromJson(Map<String, dynamic> json) => TrackEvent(
    eventId: json['event_id'] as String,
    keyEvent: json['key_event'] as String,
    entityId: json['entity_id'] as String,
    status: (json['status'] as String) == 'failed'
        ? TrackStatus.failed
        : TrackStatus.success,
    data: Map<String, dynamic>.from(json['data'] as Map),
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

/// JSON kanonis: sort keys rekursif biar hash stabil.
String canonicalJson(Map<String, dynamic> data) {
  final sortedKeys = data.keys.toList()..sort();
  final out = <String, dynamic>{};
  for (final k in sortedKeys) {
    final v = data[k];
    if (v is Map<String, dynamic>) {
      out[k] = jsonDecode(canonicalJson(v));
    } else if (v is Map) {
      out[k] = jsonDecode(canonicalJson(Map<String, dynamic>.from(v)));
    } else if (v is List) {
      out[k] = v
          .map(
            (e) => e is Map<String, dynamic> ? jsonDecode(canonicalJson(e)) : e,
          )
          .toList();
    } else {
      out[k] = v;
    }
  }
  return jsonEncode(out);
}

/// djb2 — kecil, stabil antar run (String.hashCode tidak stabil).
String stableHash(String input) {
  var hash = 5381;
  for (var i = 0; i < input.length; i++) {
    hash = ((hash << 5) + hash + input.codeUnitAt(i)) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16);
}
