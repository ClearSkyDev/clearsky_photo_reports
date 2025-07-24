import * as ImageManipulator from 'expo-image-manipulator';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import { storage, offlineMode } from './firebaseConfig';

// Resize then crop a photo to ensure a 1:1 aspect ratio
export async function compressAndSquarePhoto(uri) {
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

// Upload an image to Firebase Storage and return its download URL
export async function uploadImageToStorage(uri, projectId, filename) {
  if (offlineMode) {
    console.log('offline mode - skipping upload');
    return null;
  }
  try {
    const response = await fetch(uri);
    const blob = await response.blob();
    const storageRef = ref(storage, `inspections/${projectId}/${filename}`);
    await uploadBytes(storageRef, blob);
    return await getDownloadURL(storageRef);
  } catch (err) {
    console.error('Error uploading image:', err);
    return null;
  }
}

// Helper to upload a photo and append it to state
export async function handlePhotoUpload(
  photoUri,
  sectionPrefix,
  uploadedPhotos,
  setUploadedPhotos,
  projectId = 'demo',
  userLabel = sectionPrefix,
  annotations = []
) {
  const squareUri = await compressAndSquarePhoto(photoUri);
  const filename = `${Date.now()}.jpg`;
  const downloadUrl = await uploadImageToStorage(squareUri, projectId, filename);
  const newPhoto = {
    id: Date.now().toString(),
    imageUri: downloadUrl || squareUri,
    sectionPrefix,
    userLabel,
    annotations,
    aiSuggestedLabel: '',
    approved: false,
  };
  setUploadedPhotos([...uploadedPhotos, newPhoto]);
  return downloadUrl;
}
