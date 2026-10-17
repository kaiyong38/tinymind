# TinyMind

TinyMind is a Flutter learning app for children ages 3–6. It uses Firebase
services and currently targets Android only.

- Android application ID: `com.kaiyong.tinymind`
- Firebase project: `tinymind-dab14`

## Features

- Four learning worlds: Letters, Numbers, Shapes, and Colors.
- Age-aware activity recommendations that adapt the starting point to the
  learner.
- Stars, achievements, and progress tracking as learning rewards.
- Parent pages for learner profiles, settings, and progress.
- Learning reports that can be exported and shared.
- A parent gate requiring a four-digit PIN on every parent-area entry.
- The Grown-ups page in the child menu requires the PIN every time it is
  opened, and returns to Play when the app goes to the background.
- The app starts with an anonymous Firebase account and opens the child picker
  directly. A parent must enter the device-only PIN on every parent-area entry.
- Backup is optional. A parent can link a Google account or an email and
  password to back up the current account; the account identifier is kept.
  Email accounts must verify their email before they can sign in on a new
  phone. A Google account and an email account with the same email are
  joined into one account. When an account has both, TinyMind checks it is
  you with Google first (for deleting the account or a forgotten PIN), and
  you can use your password instead. Without a backup, data is lost if the
  app is uninstalled or the device is changed.
- Privacy information and controls for deleting an account.
- The privacy policy is shown in the app and hosted online at
  <https://tinymind-dab14.web.app/privacy-policy.html>.
- The child picker shows the TinyMind app icon and name. A small pencil
  button in the top-right corner (tooltip "Manage", behind the parent PIN)
  turns on manage mode, where a grown-up can change a learner's nickname,
  age and avatar (and still remove a learner); a check button ends it.
  Changing the age changes which activities are suggested.
- If the child picker cannot load the children, it shows the error code and
  a few small diagnostic lines (error message, the end of the account id,
  whether it is anonymous, and its sign-in providers) with a Retry button.
  For `permission-denied` or `unauthenticated` errors it also offers
  "Start over", which signs this phone out after a warning and starts fresh.
- Password checks (for example before deleting an account) use a compact
  one-row dialog, so the field and buttons stay visible in landscape with the
  keyboard open.
- Music volume is adjusted in the menu (and music can be muted). Voice volume
  is not adjustable; narration always plays at full volume.

## Large screens

On large displays, TinyMind lays out the app on a 640 × 400 logical-pixel
canvas and scales it uniformly to fill the screen (up to 3×). Phone-sized
layouts are left unchanged. The same scaling applies to navigation overlays
such as dialogs, menus, and SnackBars.

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

CI runs `flutter analyze` and `flutter test` on every push and pull request
using Flutter `3.41.3` (see
[.github/workflows/flutter.yml](.github/workflows/flutter.yml)).

The test files are:

```text
test/activities_test.dart
test/compact_landscape_test.dart
test/colors_redesign_test.dart
test/drag_answer_test.dart
test/font_assets_test.dart
test/large_screen_scaler_test.dart
test/learning_report_builder_test.dart
test/letters_redesign_test.dart
test/music_settings_test.dart
test/narration_interjections_test.dart
test/numbers_redesign_test.dart
test/overflow_audit_test.dart
test/parent_gate_service_test.dart
test/privacy_policy_page_test.dart
test/progress_and_next_test.dart
test/progress_store_notify_test.dart
test/progress_store_test.dart
test/question_bank_rules_test.dart
test/quiz_page_audit_test.dart
test/quiz_visuals_test.dart
test/read_again_and_numbering_test.dart
test/shapes_redesign_test.dart
test/tts_text_helper_test.dart
test/widget_test.dart
```

`test/overflow_audit_test.dart` and `test/quiz_page_audit_test.dart` carry the
`overflow` tag and are run by `flutter test --tags overflow`.

Question-bank requirements are documented in
[docs/question_bank_rules.md](docs/question_bank_rules.md).

## Privacy policy

The policy text lives in three places that must stay in sync:
`lib/pages/privacy_policy_page.dart` (in the app),
`public/privacy-policy.html` (hosted at
<https://tinymind-dab14.web.app/privacy-policy.html>), and
`docs/privacy-policy.html` (an identical copy). The "Last updated" date is
`AppInfo.privacyPolicyLastUpdated`, and `docs/privacy-policy.version.json`
records it together with a fingerprint of the policy text.

After changing the policy:

```sh
dart run tool/update_privacy_date.dart
flutter test
firebase deploy --only hosting
```

The tool sets "Last updated" to today in all three places when the policy
text has changed, and prints "Privacy policy unchanged." otherwise. The tests
fail if the policy text changes without running the tool.

## Build a release package

Release signing reads the following properties from
`android/key.properties`:

```properties
storeFile=<keystore-file-path>
storePassword=<keystore-password>
keyAlias=<key-alias>
keyPassword=<key-password>
```

Do not put real values in this example. `android/key.properties` and keystore
files (`.jks`) are excluded from Git and must be kept private. Without a valid
`key.properties`, debug builds and `flutter test` continue to work; only a
release build reports a signing configuration error.

Build split APKs for testers (the ARM64 APK is
`app-arm64-v8a-release.apk`):

```sh
flutter build apk --release --split-per-abi
```

Build an app bundle for Google Play:

```sh
flutter build appbundle --release
```

Share the APK using Firebase App Distribution or send the APK directly.
Testers installing an APK directly need to allow installation from unknown
sources for the app or browser they use to open it.

## Future work

The app currently supports Android only. iOS support and Facebook sign-in are
future work.

## Known limitations / future work

- Merging child profiles across different accounts/devices is not supported.
- Family sharing is not supported.
- The parent PIN is stored on this device and is not synced.
- The PIN lockout timer is kept in memory and resets when the app restarts.
- Backup needs a Google account or an email address. Phones without Google
  services can still use the app anonymously, but cannot use Google backup.