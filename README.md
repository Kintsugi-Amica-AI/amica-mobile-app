# Amica Mobile App

Flutter mobile application for Amica, a women's safety and security app.

## Scan Vehicle and Vehicle Journeys

### Rating retries

If a rating fails, the screen keeps the selected stars and explains whether the
failure is connectivity, session, journey status, or missing backend access.
Scan the same plate and choose **Rate a completed ride** to retry after leaving
the original journey screen. Each journey still counts once.

### Multiple voice phrases and launcher icon

In Settings, add or remove up to ten secret phrases, then save. Any configured
phrase can trigger Voice SOS during an active fake call; all phrases use the
saved emergency message. Existing profiles with a single `secretPhrase` remain
compatible. Settings stores `secretPhrases` plus its first entry in the legacy
field. Empty and duplicate phrases are rejected. Test recognition on your device;
the app does not claim measured recognition confidence.

The Android launcher uses the supplied artwork in
`android/app/src/main/res/drawable-nodpi/amica_logo.png`, with a legacy bitmap
resource and an adaptive icon for modern Android. Reinstall the APK to update it;
launchers can cache icons briefly.

Scan Vehicle recognizes modern Sri Lankan registrations with two/three letters
and four digits, including stacked rows and optional province prefixes. Automatic
capture checks every two seconds and requires two matching readings. The shutter
and gallery options also try rotated images. Keyboard entry is available when
OCR is uncertain. Confirm the plate before boarding; OCR is not guaranteed.

1. Deploy the backend vehicle-review rules/functions and import its demo fixtures
   using `amica-cloud-backend/docs/scan_vehicle_setup.md`.
2. Log in on Android, add your own consenting test contact, and enable camera,
   location, SMS, phone, and notification permissions when requested. SMS/calls
   need a working SIM and may incur charges; an emulator cannot verify delivery.
3. Open Scan Vehicle. Test `WP NC 9024`, `CBR 6797`, `CBO 3286`, or `CBR 6307`.
   These are fictional ratings on example plates, not real driver assessments.
4. Tap **I am traveling in this vehicle**, check the plate and confirm. Boarding
   SMS is submitted to all active contacts. The next screen reports submission
   counts; submission does not confirm delivery. No contact/permission failures
   should be mistaken for a sent message.
5. Select the destination on the map and vehicle type, then accept or edit the
   estimated minutes. The estimate uses distance and typical speed, not live
   traffic or a road route. Tap **Start Vehicle Journey**.
6. The existing safety timer asks whether you are safe at the deadline. Android's
   foreground monitor submits SMS after one minute without a response and attempts
   a call to the primary contact after three minutes. SMS includes the plate.
   Background execution depends on Android permissions/device restrictions;
   force-stop, reboot, missing SIM, or denied call access can prevent escalation.
7. Mark the journey safe, select 1-5 stars, and submit. Firestore stores one review
   per journey; the backend updates the average. Scan again to see the new average.

Unanswered three-minute checks sync as unverified events when the journey screen
is running again with network access. They do not automatically change passenger
ratings or establish driver misconduct. The background message uses the journey's
last saved location, not continuous live tracking. Test screen-off behavior on a
real device before relying on it; this remains a university prototype.

## Planned Features

- User authentication
- Emergency contacts
- Smart Journey Timer
- Bus Stop Alert with a distance alarm before your drop-off
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
- `CAMERA`

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
- The timer then opens the full-screen Safety Check, which shows a live countdown to the automatic emergency-contact alert and offers "I am safe" or "Send SOS now". It cannot be dismissed with the back button, so an accidental swipe is never read as a safety confirmation.
- The Safety Check screen only reports the user's answer. The journey timer screen stays the single place that updates the Firestore `journeys` document, stops the native safety service, and creates the `sos_alerts` document, so both answers behave the same whether the check was answered immediately or after an escalation already fired.
- If there is no response for 1 minute, the native safety service sends a direct SMS to the first active emergency contact.
- If there is still no response after 3 minutes, the native safety service starts a phone call to that contact.
- Android will ask for Notification, SMS, and Phone permissions on the timer screen during debug testing. Allow them before the timer ends.
- The foreground safety service stops when the user taps "I am safe" or manually sends SOS from the timer screen.

