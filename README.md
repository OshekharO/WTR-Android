# OtakuStream

OtakuStream is a Flutter reader app for novels, manga, and anime-style content. The codebase provides working integrations for WTR (novels) and AsuraScans (manga), with foundations to expand into other source-driven extensions (anime, additional scraping-backed sources).

## Quick overview

- Status: Work-in-progress, source/extension-driven architecture planned
- Platform: Flutter (mobile, web, desktop targets supported by Flutter)
- SDK compatibility: Flutter `>=3.4.0 <4.0.0`

## Highlights

- Home feed (WTR ranking for novels)
- Manga viewer (AsuraScans integration)
- Search and details flows
- Chapter list and reader foundations
- Video player foundations
- Extensions screen (source selection) foundation
- Theme support (light / dark / system)
- Demo fallback data and robust networking

## Getting started

1. Install Flutter and ensure a compatible SDK version.
2. Fetch packages and run the app:

```bash
flutter pub get
flutter run
```

Build a release APK:

```bash
flutter build apk --release
```

## Project layout (key folders)

- `lib/src/app.dart` — main app entry and route/theme configuration
- `lib/src/core/` — constants, networking, storage and utilities
- `lib/src/features/` — screens and feature modules (home, search, details, reader, extensions, settings)
- `lib/src/features/extensions/` — where source/extension implementations will live

## API / Endpoints

Integrations:

- Novels: WTR — constants live in `lib/src/core/constants/api_constants.dart`.
- Manga: AsuraScans — manga/source implementation lives under `lib/src/features/reader/` or `lib/src/features/extensions/manga/` (search the workspace for the actual file if needed).

Common paths used by the current WTR integration:

```dart
webBaseUrl = 'https://wtr-lab.com'
apiProxyBaseUrl = 'https://cors-bypasser-pro.vercel.app/proxy?url=https://wtr-lab.com'
serieRanking = '/api/serie/ranking'
search = '/api/search'
novelDetails = '/api/novel/details'
chapterList = '/api/novel/chapters'
readerGet = '/api/reader/get'
```

## Architecture direction

The goal is a source-agnostic UI where screens consume common models and a `ContentSource` interface. Implementations (WTR, scraping, other APIs) live behind a `SourceRegistry` and are selectable from the Extensions screen.

Recommended interface shape (for implementers):

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

## Development notes & rules

- Keep networking and parsing inside repositories or source implementations — UI widgets should call high-level source methods only.
- Isolate Cloudflare, DNS, or scraping logic behind services.
- Preserve demo fallback data unless intentionally removed.
- Log network and parser errors via `Logger` for easier debugging.

## Roadmap (short)

- Add common models: `ContentItem`, `ContentDetails`, `ChapterItem`
- Implement `ContentSource` and `SourceRegistry`
- Convert WTR integration into a `WtrNovelSource`
- Wire Home/Search/Details/Reader to use the active source
- Expand Extensions and Settings features

## Contributing

- Open issues for bugs and feature requests.
- Create small, focused PRs with clear descriptions and testing notes.

## Maintainer

Saksham Shekher / OshekharO

---
For implementation guidance see `llms.txt` for pointers aimed at AI assistants and contributors.
