import 'package:flutter/material.dart';
import 'package:flutter_cors_image/flutter_cors_image.dart';

import '../../books/data/models/book.dart';
import '../../chapter_list/presentation/chapter_list_page.dart';
import '../data/details_repository.dart';

class DetailsPage extends StatefulWidget {
  const DetailsPage({super.key, required this.book});
  final Book book;
  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  final _repo = DetailsRepository();
  final _similarScrollController = ScrollController();
  late Future<Book> _future = _repo.fetchDetails(widget.book);
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
  Widget build(BuildContext context) => FutureBuilder<Book>(
        future: _future,
        builder: (context, snap) {
          final book = snap.data ?? widget.book;
          return Scaffold(
            appBar: AppBar(title: Text(book.title)),
            body: ListView(padding: const EdgeInsets.all(16), children: [
              Container(
                height: 240,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                clipBehavior: Clip.antiAlias,
                child: book.coverUrl == null
                    ? const Center(child: Icon(Icons.auto_stories, size: 72))
                    : CustomNetworkImage(
                        url: book.coverUrl!,
                        width: double.infinity,
                        height: 240,
                        fit: BoxFit.cover,
                        errorWidget: const Center(child: Icon(Icons.auto_stories, size: 72)),
                      ),
              ),
              const SizedBox(height: 16),
              Text(book.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text('by ${book.author}'),
              const SizedBox(height: 12),
              Text(book.description),
              const SizedBox(height: 20),
              FilledButton.icon(icon: const Icon(Icons.list), label: const Text('View Chapters'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChapterListPage(book: book)))),
              const SizedBox(height: 24),
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
                      Text('Similar Novels', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cardWidth = constraints.maxWidth >= 700 ? 180.0 : 150.0;
                          final scrollStep = cardWidth + 12;

                          return SizedBox(
                            height: 236,
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
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    width: double.infinity,
                                                    color: Theme.of(context).colorScheme.primaryContainer,
                                                    child: similar.coverUrl == null
                                                        ? const Center(child: Icon(Icons.auto_stories, size: 48))
                                                        : CustomNetworkImage(
                                                            url: similar.coverUrl!,
                                                            width: double.infinity,
                                                            height: double.infinity,
                                                            fit: BoxFit.cover,
                                                            errorWidget: const Center(child: Icon(Icons.auto_stories, size: 48)),
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
                                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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
            ]),
          );
        },
      );
}
