# Worbix

A child-friendly word puzzle game built with Flutter.

## Features
- 20 Levels with 6x6 grids.
- AdMob Integration (Banner, Interstitial, Rewarded).
- Local Persistence (Hive).
- Child-friendly UI.

## Getting Started

### Prerequisites
- Flutter SDK 3.9.2+
- Android Studio / VS Code

### Setup
1. Clone the repository.
2. Run `flutter pub get` to install dependencies.
3. Update AdMob IDs in `lib/src/features/ads/ad_manager.dart` for production.

### Running the App
- Run `flutter run` to launch on a connected device or emulator.
- Use `flutter test` to run unit tests.

### Helper Scripts
- `levels.json` is located in `assets/`. It is the source of truth for game data.
