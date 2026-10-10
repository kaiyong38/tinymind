# TinyMind

TinyMind is a Flutter learning app for children ages 3–6. It uses Firebase
services and currently targets Android only.

## Features

- Four learning worlds: Letters, Numbers, Shapes, and Colors.
- Age-aware activity recommendations that adapt the starting point to the
  learner.
- Stars, achievements, and progress tracking as learning rewards.
- Parent pages for learner profiles, settings, and progress.
- Learning reports that can be exported and shared.
- A parent gate protected by device authentication (when available) or a
  four-digit PIN.
- Privacy information and controls for deleting an account.

## Technology

- Flutter and Dart
- Firebase Core, Firebase Authentication, and Cloud Firestore
- `local_auth` for device authentication
- `shared_preferences` for local settings and cached progress
- `google_fonts` and bundled Baloo 2 font files
- `audioplayers` and `flutter_tts` for music and narration
- `flutter_svg` for illustrations
- `pdf` and `share_plus` for learning reports
- `crypto` for secure PIN-related operations

## Project structure

```text
lib/
  models/       Learning activities, questions, progress, and achievements
  pages/        Authentication, parent, privacy, and report pages
  services/     Firebase, progress, accessibility, audio, and report services
  widgets/      Reusable quiz, text, and interaction widgets
  main.dart     App shell, home/library, quiz, and result pages
test/           Widget and unit tests
docs/           Question-bank rules and redesign documentation
assets/         Audio, branding, fonts, and world illustrations
```

## Run the app

1. Install Flutter and the Android SDK.
2. From the repository root, fetch dependencies:

   ```sh
   flutter pub get
   ```

3. Android Firebase setup requires `android/app/google-services.json`. A
   Firebase client configuration file is currently tracked in this checkout.
   If your copy does not include it, or you are using a different Firebase
   project, download the Android configuration from that project's Firebase
   Console and place it at the path above.
4. Start the app on a connected Android device or emulator:

   ```sh
   flutter run
   ```

Firebase client configuration is not a service-account credential. Never add
Firebase Admin SDK credentials, passwords, or private keys to the app or
repository.

## Test and analyze

Run static analysis and the complete test suite:

```sh
flutter analyze
flutter test
```

Run only the layout/overflow audit tests:

```sh
flutter test --tags overflow
```

Question-bank requirements are documented in
[docs/question_bank_rules.md](docs/question_bank_rules.md).

## Build a release package

```sh
flutter build apk --release
flutter build appbundle --release
```

The current Android Gradle release build is configured to use the debug
signing key. These commands build release-mode artifacts, but a production
distribution should be configured with a private release keystore first.
Keep the keystore and `key.properties` private and out of version control.

A typical `android/key.properties` file has this shape; replace each
placeholder locally and do not commit real values:

```properties
storePassword=<keystore-password>
keyPassword=<key-password>
keyAlias=<key-alias>
storeFile=<path-to-keystore>
```

The current Gradle release configuration does not yet read `key.properties`;
wire it into the Android signing configuration before producing a
store-signed release. Keep the real keystore and passwords in a secure backup.