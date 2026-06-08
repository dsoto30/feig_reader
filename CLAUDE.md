# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter application (`feig_reader`) targeting Windows, Android, iOS, macOS, Linux, and Web. Currently a starter template — business logic for FEIG RFID reader integration is the intended direction.

- Dart SDK: ^3.12.0 / Flutter 3.18.0+
- App ID: `com.example.feig_reader`

## Commands

```bash
flutter pub get          # install dependencies
flutter run              # run (auto-detects device)
flutter run -d windows   # run on Windows desktop
flutter run -d chrome    # run in browser
flutter test             # run all tests
flutter analyze          # static analysis
dart format lib/         # format source files
flutter clean            # wipe build artifacts
flutter build windows    # release build for Windows
flutter build apk        # release APK for Android
```

To run a single test file: `flutter test test/widget_test.dart`

## Architecture

All app code lives in `lib/`. Currently a single file (`lib/main.dart`) with:
- `MyApp` — root `StatelessWidget`, configures `MaterialApp` and theme
- `MyHomePage` — `StatefulWidget` home screen (boilerplate counter)

Platform-specific native scaffolding is in `android/`, `ios/`, `windows/`, `linux/`, `macos/`, and `web/` — these should rarely need manual editing.

Linting rules extend `flutter_lints/flutter.yaml` (see `analysis_options.yaml`).
