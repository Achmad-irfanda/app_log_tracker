import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/log_tracker.dart';
import '../domain/track_event.dart';
import '../domain/track_language.dart';

/// Halaman debug: lihat, cari, filter, dan hapus log yang tersimpan di local.
/// Read-only kecuali tombol hapus (dipakai saat logout / testing).
/// Bahasa UI diatur via [language] (default Indonesia).
class TrackerLogPage extends StatefulWidget {
  const TrackerLogPage({
    super.key,
    required this.tracker,
    this.language = TrackerLanguage.indonesian,
  });

  final LogTracker tracker;
  final TrackerLanguage language;

  @override
  State<TrackerLogPage> createState() => _TrackerLogPageState();
}

class _TrackerLogPageState extends State<TrackerLogPage> {
  String _query = '';
  TrackStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final strings = TrackerStrings.of(widget.language);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.pageTitle),
        actions: [
          IconButton(
            tooltip: strings.clearTooltip,
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await widget.tracker.clear();
              if (context.mounted) setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: strings.searchHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(strings.filterAll),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(strings.filterSuccess),
                  selected: _filter == TrackStatus.success,
                  onSelected: (_) =>
                      setState(() => _filter = TrackStatus.success),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(strings.filterFailed),
                  selected: _filter == TrackStatus.failed,
                  onSelected: (_) =>
                      setState(() => _filter = TrackStatus.failed),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<TrackEvent>>(
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
                  return Center(
                    child: Text(
                      '${strings.emptyTitle}\n${strings.emptySubtitle}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final e = items[i];
                    final failed = e.status == TrackStatus.failed;
                    return ListTile(
                      leading: Icon(
                        failed
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
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
                        builder: (dialogContext) => AlertDialog(
                          title: Text(e.keyEvent),
                          content: SingleChildScrollView(
                            child: Text(
                              const JsonEncoder.withIndent(
                                '  ',
                              ).convert(e.toJson()),
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                          actions: [
                            TextButton(
                              // Pakai context dialog, bukan context halaman,
                              // supaya yang tertutup cuma dialognya.
                              onPressed: () => Navigator.pop(dialogContext),
                              child: Text(strings.close),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Tombol bubble buat buka log dari dalam app (debug only).
class TrackerBubble extends StatelessWidget {
  const TrackerBubble({
    super.key,
    required this.tracker,
    this.language = TrackerLanguage.indonesian,
  });

  final LogTracker tracker;
  final TrackerLanguage language;

  @override
  Widget build(BuildContext context) {
    final strings = TrackerStrings.of(language);
    return FloatingActionButton.small(
      heroTag: 'tracker_bubble',
      tooltip: strings.openLogTooltip,
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TrackerLogPage(tracker: tracker, language: language),
        ),
      ),
      child: const Icon(Icons.bug_report_outlined),
    );
  }
}
