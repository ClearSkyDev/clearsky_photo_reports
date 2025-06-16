# clearsky-photo-reports
AI powered roof inspection reporting app

## React Native Prototype

A minimal React Native + Expo implementation for the ClearSky Photo Intake screen is provided under `react_native/App.js`. This prototype demonstrates the collapsible inspection sections and photo upload workflow using Expo's image picker.

## Questionnaire Generation Demo

The file `react_native/roofQuestionnaire.js` contains a utility that converts approved photo labels into a structured questionnaire object. A small demo script is available under `scripts/demo_generate_questionnaire.js`:

```bash
node scripts/demo_generate_questionnaire.js
```

Running the script outputs a pre-filled questionnaire based on sample photos.

## Report Preview Screen

`react_native/ReportPreviewScreen.js` implements a basic report preview. It takes a set of approved photo objects and a questionnaire object and allows inspectors to edit a summary then export the result as HTML or PDF. The exported file is saved to the device and the native share sheet is opened so the report can be shared or saved using any available app.

The preview screen now also includes a signature canvas so inspectors can sign the report before exporting.

## Inspection Checklist

The app tracks key inspection tasks such as uploading photos, filling out metadata and capturing a signature.
Progress can be viewed from the "View Checklist" button on the Send Report screen and a summary is included in the generated HTML/PDF reports.

## Flutter Report Preview

The Flutter implementation renders the inspection report HTML differently depending on the platform:

- **Web**: an `IFrameElement` from `dart:html` is registered with `ui.platformViewRegistry` and inserted using `HtmlElementView`.
- **Mobile**: the [`webview_flutter`](https://pub.dev/packages/webview_flutter) plugin displays the report. The HTML is converted to a base64 data URI and loaded as local content.

## Firebase Setup

This project uses Firebase for data storage and optional photo uploads. Install the `firebase_core`, `cloud_firestore` and `firebase_storage` packages and generate platform configuration files.

1. Create a Firebase project in the [Firebase console](https://console.firebase.google.com).
2. Download **google-services.json** for Android and **GoogleService-Info.plist** for iOS and place them in the respective platform directories.
3. Run `flutterfire configure` to generate `lib/firebase_options.dart` which provides the `DefaultFirebaseOptions` used during `Firebase.initializeApp`.

## Local Storage Alternative

For scenarios where Firebase is not available, reports can be stored locally using `LocalReportStore`. This implementation saves report JSON files under the application's documents directory and keeps an index of saved reports with `shared_preferences`.
