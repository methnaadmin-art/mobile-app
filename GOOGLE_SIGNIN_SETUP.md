# Google Sign-In Setup Guide for Methna App

## Overview
This guide walks you through setting up Google Sign-In for the Methna app on both Android and iOS platforms.

---

## Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click **Select a project** → **New Project**
3. Name it: `methna-app`
4. Click **Create**

---

## Step 2: Enable Google Sign-In API

1. In Google Cloud Console, go to **APIs & Services** → **Library**
2. Search for **"Google Sign-In"** or **"Google Identity"**
3. Click **Enable**

---

## Step 3: Configure OAuth Consent Screen

1. Go to **APIs & Services** → **OAuth consent screen**
2. Select **External** user type
3. Fill in the required fields:
   - **App name**: Methna
   - **User support email**: your email
   - **Developer contact**: your email
4. Click **Save and Continue**
5. Skip Scopes (default is fine)
6. Add test users if needed
7. Click **Save and Continue**

---

## Step 4: Create OAuth 2.0 Credentials

### 4.1 Web Client (Required for Android)

1. Go to **APIs & Services** → **Credentials**
2. Click **+ CREATE CREDENTIALS** → **OAuth client ID**
3. Select **Web application**
4. Name: `Methna Web Client`
5. Leave Authorized origins/redirect URIs empty for now
6. Click **Create**
7. **Save the Client ID** - you'll need this!

### 4.2 Android Client

1. Click **+ CREATE CREDENTIALS** → **OAuth client ID**
2. Select **Android**
3. Name: `Methna Android Client`
4. Package name: `com.methna.methna_app`
5. Get SHA-1 fingerprint by running in terminal:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   Or for debug keystore:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
6. Paste the SHA-1 fingerprint
7. Click **Create**

### 4.3 iOS Client

1. Click **+ CREATE CREDENTIALS** → **OAuth client ID**
2. Select **iOS**
3. Name: `Methna iOS Client`
4. Bundle ID: `com.methna.methnaApp`
5. Click **Create**
6. **Save the Client ID** - you'll need this!

---

## Step 5: Download Configuration Files

### Android (google-services.json)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or link your Google Cloud project
3. Add an Android app with package name: `com.methna.methna_app`
4. Download `google-services.json`
5. Replace the placeholder file at:
   ```
   android/app/google-services.json
   ```

### iOS (GoogleService-Info.plist)

1. In Firebase Console, add an iOS app with bundle ID: `com.methna.methnaApp`
2. Download `GoogleService-Info.plist`
3. Replace the placeholder file at:
   ```
   ios/Runner/GoogleService-Info.plist
   ```

---

## Step 6: Update iOS Info.plist

After downloading `GoogleService-Info.plist`, update `ios/Runner/Info.plist`:

1. Find the `REVERSED_CLIENT_ID` value in your `GoogleService-Info.plist`
2. Replace `YOUR_IOS_CLIENT_ID` in Info.plist with the actual value:
   ```xml
   <string>com.googleusercontent.apps.ACTUAL_CLIENT_ID</string>
   ```

3. Update the `GIDClientID`:
   ```xml
   <key>GIDClientID</key>
   <string>ACTUAL_CLIENT_ID.apps.googleusercontent.com</string>
   ```

---

## Step 7: Verify Setup

### Android
Run the app and test Google Sign-In:
```bash
flutter run
```

### iOS
1. Open in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. Ensure `GoogleService-Info.plist` is added to the Runner target
3. Run the app

---

## Troubleshooting

### "Sign in failed" on Android
- Verify SHA-1 fingerprint matches your keystore
- Ensure `google-services.json` has correct package name
- Check that Web Client ID is created (required for Android)

### "Sign in failed" on iOS
- Verify Bundle ID matches in all places
- Ensure URL schemes are correctly configured in Info.plist
- Check that `GoogleService-Info.plist` is added to Xcode project

### "Developer Error" 
- This usually means OAuth credentials mismatch
- Double-check all Client IDs and package names

---

## Configuration Checklist

- [ ] Google Cloud Project created
- [ ] OAuth consent screen configured
- [ ] Web Client ID created
- [ ] Android Client ID created with correct SHA-1
- [ ] iOS Client ID created with correct Bundle ID
- [ ] `google-services.json` downloaded and placed in `android/app/`
- [ ] `GoogleService-Info.plist` downloaded and placed in `ios/Runner/`
- [ ] iOS Info.plist updated with correct REVERSED_CLIENT_ID
- [ ] App tested on both platforms

---

## Quick Reference

| Platform | Package/Bundle ID |
|----------|-------------------|
| Android  | `com.methna.methna_app` |
| iOS      | `com.methna.methnaApp` |

| File | Location |
|------|----------|
| google-services.json | `android/app/google-services.json` |
| GoogleService-Info.plist | `ios/Runner/GoogleService-Info.plist` |
