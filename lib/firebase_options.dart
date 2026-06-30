// Firebase configuration for this app.
//
// ─────────────────────────────────────────────────────────────────────────
//  HOW TO FILL THIS IN (one-time, ~5 minutes):
//
//  1. Go to https://console.firebase.google.com and create a project
//     (e.g. "jee-2027-challenge"). Google Analytics is optional — skip it.
//
//  2. Inside the project, click the Android icon ("Add app").
//        • Android package name:  com.jee2027.jee_challenge
//        • (Nickname / SHA-1 can be left blank.)
//     Click "Register app".
//
//  3. Firebase shows a `google-services.json` download. You DON'T need the
//     file — instead open it (or the "config" values shown) and copy these
//     5 values into the placeholders below:
//        apiKey            -> "current_key"            (in api_key section)
//        appId             -> "mobilesdk_app_id"
//        messagingSenderId -> "project_number"
//        projectId         -> "project_id"
//        storageBucket     -> "storage_bucket"
//
//  4. In the Firebase console left menu:
//        • Build → Authentication → Get started → enable "Email/Password".
//        • Build → Firestore Database → Create database → Production mode →
//          pick a location → Enable. Then open the "Rules" tab and paste:
//
//            rules_version = '2';
//            service cloud.firestore {
//              match /databases/{database}/documents {
//                match /users/{uid} {
//                  allow read, write: if request.auth != null
//                                     && request.auth.uid == uid;
//                }
//              }
//            }
//
//  5. Replace the placeholders below, then push. The GitHub Actions build
//     produces an APK with sync enabled.
// ─────────────────────────────────────────────────────────────────────────

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => android;

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAUmOhX-XCSjbmFfp-gVXC6Ni8iDRlu1iY',
    appId: '1:90377329009:android:03bd71f53edd10bf603ed0',
    messagingSenderId: '90377329009',
    projectId: 'jee-2027-7953a',
    storageBucket: 'jee-2027-7953a.firebasestorage.app',
  );
}
