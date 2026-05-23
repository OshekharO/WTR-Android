# OtakuStream

OtakuStream is a Flutter/Dart multi-source reader app for discovering and reading novels, manga, and anime-style content. The current implementation focuses on WTR API-powered novel reading while the codebase is being shaped into a source/extension-driven architecture.

## Features

- Splash screen and responsive app shell
- Home feed using WTR ranking data
- Search flow
- Details screen
- Chapter list screen
- Novel reader foundation
- Manga reader page foundation
- Anime/video player page foundation
- Extensions screen foundation
- Settings screen foundation
- Dio-based networking with logging
- Demo fallback data when API calls fail
- Adaptive light/dark/system theme support
- Responsive layout setup

## Tech stack

- Flutter SDK `>=3.4.0 <4.0.0`
- Dart
- Dio and HTTP for networking
- SharedPreferences for local preferences
- Logger for debugging
- AdaptiveTheme for theme switching
- Responsive Framework for layouts
- Google Nav Bar for bottom navigation
- DNS Client for resolver support
- Cloudflare bypass/interceptor packages for protected sources
- Dart Web Scraper for future scraping-based sources
- Cached Network Image, Photo View, Chewie, and Video Player for media rendering

## Project structure

```txt
lib/
└── src/
    ├── app.dart
    ├── core/
    │   ├── constants/
    │   └── network/
    └── features/
        ├── books/
        ├── chapter_list/
        ├── details/
        ├── extensions/
        ├── home/
        ├── reader/
        ├── search/
        └── settings/
```

## Current API configuration

WTR API constants are defined in:

```txt
lib/src/core/constants/api_constants.dart
```

Current paths:

```dart
webBaseUrl = 'https://wtr-lab.com'
apiProxyBaseUrl = 'https://cors-bypasser-pro.vercel.app/proxy?url=https://wtr-lab.com'
serieRanking = '/api/serie/ranking'
search = '/api/search'
novelDetails = '/api/novel/details'
chapterList = '/api/novel/chapters'
readerGet = '/api/reader/get'
```

## Planned architecture

The long-term goal is to keep UI screens source-agnostic. Home, Search, Details, Chapter List, Reader, Manga Reader, and Anime Player should consume common models and source interfaces instead of directly depending on one provider.

Planned source types:

- Novel API sources
- Manga API sources
- Anime/video sources
- Scraping-based sources
- Future custom extensions

Planned common interface:

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

## Main app flow

```txt
User opens app
↓
App loads theme and app shell
↓
Home fetches WTR ranking data
↓
User searches or opens a title
↓
Details loads metadata
↓
Chapter list loads chapters
↓
Reader displays chapter content
```

Future extension flow:

```txt
User selects source from Extensions
↓
Selected source ID is saved locally
↓
Home/Search/Details/Reader use the active source
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

- Keep API and scraping logic out of UI screens.
- Put provider-specific logic inside repositories or future source/extension classes.
- Use `DioClient` for API calls.
- Use `Logger` for request, parser, and fallback debugging.
- Keep demo fallback behavior unless intentionally replacing it.
- Keep code compatible with Flutter SDK `>=3.4.0 <4.0.0`.
- Add new providers by implementing a source class and registering it in the future source registry.
- Keep Cloudflare, DNS, and scraping logic isolated from presentation widgets.

## Roadmap

- Add common source models: `ContentItem`, `ContentDetails`, and `ChapterItem`
- Add `ContentSource` interface
- Convert current WTR logic into `WtrNovelSource`
- Add `SourceRegistry`
- Add preferences service for selected source and settings
- Wire Home/Search/Details/Chapter List to active source
- Expand Extensions tab
- Improve Settings tab with DNS, theme, GitHub, issue, and about options
- Add manga and anime source implementations
- Add reader/player rendering based on content type

## Maintainer

Created and maintained by Saksham Shekher / OshekharO.
