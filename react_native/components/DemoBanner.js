import React, { useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { offlineMode } from '../firebaseConfig';

export function useDemoMode() {
  return offlineMode;
}

export default function DemoBanner({ subtext }) {
  const demoMode = useDemoMode();
  const [dismissed, setDismissed] = useState(false);

  if (!demoMode || dismissed) {
    return null;
  }

  return (
    <View style={styles.container}>
      <View style={styles.messageContainer}>
        <Text style={styles.text}>
          ⚠️ Running in demo mode. Firebase not connected.
        </Text>
        {subtext ? <Text style={styles.subtext}>{subtext}</Text> : null}
      </View>
      <TouchableOpacity onPress={() => setDismissed(true)} style={styles.close}>
        <Text style={styles.closeText}>X</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#FFC107',
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 8,
    paddingHorizontal: 12,
  },
  messageContainer: {
    flex: 1,
  },
  text: {
    fontWeight: 'bold',
    color: '#000',
  },
  subtext: {
    fontSize: 12,
    color: '#000',
  },
  close: {
    marginLeft: 8,
    paddingHorizontal: 8,
  },
  closeText: {
    fontWeight: 'bold',
    fontSize: 16,
    color: '#000',
  },
});
