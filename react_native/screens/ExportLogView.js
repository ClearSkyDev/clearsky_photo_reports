// ExportLogView.js - full export screen with local log, notes, encrypted sync, restore, undo, and CSV export
import React, { useState, useEffect, useRef } from 'react';
import { View, Text, FlatList, TouchableOpacity, StyleSheet, TextInput, Share, Alert } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as FileSystem from 'expo-file-system';
import * as Sharing from 'expo-sharing';
import CryptoJS from 'crypto-js';
import { collection, doc, setDoc, getDoc } from 'firebase/firestore';
import { db, auth } from '../firebaseConfig';

const ExportLogView = ({ log, generateCSV, generatePDF }) => {
  const [searchText, setSearchText] = useState('');
  const [filteredLog, setFilteredLog] = useState(log);
  const [notes, setNotes] = useState({});
  const [undoData, setUndoData] = useState(null);
  const secretKey = 'your_secret_key';

  useEffect(() => {
    filterLog();
  }, [searchText, log]);

  const filterLog = () => {
    const filtered = log.filter(item =>
      item.title?.toLowerCase().includes(searchText.toLowerCase())
    );
    setFilteredLog(filtered);
  };

  const saveBackup = async () => {
    try {
      const data = JSON.stringify(log);
      const ciphertext = CryptoJS.AES.encrypt(data, secretKey).toString();
      const path = FileSystem.documentDirectory + 'backup.txt';
      await FileSystem.writeAsStringAsync(path, ciphertext);
      await Sharing.shareAsync(path);
    } catch (err) {
      Alert.alert('Error', 'Failed to export backup.');
    }
  };

  const restoreBackup = async () => {
    try {
      const uri = FileSystem.documentDirectory + 'backup.txt';
      const encrypted = await FileSystem.readAsStringAsync(uri);
      const bytes = CryptoJS.AES.decrypt(encrypted, secretKey);
      const decrypted = bytes.toString(CryptoJS.enc.Utf8);
      const parsed = JSON.parse(decrypted);
      setUndoData(log);
      Alert.alert('Restore', 'Backup loaded. Please confirm overwrite.', [
        {
          text: 'Confirm',
          onPress: async () => {
            await AsyncStorage.setItem('exportLog', JSON.stringify(parsed));
            Alert.alert('Restored', 'Backup successfully restored.');
          },
        },
        { text: 'Cancel' },
      ]);
    } catch (err) {
      Alert.alert('Error', 'Failed to restore backup.');
    }
  };

  const undoRestore = async () => {
    if (!undoData) return;
    await AsyncStorage.setItem('exportLog', JSON.stringify(undoData));
    Alert.alert('Undo', 'Previous state restored.');
  };

  const exportToCloud = async () => {
    const user = auth.currentUser;
    if (!user) return;
    await setDoc(doc(db, 'users', user.uid), {
      log,
      timestamp: new Date().toISOString(),
    });
    Alert.alert('Uploaded', 'Export log saved to cloud.');
  };

  const loadFromCloud = async () => {
    const user = auth.currentUser;
    if (!user) return;
    const snap = await getDoc(doc(db, 'users', user.uid));
    if (snap.exists()) {
      const cloudLog = snap.data().log || [];
      setUndoData(log);
      await AsyncStorage.setItem('exportLog', JSON.stringify(cloudLog));
      Alert.alert('Restored', 'Cloud backup loaded.');
    }
  };

  const renderItem = ({ item }) => (
    <View style={styles.card}>
      <Text style={styles.title}>{item.title}</Text>
      <Text>{item.timestamp}</Text>
      <TextInput
        placeholder="Notes"
        style={styles.noteInput}
        value={notes[item.id] || ''}
        onChangeText={(text) => setNotes({ ...notes, [item.id]: text })}
      />
    </View>
  );

  return (
    <View style={styles.container}>
      <Text style={styles.header}>Export Log</Text>
      <TextInput
        style={styles.searchInput}
        placeholder="Search by title"
        value={searchText}
        onChangeText={setSearchText}
      />
      <FlatList
        data={filteredLog}
        keyExtractor={(item) => item.id}
        renderItem={renderItem}
      />
      <View style={styles.buttonRow}>
        <TouchableOpacity style={styles.button} onPress={generateCSV}>
          <Text>Export CSV</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.button} onPress={generatePDF}>
          <Text>Export PDF</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.button} onPress={saveBackup}>
          <Text>Backup</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.button} onPress={restoreBackup}>
          <Text>Restore</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.button} onPress={undoRestore}>
          <Text>Undo</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.button} onPress={exportToCloud}>
          <Text>Cloud Save</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.button} onPress={loadFromCloud}>
          <Text>Cloud Load</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, padding: 10 },
  header: { fontSize: 22, textAlign: 'center', marginBottom: 10 },
  searchInput: { borderWidth: 1, borderColor: '#ccc', padding: 6, marginBottom: 10 },
  card: { borderWidth: 1, borderColor: '#eee', padding: 10, marginBottom: 8 },
  title: { fontWeight: 'bold' },
  noteInput: { marginTop: 4, borderWidth: 1, borderColor: '#ccc', padding: 4 },
  buttonRow: { flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'space-between', marginTop: 10 },
  button: { padding: 8, backgroundColor: '#eee', borderRadius: 4, margin: 4 },
});

export default ExportLogView;
