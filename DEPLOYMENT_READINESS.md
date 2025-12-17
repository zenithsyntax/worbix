# Play Store Deployment Readiness Checklist

## ✅ Completed Configuration

### 1. App Signing ✅
- **Keystore**: Located at `C:\Users\LENOVO\worbix-release-key.jks`
- **key.properties**: Configured at `android/key.properties`
- **Build Configuration**: Release signing configured in `build.gradle.kts`
- **Status**: ✅ Ready - Keystore file exists and is configured

### 2. Application Identity ✅
- **Application ID**: `com.worbix.app`
- **App Name**: "Worbix"
- **Package Name**: Configured correctly in `build.gradle.kts` and `MainActivity.kt`
- **Status**: ✅ Ready

### 3. Version Information ✅
- **Current Version**: `1.0.0+1` (from `pubspec.yaml`)
  - Version Name: `1.0.0`
  - Version Code: `1`
- **Status**: ✅ Ready for initial release

### 4. ProGuard Configuration ✅
- **ProGuard Rules**: Configured in `android/app/proguard-rules.pro`
- **Google Mobile Ads**: Rules included for AdMob
- **Status**: ✅ Ready

### 5. AdMob Integration ✅
- **App ID**: `ca-app-pub-9698718721404755~2343475738` (configured in AndroidManifest.xml)
- **Production Ad Unit IDs**: Configured in `ad_manager.dart`
  - Banner: `ca-app-pub-9698718721404755/6442502844`
  - Interstitial: `ca-app-pub-9698718721404755/4637083696`
  - Rewarded: `ca-app-pub-9698718721404755/8520488387`
- **Test Ad Detection**: Automatically uses test ads in debug mode
- **Status**: ✅ Ready

### 6. App Icons ✅
- **Icons Generated**: ✅ Using `flutter_launcher_icons`
- **Icon Source**: `assets/worbix-app-Icon.png`
- **Status**: ✅ Ready

### 7. Permissions ✅
- **INTERNET**: Required for ads - ✅ Configured in AndroidManifest.xml
- **Status**: ✅ Ready

### 8. Code Quality ✅
- **Flutter Analyze**: ✅ Completed (minor deprecation warnings only, no critical issues)
- **Status**: ✅ Ready

## ⚠️ Required Actions Before Upload

### 1. Privacy Policy URL (CRITICAL) ⚠️

**Status**: ❌ **ACTION REQUIRED**

Play Store **requires** a publicly accessible Privacy Policy URL for apps with advertisements.

**Current Situation**:
- Privacy policy content exists in-app (`PrivacyPolicyScreen`)
- But Play Store needs a **publicly accessible web URL**

**Options to Host Privacy Policy**:

**Option A: GitHub Pages (Free & Easy)**
1. Create a new GitHub repository (e.g., `worbix-privacy-policy`)
2. Create `index.html` with your privacy policy content
3. Enable GitHub Pages in repository settings
4. Your URL will be: `https://yourusername.github.io/worbix-privacy-policy/`

**Option B: Firebase Hosting (Free)**
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Create Firebase project and enable Hosting
3. Deploy privacy policy HTML file
4. Your URL will be: `https://your-project.web.app/privacy-policy.html`

**Option C: Your Own Domain**
- Host privacy policy on your own website

**Option D: Use a Privacy Policy Generator Service**
- Services like privacypolicygenerator.info can host it for you

**What You Need**:
- Create HTML version of your privacy policy (copy content from `PrivacyPolicyScreen`)
- Host it at a public URL
- **Keep this URL handy** - you'll need it when filling out Play Console forms

### 2. Test Release Build 🔄

**Before uploading to Play Store, test the release build:**

```powershell
# Build and install on connected device
flutter build apk --release
# OR use adb install to install the APK
```

**Test Checklist**:
- [ ] App launches correctly
- [ ] All game levels work
- [ ] Ads load and display (should show production ads in release builds)
- [ ] Settings work correctly
- [ ] Privacy policy screen accessible
- [ ] Sound effects work
- [ ] No crashes or errors
- [ ] Game progress saves correctly

### 3. Prepare Play Store Assets

**Required Assets**:
- [ ] **App Icon**: 512 x 512 px (PNG, 32-bit color, no transparency)
- [ ] **Feature Graphic**: 1024 x 500 px (JPG or 24-bit PNG)
- [ ] **Phone Screenshots**: At least 2, up to 8
  - Minimum dimensions: 320px (shortest side)
  - Recommended: 1080 x 1920 (portrait) or 1920 x 1080 (landscape)
