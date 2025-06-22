import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';

import SplashScreen from './SplashScreen';
import ClearSkyPhotoIntakeScreen from './App';
import ReportPreviewScreen from './ReportPreviewScreen';

const Stack = createStackNavigator();

export default function MainApp() {
  return (
    <NavigationContainer>
      <Stack.Navigator initialRouteName="Splash">
        <Stack.Screen
          name="Splash"
          component={SplashScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="ClearSkyPhotoIntakeScreen"
          component={ClearSkyPhotoIntakeScreen}
        />
        <Stack.Screen
          name="ReportPreviewScreen"
          component={ReportPreviewScreen}
        />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
