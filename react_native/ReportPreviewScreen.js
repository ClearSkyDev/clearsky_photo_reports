import React, { useState } from 'react';
import { ScrollView, View, Text, Image, TextInput, Button } from 'react-native';
import Signature from 'react-native-signature-canvas';
import generateReportHTML from './generateReportHTML';
import { exportReportAsPDF, exportReportAsHTML } from './exportReport';
import AnnotatedImage from './AnnotatedImage';

// Inspector roles determine the tone of the auto generated summary
export const InspectorRole = Object.freeze({
  adjuster: 'adjuster',
  contractor: 'contractor',
  ladderAssist: 'ladderAssist',
  hybrid: 'hybrid',
});

// Temporary selection until integrated with settings storage
let selectedRole = InspectorRole.adjuster;

function generateAISummary(uploadedPhotos, role) {
  const base = 'Inspection Summary:\n\n';
  switch (role) {
    case InspectorRole.ladderAssist:
      return (
        base +
        'This report is for documentation only. No analysis, opinions, or recommendations are included. It provides photographic evidence of the current property condition as observed.'
      );
    case InspectorRole.adjuster:
      return (
        base +
        'Based on visible damage, this roof shows potential weather-related impacts. Observations include granule loss, edge wear, and possible hail bruising. Further review of soft metals is advised. Coverage determination may depend on carrier guidelines and date of loss relevance.'
      );
    case InspectorRole.contractor:
      return (
        base +
        'Field inspection indicates functional and cosmetic compromise. Roof slopes show clear signs of damage, including displaced shingles and possible underlayment exposure. Contractor recommends repair or full replacement pending approval from the carrier or homeowner.'
      );
    case InspectorRole.hybrid:
    default:
      return (
        base +
        'This report blends documentation and practical insight. While not offering formal coverage decisions, damage patterns suggest eligibility for repair or replacement. Observed issues include edge erosion, seal tab fractures, and missing accessories.'
      );
  }
}

export default function ReportPreviewScreen({ uploadedPhotos, roofQuestionnaire }) {
  const [summaryText, setSummaryText] = useState('');
  const [clientName, setClientName] = useState('');
  const [clientAddress, setClientAddress] = useState('');
  const [insuranceCarrier, setInsuranceCarrier] = useState('');
  const [claimNumber, setClaimNumber] = useState('');
  const [perilType, setPerilType] = useState('');
  const [inspectorName, setInspectorName] = useState('');
  const [reportId, setReportId] = useState('');
  const [weatherNotes, setWeatherNotes] = useState('');
  const [preparedLabel, setPreparedLabel] = useState('');
  // Holds the inspector signature as a base64 encoded PNG
  const [signatureData, setSignatureData] = useState(null);
  const [includeAnnotations, setIncludeAnnotations] = useState(true);

  // Save the drawn signature when the user taps "Save" on the canvas
  const handleSignature = (signature) => {
    setSignatureData(signature);
  };

  const handleEmpty = () => {
    alert('Please sign before submitting.');
  };

  const inputStyle = {
    borderColor: 'gray',
    borderWidth: 1,
    padding: 8,
    marginVertical: 6,
    borderRadius: 6,
  };

  const handleExportPDF = async () => {
    const roleSummary = generateAISummary(uploadedPhotos, selectedRole);
    const html = generateReportHTML(
      uploadedPhotos,
      roofQuestionnaire,
      roleSummary,
      clientName,
      clientAddress,
      insuranceCarrier,
      claimNumber,
      perilType,
      inspectorName,
      reportId,
      weatherNotes,
      signatureData,
      preparedLabel,
      includeAnnotations
    );
    await exportReportAsPDF(html);
  };

  const handleExportHTML = async () => {
    const roleSummary = generateAISummary(uploadedPhotos, selectedRole);
    const html = generateReportHTML(
      uploadedPhotos,
      roofQuestionnaire,
      roleSummary,
      clientName,
      clientAddress,
      insuranceCarrier,
      claimNumber,
      perilType,
      inspectorName,
      reportId,
      weatherNotes,
      signatureData,
      preparedLabel,
      includeAnnotations
    );
    await exportReportAsHTML(html);
  };

  return (
    <ScrollView style={{ padding: 16 }}>
      <Text style={{ fontSize: 20, fontWeight: 'bold' }}>Inspection Report</Text>
      <Text>Date: {new Date().toLocaleDateString()}</Text>
      <View style={{ marginBottom: 20 }}>
        <Text style={{ fontWeight: 'bold' }}>Client Information</Text>
        <TextInput
          placeholder="Client Name"
          value={clientName}
          onChangeText={setClientName}
          style={inputStyle}
        />
        <TextInput
          placeholder="Address"
          value={clientAddress}
          onChangeText={setClientAddress}
          style={inputStyle}
        />
        <TextInput
          placeholder="Insurance Carrier"
          value={insuranceCarrier}
          onChangeText={setInsuranceCarrier}
          style={inputStyle}
        />
        <TextInput
          placeholder="Claim Number"
          value={claimNumber}
          onChangeText={setClaimNumber}
          style={inputStyle}
        />
        <TextInput
          placeholder="Peril Type (e.g. Hail, Wind, Fire)"
          value={perilType}
          onChangeText={setPerilType}
          style={inputStyle}
        />
        <TextInput
          placeholder="Inspector Name"
          value={inspectorName}
          onChangeText={setInspectorName}
          style={inputStyle}
        />
        <TextInput
          placeholder="Report ID"
          value={reportId}
          onChangeText={setReportId}
          style={inputStyle}
        />
        <TextInput
          placeholder="Weather Notes"
          value={weatherNotes}
          onChangeText={setWeatherNotes}
          style={inputStyle}
        />
        <TextInput
          placeholder="Prepared Label (optional)"
          value={preparedLabel}
          onChangeText={setPreparedLabel}
          style={inputStyle}
        />
      </View>
      <View style={{ marginTop: 16 }}>
        {[
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
        ].map((section) => (
          <View key={section} style={{ marginBottom: 8 }}>
            <Text style={{ fontSize: 16, marginVertical: 8 }}>{section}</Text>
            {uploadedPhotos
              .filter((p) => p.sectionPrefix === section)
              .map((photo) => (
                <View key={photo.id} style={{ marginBottom: 12 }}>
                  {includeAnnotations ? (
                    <AnnotatedImage
                      photo={photo}
                      style={{ width: '100%', aspectRatio: 1, borderRadius: 6 }}
                    />
                  ) : (
                    <Image
                      source={{ uri: photo.imageUri }}
                      style={{ width: '100%', aspectRatio: 1, borderRadius: 6 }}
                      resizeMode="cover"
                    />
                  )}
                  <Text>{photo.userLabel}</Text>
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

      <View style={{ height: 300, marginVertical: 20 }}>
        <Text style={{ fontWeight: 'bold' }}>Inspector Signature:</Text>
        <Signature
          onOK={handleSignature}
          onEmpty={handleEmpty}
          descriptionText="Sign below"
          clearText="Clear"
          confirmText="Save"
          webStyle={`.m-signature-pad--footer { display: none; }`}
        />
      </View>

      <Button
        title={includeAnnotations ? 'Hide Markup' : 'Show Markup'}
        onPress={() => setIncludeAnnotations(!includeAnnotations)}
      />

      <Button title="Export as PDF" onPress={handleExportPDF} />
      <Button title="Export as HTML" onPress={handleExportHTML} />
    </ScrollView>
  );
}
