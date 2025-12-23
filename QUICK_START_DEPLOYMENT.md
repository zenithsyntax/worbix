# Quick Start: Play Store Deployment

## ✅ What's Been Done

Your app has been configured for Play Store deployment:

1. ✅ **Application ID**: Changed to `com.worbix.app`
2. ✅ **App Signing**: Configured (you need to create keystore)
3. ✅ **ProGuard**: Rules added for Google Mobile Ads
4. ✅ **Permissions**: INTERNET permission added
5. ✅ **App Metadata**: Description and label updated

## 🚀 Next Steps (Required)

### 1. Create Keystore (5 minutes)

**Windows PowerShell:**
```powershell
keytool -genkey -v -keystore "$env:USERPROFILE\worbix-release-key.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias worbix
```

**Mac/Linux:**
```bash
keytool -genkey -v -keystore ~/worbix-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias worbix
```

**Note:** Password must be at least 6 characters.

**Save the passwords you enter!**

### 2. Configure key.properties (2 minutes)

1. Copy template:
   ```bash
   cp android/key.properties.template android/key.properties
   ```

2. Edit `android/key.properties` with your keystore details:
   ```properties
   storePassword=your_keystore_password
   keyPassword=your_key_password
   keyAlias=worbix
   storeFile=C:\\Users\\YourName\\worbix-release-key.jks
   ```
   (Use absolute path with forward slashes or escaped backslashes)

### 3. Build Release Bundle (2 minutes)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### 4. Upload to Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Create new app or select existing
3. Upload the `.aab` file
4. Complete store listing (screenshots, description, etc.)
5. Submit for review

## ⚠️ Important Reminders

- **Privacy Policy URL**: You'll need a publicly accessible URL for your privacy policy in Play Console
- **Test the Release Build**: Run `flutter run --release` on a real device first
- **Backup Your Keystore**: Store it securely - you'll need it for all future updates
- **Version Numbers**: Increment in `pubspec.yaml` for each update (format: `1.0.0+1`)

## 📋 Play Store Requirements Checklist

Before submitting, ensure you have:

- [ ] App bundle built (`flutter build appbundle --release`)
- [ ] Keystore created and configured
- [ ] Privacy Policy URL (hosted publicly)
- [ ] App screenshots (phone: 2-8 required)
- [ ] Feature graphic (1024 x 500)
- [ ] App icon (512 x 512)
- [ ] Short description (80 chars max)
- [ ] Full description (4000 chars max)
- [ ] Content rating completed
- [ ] Data safety form completed

## 📖 Full Documentation

See `PLAYSTORE_DEPLOYMENT.md` for detailed instructions.








