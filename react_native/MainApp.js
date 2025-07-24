import React, { useEffect } from 'react';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import { View, Text } from 'react-native';
import ErrorBoundary from './ErrorBoundary';
import { offlineMode } from './firebaseConfig';

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
      {offlineMode && (
        <View
          style={{ backgroundColor: 'orange', padding: 8 }}
        >
          <Text style={{ color: 'white', textAlign: 'center' }}>
            ⚠️ Running in demo mode. Firebase not connected.
          </Text>
        </View>
      )}
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
