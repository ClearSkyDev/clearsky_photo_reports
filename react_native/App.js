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
} from 'react-native';
import { Picker } from '@react-native-picker/picker';
import * as ImagePicker from 'expo-image-picker';

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

  const handlePhotoUpload = async (section) => {
    let result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsEditing: false,
      quality: 1,
    });

    if (!result.canceled) {
      const newPhoto = {
        uri: result.assets[0].uri,
        label: generateAISuggestion(section),
      };

      setPhotoData((prevData) => {
        const updatedSection = prevData[section]
          ? [...prevData[section], newPhoto]
          : [newPhoto];
        return { ...prevData, [section]: updatedSection };
      });
      if (autoChecklist) {
        setChecklist((prev) => ({ ...prev, [section]: true }));
      }
    }
  };

  const handleLabelChange = (section, index, newLabel) => {
    setPhotoData((prevData) => {
      const updatedSection = [...prevData[section]];
      updatedSection[index].label = newLabel;
      return { ...prevData, [section]: updatedSection };
    });
  };

  const progress = Object.values(checklist).filter(Boolean).length;

  return (
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
            <Image
              source={{ uri: item.uri }}
              style={{ width: 200, height: 200, borderRadius: 6 }}
              resizeMode="cover"
            />

            <TextInput
              value={item.label}
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
                  onPress={() => handleLabelChange(selectedSection, index, `${item.label} ${tag}`)}
                >
                  <Text style={styles.tagText}>{tag}</Text>
                </TouchableOpacity>
              ))}
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
  tagRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginTop: 4,
  },
  tagButton: {
    backgroundColor: '#eee',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
    margin: 2,
  },
  tagText: {
    fontSize: 12,
    color: '#333',
  },
});

