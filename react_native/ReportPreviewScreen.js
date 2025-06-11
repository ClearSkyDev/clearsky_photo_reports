import React, { useState } from 'react';
import { ScrollView, View, Text, Image, TextInput, Button } from 'react-native';
import * as Print from 'expo-print';

// Utility to generate HTML from uploaded photos and questionnaire
function generateReportHTML(photos, questionnaire, notes) {
  const photoSections = [
    'Address',
    'Front',
    'Right',
    'Back',
    'Left',
    'Roof Edge',
    'Slopes',
    'Accessories',
    'Rear Yard',
  ];

  const photosHtml = photoSections
    .map((section) => {
      const sectionPhotos = photos.filter((p) =>
        p.sectionPrefix.toLowerCase().includes(section.toLowerCase())
      );
      if (sectionPhotos.length === 0) return '';
      const imgs = sectionPhotos
        .map(
          (photo) => `
          <div style="margin-bottom:12px">
            <img src="${photo.imageUri}" style="width:100%;height:auto" />
            <div>Label: ${photo.userLabel}</div>
          </div>`
        )
        .join('');
      return `<h3>${section}</h3>${imgs}`;
    })
    .join('');

  const questionnaireHtml = Object.entries(questionnaire)
    .map(([section, data]) => {
      if (typeof data === 'object' && !Array.isArray(data)) {
        const inner = Object.entries(data)
          .map(([key, values]) => `<div>${key}: ${values.join(', ')}</div>`) 
          .join('');
        return `<h4>${section.toUpperCase()}</h4>${inner}`;
      }
      if (Array.isArray(data)) {
        return `<h4>${section.toUpperCase()}</h4><div>${data.join(', ')}</div>`;
      }
      return '';
    })
    .join('');

  return `
    <html>
      <body style="font-family: Arial, sans-serif; padding:16px">
        <h2>Inspection Report</h2>
        <div>Date: ${new Date().toLocaleDateString()}</div>
        ${photosHtml}
        <h3>Roof Questionnaire Summary</h3>
        ${questionnaireHtml}
        <h3>Inspector Summary</h3>
        <div>${notes}</div>
      </body>
    </html>
  `;
}

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
