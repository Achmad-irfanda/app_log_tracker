import 'package:dio/dio.dart';

import '../domain/track_event.dart';
import 'log_tracker.dart';

/// Auto-track semua request Dio sebagai `keyEvent: 'api_log'`.
/// Pasang: `dio.interceptors.add(TrackerDioInterceptor(tracker))`.
class TrackerDioInterceptor extends Interceptor {
  TrackerDioInterceptor(this.tracker);

  final LogTracker tracker;

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _log(
      response.requestOptions,
      response.statusCode,
      TrackStatus.success,
      null,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final req = err.requestOptions;
    _log(
      req,
      err.response?.statusCode,
      TrackStatus.failed,
      err.message ?? err.type.name,
    );
    handler.next(err);
  }

  void _log(
    RequestOptions req,
    int? statusCode,
    TrackStatus status,
    String? error,
  ) {
    // Fire-and-forget: jangan block request.
    tracker.track(
      keyEvent: 'api_log',
      id: '${req.method}:${req.path}',
      status: status,
      data: {
        'method': req.method,
        'url': req.uri.toString(),
        'status_code': statusCode,
        'error': ?error,
      },
    );
  }
}
