import 'package:flutter/material.dart';
import 'package:flutter_cors_image/flutter_cors_image.dart';

import '../../books/data/models/book.dart';
import '../../chapter_list/presentation/chapter_list_page.dart';
import '../data/details_repository.dart';
import '../data/models/novel_details.dart';

class DetailsPage extends StatefulWidget {
  const DetailsPage({super.key, required this.book});
  final Book book;
  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  final _repo = DetailsRepository();
  final _similarScrollController = ScrollController();
  late Future<NovelDetails> _future = _repo.fetchDetails(widget.book);
  late Future<List<Book>> _similarFuture = _repo.fetchSimilarNovels(widget.book);

  @override
  void dispose() {
    _similarScrollController.dispose();
    super.dispose();
  }

  void _scrollSimilarBy(double delta) {
    if (!_similarScrollController.hasClients) return;
    final position = _similarScrollController.position;
    final target = (_similarScrollController.offset + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _similarScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<NovelDetails>(
        future: _future,
        builder: (context, snap) {
          final details = snap.data ?? NovelDetails.fromBook(widget.book);
          final book = details.book;
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(title: Text(book.title)),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _HeroCover(book: book),
                const SizedBox(height: 16),
                Text(
                  book.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'by ${book.author}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Text(
                  book.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(label: 'Translated', icon: Icons.translate),
                    _InfoChip(label: '${details.rawChapterCount} raw chapters', icon: Icons.auto_stories_outlined),
                    _InfoChip(label: '${details.viewCount} views', icon: Icons.visibility_outlined),
                    _InfoChip(label: '${details.inLibraryCount} in library', icon: Icons.bookmark_outline),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.list),
                    label: const Text('View Chapters'),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChapterListPage(book: book))),
                  ),
                ),
                const SizedBox(height: 20),
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
                          _StatTile(label: 'Rating', value: details.rating > 0 ? details.rating.toStringAsFixed(1) : 'N/A', icon: Icons.star_outline),
                          _StatTile(label: 'Chapters', value: '${book.chapterCount ?? details.rawChapterCount}', icon: Icons.menu_book_outlined),
                          _StatTile(label: 'Total Rate', value: '${details.totalRate}', icon: Icons.thumb_up_outlined),
                          _StatTile(label: 'Verified', value: details.rawVerified ? 'Yes' : 'No', icon: Icons.verified_outlined),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
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
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _SectionCard(
                  title: 'Original Details',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(label: 'Raw Title', value: details.rawTitle),
                      const SizedBox(height: 12),
                      _DetailRow(label: 'Raw Author', value: details.rawAuthor),
                      const SizedBox(height: 12),
                      _DetailRow(label: 'Raw Description', value: details.rawDescription),
                      const SizedBox(height: 12),
                      _DetailRow(label: 'Source', value: details.releasedByName ?? details.requestedByName ?? 'Unknown'),
                      const SizedBox(height: 12),
                      _DetailRow(label: 'Ranks', value: _formatRanks(details)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (details.lastChapters.isNotEmpty) ...[
                  _SectionCard(
                    title: 'Latest Chapters',
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: details.lastChapters.length,
                      separatorBuilder: (_, __) => const Divider(height: 20),
                      itemBuilder: (context, index) {
                        final chapter = details.lastChapters[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Text('${chapter.order}'),
                          ),
                          title: Text(chapter.title),
                          subtitle: Text([
                            if (chapter.rawName.trim().isNotEmpty) chapter.rawName,
                            if (chapter.updatedAt != null) _formatDate(context, chapter.updatedAt),
                          ].join(' • ')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (details.rawSources.isNotEmpty) ...[
                  _SectionCard(
                    title: 'Raw Sources',
                    child: Column(
                      children: details.rawSources
                          .map(
                            (source) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            source.slug.isEmpty ? 'Source ${source.id}' : source.slug,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (source.isDefault) const _MiniBadge(label: 'Default'),
                                        if (source.verified) ...[
                                          const SizedBox(width: 8),
                                          const _MiniBadge(label: 'Verified'),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Chapters: ${source.chapterCount}   Views: ${source.viewCount}'),
                                    if (source.createdAt != null) ...[
                                      const SizedBox(height: 4),
                                      Text('Created: ${_formatDate(context, source.createdAt)}'),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                FutureBuilder<List<Book>>(
                  future: _similarFuture,
                  builder: (context, similarSnap) {
                    final similarBooks = similarSnap.data ?? const <Book>[];
                    if (similarSnap.connectionState == ConnectionState.waiting && similarBooks.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (similarBooks.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Similar Novels',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cardWidth = constraints.maxWidth >= 700 ? 180.0 : 150.0;
                            final scrollStep = cardWidth + 12;

                            return SizedBox(
                              height: 250,
                              child: Row(
                                children: [
                                  IconButton.filledTonal(
                                    onPressed: () => _scrollSimilarBy(-scrollStep),
                                    icon: const Icon(Icons.chevron_left),
                                    tooltip: 'Scroll left',
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ListView.separated(
                                      controller: _similarScrollController,
                                      scrollDirection: Axis.horizontal,
                                      itemCount: similarBooks.length,
                                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                                      itemBuilder: (context, index) {
                                        final similar = similarBooks[index];
                                        return SizedBox(
                                          width: cardWidth,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(20),
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => DetailsPage(book: similar)),
                                            ),
                                            child: Card(
                                              clipBehavior: Clip.antiAlias,
                                              margin: EdgeInsets.zero,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3)),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Container(
                                                      width: double.infinity,
                                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                                      child: similar.coverUrl == null
                                                          ? const Center(child: Icon(Icons.auto_stories, size: 48))
                                                          : Padding(
                                                              padding: const EdgeInsets.all(10),
                                                              child: CustomNetworkImage(
                                                                url: similar.coverUrl!,
                                                                width: double.infinity,
                                                                height: double.infinity,
                                                                fit: BoxFit.cover,
                                                                errorWidget: const Center(child: Icon(Icons.auto_stories, size: 48)),
                                                              ),
                                                            ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.all(12),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          similar.title,
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          similar.author,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: Theme.of(context).textTheme.bodySmall,
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
                                  const SizedBox(width: 8),
                                  IconButton.filledTonal(
                                    onPressed: () => _scrollSimilarBy(scrollStep),
                                    icon: const Icon(Icons.chevron_right),
                                    tooltip: 'Scroll right',
                                  ),
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

  String _formatRanks(NovelDetails details) {
    final parts = <String>[];
    if (details.rankWeek != null) parts.add('Week #${details.rankWeek}');
    if (details.rankMonth != null) parts.add('Month #${details.rankMonth}');
    if (details.rankAll != null) parts.add('All #${details.rankAll}');
    return parts.isEmpty ? 'N/A' : parts.join(' • ');
  }

  String _formatDate(BuildContext context, DateTime? date) {
    if (date == null) return 'Unknown';
    return MaterialLocalizations.of(context).formatShortDate(date);
  }
}

class _HeroCover extends StatelessWidget {
  const _HeroCover({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: book.coverUrl == null
          ? const Center(child: Icon(Icons.auto_stories, size: 72))
          : CustomNetworkImage(
              url: book.coverUrl!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorWidget: const Center(child: Icon(Icons.auto_stories, size: 72)),
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(height: 4),
        SelectableText(value.isEmpty ? 'N/A' : value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
