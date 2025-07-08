// src/services/auth.ts
import { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { Actor, HttpAgent } from '@dfinity/agent';
import { AuthClient } from '@dfinity/auth-client';

interface User {
  principal: string;
  username?: string;
  learningPoints: number;
  submittedClaims: string[];
}

interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  authenticate: () => Promise<void>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [authClient, setAuthClient] = useState<AuthClient | null>(null);

  useEffect(() => {
    const initAuth = async () => {
      const client = await AuthClient.create();
      setAuthClient(client);
      
      if (await client.isAuthenticated()) {
        setIsAuthenticated(true);
        const identity = client.getIdentity();
        const principal = identity.getPrincipal().toString();
        // Fetch user data from canister in production
        setUser({
          principal,
          learningPoints: 125,
          submittedClaims: ['claim-001', 'claim-002'],
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
    });
  };

  const logout = async () => {
    if (authClient) {
      await authClient.logout();
      setIsAuthenticated(false);
      setUser(null);
    }
  };

  return (
    <AuthContext.Provider value={{ user, isAuthenticated, authenticate, logout }}>
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