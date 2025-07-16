import React from 'react';
import { Platform, Text, View } from 'react-native';

export default function PDFExportBanner() {
  if (__DEV__ && Platform.OS === 'web') {
    return (
      <View style={{ backgroundColor: 'orange', padding: 10 }}>
        <Text style={{ color: 'white', fontWeight: 'bold' }}>
          PDF Export is not available in Expo Go. Test in a custom build.
        </Text>
      </View>
    );
  }
  return null;
}
