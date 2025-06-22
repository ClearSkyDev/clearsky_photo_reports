import React, { createContext, useState, useContext, useEffect } from 'react';
import { Text } from 'react-native';
import { signInAnonymously, onAuthStateChanged } from 'firebase/auth';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { auth, db } from './firebaseConfig';

const AppContext = createContext();

export function AppProvider({ children }) {
  const [role, setRole] = useState([]);
  const [subscription, setSubscription] = useState({
    isPro: false,
    freeReportsRemaining: 3,
  });
  const [userId, setUserId] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, async (user) => {
      if (user) {
        setUserId(user.uid);
        const userRef = doc(db, 'users', user.uid);
        const snap = await getDoc(userRef);
        if (snap.exists()) {
          const data = snap.data();
          setRole(data.role || []);
          setSubscription(
            data.subscription || { isPro: false, freeReportsRemaining: 3 }
          );
        } else {
          await setDoc(userRef, {
            role: [],
            subscription: { isPro: false, freeReportsRemaining: 3 },
          });
        }
        setLoading(false);
      } else {
        await signInAnonymously(auth);
      }
    });

    return () => unsub();
  }, []);

  if (loading) return <Text style={{ margin: 20 }}>Loading...</Text>;

  return (
    <AppContext.Provider
      value={{ userId, role, setRole, subscription, setSubscription }}
    >
      {children}
    </AppContext.Provider>
  );
}

export function useAppContext() {
  return useContext(AppContext);
}
