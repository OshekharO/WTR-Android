import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:otaku_stream/src/core/storage/prefs_service.dart';
import 'package:otaku_stream/src/extensions/models/chapter_item.dart';
import 'package:otaku_stream/src/extensions/models/content_details.dart';
import 'package:otaku_stream/src/extensions/models/content_item.dart';
import 'package:otaku_stream/src/extensions/novel/wtr_source.dart';
import 'package:otaku_stream/src/extensions/registry/source_registry.dart';
import 'package:otaku_stream/src/features/home/presentation/home_page.dart';

void main() {
  testWidgets('Home tab renders section rails', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await PrefsService.init();

    final fakeSource = _FakeWtrNovelSource();
    SourceRegistry.instance.register(fakeSource);
    await PrefsService.instance.setActiveSourceId(fakeSource.id);
    SourceRegistry.instance.init();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Latest'), findsOneWidget);
    expect(find.text('Today Trending'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Latest Story'), findsOneWidget);
  });
}

class _FakeWtrNovelSource extends WtrNovelSource {
  @override
  String get id => 'fake_wtr_novel';

  @override
  String get name => 'Fake WTR';

  @override
  Future<List<ContentItem>> getHome() async => const [];

    Future<List<ContentItem>> getLatest({int page = 1, int limit = 10}) async =>
      _items.take(limit).toList(growable: false);

  @override
  Future<List<ContentItem>> getRanking({required String type, int limit = 10}) async =>
      _items.take(limit).toList(growable: false);

  @override
  Future<ContentDetails> getDetails(ContentItem item) async =>
      ContentDetails.fromItem(item);

  @override
  Future<List<ChapterItem>> getChapters(ContentItem item) async => const [];

  @override
  Future<String> getChapterContent({
    required ContentItem item,
    required int chapterId,
    required int chapterNo,
  }) async =>
      '';

  @override
  Future<List<String>> getChapterImages({
    required ContentItem item,
    required int chapterId,
    required int chapterNo,
  }) async =>
      const [];

  @override
  Future<String?> getEpisodeUrl({
    required ContentItem item,
    required int episodeId,
    required int episodeNo,
  }) async =>
      null;

  static const _items = [
    ContentItem(
      id: 1,
      rawId: 1,
      slug: 'latest-story',
      title: 'Latest Story',
      author: 'Author One',
      description: 'Latest description',
      coverUrl: 'https://img.wtr-lab.com/cdn/series/test1.jpg',
      chapterCount: 12,
      sourceId: 'fake_wtr_novel',
    ),
    ContentItem(
      id: 2,
      rawId: 2,
      slug: 'second-story',
      title: 'Second Story',
      author: 'Author Two',
      description: 'Second description',
      coverUrl: 'https://img.wtr-lab.com/cdn/series/test2.jpg',
      chapterCount: 42,
      sourceId: 'fake_wtr_novel',
    ),
  ];
}
