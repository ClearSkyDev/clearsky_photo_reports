import React, { createContext, useState, useContext } from 'react';

const AppContext = createContext();

export function AppProvider({ children }) {
  const [role, setRole] = useState(['Adjuster']);
  const [subscription, setSubscription] = useState({
    isPro: false,
    freeReportsRemaining: 3,
  });

  return (
    <AppContext.Provider value={{ role, setRole, subscription, setSubscription }}>
      {children}
    </AppContext.Provider>
  );
}

export function useAppContext() {
  return useContext(AppContext);
}
