import 'package:app_log_tracker/app_log_tracker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Demo app_log_tracker:
/// - custom event (errorApiRegistrasi, notif_read)
/// - auto API log via Dio + http
/// - dedup, payload preview, flush, overlay UI
void main() {
  runApp(const TrackerDemoApp());
}

class TrackerDemoApp extends StatefulWidget {
  const TrackerDemoApp({super.key});

  @override
  State<TrackerDemoApp> createState() => _TrackerDemoAppState();
}

class _TrackerDemoAppState extends State<TrackerDemoApp> {
  late final LogTracker tracker;
  late final Dio dio;
  String _log = 'Siap. Track sesuatu dulu.';

  @override
  void initState() {
    super.initState();
    // Ganti ke SqfliteTrackStorage() untuk persist antar restart.
    tracker = LogTracker(storage: InMemoryTrackStorage());
    dio = Dio()..interceptors.add(TrackerDioInterceptor(tracker));
  }

  void _info(String s) => setState(() => _log = s);

  Future<void> _trackErrorRegistrasi() async {
    final added = await tracker.track(
      keyEvent: 'errorApiRegistrasi',
      id: 'user_123',
      status: TrackStatus.failed,
      data: {'code': 'EMAIL_TAKEN', 'message': 'Email sudah dipakai'},
    );
    _info(added ? 'errorApiRegistrasi DITAMBAH' : 'DUPLIKAT -> di-skip');
  }

  Future<void> _trackNotifRead() async {
    final added = await tracker.track(
      keyEvent: 'notif_read',
      id: 'notif_${DateTime.now().millisecond}',
      status: TrackStatus.success,
      data: {'read': true},
    );
    _info(added ? 'notif_read DITAMBAH' : 'DUPLIKAT -> di-skip');
  }

  Future<void> _hitDio() async {
    try {
      await dio.get('https://jsonplaceholder.typicode.com/posts/1');
      _info('Dio GET sukses -> cek overlay, ada api_log');
    } catch (e) {
      _info('Dio error: $e');
    }
  }

  Future<void> _hitHttp() async {
    try {
      final client = TrackedHttpClient(tracker, http.Client());
      final res = await client.get(
        Uri.parse('https://jsonplaceholder.typicode.com/posts/2'),
      );
      _info('http GET ${res.statusCode} -> cek overlay, ada api_log');
    } catch (e) {
      _info('http error: $e');
    }
  }

  Future<void> _previewPayload() async {
    final payload = await tracker.buildPayload();
    final events = payload['events'] as List;
    _info(
      'batch_id: ${payload['batch_id']}\n'
      'events: ${events.length}\n'
      '${events.take(3).map((e) => (e as Map)['key_event']).join(', ')}',
    );
  }

  Future<void> _flush() async {
    final result = await tracker.flush((payload) async {
      // Ganti dengan API server lu:
      // await dio.post('https://api.lu/logs', data: payload);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      debugPrint(
        'FLUSH: ${payload['batch_id']} '
        '${(payload['events'] as List).length} events',
      );
    });
    _info(
      result.success
          ? 'FLUSH sukses, ${result.sentCount} terkirim, local dibersihkan'
          : 'FLUSH gagal, retryable=${result.retryable}: ${result.error}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'app_log_tracker demo',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text('app_log_tracker demo')),
        floatingActionButton: TrackerBubble(tracker: tracker),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _trackErrorRegistrasi,
                  child: const Text('Track errorApiRegistrasi'),
                ),
                ElevatedButton(
                  onPressed: _trackNotifRead,
                  child: const Text('Track notif_read'),
                ),
                ElevatedButton(
                  onPressed: _hitDio,
                  child: const Text('Dio GET'),
                ),
                ElevatedButton(
                  onPressed: _hitHttp,
                  child: const Text('http GET'),
                ),
                ElevatedButton(
                  onPressed: _previewPayload,
                  child: const Text('Preview payload'),
                ),
                ElevatedButton(onPressed: _flush, child: const Text('Flush')),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TrackerLogPage(tracker: tracker),
                    ),
                  ),
                  child: const Text('Buka overlay log'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _log,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Coba: tekan "Track errorApiRegistrasi" 2x -> '
              'yang kedua di-skip (dedup). Ubah data-nya -> ditambah.',
            ),
          ],
        ),
      ),
    );
  }
}
