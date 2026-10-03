import 'package:flutter/material.dart';

import '../domain/track_event.dart';
import '../data/log_tracker.dart';

/// Overlay debug: list + detail + search by keyEvent.
/// V1: read-only, tanpa dependency tambahan.
class TrackerLogPage extends StatefulWidget {
  const TrackerLogPage({super.key, required this.tracker});

  final LogTracker tracker;

  @override
  State<TrackerLogPage> createState() => _TrackerLogPageState();
}

class _TrackerLogPageState extends State<TrackerLogPage> {
  String _query = '';
  TrackStatus? _filter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Log Tracker'),
        actions: [
          IconButton(
            tooltip: 'Clear (logout)',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await widget.tracker.clear();
              if (context.mounted) setState(() {});
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search keyEvent / entityId...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                ),
                const SizedBox(height: 8),
                SegmentedButton<TrackStatus?>(
                  segments: const [
                    ButtonSegment(value: null, label: Text('All')),
                    ButtonSegment(
                      value: TrackStatus.success,
                      label: Text('Success'),
                    ),
                    ButtonSegment(
                      value: TrackStatus.failed,
                      label: Text('Failed'),
                    ),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (s) => setState(() => _filter = s.first),
                ),
              ],
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<TrackEvent>>(
        future: widget.tracker.storage.query(
          keyEvent: null,
          status: _filter,
          limit: 200,
        ),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!
              .where(
                (e) =>
                    _query.isEmpty ||
                    e.keyEvent.toLowerCase().contains(_query) ||
                    e.entityId.toLowerCase().contains(_query),
              )
              .toList();
          if (items.isEmpty) {
            return const Center(child: Text('Belum ada log'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final e = items[i];
              final failed = e.status == TrackStatus.failed;
              return ListTile(
                leading: Icon(
                  failed ? Icons.error_outline : Icons.check_circle_outline,
                  color: failed ? Colors.red : Colors.green,
                ),
                title: Text(
                  e.keyEvent,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${e.entityId}\n${e.createdAt.toIso8601String()}',
                ),
                isThreeLine: true,
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(e.keyEvent),
                    content: SingleChildScrollView(
                      child: Text(e.toJson().toString()),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Tutup'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Floating bubble untuk buka log dari dalam app (debug only).
class TrackerBubble extends StatelessWidget {
  const TrackerBubble({super.key, required this.tracker});

  final LogTracker tracker;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: 'tracker_bubble',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TrackerLogPage(tracker: tracker)),
      ),
      child: const Icon(Icons.bug_report_outlined),
    );
  }
}
