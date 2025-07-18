// src/services/auth.tsx
import { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { Actor, HttpAgent } from '@dfinity/agent';
import { AuthClient } from '@dfinity/auth-client';
import { Identity } from '@dfinity/agent';

interface User {
  principal: string;
  username?: string;
  learningPoints: number;
  submittedClaims: string[];
  hasCompletedTutorial?: boolean;
  profile?: {
    displayName?: string;
    avatar?: string;
    joinDate: string;
    reputation: number;
    badges: string[];
  };
}

interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  isInitializing: boolean;
  authenticate: () => Promise<void>;
  logout: () => Promise<void>;
  completeTutorial: () => void;
  updateUserProfile: (updates: Partial<User['profile']>) => Promise<void>;
  refreshUserData: () => Promise<void>;
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
  const [agent, setAgent] = useState<HttpAgent | null>(null);

  // Check if tutorial is completed
  const checkTutorialCompletion = () => {
    return localStorage.getItem('aletheia_tutorial_completed') === 'true';
  };

  // Load user data from localStorage
  const loadUserFromStorage = (principal: string): User | null => {
    try {
      const stored = localStorage.getItem(`aletheia_user_${principal}`);
      return stored ? JSON.parse(stored) : null;
    } catch (error) {
      console.error('Failed to load user from storage:', error);
      return null;
    }
  };

  // Save user data to localStorage
  const saveUserToStorage = (user: User) => {
    try {
      localStorage.setItem(`aletheia_user_${user.principal}`, JSON.stringify(user));
    } catch (error) {
      console.error('Failed to save user to storage:', error);
    }
  };

  // Create default user profile
  const createDefaultUser = (principal: string): User => {
    const defaultUser: User = {
      principal,
      learningPoints: 0,
      submittedClaims: [],
      hasCompletedTutorial: checkTutorialCompletion(),
      profile: {
        displayName: `User_${principal.slice(0, 8)}`,
        joinDate: new Date().toISOString(),
        reputation: 0,
        badges: ['Newcomer'],
      },
    };
    saveUserToStorage(defaultUser);
    return defaultUser;
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
          const principal = identity.getPrincipal().toString();
          
          // Create HTTP agent
          const httpAgent = new HttpAgent({
            identity,
            host: INTERNET_IDENTITY_CONFIG.host,
          });
          
          if (process.env.DFX_NETWORK !== 'ic') {
            await httpAgent.fetchRootKey();
          }
          
          setAgent(httpAgent);
          setIsAuthenticated(true);

          // Load or create user
          let userData = loadUserFromStorage(principal);
          if (!userData) {
            userData = createDefaultUser(principal);
          }
          
          setUser(userData);
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
      const principal = identity.getPrincipal().toString();
      
      // Create HTTP agent
      const httpAgent = new HttpAgent({
        identity,
        host: INTERNET_IDENTITY_CONFIG.host,
      });
      
      if (process.env.DFX_NETWORK !== 'ic') {
        await httpAgent.fetchRootKey();
      }
      
      setAgent(httpAgent);
      setIsAuthenticated(true);

      // Load or create user
      let userData = loadUserFromStorage(principal);
      if (!userData) {
        userData = createDefaultUser(principal);
      }
      
      setUser(userData);
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
      setAgent(null);
      
      // Clear user data from localStorage
      if (user?.principal) {
        localStorage.removeItem(`aletheia_user_${user.principal}`);
      }
    } catch (error) {
      console.error('Logout error:', error);
      throw error;
    }
  };

  // Mark tutorial as complete in user state
  const completeTutorial = () => {
    if (user) {
      const updatedUser = {
        ...user,
        hasCompletedTutorial: true,
        learningPoints: user.learningPoints + 50, // Bonus points for completing tutorial
      };
      setUser(updatedUser);
      saveUserToStorage(updatedUser);
    }
    localStorage.setItem('aletheia_tutorial_completed', 'true');
  };

  // Update user profile
  const updateUserProfile = async (updates: Partial<User['profile']>) => {
    if (!user) {
      throw new Error('User not authenticated');
    }

    const updatedUser = {
      ...user,
      profile: {
        displayName: user.profile?.displayName || `User_${user.principal.slice(0, 8)}`,
        avatar: user.profile?.avatar,
        joinDate: user.profile?.joinDate || new Date().toISOString(),
        reputation: user.profile?.reputation || 0,
        badges: user.profile?.badges || ['Newcomer'],
        ...updates,
      },
    };

    setUser(updatedUser);
    saveUserToStorage(updatedUser);
  };

  // Refresh user data from backend
  const refreshUserData = async () => {
    if (!user || !agent) {
      throw new Error('User not authenticated or agent not available');
    }

    try {
      // Here you would typically fetch updated user data from your backend canisters
      // For now, we'll just reload from storage
      const updatedUser = loadUserFromStorage(user.principal);
      if (updatedUser) {
        setUser(updatedUser);
      }
    } catch (error) {
      console.error('Failed to refresh user data:', error);
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
      completeTutorial,
      updateUserProfile,
      refreshUserData,
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

// Export agent for use in other services
export const getAgent = (): HttpAgent | null => {
  // This would need to be implemented with a way to access the agent from the auth context
  // For now, return null and handle in individual services
  return null;
};