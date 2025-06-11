import React, { useState } from 'react';
import { ScrollView, View, Text, Image, TextInput, Button } from 'react-native';
import * as Print from 'expo-print';
import generateReportHTML from './generateReportHTML';

export default function ReportPreviewScreen({ uploadedPhotos, roofQuestionnaire }) {
  const [summaryText, setSummaryText] = useState('');

  const handleExportPDF = async () => {
    const html = generateReportHTML(uploadedPhotos, roofQuestionnaire, summaryText);
    const { uri } = await Print.printToFileAsync({ html });
    console.log('PDF saved to', uri);
  };

  const handleExportHTML = async () => {
    const html = generateReportHTML(uploadedPhotos, roofQuestionnaire, summaryText);
    const { uri } = await Print.printToFileAsync({ html, base64: false });
    console.log('HTML saved to', uri);
  };

  return (
    <ScrollView style={{ padding: 16 }}>
      <Text style={{ fontSize: 20, fontWeight: 'bold' }}>Inspection Report</Text>
      <Text>Date: {new Date().toLocaleDateString()}</Text>
      <View style={{ marginTop: 16 }}>
        {['Address','Front','Right','Back','Left','Roof Edge','Slopes','Accessories','Rear Yard'].map((section) => (
          <View key={section} style={{ marginBottom: 8 }}>
            <Text style={{ fontSize: 16, marginVertical: 8 }}>{section}</Text>
            {uploadedPhotos
              .filter((p) => p.sectionPrefix.toLowerCase().includes(section.toLowerCase()))
              .map((photo) => (
                <View key={photo.id} style={{ marginBottom: 12 }}>
                  <Image source={{ uri: photo.imageUri }} style={{ width: '100%', height: 200 }} resizeMode="cover" />
                  <Text>Label: {photo.userLabel}</Text>
                </View>
              ))}
          </View>
        ))}
      </View>

      <Text style={{ fontSize: 16, marginTop: 16 }}>Roof Questionnaire Summary:</Text>
      {Object.entries(roofQuestionnaire).map(([section, data]) => (
        <View key={section} style={{ marginVertical: 8 }}>
          <Text style={{ fontWeight: 'bold' }}>{section.toUpperCase()}</Text>
          {typeof data === 'object' && !Array.isArray(data)
            ? Object.entries(data).map(([key, values]) => (
                <Text key={key}>{key}: {values.join(', ')}</Text>
              ))
            : Array.isArray(data)
            ? <Text>{data.join(', ')}</Text>
            : null}
        </View>
      ))}

      <Text style={{ fontWeight: 'bold', marginTop: 16 }}>Inspector Summary:</Text>
      <TextInput
        multiline
        numberOfLines={6}
        value={summaryText}
        onChangeText={setSummaryText}
        placeholder="Write any final comments, concerns, or recommendations here..."
        style={{
          borderColor: 'gray',
          borderWidth: 1,
          padding: 8,
          marginBottom: 16,
        }}
      />

      <Button title="Export as PDF" onPress={handleExportPDF} />
      <Button title="Export as HTML" onPress={handleExportHTML} />
    </ScrollView>
  );
}
