import React, { useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TextInput,
  Image,
  Button,
  TouchableOpacity,
  Modal,
} from 'react-native';
import { Picker } from '@react-native-picker/picker';
import * as ImagePicker from 'expo-image-picker';
import PhotoAnnotationScreen from './PhotoAnnotationScreen';
import AnnotatedImage from './AnnotatedImage';
import { appColors, appSpacing, appTypography } from './appTheme';

// Mock AI label suggestions per inspection section
const mockAISuggestions = {
  Front: [
    'Front Elevation – Downspout – Possible Hail Damage',
    'Front Elevation – Gutter – Sagging',
  ],
  Right: [
    'Right Elevation – Fascia – Peeling Paint',
    'Right Elevation – Siding – Impact Marks',
  ],
  Back: [
    'Back Elevation – Window Trim – Wood Rot',
    'Back Elevation – Hose Bib – Rust Stains',
  ],
  Left: [
    'Left Elevation – AC Unit – Obstruction',
    'Left Elevation – Foundation Crack',
  ],
  'Roof Edge': ['Roof Edge – Drip Edge – Bent', 'Roof Edge – Soffit – Animal Damage'],
  Slopes: [
    'Roof Slope – Shingle Crease – Wind Lift',
    'Roof Slope – Soft Spot – Possible Deck Rot',
  ],
  Buildings: ['Detached Garage – Missing Shingles', 'Shed – Rotting Fascia'],
  Address: ['Address Confirmed – 123 Main St', 'Front View – House Orientation Verified'],
};

// Return a random AI suggestion for a given section or a fallback text
const generateAISuggestion = (sectionPrefix) => {
  const suggestions = mockAISuggestions[sectionPrefix] || [
    'General Observation – No Issues Detected',
  ];
  return suggestions[Math.floor(Math.random() * suggestions.length)];
};

// Very simple AI annotation generator placeholder
const generateAIAnnotations = () => [
  { type: 'circle', x: 150, y: 150, r: 40 },
  { type: 'arrow', startX: 20, startY: 20, endX: 80, endY: 80 },
];

// Simple tag recommendations per section type
const tagSuggestions = {
  Slopes: ['shingle', 'tile', 'metal'],
  Front: ['siding', 'gutter'],
  Right: ['vent', 'flashing'],
  Back: ['deck', 'pipe boot'],
  Left: ['chimney', 'window'],
  Buildings: ['garage', 'shed'],
};

// Simplified field workflow for the intake screen
const inspectionSections = [
  'Address',
  'Front',
  'Right',
  'Back',
  'Left',
  'Roof Edge',
  'Slopes',
  'Buildings',
];


