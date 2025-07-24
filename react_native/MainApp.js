import React from 'react';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import ErrorBoundary from './ErrorBoundary';

// Screens
import SplashScreen from './screens/SplashScreen';
import PhotoIntakeScreen from './screens/PhotoIntakeScreen';
import ReportPreviewScreen from './screens/ReportPreviewScreen';

const Stack = createStackNavigator();

export default function MainApp() {
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
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
