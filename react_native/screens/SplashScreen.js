import React, { useEffect } from 'react';
import { View, Text } from 'react-native';

export default function SplashScreen({ navigation }) {
  useEffect(() => {
    console.log('SplashScreen mounted');
    const timer = setTimeout(() => {
      try {
        console.log('Navigating to PhotoIntake');
        navigation.replace('PhotoIntake');
      } catch (err) {
        console.error('Navigation error', err);
      }
    }, 2000);

    return () => {
      clearTimeout(timer);
      console.log('SplashScreen cleanup');
    };
  }, [navigation]);

  return (
    <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
      <Text>ClearSky Splash Screen</Text>
    </View>
  );
}