export default function ClearSkyPhotoIntakeScreen() {
  // Store photos keyed by section name
  const [photoData, setPhotoData] = useState({});
  const [selectedSection, setSelectedSection] = useState(inspectionSections[0]);
  const [checklist, setChecklist] = useState(
    Object.fromEntries(inspectionSections.map((s) => [s, false]))
  );
  const [autoChecklist, setAutoChecklist] = useState(true);
  const [editingPhoto, setEditingPhoto] = useState(null);

  const handlePhotoUpload = async (section) => {
    console.log('Upload photo for', section);
    let result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsEditing: false,
      quality: 1,
    });

    if (!result.canceled) {
      const newPhoto = {
        imageUri: result.assets[0].uri,
        originalUri: result.assets[0].uri,
        userLabel: generateAISuggestion(section),
        annotations: generateAIAnnotations(),
        showAnnotated: false,
      };

      setPhotoData((prevData) => {
        const updatedSection = prevData[section]
          ? [...prevData[section], newPhoto]
          : [newPhoto];
        return { ...prevData, [section]: updatedSection };
      });
      console.log('Added photo to', section);
      if (autoChecklist) {
        setChecklist((prev) => ({ ...prev, [section]: true }));
      }
    }
  };

  const handleLabelChange = (section, index, newLabel) => {
    console.log('Label change', section, index, newLabel);
    setPhotoData((prevData) => {
      const updatedSection = [...prevData[section]];
      updatedSection[index].userLabel = newLabel;
      return { ...prevData, [section]: updatedSection };
    });
  };

  const handleSaveAnnotations = (section, index, annotations) => {
    console.log('Save annotations', section, index);
    setPhotoData((prevData) => {
      const updatedSection = [...prevData[section]];
      updatedSection[index].annotations = annotations;
      updatedSection[index].showAnnotated = true;
      return { ...prevData, [section]: updatedSection };
    });
    setEditingPhoto(null);
  };

  const progress = Object.values(checklist).filter(Boolean).length;

  return (
    <View style={{ flex: 1 }}>
      <Modal visible={!!editingPhoto} animationType="slide">
        {editingPhoto && (
          <PhotoAnnotationScreen
            photo={photoData[editingPhoto.section][editingPhoto.index]}
            onSave={(ann) => handleSaveAnnotations(editingPhoto.section, editingPhoto.index, ann)}
            onClose={() => setEditingPhoto(null)}
          />
        )}
      </Modal>
      <ScrollView contentContainerStyle={styles.container}>
      <Picker
        selectedValue={selectedSection}
        onValueChange={(val) => setSelectedSection(val)}
      >
        {inspectionSections.map((s) => (
          <Picker.Item label={s} value={s} key={s} />
        ))}
      </Picker>

      <View style={{ marginVertical: 10 }}>
        <Button
          title={`Upload Photo for ${selectedSection}`}
          onPress={() => handlePhotoUpload(selectedSection)}
        />

        {photoData[selectedSection]?.map((item, index) => (
          <View key={index} style={{ marginTop: 10 }}>
            {item.showAnnotated && item.annotations.length ? (
              <AnnotatedImage
                photo={item}
                style={{ width: 200, height: 200, borderRadius: 6 }}
              />
            ) : (
              <Image
                source={{ uri: item.imageUri }}
                style={{ width: 200, height: 200, borderRadius: 6 }}
                resizeMode="cover"
              />
            )}

            <TextInput
              value={item.userLabel}
              onChangeText={(text) => handleLabelChange(selectedSection, index, text)}
              placeholder="Enter photo label"
              style={{
                borderWidth: 1,
                borderColor: '#ccc',
                padding: 8,
                marginTop: 5,
                borderRadius: 4,
              }}
            />

            <View style={styles.tagRow}>
              {tagSuggestions[selectedSection]?.map((tag) => (
                <TouchableOpacity
                  key={tag}
                  style={styles.tagButton}
                  onPress={() => handleLabelChange(selectedSection, index, `${item.userLabel} ${tag}`)}
                >
                  <Text style={styles.tagText}>{tag}</Text>
                </TouchableOpacity>
              ))}
            </View>
            <View style={{ flexDirection: 'row', marginTop: 4 }}>
              <Button title="Annotate" onPress={() => setEditingPhoto({ section: selectedSection, index })} />
              {item.annotations.length > 0 && (
                <Button
                  title={item.showAnnotated ? 'Original' : 'Marked Up'}
                  onPress={() => {
                    setPhotoData((prev) => {
                      const updated = [...prev[selectedSection]];
                      updated[index].showAnnotated = !updated[index].showAnnotated;
                      return { ...prev, [selectedSection]: updated };
                    });
                  }}
                />
              )}
            </View>
          </View>
        ))}
      </View>

      <View style={{ marginTop: 20 }}>
        <Text>
          Checklist: {progress}/{inspectionSections.length} sections completed
        </Text>
        <View style={{ flexDirection: 'row', alignItems: 'center', marginTop: 8 }}>
          <Text>Auto-complete checklist</Text>
          <Button
            title={autoChecklist ? 'On' : 'Off'}
            onPress={() => setAutoChecklist(!autoChecklist)}
          />
        </View>
      </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: appSpacing.medium,
  },
  sectionContainer: {
    marginBottom: appSpacing.medium,
    borderWidth: 1,
    borderColor: appColors.border,
    borderRadius: 8,
  },
  sectionHeader: {
    padding: appSpacing.small + 4,
    backgroundColor: appColors.background,
  },
  sectionTitle: {
    ...appTypography.subheading,
  },
  sectionContent: {
    padding: appSpacing.small + 4,
  },
  photoItem: {
    margin: appSpacing.small / 2,
    width: 100,
  },
  thumbnail: {
    width: 100,
    height: 100,
    borderRadius: 4,
  },
  labelInput: {
    borderBottomWidth: 1,
    borderColor: appColors.border,
    paddingVertical: 4,
    marginTop: 4,
  },
  suggestText: {
    fontSize: 12,
    color: appColors.textSecondary,
    marginTop: 2,
  },
  actionRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 4,
  },
  actionButton: {
    paddingHorizontal: appSpacing.small / 2,
  },
  tagRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginTop: 4,
  },
  tagButton: {
    backgroundColor: appColors.background,
    paddingHorizontal: appSpacing.small - 2,
    paddingVertical: 2,
    borderRadius: 4,
    margin: 2,
  },
  tagText: {
    fontSize: 12,
    color: appColors.textPrimary,
  },
});

