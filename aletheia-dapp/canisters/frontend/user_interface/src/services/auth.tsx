// src/services/auth.ts
import { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { Actor, HttpAgent } from '@dfinity/agent';
import { AuthClient } from '@dfinity/auth-client';

interface User {
  principal: string;
  username?: string;
  learningPoints: number;
  submittedClaims: string[];
  hasCompletedTutorial?: boolean; // Added tutorial completion flag
}

interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  authenticate: () => Promise<void>;
  logout: () => Promise<void>;
  completeTutorial: () => void; // Added method to mark tutorial complete
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [authClient, setAuthClient] = useState<AuthClient | null>(null);

  // Check if tutorial is completed
  const checkTutorialCompletion = () => {
    return localStorage.getItem('aletheia_tutorial_completed') === 'true';
  };

  useEffect(() => {
    const initAuth = async () => {
      const client = await AuthClient.create();
      setAuthClient(client);
      
      if (await client.isAuthenticated()) {
        setIsAuthenticated(true);
        const identity = client.getIdentity();
        const principal = identity.getPrincipal().toString();
        
        setUser({
          principal,
          learningPoints: 125,
          submittedClaims: ['claim-001', 'claim-002'],
          hasCompletedTutorial: checkTutorialCompletion()
        });
      }
    };

    initAuth();
  }, []);

  const authenticate = async () => {
    if (!authClient) return;
    
    await new Promise<void>((resolve, reject) => {
      authClient.login({
        identityProvider: process.env.DFX_NETWORK === 'ic' 
          ? 'https://identity.ic0.app'
          : `http://localhost:8000?canisterId=${process.env.INTERNET_IDENTITY_CANISTER_ID}`,
        onSuccess: () => resolve(),
        onError: reject,
      });
    });

    setIsAuthenticated(true);
    const identity = authClient.getIdentity();
    const principal = identity.getPrincipal().toString();
    
    setUser({
      principal,
      learningPoints: 125,
      submittedClaims: ['claim-001', 'claim-002'],
      hasCompletedTutorial: checkTutorialCompletion()
    });
  };

  const logout = async () => {
    if (authClient) {
      await authClient.logout();
      setIsAuthenticated(false);
      setUser(null);
    }
  };

  // Mark tutorial as complete in user state
  const completeTutorial = () => {
    if (user) {
      setUser({
        ...user,
        hasCompletedTutorial: true
      });
    }
    localStorage.setItem('aletheia_tutorial_completed', 'true');
  };

  return (
    <AuthContext.Provider value={{ 
      user, 
      isAuthenticated, 
      authenticate, 
      logout,
      completeTutorial
    }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};