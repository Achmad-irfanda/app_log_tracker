/// Bahasa UI halaman Track Log. Default Indonesia yang friendly,
/// English tersedia buat consumer luar.
enum TrackerLanguage { indonesian, english }

/// Semua string user-facing overlay. Tambah bahasa baru = tambah class.
class TrackerStrings {
  const TrackerStrings._();

  factory TrackerStrings.of(TrackerLanguage language) {
    switch (language) {
      case TrackerLanguage.indonesian:
        return const _IdStrings();
      case TrackerLanguage.english:
        return const _EnStrings();
    }
  }

  String get pageTitle => 'Track Log';
  String get searchHint => '';
  String get filterAll => '';
  String get filterSuccess => '';
  String get filterFailed => '';
  String get emptyTitle => '';
  String get emptySubtitle => '';
  String get clearTooltip => '';
  String get close => '';
  String get openLogTooltip => '';
}

class _IdStrings extends TrackerStrings {
  const _IdStrings() : super._();

  @override
  String get searchHint => 'Cari keyEvent / id...';
  @override
  String get filterAll => 'Semua';
  @override
  String get filterSuccess => 'Sukses';
  @override
  String get filterFailed => 'Gagal';
  @override
  String get emptyTitle => 'Belum ada log.';
  @override
  String get emptySubtitle => 'Track event dulu, baru muncul di sini.';
  @override
  String get clearTooltip => 'Hapus semua (misal saat logout)';
  @override
  String get close => 'Tutup';
  @override
  String get openLogTooltip => 'Buka Track Log';
}

class _EnStrings extends TrackerStrings {
  const _EnStrings() : super._();

  @override
  String get searchHint => 'Search keyEvent / id...';
  @override
  String get filterAll => 'All';
  @override
  String get filterSuccess => 'Success';
  @override
  String get filterFailed => 'Failed';
  @override
  String get emptyTitle => 'No logs yet.';
  @override
  String get emptySubtitle => 'Track an event first, it will show up here.';
  @override
  String get clearTooltip => 'Clear all (e.g. on logout)';
  @override
  String get close => 'Close';
  @override
  String get openLogTooltip => 'Open Track Log';
}
