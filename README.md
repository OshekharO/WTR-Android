# WTR Android

A minimal native Android starter project for testing the WTR reader API.

## API endpoint

```http
POST https://wtr-lab.com/api/reader/get
Content-Type: application/json
```

Example payload:

```json
{
  "translate": "ai",
  "language": "en",
  "raw_id": 70381,
  "chapter_no": 1,
  "retry": false,
  "force_retry": false,
  "chapter_id": 39133649
}
```

## Project structure

```text
WTR-Android/
├── app/
│   ├── build.gradle.kts
│   └── src/main/
│       ├── AndroidManifest.xml
│       ├── java/com/oshekhar/wtr/MainActivity.kt
│       └── res/values/styles.xml
├── build.gradle.kts
├── gradle.properties
├── settings.gradle.kts
└── README.md
```

## Open in Android Studio

1. Clone the repository.
2. Open the root folder in Android Studio.
3. Let Gradle sync.
4. Run the `app` configuration.
