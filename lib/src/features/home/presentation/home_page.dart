import 'package:flutter/material.dart';

import '../../details/presentation/details_page.dart';
import '../../search/presentation/search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final pages = const [
    _HomeContent(),
    SearchPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WTR Android')),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search_rounded), label: 'Search'),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final books = ['Solo Leveling', 'Omniscient Reader', 'The Beginning After The End'];
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => Card(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.menu_book_rounded)),
          title: Text(books[index]),
          subtitle: const Text('Tap to view details'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DetailsPage(title: books[index])),
          ),
        ),
      ),
    );
  }
}
