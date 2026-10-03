import 'package:http/http.dart' as http;

import '../domain/track_event.dart';
import 'log_tracker.dart';

/// Wrapper `package:http` biar auto-track tanpa ubah call site.
/// Pakai: `final client = TrackedHttpClient(tracker, http.Client());`
class TrackedHttpClient extends http.BaseClient {
  TrackedHttpClient(this.tracker, this.inner);

  final LogTracker tracker;
  final http.Client inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await inner.send(request);
      stopwatch.stop();
      unawaitedLog(
        keyEvent: 'api_log',
        id: '${request.method}:${request.url.path}',
        status: response.statusCode < 400
            ? TrackStatus.success
            : TrackStatus.failed,
        data: {
          'method': request.method,
          'url': request.url.toString(),
          'status_code': response.statusCode,
          'duration_ms': stopwatch.elapsedMilliseconds,
        },
      );
      return response;
    } catch (e) {
      stopwatch.stop();
      unawaitedLog(
        keyEvent: 'api_log',
        id: '${request.method}:${request.url.path}',
        status: TrackStatus.failed,
        data: {
          'method': request.method,
          'url': request.url.toString(),
          'error': e.toString(),
          'duration_ms': stopwatch.elapsedMilliseconds,
        },
      );
      rethrow;
    }
  }

  void unawaitedLog({
    required String keyEvent,
    required String id,
    required TrackStatus status,
    required Map<String, dynamic> data,
  }) {
    // ignore: discarded_futures
    tracker.track(keyEvent: keyEvent, id: id, status: status, data: data);
  }
}
