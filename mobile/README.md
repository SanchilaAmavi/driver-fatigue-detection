# Mobile App Scaffold

This folder contains starter scaffolding for both a React Native mobile application and a Flutter mobile application.

## React Native scaffold

- `mobile/react_native/App.js`
- `mobile/react_native/src/screens/`
- `mobile/react_native/src/services/`
- `mobile/react_native/index.js`
- `mobile/react_native/app.json`

## Flutter scaffold

- `mobile/flutter/lib/main.dart`
- `mobile/flutter/lib/screens/home_screen.dart`
- `mobile/flutter/lib/screens/camera_screen.dart`
- `mobile/flutter/lib/screens/dashboard_screen.dart`
- `mobile/flutter/lib/screens/login_screen.dart`
- `mobile/flutter/lib/services/api_service.dart`
- `mobile/flutter/lib/services/alert_service.dart`
- `mobile/flutter/lib/services/firebase_service.dart`
- `mobile/flutter/lib/services/face_detection_service.dart`
- `mobile/flutter/pubspec.yaml`

## Purpose

The mobile apps will connect to the FastAPI backend through WSO2 or directly.
They are designed to provide:

- live camera-based fatigue detection
- eye/mouth/head-pose analysis
- real-time alerts
- Firebase event logging
- backend trip history recording

## Flutter Firebase notes

For Firebase to work, place your Android config file at:

- `mobile/flutter/android/app/google-services.json`

and your iOS plist at:

- `mobile/flutter/ios/Runner/GoogleService-Info.plist`

Then add the Google services Gradle plugin to the Flutter Android project, and run `flutter pub get`.