To test manual SOS:

1. Start a journey, then tap "Trigger test SOS", or tap the Home Dashboard SOS card.
2. Confirm a Firestore `sos_alerts` document is created with a `location` map.
3. Confirm the SOS Active screen shows the location on a map.

## Bus Stop Alert

Smart Stop Alert warns a rider before their bus reaches the stop they are getting off at, so they can rest on a long or unfamiliar route without missing it.

The rider opens "Bus Stop Alert" from the Home Dashboard, names the stop (geocoded to the map) or taps the map to pin it, picks how far out to be warned, and starts the ride. Amica then tracks the distance and sounds an alarm on arrival inside that radius.

- The default alert distance is **2 km**. 1 km, 3 km, and 5 km are also offered, because a fixed 2 km fires immediately on a short city hop and lands too late on a long intercity run.
- If the chosen stop is already inside the alert radius when the ride is about to start, the setup screen says so and asks for a shorter distance instead of arming an alarm that would sound straight away.
- The alarm sounds **once per ride**, so a bus weaving in and out of the radius or a jittery GPS fix does not set it off repeatedly.
- Tracking runs in a native Android foreground service with a partial wake lock, so the alarm still sounds with Amica closed and the screen off — which is the whole point, since the phone will be in a pocket.
- The alarm uses an alarm-usage notification channel (alarm sound plus a long vibration pattern) rather than a notification chime, so it can wake someone who dozed off.
- The tracking notification shows the live remaining distance and has a "Stop" action.

A stop alert ride is stored in the shared Firestore `journeys` collection as `journeyType: 'bus'` with a `stopAlert` map, matching the backend schema's note that "Smart Stop Alert can use `destination` and `journeyType`". Its safety countdown is switched off (`safetyCheck.required: false`): the rider is asking to be told when the bus nears their stop, not to be asked whether they arrived by a deadline they cannot predict. The Journey Timer and the Bus Stop Alert filter each other out when reading active journeys.

Android permissions used:

- `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` for the distance tracking
- `FOREGROUND_SERVICE_LOCATION` for the location-typed foreground service on Android 14+
- `POST_NOTIFICATIONS` for the alarm

`ACCESS_BACKGROUND_LOCATION` is deliberately **not** requested. A location-typed foreground service started while the app is in the foreground — which it always is, since the rider starts the ride from the app — may keep receiving location in the background without it.

To test:

