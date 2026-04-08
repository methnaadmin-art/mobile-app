# Release Checklist (Play Store + App Store)

Use this checklist before every production submission.

## 1) Versioning

- Update `version` in `pubspec.yaml` using `x.y.z+build`.
- Confirm version in app settings/about screen if shown.
- Use a new build number for every upload.

## 2) Secrets and Runtime Defines

- Copy `env/release.example.json` to `env/release.json`.
- Fill production values (API, socket, Stripe, merchant settings).
- Never commit `env/release.json`, `android/key.properties`, or keystore files.

## 3) Android Signing + Build

- Ensure `android/key.properties` exists with valid values:
  - `storePassword`
  - `keyPassword`
  - `keyAlias`
  - `storeFile`
- Ensure keystore file exists at the path in `storeFile`.
- Build command:

```bash
flutter build appbundle --release --dart-define-from-file=env/release.json
```

- Output artifact:
  - `build/app/outputs/bundle/release/app-release.aab`

## 4) iOS Signing + Build (macOS)

- Open `ios/Runner.xcworkspace` in Xcode.
- Set Team and Signing for Release configuration.
- Confirm Bundle Identifier is correct (`com.methna.app`).
- Confirm iOS deployment target is 13.0+.
- Build command:

```bash
flutter build ipa --release --dart-define-from-file=env/release.json
```

- Upload via Xcode Organizer or Transporter.

## 5) Quality Gates

Run all before submission:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release --dart-define-from-file=env/release.json
```

For iOS (on macOS):

```bash
flutter build ipa --release --dart-define-from-file=env/release.json
```

## 6) Store Metadata Readiness

Prepare both stores:

- App name, subtitle/short description, full description
- Category
- Privacy Policy URL
- Support URL and contact email
- Screenshots for required device classes
- App icon and feature graphic (Android)
- Age/content rating questionnaire
- Data safety / privacy nutrition details

## 7) Policy and Permissions Review

- Request only permissions used by features.
- Ensure permission purpose strings are user-friendly and specific.
- Verify notification behavior and opt-in flows.
- Verify location usage matches product behavior.

## 8) Stripe Production Readiness

- Use live publishable key (`pk_live_...`) in release defines.
- Set `STRIPE_TEST_MODE=false` in release defines.
- Use production backend Stripe secret key on server.
- Verify webhook handling server-side for successful payments.

## 9) Release Smoke Test Plan

Test on real devices:

- Login / registration / OTP
- Profile photo upload and crop
- Swiping and matching
- Chat send/receive notifications
- Subscription purchase + post-purchase entitlement unlock
- App restart and session restore

## 10) Post-Release Monitoring

- Monitor crash reports for 24-48h.
- Monitor payment success/failure rates.
- Monitor backend API error rates and latency.
- Prepare a rollback/hotfix plan.
