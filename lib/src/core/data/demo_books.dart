import '../../features/books/data/models/book.dart';
import '../../features/chapter_list/data/models/chapter_item.dart';

const demoBooks = <Book>[
  Book(id: 70381, title: 'Future Daughters Show Up', author: 'WTR', description: 'A translated web novel available for reader testing.'),
  Book(id: 1002, title: 'Solo Leveling', author: 'Chugong', description: 'Action fantasy novel placeholder entry.'),
  Book(id: 1003, title: 'Omniscient Reader', author: 'Sing Shong', description: 'Apocalypse fantasy placeholder entry.'),
  Book(id: 1004, title: 'The Beginning After The End', author: 'TurtleMe', description: 'Fantasy adventure placeholder entry.'),
];

List<ChapterItem> demoChapters(int bookId) => List.generate(
  20,
  (i) => ChapterItem(
    id: bookId == 70381 ? 39133649 + i : bookId * 1000 + i,
    number: i + 1,
    title: 'Chapter ${i + 1}',
  ),
);
