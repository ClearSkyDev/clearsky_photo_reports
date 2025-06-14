import React, { useState } from 'react';
import { View, Text, ScrollView, StyleSheet, TextInput, Image, Button } from 'react-native';
import * as ImagePicker from 'expo-image-picker';

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
  'Roof Accessories': ['Skylight – Flashing Improper', 'Satellite Dish – Improper Mount'],
  'Roof Conditions': ['Granule Loss – Aging', 'Shingle Curling – Wind Damage'],
  Address: ['Address Confirmed – 123 Main St', 'Front View – House Orientation Verified'],
};

// Return a random AI suggestion for a given section or a fallback text
const generateAISuggestion = (sectionPrefix) => {
  const suggestions = mockAISuggestions[sectionPrefix] || [
    'General Observation – No Issues Detected',
  ];
  return suggestions[Math.floor(Math.random() * suggestions.length)];
};

const inspectionSections = [
  'Address',
  'Front Elevation',
  'Right Elevation',
  'Back Elevation',
  'Left Elevation',
  'Roof Edge',
  'Front Slope',
  'Right Slope',
  'Back Slope',
  'Left Slope',
  'Roof Accessories',
  'Roof Conditions',
];


export default function ClearSkyPhotoIntakeScreen() {
  // Store photos keyed by section name
  const [photoData, setPhotoData] = useState({});

  const handlePhotoUpload = async (section) => {
    let result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsEditing: false,
      quality: 1,
    });

    if (!result.canceled) {
      const newPhoto = {
        uri: result.assets[0].uri,
        label: `${section.toLowerCase()} photo`, // Default label suggestion
      };

      setPhotoData((prevData) => {
        const updatedSection = prevData[section]
          ? [...prevData[section], newPhoto]
          : [newPhoto];
        return { ...prevData, [section]: updatedSection };
      });
    }
  };

  const handleLabelChange = (section, index, newLabel) => {
    setPhotoData((prevData) => {
      const updatedSection = [...prevData[section]];
      updatedSection[index].label = newLabel;
      return { ...prevData, [section]: updatedSection };
    });
  };

  return (
    <ScrollView contentContainerStyle={styles.container}>
      {inspectionSections.map((section) => (
        <View
          key={section}
          style={{ marginVertical: 10, padding: 10, borderBottomWidth: 1 }}
        >
          <Text style={{ fontWeight: 'bold', fontSize: 16 }}>{section}</Text>

          <Button
            title={`Upload Photo for ${section}`}
            onPress={() => handlePhotoUpload(section)}
          />

          {photoData[section]?.map((item, index) => (
            <View key={index} style={{ marginTop: 10 }}>
              <Image
                source={{ uri: item.uri }}
                style={{ width: 200, height: 200, borderRadius: 6 }}
                resizeMode="cover"
              />

              <TextInput
                value={item.label}
                onChangeText={(text) => handleLabelChange(section, index, text)}
                placeholder="Enter photo label"
                style={{
                  borderWidth: 1,
                  borderColor: '#ccc',
                  padding: 8,
                  marginTop: 5,
                  borderRadius: 4,
                }}
              />
            </View>
          ))}
        </View>
      ))}
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
});

