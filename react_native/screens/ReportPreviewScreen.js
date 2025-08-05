
import React, { useEffect, useState } from 'react';
import { View, Text, Image, StyleSheet, Button, Alert, TextInput } from 'react-native';
import { useRoute } from '@react-navigation/native';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import { collection, addDoc, serverTimestamp } from 'firebase/firestore';
import { storage, db } from '../firebaseConfig';
import * as FileSystem from 'expo-file-system';

export default function ReportPreviewScreen() {
  const route = useRoute();
  const { imageUri } = route.params || {};
  const [uploading, setUploading] = useState(false);
  const [downloadUrl, setDownloadUrl] = useState(null);
  const [name, setName] = useState('');
  const [notes, setNotes] = useState('');

  useEffect(() => {
    console.log('ReportPreviewScreen mounted with image:', imageUri);
  }, [imageUri]);

  const uploadToFirebase = async () => {
    if (!imageUri || !name) {
      Alert.alert('Missing Info', 'Please enter a name and select an image.');
      return;
    }

    try {
      setUploading(true);
      const imageBlob = await FileSystem.readAsStringAsync(imageUri, {
        encoding: FileSystem.EncodingType.Base64,
      });
      const response = await fetch(`data:image/jpeg;base64,${imageBlob}`);
      const blob = await response.blob();

      const filename = imageUri.split('/').pop();
      const storageRef = ref(storage, `reports/${filename}`);

      await uploadBytes(storageRef, blob);
      const url = await getDownloadURL(storageRef);
      setDownloadUrl(url);

      await addDoc(collection(db, 'reports'), {
        name,
        notes,
        imageUrl: url,
        createdAt: serverTimestamp(),
      });

      Alert.alert('Success', 'Report uploaded successfully.');
    } catch (err) {
      console.error('Upload failed', err);
      Alert.alert('Upload Failed', 'Could not upload image or save report.');
    } finally {
      setUploading(false);
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Report Preview Screen</Text>
      {imageUri ? (
        <Image source={{ uri: imageUri }} style={styles.preview} />
      ) : (
        <Text>No image provided.</Text>
      )}
      <TextInput
        style={styles.input}
        placeholder="Inspector Name"
        value={name}
        onChangeText={setName}
      />
      <TextInput
        style={styles.input}
        placeholder="Notes"
        value={notes}
        onChangeText={setNotes}
        multiline
      />
      {imageUri && (
        <Button
          title={uploading ? 'Uploading...' : 'Upload Report'}
          onPress={uploadToFirebase}
          disabled={uploading}
        />
      )}
      {downloadUrl && <Text style={styles.link}>Uploaded: {downloadUrl}</Text>}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 16,
  },
  title: {
    fontSize: 18,
    marginBottom: 20,
  },
  preview: {
    width: 300,
    height: 225,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#ccc',
    marginBottom: 20,
  },
  input: {
    width: '100%',
    padding: 12,
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 6,
    marginBottom: 12,
    backgroundColor: '#fff',
  },
  link: {
    marginTop: 12,
    color: 'blue',
    fontSize: 12,
    textAlign: 'center',
  },
});
