# OtakuStream

OtakuStream is a Flutter-based reader app for discovering and reading web novel content from the WTR API. The project is being structured into a scalable multi-source content app that can support novels, manga, anime, and future extension-based sources without rewriting the core UI.

## Current status

The app currently includes:

- Splash screen
- Home screen
- Search screen
- Details screen
- Chapter list flow
- Reader flow foundation
- Dio-based API client
- Logger-based request debugging
- Adaptive light/dark/system theme support
- Responsive layout setup
- Demo fallback data when API calls fail

## Future direction

The planned architecture is based on a common extension/source system.

Supported source types planned:

- Novel API
- Manga API
- Anime API
- Future custom sources/extensions

Each source will define its own:

- API base URL
- Home feed logic
- Search logic
- Details parser
- Chapter/episode list logic
- Content fetch logic

The app UI should not care whether the active source is novel, manga, or anime. It should only call a common interface.

## Planned common source interface

```dart
abstract class ContentSource {
  String get id;
  String get name;
  String get type;
  String get baseUrl;

  Future<List<ContentItem>> getHome();
  Future<List<ContentItem>> search(String query);
  Future<ContentDetails> getDetails(String id);
  Future<List<ChapterItem>> getChapters(String id);
}
```

Example source classes:

```dart
class NovelSource implements ContentSource {}
class MangaSource implements ContentSource {}
class AnimeSource implements ContentSource {}
```

## Planned project structure

```txt
lib/
└── src/
    ├── core/
    │   ├── network/
    │   │   ├── api_client.dart
    │   │   ├── dio_client.dart
    │   │   └── dns_resolver_service.dart
    │   ├── storage/
    │   │   └── prefs_service.dart
    │   └── constants/
    │       └── app_constants.dart
    │
    ├── extensions/
    │   ├── models/
    │   │   ├── content_item.dart
    │   │   ├── content_details.dart
    │   │   ├── chapter_item.dart
    │   │   └── content_source.dart
    │   ├── registry/
    │   │   └── source_registry.dart
    │   ├── novel/
    │   │   └── wtr_novel_source.dart
    │   ├── manga/
    │   │   └── manga_source.dart
    │   └── anime/
    │       └── anime_source.dart
    │
    ├── features/
    │   ├── home/
    │   ├── search/
    │   ├── details/
    │   ├── chapter_list/
    │   ├── reader/
    │   ├── extensions/
    │   └── settings/
    │
    └── app.dart
```

## Main app flow

```txt
User opens app
↓
App loads selected extension from SharedPreferences
↓
Home uses active extension API
↓
User can switch extension from Extensions tab
↓
Search, Details, ChapterList and Reader use selected extension
↓
Settings handles theme, links, DNS, about and debug options
```

## Package usage

| Package | Usage |
|---|---|
| `dio` / `http` | API requests |
| `shared_preferences` | Save selected extension, theme and DNS settings |
| `dns_client` | Custom DNS resolver support |
| `cloudflare_bypass` / `cloudflare_interceptor` | Protected source handling |
| `dart_web_scraper` | Scraping sources without public APIs |
| `google_nav_bar` | Bottom navigation |
| `adaptive_theme` | Light/dark/system theme |
| `responsive_framework` | Responsive layout |
| `logger` | Debug logging |
| `leak_tracker` | Memory/debug tracking |
| `icons_launcher` | App icon setup |
| `mix`, `nb_utils` | UI utilities |

## API paths

Current WTR API constants are defined in:

```txt
lib/src/core/constants/api_constants.dart
```

Current paths include:

```dart
webBaseUrl = 'https://wtr-lab.com'
apiProxyBaseUrl = 'https://cors-bypasser-pro.vercel.app/proxy?url=https://wtr-lab.com'
serieRanking = '/api/serie/ranking'
search = '/api/search'
novelDetails = '/api/novel/details'
chapterList = '/api/novel/chapters'
readerGet = '/api/reader/get'
```

## Run locally

```bash
flutter pub get
flutter run
```

## Build APK

```bash
flutter build apk --release
```

## Development notes

- Keep API and scraping logic inside source/extension classes.
- Keep UI screens generic and source-agnostic.
- Use `Logger` for network and parser debugging.
- Use `SharedPreferences` only through a service wrapper.
- Avoid hardcoding source-specific logic inside Home, Search, Details, or Reader screens.
- Add new content providers by implementing `ContentSource` and registering it in the source registry.

## Developer

Created and maintained by Saksham Shekher / OshekharO.
