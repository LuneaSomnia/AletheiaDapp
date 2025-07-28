// src/services/auth.tsx
import { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { Actor, HttpAgent } from '@dfinity/agent';
import { AuthClient } from '@dfinity/auth-client';
import { Principal } from '@dfinity/principal';
import { getAletheianProfileActor, getCurrentPrincipal, initializeAgent } from './canisters';
import type { AletheianProfile } from './canisters';

interface User extends AletheianProfile {
  principal: string;
}

interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  isInitializing: boolean;
  authenticate: () => Promise<void>;
  logout: () => Promise<void>;
  refreshProfile: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

// Internet Identity configuration
const INTERNET_IDENTITY_CONFIG = {
  whitelist: [process.env.REACT_APP_CANISTER_ID || ''],
  host: process.env.DFX_NETWORK === 'ic' ? 'https://ic0.app' : 'http://localhost:8000',
  identityProvider: process.env.DFX_NETWORK === 'ic' 
    ? 'https://identity.ic0.app'
    : `http://localhost:8000?canisterId=${process.env.INTERNET_IDENTITY_CANISTER_ID}`,
};

export const AuthProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isInitializing, setIsInitializing] = useState(true);
  const [authClient, setAuthClient] = useState<AuthClient | null>(null);

  // Load user profile from canister
  const loadUserProfile = async (principal: Principal): Promise<User | null> => {
    try {
      const profileActor = await getAletheianProfileActor();
      const profile = await profileActor.getProfile(principal);
      
      if (profile) {
        return {
          ...profile,
          principal: principal.toString(),
          xp: Number(profile.xp),
          warnings: Number(profile.warnings),
          accuracy: Number(profile.accuracy),
          claimsVerified: Number(profile.claimsVerified),
          createdAt: Number(profile.createdAt),
          lastActive: Number(profile.lastActive)
        };
      }
      
      return null;
    } catch (error) {
      console.error('Failed to load user profile:', error);
      // Return mock profile for development
      return {
        id: principal,
        principal: principal.toString(),
        rank: 'Senior',
        xp: 1250,
        expertiseBadges: ['Health & Medicine', 'Politics'],
        location: 'Global',
        status: 'Active',
        warnings: 0,
        accuracy: 95.5,
        claimsVerified: 42,
        completedTraining: ['critical-thinking-101', 'bias-identification'],
        createdAt: Date.now() - 90 * 24 * 60 * 60 * 1000, // 90 days ago
        lastActive: Date.now()
      };
    }
  };

  // Initialize authentication
  useEffect(() => {
    const initAuth = async () => {
      try {
        setIsInitializing(true);
        
        // Create auth client
        const client = await AuthClient.create({
          idleOptions: {
            disableDefaultIdleCallback: true,
            disableIdle: true,
          },
        });
        setAuthClient(client);

        // Check if user is already authenticated
        if (await client.isAuthenticated()) {
          const identity = client.getIdentity();
          const principal = identity.getPrincipal();
          
          // Initialize agent with identity
          await initializeAgent();
          
          setIsAuthenticated(true);

          // Load user profile
          const userData = await loadUserProfile(principal);
          setUser(userData);

          // Send heartbeat to update last active time
          if (userData) {
            try {
              const profileActor = await getAletheianProfileActor();
              await profileActor.heartbeat();
            } catch (error) {
              console.warn('Failed to send heartbeat:', error);
            }
          }
        }
      } catch (error) {
        console.error('Failed to initialize authentication:', error);
      } finally {
        setIsInitializing(false);
      }
    };

    initAuth();
  }, []);

  const authenticate = async () => {
    if (!authClient) {
      throw new Error('Auth client not initialized');
    }
    
    try {
      await new Promise<void>((resolve, reject) => {
        authClient.login({
          identityProvider: INTERNET_IDENTITY_CONFIG.identityProvider,
          onSuccess: () => resolve(),
          onError: (error) => reject(new Error(`Authentication failed: ${error}`)),
          windowOpenerFeatures: 'toolbar=0,location=0,status=0,menubar=0,scrollbars=1,resizable=1,width=500,height=600',
        });
      });

      const identity = authClient.getIdentity();
      const principal = identity.getPrincipal();
      
      // Initialize agent with new identity
      await initializeAgent();
      
      setIsAuthenticated(true);

      // Load user profile
      const userData = await loadUserProfile(principal);
      setUser(userData);

      // Send heartbeat
      if (userData) {
        try {
          const profileActor = await getAletheianProfileActor();
          await profileActor.heartbeat();
        } catch (error) {
          console.warn('Failed to send heartbeat:', error);
        }
      }
    } catch (error) {
      console.error('Authentication error:', error);
      throw error;
    }
  };

  const logout = async () => {
    try {
      if (authClient) {
        await authClient.logout();
      }
      setIsAuthenticated(false);
      setUser(null);
    } catch (error) {
      console.error('Logout error:', error);
      throw error;
    }
  };

  const refreshProfile = async () => {
    if (!isAuthenticated) {
      throw new Error('User not authenticated');
    }

    try {
      const principal = await getCurrentPrincipal();
      if (principal) {
        const userData = await loadUserProfile(principal);
        setUser(userData);
      }
    } catch (error) {
      console.error('Failed to refresh profile:', error);
      throw error;
    }
  };

  return (
    <AuthContext.Provider value={{ 
      user, 
      isAuthenticated, 
      isInitializing,
      authenticate, 
      logout,
      refreshProfile
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