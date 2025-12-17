# Play Store Deployment Guide

This guide will help you prepare and deploy your Worbix app to the Google Play Store.

## ✅ Completed Setup

The following configurations have been completed:

1. **Application ID**: Changed from `com.example.worbix` to `com.worbix.app`
2. **App Signing**: Configured release signing setup in `build.gradle.kts`
3. **ProGuard Rules**: Added ProGuard rules for Google Mobile Ads
4. **Permissions**: Added INTERNET permission to AndroidManifest
5. **App Metadata**: Updated app description and label

## 🔑 Required: App Signing Setup

### Step 1: Generate a Keystore

You need to create a keystore file for signing your release builds. **Keep this file secure and backed up!**

Run this command in your terminal:

**For Windows PowerShell:**
```powershell
keytool -genkey -v -keystore "$env:USERPROFILE\worbix-release-key.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias worbix
```

**For Mac/Linux:**
```bash
keytool -genkey -v -keystore ~/worbix-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias worbix
```

**Note:** The keystore password must be at least 6 characters long.

**Important Notes:**
- Store the keystore file in a secure location (NOT in the project directory)
- Remember the passwords you set - you'll need them later
- The keystore file is required for all future updates to your app

### Step 2: Create key.properties

1. Copy the template file:
   ```bash
   cp android/key.properties.template android/key.properties
   ```

2. Edit `android/key.properties` and fill in your actual values:
   ```properties
   storePassword=your_actual_keystore_password
   keyPassword=your_actual_key_password
   keyAlias=worbix
   storeFile=/absolute/path/to/your/worbix-release-key.jks
   ```

   **Example for Windows:**
   ```properties
   storeFile=C:\\Users\\YourName\\worbix-release-key.jks
   ```

   **Example for Mac/Linux:**
   ```properties
   storeFile=/Users/YourName/worbix-release-key.jks
   ```

3. **IMPORTANT**: The `key.properties` file is already in `.gitignore` - DO NOT commit it to version control!

## 📦 Building the Release APK/AAB

### Option 1: Build App Bundle (Recommended for Play Store)

```bash
flutter build appbundle --release
```

The output will be at: `build/app/outputs/bundle/release/app-release.aab`

### Option 2: Build APK (For testing or direct distribution)

```bash
flutter build apk --release
```

The output will be at: `build/app/outputs/flutter-apk/app-release.apk`

### Option 3: Build Split APKs (Smaller file size)

```bash
flutter build apk --split-per-abi --release
```

This creates separate APKs for different architectures.

## 📋 Pre-Deployment Checklist

Before uploading to Play Store, ensure:

- [ ] **App Signing**: Keystore created and `key.properties` configured
- [ ] **Version Number**: Update version in `pubspec.yaml` (format: `major.minor.patch+buildNumber`)
- [ ] **App Icons**: Verify app icons are generated (run `flutter pub run flutter_launcher_icons`)
- [ ] **AdMob IDs**: Verify production AdMob IDs are set in `lib/src/features/ads/ad_manager.dart`
- [ ] **Privacy Policy**: Ensure privacy policy URL is accessible (required for apps with ads)
- [ ] **Test Build**: Test the release build thoroughly on a real device
- [ ] **Screenshots**: Prepare screenshots for Play Store listing (required sizes vary by device type)
- [ ] **App Description**: Prepare short and full descriptions for Play Store
- [ ] **Content Rating**: Complete content rating questionnaire in Play Console

## 🎯 Play Store Console Setup

1. **Create Developer Account**: Sign up at [Google Play Console](https://play.google.com/console) ($25 one-time fee)

2. **Create New App**:
   - Go to "All apps" → "Create app"
   - Fill in app details (name, default language, app type, free/paid)
   - Accept declarations

3. **App Content**:
   - Privacy Policy (required for apps with ads)
   - Content Rating questionnaire
   - Target audience
   - Data safety form

4. **Store Listing**:
   - App name: "Worbix"
   - Short description (80 chars max)
   - Full description (4000 chars max)
   - Screenshots (phone, tablet if applicable)
   - Feature graphic (1024 x 500)
   - App icon (512 x 512)

5. **Production Release**:
   - Go to "Production" → "Create new release"
   - Upload the `.aab` file from `build/app/outputs/bundle/release/`
   - Add release notes
   - Review and roll out

## 🔄 Updating Your App

For future updates:

1. Update version in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # Increment version and build number
   ```

2. Build new release:
   ```bash
   flutter build appbundle --release
   ```

3. Upload to Play Console using the same keystore

## ⚠️ Important Notes

- **Never lose your keystore file** - you cannot update your app without it
- **Keep `key.properties` secure** - it contains sensitive passwords
- **Test thoroughly** before releasing to production
- **AdMob**: Ensure you're using production ad unit IDs, not test IDs
- **Privacy Policy**: Required for apps with ads - must be publicly accessible

## 🐛 Troubleshooting

### Build fails with signing error
- Verify `key.properties` file exists and paths are correct
- Check that keystore file path uses forward slashes or escaped backslashes
- Ensure passwords are correct

### App crashes on release build
- Check ProGuard rules in `android/app/proguard-rules.pro`
- Verify all dependencies are compatible with release builds
- Test with `flutter run --release` first

### Version code conflicts
- Increment the build number (the number after `+` in `pubspec.yaml`)
- Each upload must have a higher version code than the previous

## 📚 Additional Resources

- [Flutter Deployment Guide](https://docs.flutter.dev/deployment/android)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [App Signing Best Practices](https://developer.android.com/studio/publish/app-signing)
