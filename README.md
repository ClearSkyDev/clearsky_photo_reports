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
