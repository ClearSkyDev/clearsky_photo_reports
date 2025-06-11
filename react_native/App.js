import React, { useState } from 'react';
import { View, Text, ScrollView, TouchableOpacity, StyleSheet, TextInput, Image, FlatList, Button } from 'react-native';
import * as ImagePicker from 'expo-image-picker';

const inspectionSections = [
  'Address + Front Shot',
  'Front Elevation',
  'Right Elevation',
  'Back Elevation',
  'Left Elevation',
  'Rear Yard',
  'Roof Edge',
  'Front Slope',
  'Right Slope',
  'Back Slope',
  'Left Slope',
  'Accessories & Conditions'
];

export default function ClearSkyPhotoIntakeScreen() {
  const [photosBySection, setPhotosBySection] = useState({});

  const handleAddPhoto = async (section) => {
    const result = await ImagePicker.launchCameraAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      quality: 0.5,
    });

    if (!result.canceled) {
      const photoObj = {
        id: Date.now().toString(),
        imageUri: result.assets[0].uri,
        sectionPrefix: section,
        userLabel: section,
        aiSuggestedLabel: '',
        approved: false,
      };
      setPhotosBySection((prev) => ({
        ...prev,
        [section]: prev[section] ? [...prev[section], photoObj] : [photoObj],
      }));
    }
  };

  const updatePhoto = (section, id, changes) => {
    setPhotosBySection((prev) => ({
      ...prev,
      [section]: prev[section].map((p) => (p.id === id ? { ...p, ...changes } : p)),
    }));
  };

  return (
    <ScrollView contentContainerStyle={styles.container}>
      {inspectionSections.map((section) => (
        <SectionAccordion
          key={section}
          section={section}
          photos={photosBySection[section] || []}
          onAddPhoto={() => handleAddPhoto(section)}
          onUpdateLabel={(id, text) => updatePhoto(section, id, { userLabel: text })}
          onApprove={(id) => updatePhoto(section, id, { approved: true })}
          onEdit={(id) => updatePhoto(section, id, { approved: false })}
          onSkip={(id) => updatePhoto(section, id, { approved: false })}
        />
      ))}
    </ScrollView>
  );
}

function SectionAccordion({ section, photos, onAddPhoto, onUpdateLabel, onApprove, onEdit, onSkip }) {
  const [open, setOpen] = useState(false);

  return (
    <View style={styles.sectionContainer}>
      <TouchableOpacity onPress={() => setOpen(!open)} style={styles.sectionHeader}>
        <Text style={styles.sectionTitle}>{section}</Text>
      </TouchableOpacity>
      {open && (
        <View style={styles.sectionContent}>
          <Button title="Add Photo" onPress={onAddPhoto} />
          <FlatList
            data={photos}
            numColumns={3}
            keyExtractor={(item) => item.id}
            renderItem={({ item }) => (
              <View style={styles.photoItem}>
                <Image source={{ uri: item.imageUri }} style={styles.thumbnail} />
                <TextInput
                  style={styles.labelInput}
                  value={item.userLabel}
                  placeholder={`${section} label`}
                  editable={!item.approved}
                  onChangeText={(text) => onUpdateLabel(item.id, text)}
                />
                {item.aiSuggestedLabel ? (
                  <Text style={styles.suggestText}>{item.aiSuggestedLabel}</Text>
                ) : null}
                <View style={styles.actionRow}>
                  <TouchableOpacity onPress={() => onApprove(item.id)} style={styles.actionButton}>
                    <Text>✅</Text>
                  </TouchableOpacity>
                  <TouchableOpacity onPress={() => onEdit(item.id)} style={styles.actionButton}>
                    <Text>✏️</Text>
                  </TouchableOpacity>
                  <TouchableOpacity onPress={() => onSkip(item.id)} style={styles.actionButton}>
                    <Text>⏭️</Text>
                  </TouchableOpacity>
                </View>
              </View>
            )}
          />
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: 16,
  },
  sectionContainer: {
    marginBottom: 16,
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 8,
  },
  sectionHeader: {
    padding: 12,
    backgroundColor: '#eee',
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: 'bold',
  },
  sectionContent: {
    padding: 12,
  },
  photoItem: {
    margin: 4,
    width: 100,
  },
  thumbnail: {
    width: 100,
    height: 100,
    borderRadius: 4,
  },
  labelInput: {
    borderBottomWidth: 1,
    borderColor: '#aaa',
    paddingVertical: 4,
    marginTop: 4,
  },
  suggestText: {
    fontSize: 12,
    color: '#666',
    marginTop: 2,
  },
  actionRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 4,
  },
  actionButton: {
    paddingHorizontal: 4,
  },
});

