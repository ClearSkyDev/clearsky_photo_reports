import * as ImageManipulator from 'expo-image-manipulator';

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

// Helper to upload a photo and append it to state
export async function handlePhotoUpload(photoUri, sectionPrefix, uploadedPhotos, setUploadedPhotos) {
  const squareUri = await compressAndSquarePhoto(photoUri);
  const newPhoto = {
    id: Date.now().toString(),
    imageUri: squareUri,
    sectionPrefix,
    userLabel: sectionPrefix,
    aiSuggestedLabel: '',
    approved: false,
  };
  setUploadedPhotos([...uploadedPhotos, newPhoto]);
}