1. Configure Firebase dev backend and a local Google Maps API key.
2. Log in, open the Home Dashboard, and tap "Bus Stop Alert".
3. Allow location permission when asked.
4. Type a stop a good distance away (for example "Malabe" while in Colombo Fort), or tap the map to pin it.
5. Confirm the card shows the current distance to that stop.
6. Pick an alert distance and confirm the warning appears if you choose one larger than the current distance.
7. Start the ride and confirm a Firestore `journeys` document is created with `journeyType` `bus` and a `stopAlert` map.
8. Confirm the tracking notification appears with the live remaining distance.
9. Lock the phone and travel toward the stop (or use the emulator's extended controls to set a location inside the radius).
10. Confirm the alarm sounds and vibrates, and that the notification reads "Your stop is coming up".
11. Re-open Amica and confirm the screen shows the approaching-stop state rather than alarming a second time.
12. Tap "I am getting off here" and confirm the journey status becomes `safe` and the notification clears.

MVP notes:

- Distance is straight-line (great-circle), not road distance, so a route that loops away from the stop warns slightly late relative to road travel. Road distance needs the Directions API, which is out of scope for the MVP.
- Accuracy depends on the GPS fix. Inside a tunnel or a dense built-up area the distance may lag until the next good fix.
- Manufacturer battery settings can still stop a foreground service. Disable battery optimization for Amica when testing a long ride.
- Emulators without Google Play services may not deliver location updates to the native service.

## Fake Call and Voice SOS

Fake Call is simulated inside the app. It does not make a real phone call. The visible call screens avoid debug wording so the MVP looks like a normal incoming and active call screen.

Opening Fake Call from the Home Dashboard shows the arming screen, where the call can be scheduled for 15s, 30s, 1, 2, or 5 minutes ahead, or rung immediately. A scheduled call is held by a native Android foreground service with a partial wake lock, so it still rings after Amica is closed or the phone is locked — which is the point of arming one before getting into a vehicle. The countdown appears in the notification shade with a Cancel action, and the arming screen restores the remaining time if it is reopened.

The volume-up shortcut and a schedule that comes due both open the incoming call screen directly. A scheduled call deliberately ignores the "Volume-up shortcut" setting, since the user armed that specific call.

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
- whether volume up pressed three times should open the call screen
- voice SOS enable/disable
- secret phrase enable/disable
- the exact secret phrase
- the SOS message sent to the primary active emergency contact when the phrase is spoken during the fake call

When the phrase is detected, the app sends the configured SOS message by SMS to the first active emergency contact by priority and creates a Firestore `sos_alerts` document with:

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
5. Allow microphone and SMS permission if Android asks.
6. Say "amica help me" while the call screen is active.
7. Confirm the primary active emergency contact receives the configured SOS SMS.
8. Confirm the app creates a Firestore `sos_alerts` document with `triggerType` set to `voice`.
9. Confirm the SOS Active screen opens and shows the location.

Scheduled call test flow:

1. Log in.
2. Open the Home Dashboard and tap "Fake Call".
3. Choose a delay and tap "Schedule in ...".
4. Allow the notification permission if Android asks.
5. Confirm the "Call scheduled" notification appears with a live countdown.
6. Leave Amica or lock the phone.
7. Confirm the incoming call screen opens when the countdown ends. If Android blocks the automatic launch, tap the incoming-call notification.
8. Repeat, and confirm "Cancel scheduled call" (in the app or from the notification action) stops the pending call.

Volume shortcut test flow:

1. Log in.
2. Open Settings and enable "Volume-up shortcut".
3. Keep the "Safety shortcut armed" notification visible.
4. You may now leave Amica or lock the phone.
5. Press the Android volume up button three times within about 1.5 seconds.
6. Confirm the incoming call screen opens. If Android blocks the automatic launch, tap the incoming-call notification.

MVP notes:

- No real phone call is made by Fake Call.
- A scheduled call survives the app being closed, but Android may still stop the foreground service under aggressive manufacturer battery settings. Disable battery optimization for Amica during testing if a schedule does not fire.
- Voice SOS does not run in the background.
- The volume-up shortcut uses an Android foreground service so it can work after the app UI is closed, as long as Android keeps the Amica shortcut notification running.
- Android may block direct background activity launch on some versions or battery modes. The app posts a high-priority incoming-call notification as a fallback.
- The shortcut watches volume changes. When the shortcut service starts, it may lower a maxed-out volume stream by one step so the next Volume Up press can be detected.
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

## Scan Before You Ride

Scan Before You Ride uses on-device OCR, matching the `amica-ai-core` plate OCR prototype's normalization rules (uppercase, alphanumeric only) so the mobile app and the AI module agree on the same plate format.

- `google_mlkit_text_recognition` reads the plate text from a captured or gallery photo, fully on-device (no image is uploaded).
- The recognized text is cleaned with the same rule as `plate_text_cleaner.py`: strip everything except letters and digits, then uppercase.
- The cleaned plate is looked up in the shared Firestore `vehicles` collection by `normalizedPlateNumber`, matching `amica-cloud-backend`'s schema.
- The result screen shows Safe, Reported, or Unknown with the report count, risk level, and notes from the matched record.

To test:

1. Configure Firebase dev backend and `android/app/google-services.json`.
2. Seed the `vehicles` collection with `amica-cloud-backend/seed-data/vehicles.json` (or add your own test documents).
3. Log in, open the Home Dashboard, and tap "Scan Vehicle".
4. Take a photo of a plate (or a printed test plate such as `WP CA 9876` for a Reported result, or `WP CA 1234` for a Safe result).
5. Confirm the result screen shows the matching status, report count, and risk level.
6. Try an unrecognized plate and confirm the app shows Unknown instead of failing.

MVP notes:

- OCR runs fully offline/on-device; only the cleaned plate text (not the photo) is sent to Firestore.
- Recognition accuracy depends on photo lighting, angle, and plate condition.

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
