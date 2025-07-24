import React, { useEffect } from 'react';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import ErrorBoundary from './ErrorBoundary';
import { offlineMode } from './firebaseConfig';
import DemoBanner from './components/DemoBanner';

// Screens
import SplashScreen from './screens/SplashScreen';
import PhotoIntakeScreen from './screens/PhotoIntakeScreen';
import ReportPreviewScreen from './screens/ReportPreviewScreen';

const Stack = createStackNavigator();

export default function MainApp() {
  useEffect(() => {
    console.log('MainApp mounted - offlineMode:', offlineMode);
  }, []);

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <DemoBanner subtext="Some features may be limited." />
      <ErrorBoundary>
        <NavigationContainer>
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
      </ErrorBoundary>
    </GestureHandlerRootView>
  );
}
