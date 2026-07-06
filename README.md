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
