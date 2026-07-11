# Amica Mobile App

Flutter mobile application for Amica, a women's safety and security app.

## Planned Features

- User authentication
- Emergency contacts
- Smart Journey Timer
- Live location SOS alert
- Fake Call deterrent
- Stealth Voice SOS with secret phrase detection
- Number plate OCR for Scan Before You Ride
- Firebase backend integration

## Current MVP Auth Flow

The app includes basic screens for:

- Login with email and password
- Signup with name, email, phone, password, and secret phrase
- Google sign-in using Firebase Authentication
- Password reset email from the forgot password screen
- Home dashboard with main Amica safety feature cards
- Logout

Signup and Google sign-in create a Firebase Auth user and write a matching profile document to the Firestore `users` collection.

## Firebase Setup

This repo does not commit private Firebase config files or secrets.

For local development, connect the app to the Firebase development project using FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This may generate:

```text
lib/firebase_options.dart
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

Only commit Firebase configuration files if the team has agreed they are safe for the university demo. Never commit service account JSON files, private keys, API tokens, or `.env` files.

GitHub Actions builds the debug APK without committing `android/app/google-services.json`. The Android Gradle setup applies the Google Services plugin only when that file exists, so CI can compile safely while local Firebase testing still uses your downloaded Firebase config.

The app currently calls `Firebase.initializeApp()` safely. If Firebase config is missing, the app still opens, but login/signup will show a clear setup error.

## Auth Testing

1. Configure Firebase dev project with FlutterFire CLI.
2. Enable Email/Password sign-in in Firebase Authentication.
3. Enable Google sign-in in Firebase Authentication.
4. Add the Android debug SHA-1 and SHA-256 fingerprints to the Firebase Android app for package `com.kintsugi.amica`.
5. Download the updated `google-services.json` and place it in `android/app/google-services.json`.
6. Ensure Firestore rules allow the signed-in user to create their own `users/{uid}` document.
7. Run the app.
8. Create a test account from the signup screen.
9. Confirm the user appears in Firebase Authentication.
10. Confirm a matching document appears in Firestore `users`.
11. Log out and log in again with the same account.
12. Tap "Forgot password?", enter the test email, and confirm Firebase sends a reset email.
13. Tap "Continue with Google", choose a Google account, and confirm the user/profile are created.

To find the debug SHA fingerprints on Windows:

```powershell
keytool -list -v -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -keypass android
```

Use demo-only data. Do not use real private phone numbers or personal safety phrases for testing.

## Emergency Contacts

Emergency contacts are saved in the Firestore `emergency_contacts` collection and are owned by the signed-in user's Firebase Auth UID.

To test:

1. Log in or create a test account.
2. Open the Home Dashboard.
3. Tap "Emergency Contacts".
4. Add a contact with name, phone, optional relationship, and priority.
5. Confirm the contact appears in Firestore under `emergency_contacts`.
6. Confirm the document has `userId` equal to the current user's UID.
7. Edit the contact and confirm the UI and Firestore document update.
8. Toggle the contact active/inactive.
9. Delete the contact and confirm it is removed from Firestore.

The app queries contacts with the current user's UID:

```text
emergency_contacts where userId == currentUser.uid
```

Do not commit real phone numbers, Firebase secrets, service account files, API keys, or `.env` files.

## Map and Location Setup

The MVP map/location foundation uses:

- `geolocator` for location permission and current coordinates
- `geocoding` for basic destination name/address lookup
- `google_maps_flutter` for map display
- native Android emergency actions for debug SMS and phone call testing
- Firebase Auth and Firestore for saving `journeys` and `sos_alerts`

Android permissions are configured in `android/app/src/main/AndroidManifest.xml`:

- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `VIBRATE`
- `WAKE_LOCK`
- `FOREGROUND_SERVICE`
- `FOREGROUND_SERVICE_SPECIAL_USE`
- `POST_NOTIFICATIONS`
- `SEND_SMS`
- `CALL_PHONE`
- `RECORD_AUDIO`

Google Maps requires a local Android API key. Do not commit the real key. For local testing, add this to `android/local.properties`:

```properties
GOOGLE_MAPS_API_KEY=your_local_google_maps_api_key
```

The Gradle build also accepts `googleMapsApiKey` in `android/gradle.properties`, `android/local.properties`, user-level `.gradle/gradle.properties`, or an environment variable. CI can still compile without a key, but maps will not fully render on an emulator/device until the key is configured and the Google Maps SDK for Android is enabled for that key.

iOS is not configured yet. If an iOS folder is added later, add `NSLocationWhenInUseUsageDescription`, `NSMicrophoneUsageDescription`, and `NSSpeechRecognitionUsageDescription` to `ios/Runner/Info.plist`.

To test Start Journey:

1. Configure Firebase dev backend and `android/app/google-services.json`.
2. Add a local Google Maps API key.
3. Log in on an Android emulator or device.
4. Tap "Start Journey".
5. Allow location permission.
6. Confirm the current location appears on the map.
7. Enter a destination name or address.
8. Confirm the destination appears on the map, then tap the map to refine the exact pin if needed.
9. Confirm the suggested duration appears for the selected journey type.
10. Start the journey and confirm a Firestore `journeys` document is created with destination latitude/longitude.
11. Tap "I am safe" and confirm the journey status becomes `safe`.

Journey timer safety behavior:

- The countdown text updates without reloading the full timer page.
- When the timer screen opens, Android starts a foreground journey safety service with a visible notification.
- The native safety service keeps the timer running while the screen is off or locked.
- When the timer ends, the phone vibrates twice from native Android alarm-style vibration code and also posts a high-priority safety alert notification with the same vibration pattern.
- If there is no response for 1 minute, the native safety service sends a direct SMS to the first active emergency contact.
- If there is still no response after 3 minutes, the native safety service starts a phone call to that contact.
- Android will ask for Notification, SMS, and Phone permissions on the timer screen during debug testing. Allow them before the timer ends.
- The foreground safety service stops when the user taps "I am safe" or manually sends SOS from the timer screen.

To test manual SOS:

1. Start a journey, then tap "Trigger test SOS", or tap the Home Dashboard SOS card.
2. Confirm a Firestore `sos_alerts` document is created with a `location` map.
3. Confirm the SOS Active screen shows the location on a map.

## Fake Call and Voice SOS

Fake Call is simulated inside the app. It does not make a real phone call. The visible call screens avoid debug wording so the MVP looks like a normal incoming and active call screen.

Voice SOS uses the `speech_to_text` package for MVP phrase detection. It listens only while the fake call active screen is open. It does not run in the background.

During the active call screen, Android proximity mode is enabled. On phones with a proximity sensor, the screen should turn off when the phone is held close to the ear, similar to a normal call.

Default values:

- Secret phrase: `amica help me`
- Fake caller name: `Amica Friend`
- Fake caller number: `+94 700 000 000`

The app can also read these values from the Firestore `users` document:

- `secretPhrase`
- `safetySettings.fakeCallContactName`
- `safetySettings.fakeCallPhoneNumber`
- `safetySettings.voiceSosEnabled`
- `safetySettings.secretPhraseEnabled`
- `safetySettings.fakeCallVolumeShortcutEnabled`
- `safetySettings.voiceSosEmergencyMessage`

These can be edited in the app:

```text
Home Dashboard > Profile / Settings
```

The settings page lets the user configure:

- fake caller name
- fake caller number
- whether volume down pressed three times should open the call screen
- voice SOS enable/disable
- secret phrase enable/disable
- the exact secret phrase
- the SOS message saved when the phrase is spoken during the fake call

When the phrase is detected, the app creates a Firestore `sos_alerts` document with:

- `triggerType`: `voice`
- current location
- custom SOS message from settings
- `evidence.voicePhraseDetected`: `true`
- detected phrase and expected phrase
- `evidence.fakeCallActive`: `true`

Manual test flow:

1. Log in.
2. Open the Home Dashboard.
3. Tap "Fake Call".
4. Accept the fake incoming call.
5. Allow microphone permission if Android asks.
6. Say "amica help me" while the call screen is active.
7. Confirm the app creates a Firestore `sos_alerts` document with `triggerType` set to `voice`.
8. Confirm the SOS Active screen opens and shows the location.

Volume shortcut test flow:

1. Log in.
2. Open Settings and enable "Volume-down shortcut".
3. Keep the "Safety shortcut armed" notification visible.
4. You may now leave Amica or lock the phone.
5. Press the Android volume down button three times within about 1.5 seconds.
6. Confirm the incoming call screen opens. If Android blocks the automatic launch, tap the incoming-call notification.

MVP notes:

- No real phone call is made by Fake Call.
- Voice SOS does not run in the background.
- The volume-down shortcut uses an Android foreground service so it can work after the app UI is closed, as long as Android keeps the Amica shortcut notification running.
- Android may block direct background activity launch on some versions or battery modes. The app posts a high-priority incoming-call notification as a fallback.
- The shortcut watches volume changes, so it may not trigger if the relevant volume stream is already at the minimum level.
- Proximity screen-off works only on real Android phones with a proximity sensor. Many emulators do not support it.
- Voice recognition accuracy depends on the device and environment.
- Some emulators do not support speech recognition well.
- Offline Vosk integration can be considered later.
- No secrets or API keys should be committed.

MVP limits:

- No route drawing yet.
- No Google Directions API yet.
- Destination time suggestions are simple MVP estimates, not live traffic estimates.
- Background execution uses a native Android foreground service plus a partial wake lock for MVP testing. Keep the Amica notification visible during an active journey.
- Direct SMS and automatic call start are for debug APK testing. Publishing with these permissions requires careful Play Store policy review.
- Some Android versions or manufacturer battery settings may still restrict automatic call launch from the lock screen. Disable battery optimization for Amica during testing if needed.
- If lock-screen vibration is not felt, check Android Settings > Apps > Amica > Notifications and make sure the "Amica safety alerts" channel can vibrate. Also make sure the phone is not in a mode that blocks alarm/notification vibration.
- Playing a voice message into a cellular call and ending the call is not available to normal Android apps; use backend telephony such as Twilio for that behavior.

## Deployment Strategy

- `dev` branch is used for development integration.
- Backend `dev` branch deploys to Firebase development project only.
- `main` branch is reserved for final demo/production-ready code.
- Production deployment is not automatic yet.
- Mobile app produces APK artifacts through GitHub Actions.
- AI repo produces test/artifact outputs only.

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md) for the Amica branch strategy, issue workflow, commit expectations, pull request process, and CI/CD guidance.

## Getting Started

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Build a debug APK:

```bash
flutter build apk --debug
```
