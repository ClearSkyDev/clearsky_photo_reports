import React from 'react';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';

// Screens
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
