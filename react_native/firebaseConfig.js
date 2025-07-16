import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';
import { getFunctions } from 'firebase/functions';

const firebaseConfig = {
  apiKey: process.env.EXPO_PUBLIC_FIREBASE_API_KEY || '',
  authDomain: process.env.EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN || '',
  projectId: process.env.EXPO_PUBLIC_FIREBASE_PROJECT_ID || '',
  storageBucket: process.env.EXPO_PUBLIC_FIREBASE_STORAGE_BUCKET || '',
  messagingSenderId: process.env.EXPO_PUBLIC_FIREBASE_MESSAGING_SENDER_ID || '',
  appId: process.env.EXPO_PUBLIC_FIREBASE_APP_ID || '',
};

if (!process.env.EXPO_PUBLIC_FIREBASE_API_KEY) {
  console.warn('Missing Firebase env var: EXPO_PUBLIC_FIREBASE_API_KEY');
}
if (!process.env.EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN) {
  console.warn('Missing Firebase env var: EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN');
}
if (!process.env.EXPO_PUBLIC_FIREBASE_PROJECT_ID) {
  console.warn('Missing Firebase env var: EXPO_PUBLIC_FIREBASE_PROJECT_ID');
}
if (!process.env.EXPO_PUBLIC_FIREBASE_STORAGE_BUCKET) {
  console.warn('Missing Firebase env var: EXPO_PUBLIC_FIREBASE_STORAGE_BUCKET');
}
if (!process.env.EXPO_PUBLIC_FIREBASE_MESSAGING_SENDER_ID) {
  console.warn('Missing Firebase env var: EXPO_PUBLIC_FIREBASE_MESSAGING_SENDER_ID');
}
if (!process.env.EXPO_PUBLIC_FIREBASE_APP_ID) {
  console.warn('Missing Firebase env var: EXPO_PUBLIC_FIREBASE_APP_ID');
}

// Initialize Firebase
const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);
export const functions = getFunctions(app);
