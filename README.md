# Methna App

Flutter application for Methna.

## Prerequisites

- Flutter stable (3.38.x recommended for this workspace)
- Dart SDK matching Flutter SDK
- Android Studio (Android SDK + build tools)
- Xcode 15+ (for iOS release builds on macOS)

## Local Development

```bash
flutter pub get
flutter run
```

Optional runtime defines:

```bash
flutter run --dart-define=API_BASE_URL=https://your-api/api/v1 --dart-define=SOCKET_URL=https://your-api:443
```

## Release Quick Start

1. Copy `env/release.example.json` to `env/release.json` and fill real production values.
2. Ensure Android signing file exists at `android/key.properties` and points to a valid keystore.
3. Run release validation commands:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
```

4. Build Play Store bundle:

```bash
flutter build appbundle --release --dart-define-from-file=env/release.json
```

5. Build iOS archive on macOS:

```bash
flutter build ipa --release --dart-define-from-file=env/release.json
```

## Full Deployment Guide

See `docs/release_checklist.md` for complete Android + iOS store submission checklist.
