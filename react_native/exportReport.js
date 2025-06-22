import * as Print from 'expo-print';
import * as Sharing from 'expo-sharing';
import * as FileSystem from 'expo-file-system';
import * as WebBrowser from 'expo-web-browser';
import { httpsCallable } from 'firebase/functions';
import { functions } from './firebaseConfig';

// Export report HTML content as a PDF file and prompt the user to share it
export async function exportReportAsPDF(htmlContent, fileName = 'ClearSky_Report.pdf') {
  try {
    const { uri } = await Print.printToFileAsync({ html: htmlContent, base64: false });
    const newUri = FileSystem.documentDirectory + fileName;
    await FileSystem.moveAsync({ from: uri, to: newUri });

    if (await Sharing.isAvailableAsync()) {
      await Sharing.shareAsync(newUri);
    } else {
      alert('Sharing is not available on this device.');
    }
  } catch (error) {
    console.error('Error exporting PDF:', error);
  }
}

// Generate PDF using the cloud function and open the returned URL
export async function exportReportViaCloud(htmlContent, fileName = 'ClearSky_Report.pdf') {
  try {
    const callGenerate = httpsCallable(functions, 'generatePdfReport');
    const res = await callGenerate({ html: htmlContent, fileName });
    const url = res.data.url;
    if (url) {
      await WebBrowser.openBrowserAsync(url);
    }
    return url;
  } catch (error) {
    console.error('Error generating cloud PDF:', error);
  }
}

// Save the raw HTML to a file and prompt the user to share it
export async function exportReportAsHTML(htmlContent, fileName = 'ClearSky_Report.html') {
  try {
    const fileUri = FileSystem.documentDirectory + fileName;
    await FileSystem.writeAsStringAsync(fileUri, htmlContent, {
      encoding: FileSystem.EncodingType.UTF8,
    });

    if (await Sharing.isAvailableAsync()) {
      await Sharing.shareAsync(fileUri);
    } else {
      alert('Sharing is not available on this device.');
    }
  } catch (error) {
    console.error('Error saving HTML file:', error);
  }
}
