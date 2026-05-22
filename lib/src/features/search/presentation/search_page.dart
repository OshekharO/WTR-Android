import 'package:flutter/material.dart';
import 'package:flutter_cors_image/flutter_cors_image.dart';

import '../../books/data/models/book.dart';
import '../../details/presentation/details_page.dart';
import '../data/search_repository.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _repo = SearchRepository();
  final TextEditingController _controller = TextEditingController();
  List<Book> _results = const <Book>[];
  bool _loading = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _runSearch('');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String q) async {
    final trimmed = q.trim();
    setState(() {
      _query = trimmed;
      _loading = true;
    });

    final results = await _repo.search(trimmed);
    if (!mounted) return;

    setState(() {
      _results = results;
      _loading = false;
    });
  }

  void _onSearch(String q) => _runSearch(q);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SearchBar(
              controller: _controller,
              hintText: 'Search novels...',
              leading: const Icon(Icons.search),
              trailing: [
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      _onSearch('');
                    },
                  ),
              ],
              onChanged: _onSearch,
              onSubmitted: _onSearch,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _results.isEmpty
                        ? Center(
                            child: Text(
                              _query.isEmpty ? 'Type to search novels.' : 'No results found.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                        : ListView.separated(
                            itemCount: _results.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final book = _results[index];
                              return Card(
                                child: ListTile(
                                  leading: _CoverThumb(url: book.coverUrl),
                                  title: Text(book.title),
                                  subtitle: Text(book.author),
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(book: book))),
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      );
}

class _CoverThumb extends StatelessWidget {
  const _CoverThumb({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) {
      return const CircleAvatar(child: Icon(Icons.menu_book));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: CustomNetworkImage(
            url: url!,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorWidget: const CircleAvatar(child: Icon(Icons.menu_book)),
          ),
        ),
      ),
    );
  }
}