- [ ] **Tablet Screenshots** (optional but recommended if targeting tablets)
  - 7-inch tablets: 1024 x 600 (landscape) or 600 x 1024 (portrait)
  - 10-inch tablets: 1280 x 800 (landscape) or 800 x 1280 (portrait)

**Content to Prepare**:
- [ ] **Short Description**: Max 80 characters
  - Example: "Solve challenging word puzzles in this fun 6x6 grid game for kids!"
- [ ] **Full Description**: Max 4000 characters
  - Detailed app description highlighting features, gameplay, etc.
- [ ] **App Category**: Games → Puzzle
- [ ] **Content Rating**: Complete questionnaire in Play Console
- [ ] **Target Audience**: Set age group
- [ ] **Data Safety Form**: Required for apps collecting data or showing ads

## 📦 Building for Play Store

### Option 1: App Bundle (Recommended)

```powershell
cd "d:\flutter project\New folder\worbix"
flutter build appbundle --release
```

**Output Location**: `build/app/outputs/bundle/release/app-release.aab`

**Why App Bundle?**
- Google Play generates optimized APKs for each device
- Smaller download sizes for users
- Required for Play Store (APK upload deprecated for new apps)

### Option 2: APK (For Testing Only)

```powershell
flutter build apk --release
```

**Output Location**: `build/app/outputs/flutter-apk/app-release.apk`

**Note**: Use APK only for testing. Upload AAB to Play Store.

## 🎯 Play Console Setup Steps

### Step 1: Create Developer Account
- Go to [Google Play Console](https://play.google.com/console)
- Pay one-time $25 registration fee
- Complete account setup

### Step 2: Create New App
1. Click "Create app"
2. Fill in:
   - App name: "Worbix"
   - Default language: English (United States)
   - App or game: Game
   - Free or paid: Free
3. Accept declarations

### Step 3: Store Listing
1. Go to "Store presence" → "Main store listing"
2. Upload all required graphics
3. Add short and full descriptions
4. Add screenshots
5. **Add Privacy Policy URL** (from step 1 above)

### Step 4: App Content
1. **Privacy Policy**: Add your public URL
2. **Content Rating**: Complete questionnaire (Games → Puzzle category)
3. **Target Audience**: Set appropriate age group
4. **Data Safety**: 
   - Declare data collection practices
   - Since you use ads, declare "Ads" as data use purpose
   - Indicate data collected by third parties (AdMob)

### Step 5: Production Release
1. Go to "Production" → "Create new release"
2. Upload the `.aab` file from `build/app/outputs/bundle/release/`
3. Add release notes (e.g., "Initial release - Version 1.0.0")
4. Review and roll out

### Step 6: Review Process
- Google typically reviews apps within 1-7 days
- You'll receive email notifications about review status
- Check Play Console dashboard for any issues

## 🔄 Future Updates

For app updates, increment version in `pubspec.yaml`:

```yaml
version: 1.0.1+2  # Increment version (1.0.1) and build number (+2)
```

Then rebuild and upload:
```powershell
flutter build appbundle --release
```

## 📝 Important Notes

### Keystore Security
- ⚠️ **NEVER lose your keystore file** - you cannot update your app without it
- ⚠️ **Back up** `C:\Users\LENOVO\worbix-release-key.jks` to a secure location
- ⚠️ Keep `key.properties` secure and never commit it to version control (already in .gitignore)

### AdMob
- ✅ Production ad IDs are configured
- ⚠️ Test ads automatically disabled in release builds
- ⚠️ Ensure AdMob account is set up and ad units are approved

### Privacy Policy
- ⚠️ **Must be publicly accessible** - Play Store will verify the URL
- ⚠️ Must be accessible without login or authentication
- ⚠️ Must cover data collection and use (especially for ads)

## ✅ Final Pre-Upload Checklist

Before uploading to Play Store, verify:

- [x] Keystore configured and tested
- [x] Version number set (1.0.0+1)
- [x] App icons generated
- [x] ProGuard rules configured
- [x] Production AdMob IDs configured
- [x] Code analyzed (no critical issues)
- [ ] **Privacy Policy URL created and publicly accessible** ⚠️
- [ ] Release build tested on real device
- [ ] All Play Store assets prepared (screenshots, descriptions, etc.)
- [ ] Play Console account created
- [ ] App Bundle built successfully

## 🚀 Ready to Deploy?

Once you've completed the Privacy Policy URL requirement and tested the release build, you're ready to upload to Play Store!

**Next Steps**:
1. Create and host privacy policy URL
2. Test release build thoroughly
3. Prepare all Play Store assets
4. Build app bundle: `flutter build appbundle --release`
5. Upload to Play Console

---

**Last Updated**: January 2025
**App Version**: 1.0.0+1
**Status**: Ready for deployment after privacy policy URL is set up
