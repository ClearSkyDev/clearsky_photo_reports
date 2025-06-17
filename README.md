# clearsky-photo-reports
AI powered roof inspection reporting app

## Drone & Infrared Media

Photos can now be tagged with a source type of `camera`, `drone` or `thermal`.
The new **Drone Media Upload** screen allows bulk importing of aerial or
infrared photos. Thumbnails show an icon representing the source and reports
include the capture source for each image.

## React Native Prototype

A minimal React Native + Expo implementation for the ClearSky Photo Intake screen is provided under `react_native/App.js`. This prototype demonstrates the collapsible inspection sections and photo upload workflow using Expo's image picker.

The intake screen now features a section dropdown so inspectors can quickly switch between Address, Front, Right, Back, Left, Roof Edge, Slopes and Buildings. Each uploaded photo is auto-labeled using sample AI suggestions and optional tags can be appended with a single tap. When enabled, adding a photo marks the related checklist item complete.

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

The app now supports dynamic checklists that vary by roof type and claim type. When starting a new report the correct checklist is loaded automatically and can be customized.
Each step tracks the number of required photos and checkboxes indicate progress. Incomplete steps are highlighted in the final report summary.
Progress can be viewed from the "View Checklist" button on the Send Report screen and a summary is included in the generated HTML/PDF reports.

## Photo Notes

Each photo can include an optional inspector note. Tap a photo in the upload screen to add or edit a note. Notes appear under the image in generated reports and are exported with the report data.

## Report Finalization

After exporting, inspectors can lock a report from the Send Report screen. Finalized reports cannot be edited but can still be exported or shared. A "FINALIZED" banner and lock icon identify locked reports in the history list and preview.

## Public Client Portal

Finalized reports generate a unique public link that can be shared with clients. Visiting the link displays a simplified report view with sections and photos. Clients may download the full report as a ZIP archive and leave optional comments which are saved back to Firestore for the inspector to review. The ZIP now includes the finalized PDF and all labeled photos organized by section. On web the archive is uploaded to Firebase Storage and a download link is provided. Download events are logged in Firestore. Admin users can view and revoke links from the dashboard.

## Client Messaging

Each report has a dedicated message thread stored under `reports/{id}/messages`. The public portal and inspector app display a chat-style view where clients can send questions or attach images and PDFs. Messages track who has read them so inspectors can see unread counts. Inspectors can resolve, export or mute a thread from the history screen.

## Secure Client Dashboard

Authenticated clients can access a full dashboard built with Flutter Web. Login supports regular email/password credentials or magic links sent via Firebase Auth. The dashboard provides tabs for Reports, Messages, Invoices and Settings. Clients can view finalized reports as PDFs, download ZIP archives, join message threads and pay outstanding invoices. All activity is logged to the `clientActivity` collection for visibility. Example Firestore rules are provided in `firestore_client.rules` which ensure clients only access documents matching their email address.

Run the client portal with:

```bash
flutter run -d chrome -t lib/client_portal_main.dart
```

## Weekly Snapshot Emails

Clients may opt in to a weekly email summarizing finalized reports from the previous week. The snapshot lists property addresses, invoice totals and damage notes with links to view each report or download attachments. Preferences are stored in the `clientPreferences` collection and a Firebase Cloud Function sends the messages on the configured day and hour. Administrators can trigger a send manually and all emails are logged under `snapshotEmails`.

## Report Map View

Reports with saved GPS coordinates appear on an interactive map available from the dashboard. Pins are colored based on report status and can be filtered by inspector, status or date. Tap a pin to see a quick summary and open the full report.

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

## Offline Mode

When connectivity is lost the app now stores draft reports in a local Hive database. A small "Offline" badge appears in the dashboard and all Firebase calls are skipped. Once a connection is detected a sync button uploads any pending drafts and clears the local storage.

## Admin Audit Logs

Administrators can review a history of actions such as logins, invoice updates and report changes. The **Audit Logs** screen provides search and filtering by user, action, date or target ID and exports the results to CSV for external analysis.

## On-Site AI Chat Assistant

Inspectors can access a contextual AI helper during roof inspections. Tapping the floating **Ask AI** button opens a chat drawer that suggests next photos, reviews checklist progress and answers insurance related questions. Conversations are saved under each report and can be exported for supervisor review.

## AI-Guided Photo Prompts

During photo capture the app now displays a banner suggesting the next required section based on the inspector's role. The banner updates after each photo and includes a button to open the camera directly. Required photo counts differ for ladder assists, adjusters and contractors, so prompts reflect what is still missing for the current report.
