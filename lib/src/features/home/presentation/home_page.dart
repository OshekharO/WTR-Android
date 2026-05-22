import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter_cors_image/flutter_cors_image.dart';

import '../../books/data/models/book.dart';
import '../../details/presentation/details_page.dart';
import '../../search/presentation/search_page.dart';
import '../data/home_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [const _HomeTab(), const SearchPage()];
    return Scaffold(
      appBar: AppBar(title: const Text('WTR Android')),
      body: pages[_index],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: GNav(
          gap: 8,
          selectedIndex: _index,
          onTabChange: (i) => setState(() => _index = i),
          tabs: const [GButton(icon: Icons.home, text: 'Home'), GButton(icon: Icons.search, text: 'Search')],
        ),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _repo = HomeRepository();
  late Future<List<Book>> _future = _repo.fetchHomeBooks();

  Future<void> _refresh() async => setState(() => _future = _repo.fetchHomeBooks());

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Book>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final books = snap.data ?? [];
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: books.length,
              itemBuilder: (_, i) => _BookCard(book: books[i]),
            ),
          );
        },
      );
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book});
  final Book book;
  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: _CoverThumb(url: book.coverUrl),
          title: Text(book.title),
          subtitle: Text(book.author),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(book: book))),
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
          child: CustomNetworkImage(
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
