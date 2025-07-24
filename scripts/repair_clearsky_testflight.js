// Codex Script: repair_clearsky_testflight.js
// Purpose: Fix blank screen in ClearSky TestFlight builds for both React Native (Expo) and Flutter

// -------------------------------
// React Native Fixes (Expo)
// -------------------------------

// STEP 1: Overwrite MainApp.js with proper navigation stack
const fs = require('fs');
const path = require('path');

const mainAppPath = path.resolve('react_native/MainApp.js');
fs.writeFileSync(mainAppPath, `
import React from 'react';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';

import SplashScreen from './screens/SplashScreen';
import PhotoIntakeScreen from './screens/PhotoIntakeScreen';
import ReportPreviewScreen from './ReportPreviewScreen';

const Stack = createStackNavigator();

export default function MainApp() {
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <NavigationContainer>
        <Stack.Navigator initialRouteName="Splash" screenOptions={{ headerShown: false }}>
          <Stack.Screen name="Splash" component={SplashScreen} />
          <Stack.Screen name="PhotoIntake" component={PhotoIntakeScreen} />
          <Stack.Screen name="ReportPreview" component={ReportPreviewScreen} />
        </Stack.Navigator>
      </NavigationContainer>
    </GestureHandlerRootView>
  );
}
`);

// STEP 2: Set index.js to register MainApp
const indexPath = path.resolve('react_native/index.js');
fs.writeFileSync(indexPath, `
import { registerRootComponent } from 'expo';
import MainApp from './MainApp';
registerRootComponent(MainApp);
`);

// STEP 3: Install missing navigation dependencies (run via shell)
const { execSync } = require('child_process');

console.log('Installing required React Native packages...');
execSync('expo install react-native-gesture-handler react-native-screens react-native-safe-area-context react-native-reanimated', { stdio: 'inherit' });
execSync('npm install @react-navigation/native @react-navigation/stack', { stdio: 'inherit' });


// -------------------------------
// Flutter Fixes
// -------------------------------

// STEP 4: Loosen Firebase placeholder check in main.dart
const mainDartPath = path.resolve('lib/main.dart');
let mainDart = fs.readFileSync(mainDartPath, 'utf8');
mainDart = mainDart.replace(
  /if\s*\(DefaultFirebaseOptions\.currentPlatform\.apiKey\.contains\(['"]Example['"]\)\)\s*{[^}]*}/,
  `if (DefaultFirebaseOptions.currentPlatform.apiKey.contains('Example')) {
    print("⚠️ Warning: Running in demo mode without Firebase.");
  }`
);
fs.writeFileSync(mainDartPath, mainDart);

// STEP 5: Ensure splash.png is registered in pubspec.yaml
const pubspecPath = path.resolve('pubspec.yaml');
let pubspec = fs.readFileSync(pubspecPath, 'utf8');
if (!pubspec.includes('assets/splash.png')) {
  pubspec = pubspec.replace(/flutter:\s*\n/, 'flutter:\n  assets:\n    - assets/splash.png\n');
  fs.writeFileSync(pubspecPath, pubspec);
  console.log('✅ splash.png added to pubspec.yaml');
} else {
  console.log('✅ splash.png already in pubspec.yaml');
}

// DONE
console.log('\n✅ Fix script complete. You can now rebuild and resubmit your app to TestFlight.\nIf it still fails to render, double check your Firebase keys and Expo environment variables.');
