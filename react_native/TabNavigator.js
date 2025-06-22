import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { NavigationContainer } from '@react-navigation/native';

import SplashScreen from './SplashScreen';
import ClearSkyPhotoIntakeScreen from './App';
import ReportPreviewScreen from './ReportPreviewScreen';
import SettingsScreen from './SettingsScreen';

const Tab = createBottomTabNavigator();

export default function MainApp() {
  return (
    <NavigationContainer>
      <Tab.Navigator
        initialRouteName="ClearSkyPhotoIntakeScreen"
        screenOptions={{
          headerShown: false,
        }}
      >
        <Tab.Screen
          name="Intake"
          component={ClearSkyPhotoIntakeScreen}
          options={{ tabBarLabel: 'Intake' }}
        />
        <Tab.Screen
          name="Reports"
          component={ReportPreviewScreen}
          options={{ tabBarLabel: 'Reports' }}
        />
        <Tab.Screen
          name="Settings"
          component={SettingsScreen}
          options={{ tabBarLabel: 'Settings' }}
        />
      </Tab.Navigator>
    </NavigationContainer>
  );
}
