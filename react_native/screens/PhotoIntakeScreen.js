import React, { useEffect } from 'react';
import { View, Text } from 'react-native';

export default function PhotoIntakeScreen() {
  useEffect(() => {
    console.log('PhotoIntakeScreen mounted');
  }, []);

  return (
    <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
      <Text>Photo Intake Screen</Text>
    </View>
  );
}
