import 'package:flutter/material.dart';

import '../../../core/widgets/proxied_image.dart';
import '../../../extensions/manga/manga_source.dart';
import '../../../extensions/models/content_item.dart';
import '../../../extensions/models/content_source.dart';
import '../../../extensions/novel/wtr_novel_source.dart';
import '../../../extensions/registry/source_registry.dart';
import '../../details/presentation/details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _registry = SourceRegistry.instance;
  late ContentSource _source;
  late Future<_HomeFeed> _future;

  @override
  void initState() {
    super.initState();
    _source = _registry.active;
    _future = _loadFeed();
    _registry.addListener(_onSourceChanged);
  }

  @override
  void dispose() {
    _registry.removeListener(_onSourceChanged);
    super.dispose();
  }

  void _onSourceChanged() {
    final newSource = _registry.active;
    if (newSource.id == _source.id) return;
    setState(() {
      _source = newSource;
      _future = _loadFeed();
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadFeed();
    });
    await _future;
  }

  Future<_HomeFeed> _loadFeed() async {
    if (_source is WtrNovelSource) {
      final wtr = _source as WtrNovelSource;
      final results = await Future.wait<List<ContentItem>>([
        wtr.getLatest(limit: 10),
        wtr.getRanking(type: 'daily', limit: 10),
        wtr.getRanking(type: 'weekly', limit: 10),
        wtr.getRanking(type: 'monthly', limit: 10),
      ]);
      return _HomeFeed.sectioned(
        sourceName: _source.name,
        items: const [],
        customSections: [
          _HomeSection(
            title: 'Latest',
            subtitle: 'Fresh additions from the novel feed',
            items: results[0],
            featured: true,
            cardWidth: 220,
          ),
          _HomeSection(
            title: 'Today Trending',
            subtitle: 'What readers are opening right now',
            items: results[1],
          ),
          _HomeSection(
            title: 'Weekly',
            subtitle: 'Top novels over the last seven days',
            items: results[2],
          ),
          _HomeSection(
            title: 'Monthly',
            subtitle: 'Top novels over the last thirty days',
            items: results[3],
          ),
        ],
      );
    }

    if (_source is MangaSource) {
      final manga = _source as MangaSource;
      final results = await Future.wait<List<ContentItem>>([
        manga.getPopular(limit: 10),
        manga.getTrending(period: 'week', limit: 10),
        manga.getTrending(period: 'month', limit: 10),
        manga.getTrending(period: 'all', limit: 10),
      ]);
      return _HomeFeed.sectioned(
        sourceName: _source.name,
        items: const [],
        customSections: [
          _HomeSection(
            title: 'Popular',
            subtitle: 'Most read manga and manhwa right now',
            items: results[0],
            featured: true,
            cardWidth: 220,
          ),
          _HomeSection(
            title: 'Weekly',
            subtitle: 'Trending over the last 7 days',
            items: results[1],
          ),
          _HomeSection(
            title: 'Monthly',
            subtitle: 'Trending over the last 30 days',
            items: results[2],
          ),
          _HomeSection(
            title: 'All Time',
            subtitle: 'The biggest titles on Asura',
            items: results[3],
          ),
        ],
      );
    }

    return _HomeFeed.single(
      sourceName: _source.name,
      items: await _source.getHome(),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_HomeFeed>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final feed = snap.data ?? _HomeFeed.single(sourceName: _source.name, items: const []);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: feed.isSectioned
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _HeroBanner(sourceName: feed.sourceName),
                      const SizedBox(height: 24),
                      for (final section in feed.customSections) ...[
                        _SectionRail(
                          title: section.title,
                          subtitle: section.subtitle,
                          items: section.items,
                          cardWidth: section.cardWidth,
                          featured: section.featured,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  )
                : feed.items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [_EmptyState(sourceName: feed.sourceName)],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: feed.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _ContentCard(item: feed.items[i]),
                      ),
          );
        },
      );
}

class _HomeFeed {
  const _HomeFeed._({
    required this.sourceName,
    required this.items,
    required this.customSections,
  });

  factory _HomeFeed.single({required String sourceName, required List<ContentItem> items}) {
    return _HomeFeed._(
      sourceName: sourceName,
      items: items,
      customSections: const [],
    );
  }

  factory _HomeFeed.sectioned({
    required String sourceName,
    required List<_HomeSection> customSections,
    required List<ContentItem> items,
  }) {
    return _HomeFeed._(
      sourceName: sourceName,
      items: items,
      customSections: customSections,
    );
  }

  final String sourceName;
  final List<ContentItem> items;
  final List<_HomeSection> customSections;

  bool get isSectioned => customSections.isNotEmpty;
}

class _HomeSection {
  const _HomeSection({
    required this.title,
    required this.items,
    this.subtitle,
    this.cardWidth = 180,
    this.featured = false,
  });

  final String title;
  final String? subtitle;
  final List<ContentItem> items;
  final double cardWidth;
  final bool featured;
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.sourceName});

  final String sourceName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colorScheme.onPrimary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.auto_stories_rounded, color: colorScheme.onPrimary, size: 34),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover stories by momentum',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Latest releases, trending manga, and extension-backed sources in one place from $sourceName.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimary.withValues(alpha: 0.88),
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionRail extends StatelessWidget {
  const _SectionRail({
    required this.title,
    required this.items,
    this.subtitle,
    this.cardWidth = 180,
    this.featured = false,
  });

  final String title;
  final String? subtitle;
  final List<ContentItem> items;
  final double cardWidth;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title, subtitle: subtitle),
        const SizedBox(height: 12),
        SizedBox(
          height: featured ? 318 : 256,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _RailCard(
              item: items[index],
              width: cardWidth,
              featured: featured,
              rank: index + 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}

class _RailCard extends StatelessWidget {
  const _RailCard({
    required this.item,
    required this.width,
    required this.rank,
    required this.featured,
  });

  final ContentItem item;
  final double width;
  final int rank;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailsPage(item: item)),
        ),
        child: Container(
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.25)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _CoverImage(url: item.coverUrl),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          featured ? 'Featured' : '#$rank',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.item});

  final ContentItem item;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: _CoverThumb(url: item.coverUrl),
          title: Text(item.title),
          subtitle: Text(item.author),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailsPage(item: item)),
          ),
        ),
      );
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.auto_stories_rounded, size: 42)),
      );
    }

    return ProxiedImage(
      url: url!,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorWidget: const Center(child: Icon(Icons.auto_stories_rounded, size: 42)),
    );
  }
}

class _CoverThumb extends StatelessWidget {
  const _CoverThumb({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) {
      return const CircleAvatar(child: Icon(Icons.auto_stories));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: ProxiedImage(
            url: url!,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorWidget: const CircleAvatar(child: Icon(Icons.auto_stories)),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.sourceName});

  final String sourceName;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded,
                size: 56, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Text(
              'No content from $sourceName',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Pull down to refresh',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
}
