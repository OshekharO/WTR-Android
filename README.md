# WTR Android

Flutter reader app with operational Home, Search, Details, Chapter List and Reader screens.

## API paths

Defined in `lib/src/core/constants/api_constants.dart`:

```dart
baseUrl = 'https://wtr-lab.com'
home = '/api/home'
search = '/api/search'
novelDetails = '/api/novel/details'
chapterList = '/api/novel/chapters'
readerGet = '/api/reader/get'
```

The app calls these paths through Dio and falls back to demo data if an endpoint is unavailable, so the UI remains runnable.

## Run

```bash
flutter pub get
flutter run
```
