import React from 'react';
import { View, Text, Button, StyleSheet } from 'react-native';

export default function PhotoIntakeScreen() {
  return (
    <View style={styles.container}>
      <Text>Photo Intake Screen</Text>
      <Button title="Click Me" onPress={() => alert("It works!")} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
});
