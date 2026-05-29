import 'package:flutter/material.dart';

import '../../../core/widgets/proxied_image.dart';
import '../../../extensions/models/content_details.dart';
import '../../../extensions/models/content_item.dart';
import '../../../extensions/registry/source_registry.dart';
import '../../chapter_list/presentation/chapter_list_page.dart';

class DetailsPage extends StatefulWidget {
  const DetailsPage({super.key, required this.item});

  final ContentItem item;

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  final _registry = SourceRegistry.instance;
  final _similarScrollController = ScrollController();

  late final Future<ContentDetails> _future;
  late final Future<List<ContentItem>> _similarFuture;

  @override
  void initState() {
    super.initState();
    final source = _registry.active;
    _future = source.getDetails(widget.item);
    // Similar items: re-use home feed filtered by source for now.
    // Sources can override this with a dedicated endpoint later.
    _similarFuture = source.getHome().then(
          (items) => items
              .where((i) => i.id != widget.item.id)
              .take(10)
              .toList(growable: false),
        );
  }

  @override
  void dispose() {
    _similarScrollController.dispose();
    super.dispose();
  }

  void _scrollSimilarBy(double delta) {
    if (!_similarScrollController.hasClients) return;
    final pos = _similarScrollController.position;
    final target = (_similarScrollController.offset + delta)
        .clamp(pos.minScrollExtent, pos.maxScrollExtent);
    _similarScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ContentDetails>(
        future: _future,
        builder: (context, snap) {
          final details = snap.data ?? ContentDetails.fromItem(widget.item);
          final item = details.item;

          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(title: Text(item.title)),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _HeroCover(item: item),
                const SizedBox(height: 16),
                Text(
                  item.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'by ${item.author}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  details.description,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(height: 1.6),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                        label: '${details.chapterCount} chapters',
                        icon: Icons.auto_stories_outlined),
                    _InfoChip(
                        label: '${details.viewCount} views',
                        icon: Icons.visibility_outlined),
                    if (details.rating > 0)
                      _InfoChip(
                          label: details.rating.toStringAsFixed(1),
                          icon: Icons.star_outline),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.list),
                    label: const Text('View Chapters'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChapterListPage(item: item),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Quick stats ──────────────────────────────────────────────
                _SectionCard(
                  title: 'Quick Stats',
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 700 ? 4 : 2;
                      return GridView.count(
                        crossAxisCount: columns,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 2.3,
                        children: [
                          _StatTile(
                              label: 'Rating',
                              value: details.rating > 0
                                  ? details.rating.toStringAsFixed(1)
                                  : 'N/A',
                              icon: Icons.star_outline),
                          _StatTile(
                              label: 'Chapters',
                              value: '${details.chapterCount}',
                              icon: Icons.menu_book_outlined),
                          _StatTile(
                              label: 'Views',
                              value: '${details.viewCount}',
                              icon: Icons.visibility_outlined),
                          ...details.extraFields.entries.map(
                            (e) => _StatTile(
                                label: e.key,
                                value: e.value,
                                icon: Icons.info_outline),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // ── Tags ─────────────────────────────────────────────────────
                if (details.tags.isNotEmpty) ...[
                  _SectionCard(
                    title: 'Tags',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: details.tags
                          .map(
                            (tag) => Chip(
                              label: Text(tag),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Raw details (novel-specific) ──────────────────────────────
                if (details.rawTitle != null ||
                    details.rawAuthor != null ||
                    details.rawDescription != null) ...[
                  _SectionCard(
                    title: 'Original Details',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (details.rawTitle != null) ...[
                          _DetailRow(
                              label: 'Raw Title', value: details.rawTitle!),
                          const SizedBox(height: 12),
                        ],
                        if (details.rawAuthor != null) ...[
                          _DetailRow(
                              label: 'Raw Author', value: details.rawAuthor!),
                          const SizedBox(height: 12),
                        ],
                        if (details.rawDescription != null &&
                            details.rawDescription!.isNotEmpty)
                          _DetailRow(
                              label: 'Raw Description',
                              value: details.rawDescription!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Latest chapters ───────────────────────────────────────────
                if (details.latestChapters.isNotEmpty) ...[
                  _SectionCard(
                    title: 'Latest Chapters',
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: details.latestChapters.length,
                      separatorBuilder: (_, __) => const Divider(height: 20),
                      itemBuilder: (context, index) {
                        final chapter = details.latestChapters[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            child: Text('${chapter.number}'),
                          ),
                          title: Text(chapter.title),
                          subtitle: chapter.updatedAt != null
                              ? Text(MaterialLocalizations.of(context)
                                  .formatShortDate(chapter.updatedAt!))
                              : null,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Similar content ───────────────────────────────────────────
                FutureBuilder<List<ContentItem>>(
                  future: _similarFuture,
                  builder: (context, similarSnap) {
                    final similar = similarSnap.data ?? const [];
                    if (similar.isEmpty) return const SizedBox.shrink();

                    final showSimilarControls = [
                      TargetPlatform.windows,
                      TargetPlatform.macOS,
                      TargetPlatform.linux,
                    ].contains(Theme.of(context).platform);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'More from this source',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cardWidth =
                                constraints.maxWidth >= 700 ? 180.0 : 150.0;
                            final scrollStep = cardWidth + 12;
                            return SizedBox(
                              height: 250,
                              child: Row(
                                children: [
                                  if (showSimilarControls) ...[
                                    IconButton.filledTonal(
                                      onPressed: () =>
                                          _scrollSimilarBy(-scrollStep),
                                      icon: const Icon(Icons.chevron_left),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: ListView.separated(
                                      controller: _similarScrollController,
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: similar.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 12),
                                      itemBuilder: (context, index) {
                                        final s = similar[index];
                                        return SizedBox(
                                          width: cardWidth,
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    DetailsPage(item: s),
                                              ),
                                            ),
                                            child: Card(
                                              clipBehavior: Clip.antiAlias,
                                              margin: EdgeInsets.zero,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                side: BorderSide(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .outlineVariant
                                                      .withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Container(
                                                      width: double.infinity,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .surfaceContainerHighest,
                                                      child: s.coverUrl == null
                                                          ? const Center(
                                                              child: Icon(
                                                                  Icons
                                                                      .auto_stories,
                                                                  size: 48))
                                                          : ProxiedImage(
                                                              url: s.coverUrl!,
                                                              width: double
                                                                  .infinity,
                                                              height: double
                                                                  .infinity,
                                                              fit: BoxFit.cover,
                                                              errorWidget:
                                                                  const Center(
                                                                child: Icon(
                                                                    Icons
                                                                        .auto_stories,
                                                                    size: 48),
                                                              ),
                                                            ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          s.title,
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700),
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          s.author,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  if (showSimilarControls) ...[
                                    const SizedBox(width: 8),
                                    IconButton.filledTonal(
                                      onPressed: () =>
                                          _scrollSimilarBy(scrollStep),
                                      icon: const Icon(Icons.chevron_right),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _HeroCover extends StatelessWidget {
  const _HeroCover({required this.item});

  final ContentItem item;

  @override
  Widget build(BuildContext context) => Container(
        height: 320,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.35),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: item.coverUrl == null
            ? const Center(child: Icon(Icons.auto_stories, size: 72))
            : ProxiedImage(
                url: item.coverUrl!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorWidget:
                    const Center(child: Icon(Icons.auto_stories, size: 72)),
              ),
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.25),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      );
}

class _StatTile extends StatelessWidget {
  const _StatTile(
      {required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value.isEmpty ? 'N/A' : value,
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Chip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        visualDensity: VisualDensity.compact,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
}
