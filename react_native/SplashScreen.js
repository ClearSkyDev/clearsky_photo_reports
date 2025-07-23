import React, { useEffect } from 'react';
import { View, Text, StyleSheet, Alert } from 'react-native';
import { appColors, appTypography } from './appTheme';

export default function SplashScreen({ navigation }) {
  useEffect(() => {
    if (!process.env.EXPO_PUBLIC_FIREBASE_API_KEY) {
      Alert.alert(
        'Configuration Error',
        'Firebase API key is missing. Please configure the app.'
      );
    }
    const timer = setTimeout(() => {
      navigation.replace('ClearSkyPhotoIntakeScreen');
    }, 1500);
    return () => clearTimeout(timer);
  }, [navigation]);

  return (
    <View style={styles.container}>
      <Text style={styles.title}>ClearSky Photo Reports</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: appColors.surface,
  },
  title: {
    ...appTypography.heading,
    fontSize: 24,
  },
});
