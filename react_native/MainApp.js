import React, { useEffect } from 'react';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { NavigationContainer, useNavigationContainerRef } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';

// Screens
import SplashScreen from './screens/SplashScreen';
import PhotoIntakeScreen from './screens/PhotoIntakeScreen';
import ReportPreviewScreen from './screens/ReportPreviewScreen';

const Stack = createStackNavigator();

export default function MainApp() {
  const navigationRef = useNavigationContainerRef();
  useEffect(() => {
    console.log('[MainApp] mounted');
  }, []);
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <NavigationContainer
        ref={navigationRef}
        onReady={() => {
          console.log(`[MainApp] Initial screen: ${navigationRef.getCurrentRoute()?.name}`);
        }}
        onStateChange={() => {
          console.log(`[Navigation] Navigated to ${navigationRef.getCurrentRoute()?.name}`);
        }}
      >
        <Stack.Navigator initialRouteName="Splash">
          <Stack.Screen
            name="Splash"
            component={SplashScreen}
            options={{ headerShown: false }}
          />
          <Stack.Screen name="PhotoIntake" component={PhotoIntakeScreen} />
          <Stack.Screen name="ReportPreview" component={ReportPreviewScreen} />
        </Stack.Navigator>
      </NavigationContainer>
    </GestureHandlerRootView>
  );
}
