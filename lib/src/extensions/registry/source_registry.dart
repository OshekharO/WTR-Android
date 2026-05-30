import 'package:flutter/foundation.dart';

import '../../core/storage/prefs_service.dart';
import '../anime/anime_source.dart';
import '../manga/asura_source.dart';
import '../models/content_source.dart';
import '../novel/wtr_source.dart';

/// Holds all registered [ContentSource] instances and tracks which one is
/// currently active. Widgets listen via [ChangeNotifier].
class SourceRegistry extends ChangeNotifier {
  SourceRegistry._();

  static final SourceRegistry instance = SourceRegistry._();

  // ── Registered sources ────────────────────────────────────────────────────

  final List<ContentSource> _sources = [
    WtrNovelSource(),
    MangaSource(),
    AnimeSource(),
  ];

  List<ContentSource> get all => List.unmodifiable(_sources);

  // ── Active source ─────────────────────────────────────────────────────────

  late ContentSource _active;

  ContentSource get active => _active;

  /// Call once at startup (after [PrefsService.init]).
  void init() {
    final savedId = PrefsService.instance.activeSourceId;
    _active = _sources.firstWhere(
      (s) => s.id == savedId,
      orElse: () => _sources.first,
    );
  }

  Future<void> setActive(ContentSource source) async {
    if (_active.id == source.id) return;
    _active = source;
    await PrefsService.instance.setActiveSourceId(source.id);
    notifyListeners();
  }

  // ── Registration (for future dynamic extension loading) ───────────────────

  void register(ContentSource source) {
    if (_sources.any((s) => s.id == source.id)) return;
    _sources.add(source);
    notifyListeners();
  }

  void unregister(String sourceId) {
    _sources.removeWhere((s) => s.id == sourceId);
    if (_active.id == sourceId && _sources.isNotEmpty) {
      _active = _sources.first;
    }
    notifyListeners();
  }
}
