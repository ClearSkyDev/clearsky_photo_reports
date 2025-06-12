import React, { useState } from 'react';
import { View, Text, ScrollView, TouchableOpacity, StyleSheet, TextInput, Image, FlatList, Button } from 'react-native';
import * as ImagePicker from 'expo-image-picker';
import * as ImageManipulator from 'expo-image-manipulator';

// Mock AI label suggestions per inspection section
const mockAISuggestions = {
  'Front Elevation': [
    'Front Elevation – Downspout – Possible Hail Damage',
    'Front Elevation – Gutter – Sagging',
  ],
  'Right Elevation': [
    'Right Elevation – Fascia – Peeling Paint',
    'Right Elevation – Siding – Impact Marks',
  ],
  'Back Elevation': [
    'Back Elevation – Window Trim – Wood Rot',
    'Back Elevation – Hose Bib – Rust Stains',
  ],
  'Left Elevation': [
    'Left Elevation – AC Unit – Obstruction',
    'Left Elevation – Foundation Crack',
  ],
  'Roof Edge': ['Roof Edge – Drip Edge – Bent', 'Roof Edge – Soffit – Animal Damage'],
  'Front Slope': ['Front Slope – Shingle Crease – Wind Lift', 'Front Slope – Granule Loss – Aging'],
  'Right Slope': ['Right Slope – Soft Spot – Possible Deck Rot', 'Right Slope – Nail Pops – Shingle Lift'],
  'Back Slope': ['Back Slope – Pipe Jack – Cracked Boot', 'Back Slope – Ridge Cap – Exposed Nail'],
  'Left Slope': ['Left Slope – Flashing – Loose', 'Left Slope – Vent Cap – Rust'],
  'Accessories & Conditions': ['Skylight – Flashing Improper', 'Satellite Dish – Improper Mount'],
  'Rear Yard': ['Rear Yard – Fence Damage', 'Rear Yard – Tree Limbs Over Roof'],
  'Address + Front Shot': ['Address Confirmed – 123 Main St', 'Front View – House Orientation Verified'],
};

// Return a random AI suggestion for a given section or a fallback text
const generateAISuggestion = (sectionPrefix) => {
  const suggestions = mockAISuggestions[sectionPrefix] || [
    'General Observation – No Issues Detected',
  ];
  return suggestions[Math.floor(Math.random() * suggestions.length)];
};

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

// Resize then crop a photo to ensure a 1:1 aspect ratio
async function compressAndSquarePhoto(uri) {
  try {
    const resized = await ImageManipulator.manipulateAsync(
      uri,
      [{ resize: { width: 1024 } }],
      { compress: 0.7, format: ImageManipulator.SaveFormat.JPEG }
    );

    const { width, height } = resized;
    if (width !== height) {
      const size = Math.min(width, height);
      const cropX = Math.floor((width - size) / 2);
      const cropY = Math.floor((height - size) / 2);
      const cropped = await ImageManipulator.manipulateAsync(
        resized.uri,
        [{
          crop: {
            originX: cropX,
            originY: cropY,
            width: size,
            height: size,
          },
        }],
        { compress: 0.7, format: ImageManipulator.SaveFormat.JPEG }
      );
      return cropped.uri;
    }
    return resized.uri;
  } catch (err) {
    console.error('Error squaring image:', err);
    return uri;
  }
}

export default function ClearSkyPhotoIntakeScreen() {
  const [photosBySection, setPhotosBySection] = useState({});

  const handleAddPhoto = async (section) => {
    const result = await ImagePicker.launchCameraAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      quality: 0.5,
    });

    if (!result.canceled) {
      const processedUri = await compressAndSquarePhoto(result.assets[0].uri);
      const photoObj = {
        id: Date.now().toString(),
        imageUri: processedUri,
        sectionPrefix: section,
        userLabel: section,
        aiSuggestedLabel: generateAISuggestion(section),
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

  const regenerateAISuggestion = (section, id) => {
    updatePhoto(section, id, { aiSuggestedLabel: generateAISuggestion(section) });
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
          onRegenerate={(id) => regenerateAISuggestion(section, id)}
        />
      ))}
    </ScrollView>
  );
}

function SectionAccordion({ section, photos, onAddPhoto, onUpdateLabel, onApprove, onEdit, onSkip, onRegenerate }) {
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
                  <TouchableOpacity onPress={() => onRegenerate(item.id)} style={styles.actionButton}>
                    <Text>🔄</Text>
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

