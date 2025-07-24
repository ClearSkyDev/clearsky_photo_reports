import React, { useEffect } from 'react';
import { View, Text } from 'react-native';

export default function ReportPreviewScreen() {
  useEffect(() => {
    console.log('ReportPreviewScreen mounted');
  }, []);

  return (
    <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
      <Text>Report Preview Screen</Text>
    </View>
  );
}
