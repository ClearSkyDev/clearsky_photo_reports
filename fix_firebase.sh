#!/bin/bash

set -e

# Ensure flutterfire CLI is installed
if ! command -v flutterfire &> /dev/null; then
  echo "[INFO] Installing FlutterFire CLI..."
  dart pub global activate flutterfire_cli
fi

# Run flutterfire configure
echo "[INFO] Running flutterfire configure to regenerate firebase_options.dart"
flutterfire configure --project=<your_firebase_project_id>

# Generate .env file from template
if [ -f .env.example ]; then
  echo "[INFO] Copying .env.example to .env"
  cp .env.example .env
  echo "[WARNING] Remember to replace placeholder values in .env with real Firebase credentials."
else
  echo "[ERROR] .env.example not found"
fi

# Firebase SDKs to ensure are present in pubspec.yaml
dependencies_to_add=(
  "firebase_core"
  "firebase_auth"
  "cloud_firestore"
  "logger"
)

echo "[INFO] Checking pubspec.yaml for necessary Firebase dependencies"
for dep in "${dependencies_to_add[@]}"; do
  if ! grep -q "$dep" pubspec.yaml; then
    echo "    Adding: $dep"
    echo "$dep: ^latest" >> pubspec.yaml
  fi

done

# Ensure Google config files exist
ANDROID_GOOGLE_SERVICES=android/app/google-services.json
IOS_GOOGLE_PLIST=ios/Runner/GoogleService-Info.plist

if [ ! -f "$ANDROID_GOOGLE_SERVICES" ]; then
  echo "[WARNING] Missing google-services.json in android/app/"
fi

if [ ! -f "$IOS_GOOGLE_PLIST" ]; then
  echo "[WARNING] Missing GoogleService-Info.plist in ios/Runner/"
fi

# Fix Android build.gradle files
ANDROID_BUILD_GRADLE=android/build.gradle
APP_BUILD_GRADLE=android/app/build.gradle

if ! grep -q "com.google.gms:google-services" "$ANDROID_BUILD_GRADLE"; then
  echo "[INFO] Adding Google services classpath to android/build.gradle"
  sed -i "s/dependencies {/dependencies {\n        classpath 'com.google.gms:google-services:4.3.10'/" "$ANDROID_BUILD_GRADLE"
fi

if ! grep -q "com.google.gms.google-services" "$APP_BUILD_GRADLE"; then
  echo "[INFO] Applying google-services plugin in android/app/build.gradle"
  echo "apply plugin: 'com.google.gms.google-services'" >> "$APP_BUILD_GRADLE"
fi

# iOS minimum platform version fix
PODFILE=ios/Podfile
if grep -q "platform :ios" "$PODFILE"; then
  sed -i '' "s/platform :ios.*/platform :ios, '12.0'/" "$PODFILE"
else
  echo "platform :ios, '12.0'" >> "$PODFILE"
fi

# Run pod install
cd ios && pod install && cd ..

# Patch source files to fix known issues
find lib -type f -name "*.dart" -exec sed -i "s/\bdebugPrint\b/debugPrint/g" {} +
find lib -type f -name "*.dart" -exec sed -i "s/\bprint\b/logger().d/g" {} +
find scripts -type f -name "*.dart" -exec sed -i "s/\bprint\b/logger().d/g" {} +

echo "[SUCCESS] Firebase setup and logging updated. Ready to build your app!"
echo "➡️  Run: flutter build apk --release or flutter build ios --release"
