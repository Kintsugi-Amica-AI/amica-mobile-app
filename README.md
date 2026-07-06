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
- Password reset email from the forgot password screen
- Home dashboard with main Amica safety feature cards
- Logout

Signup creates a Firebase Auth user and writes a matching profile document to the Firestore `users` collection.

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

## Login / Signup Testing

1. Configure Firebase dev project with FlutterFire CLI.
2. Enable Email/Password sign-in in Firebase Authentication.
3. Ensure Firestore rules allow the signed-in user to create their own `users/{uid}` document.
4. Run the app.
5. Create a test account from the signup screen.
6. Confirm the user appears in Firebase Authentication.
7. Confirm a matching document appears in Firestore `users`.
8. Log out and log in again with the same account.
9. Tap "Forgot password?", enter the test email, and confirm Firebase sends a reset email.

Use demo-only data. Do not use real private phone numbers or personal safety phrases for testing.

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
