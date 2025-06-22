import React, { useEffect } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { appColors, appTypography } from './appTheme';

export default function SplashScreen({ navigation }) {
  useEffect(() => {
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
