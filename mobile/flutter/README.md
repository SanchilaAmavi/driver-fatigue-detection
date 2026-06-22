# Flutter Driver Fatigue App

This Flutter starter app is designed for camera-based driver fatigue detection with on-device face analysis and Firebase logging.

## Features included

- Front camera monitoring
- Google ML Kit face detection
- Eye closure, yawning, and head-pose alerts
- Real-time overlay alert screen
- Firebase Firestore event logging
- Backend trip logging placeholder
- Dashboard and login placeholder screens

## Firebase setup

1. Add your `google-services.json` to:
   - `mobile/flutter/android/app/google-services.json`

2. If you add iOS support, add `GoogleService-Info.plist` to:
   - `mobile/flutter/ios/Runner/GoogleService-Info.plist`

3. Configure Android Gradle plugin:

### `android/build.gradle`

```groovy
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.5.0'
    }
}
```

### `android/app/build.gradle`

```groovy
plugins {
    id 'com.android.application'
    id 'com.google.gms.google-services'
}

android {
    namespace 'com.example.driver_fatigue_detection'
}

dependencies {
    implementation platform('com.google.firebase:firebase-bom:34.15.0')
    implementation 'com.google.firebase:firebase-analytics'
    implementation 'com.google.firebase:firebase-firestore'
}
```

4. Install dependencies:

```bash
cd mobile/flutter
flutter pub get
```

5. If the native Android/iOS directories do not exist yet, generate the Flutter project files first:

```bash
cd mobile/flutter
flutter create .
flutter pub get
```

6. Run the app:

```bash
flutter run
```

## Notes

- The app currently uses Firebase only for event logging.
- The backend trip logging function is a placeholder and may require auth headers once backend auth is enabled.
- Use `mobile/flutter/lib/screens/camera_screen.dart` for the real-time fatigue logic.

## Recommended next steps

- Add Firebase Authentication to `login_screen.dart`
- Add camera permission handling for Android and iOS
- Add a proper trip history screen using Firestore or backend data
- Tune the fatigue thresholds for your model and use real EAR/MAR calculations
