import 'package:flutter/material.dart';

import '../../../core/widgets/proxied_image.dart';
import '../../../extensions/models/content_item.dart';
import '../../../extensions/models/content_source.dart';
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
  late Future<List<ContentItem>> _future;

  @override
  void initState() {
    super.initState();
    _source = _registry.active;
    _future = _source.getHome();
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
      _future = _source.getHome();
    });
  }

  Future<void> _refresh() => setState(() {
        _future = _source.getHome();
      }) as Future<void>;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<ContentItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? const [];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: items.isEmpty
                ? _EmptyState(sourceName: _source.name)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _ContentCard(item: items[i]),
                  ),
          );
        },
      );
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
