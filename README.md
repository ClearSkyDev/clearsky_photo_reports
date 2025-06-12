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
