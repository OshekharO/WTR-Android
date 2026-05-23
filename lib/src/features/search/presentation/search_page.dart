import 'package:flutter/material.dart';

import '../../../core/widgets/proxied_image.dart';
import '../../../extensions/models/content_item.dart';
import '../../../extensions/models/content_source.dart';
import '../../../extensions/registry/source_registry.dart';
import '../../details/presentation/details_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _registry = SourceRegistry.instance;
  final _controller = TextEditingController();

  late ContentSource _source;
  List<ContentItem> _results = const [];
  bool _loading = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _source = _registry.active;
    _registry.addListener(_onSourceChanged);
    _runSearch('');
  }

  @override
  void dispose() {
    _registry.removeListener(_onSourceChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onSourceChanged() {
    final newSource = _registry.active;
    if (newSource.id == _source.id) return;
    _source = newSource;
    _runSearch(_query);
  }

  Future<void> _runSearch(String q) async {
    final trimmed = q.trim();
    setState(() {
      _query = trimmed;
      _loading = true;
    });
    final results = await _source.search(trimmed);
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SearchBar(
              controller: _controller,
              hintText: 'Search ${_source.name}...',
              leading: const Icon(Icons.search),
              trailing: [
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      _runSearch('');
                    },
                  ),
              ],
              onChanged: _runSearch,
              onSubmitted: _runSearch,
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
                              _query.isEmpty
                                  ? 'Type to search ${_source.name}.'
                                  : 'No results found.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                        : ListView.separated(
                            itemCount: _results.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = _results[index];
                              return Card(
                                child: ListTile(
                                  leading: _CoverThumb(url: item.coverUrl),
                                  title: Text(item.title),
                                  subtitle: Text(item.author),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DetailsPage(item: item),
                                    ),
                                  ),
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
          child: ProxiedImage(
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
