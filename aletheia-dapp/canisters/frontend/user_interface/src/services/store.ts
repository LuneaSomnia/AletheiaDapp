// src/services/store.ts
import { configureStore, createSlice, PayloadAction } from '@reduxjs/toolkit';

// Types
export interface Notification {
  id: string;
  type: 'info' | 'success' | 'warning' | 'error';
  title: string;
  message: string;
  timestamp: string;
  read: boolean;
  action?: {
    label: string;
    url: string;
  };
}

export interface GamificationState {
  totalPoints: number;
  level: number;
  experience: number;
  experienceToNextLevel: number;
  completedModules: string[];
  completedExercises: string[];
  badges: Badge[];
  achievements: Achievement[];
  streak: number;
  lastActivity: string;
  leaderboardRank?: number;
}

export interface Badge {
  id: string;
  name: string;
  description: string;
  icon: string;
  unlockedAt: string;
  progress?: number;
  maxProgress?: number;
}

export interface Achievement {
  id: string;
  name: string;
  description: string;
  points: number;
  unlockedAt?: string;
  progress?: number;
  maxProgress?: number;
}

export interface Settings {
  notifications: {
    claimUpdates: boolean;
    learningRewards: boolean;
    weeklyDigest: boolean;
    newFeatures: boolean;
    emailNotifications: boolean;
    pushNotifications: boolean;
  };
  privacy: {
    profileVisibility: 'public' | 'private' | 'friends';
    showProgress: boolean;
    showBadges: boolean;
    allowDataCollection: boolean;
  };
  appearance: {
    theme: 'light' | 'dark' | 'auto';
    fontSize: 'small' | 'medium' | 'large';
    animations: boolean;
  };
  learning: {
    difficulty: 'beginner' | 'intermediate' | 'advanced';
    autoAdvance: boolean;
    showHints: boolean;
    timeLimit: number; // in minutes
  };
}

export interface AppState {
  userClaims: any[];
  learningProgress: number;
  learningModules: any[];
  notifications: Notification[];
  gamification: GamificationState;
  settings: Settings;
  ui: {
    sidebarOpen: boolean;
    currentPage: string;
    loading: boolean;
    error: string | null;
  };
}

// Initial state
const initialState: AppState = {
  userClaims: [],
  learningProgress: 0,
  learningModules: [],
  notifications: [],
  gamification: {
    totalPoints: 0,
    level: 1,
    experience: 0,
    experienceToNextLevel: 100,
    completedModules: [],
    completedExercises: [],
    badges: [],
    achievements: [],
    streak: 0,
    lastActivity: new Date().toISOString(),
  },
  settings: {
    notifications: {
      claimUpdates: true,
      learningRewards: true,
      weeklyDigest: false,
      newFeatures: true,
      emailNotifications: true,
      pushNotifications: false,
    },
    privacy: {
      profileVisibility: 'public',
      showProgress: true,
      showBadges: true,
      allowDataCollection: true,
    },
    appearance: {
      theme: 'dark',
      fontSize: 'medium',
      animations: true,
    },
    learning: {
      difficulty: 'beginner',
      autoAdvance: false,
      showHints: true,
      timeLimit: 5,
    },
  },
  ui: {
    sidebarOpen: false,
    currentPage: 'dashboard',
    loading: false,
    error: null,
  },
};

// Slices
const notificationsSlice = createSlice({
  name: 'notifications',
  initialState: initialState.notifications,
  reducers: {
    addNotification: (state, action: PayloadAction<Omit<Notification, 'id' | 'timestamp' | 'read'>>) => {
      const notification: Notification = {
        ...action.payload,
        id: Date.now().toString(),
        timestamp: new Date().toISOString(),
        read: false,
      };
      state.unshift(notification);
    },
    markAsRead: (state, action: PayloadAction<string>) => {
      const notification = state.find(n => n.id === action.payload);
      if (notification) {
        notification.read = true;
      }
    },
    markAllAsRead: (state) => {
      state.forEach(notification => notification.read = true);
    },
    removeNotification: (state, action: PayloadAction<string>) => {
      return state.filter(n => n.id !== action.payload);
    },
    clearAllNotifications: () => [],
  },
});

const gamificationSlice = createSlice({
  name: 'gamification',
  initialState: initialState.gamification,
  reducers: {
    updatePoints: (state, action: PayloadAction<number>) => {
      state.totalPoints += action.payload;
      state.experience += action.payload;
      
      // Calculate new level
      const newLevel = Math.floor(Math.sqrt(state.experience / 100)) + 1;
      if (newLevel > state.level) {
        state.level = newLevel;
      }
      
      // Calculate experience to next level
      const nextLevelExp = Math.pow(state.level, 2) * 100;
      state.experienceToNextLevel = nextLevelExp - state.experience;
    },
    completeModule: (state, action: PayloadAction<string>) => {
      if (!state.completedModules.includes(action.payload)) {
        state.completedModules.push(action.payload);
      }
    },
    completeExercise: (state, action: PayloadAction<string>) => {
      if (!state.completedExercises.includes(action.payload)) {
        state.completedExercises.push(action.payload);
      }
    },
    addBadge: (state, action: PayloadAction<Badge>) => {
      if (!state.badges.find(b => b.id === action.payload.id)) {
        state.badges.push(action.payload);
      }
    },
    addAchievement: (state, action: PayloadAction<Achievement>) => {
      if (!state.achievements.find(a => a.id === action.payload.id)) {
        state.achievements.push(action.payload);
      }
    },
    updateStreak: (state, action: PayloadAction<number>) => {
      state.streak = action.payload;
      state.lastActivity = new Date().toISOString();
    },
    updateLeaderboardRank: (state, action: PayloadAction<number>) => {
      state.leaderboardRank = action.payload;
    },
    resetGamification: () => initialState.gamification,
  },
});

const settingsSlice = createSlice({
  name: 'settings',
  initialState: initialState.settings,
  reducers: {
    updateNotificationSettings: (state, action: PayloadAction<Partial<Settings['notifications']>>) => {
      state.notifications = { ...state.notifications, ...action.payload };
    },
    updatePrivacySettings: (state, action: PayloadAction<Partial<Settings['privacy']>>) => {
      state.privacy = { ...state.privacy, ...action.payload };
    },
    updateAppearanceSettings: (state, action: PayloadAction<Partial<Settings['appearance']>>) => {
      state.appearance = { ...state.appearance, ...action.payload };
    },
    updateLearningSettings: (state, action: PayloadAction<Partial<Settings['learning']>>) => {
      state.learning = { ...state.learning, ...action.payload };
    },
    resetSettings: () => initialState.settings,
  },
});

const uiSlice = createSlice({
  name: 'ui',
  initialState: initialState.ui,
  reducers: {
    toggleSidebar: (state) => {
      state.sidebarOpen = !state.sidebarOpen;
    },
    setCurrentPage: (state, action: PayloadAction<string>) => {
      state.currentPage = action.payload;
    },
    setLoading: (state, action: PayloadAction<boolean>) => {
      state.loading = action.payload;
    },
    setError: (state, action: PayloadAction<string | null>) => {
      state.error = action.payload;
    },
  },
});

const appSlice = createSlice({
  name: 'app',
  initialState: {
    userClaims: initialState.userClaims,
    learningProgress: initialState.learningProgress,
    learningModules: initialState.learningModules,
  },
  reducers: {
    setUserClaims: (state, action: PayloadAction<any[]>) => {
      state.userClaims = action.payload;
    },
    addUserClaim: (state, action: PayloadAction<any>) => {
      state.userClaims.unshift(action.payload);
    },
    setLearningModules: (state, action: PayloadAction<any[]>) => {
      state.learningModules = action.payload;
    },
    updateLearningProgress: (state, action: PayloadAction<number>) => {
      state.learningProgress += action.payload;
    },
  },
});

// Store configuration
const store = configureStore({
  reducer: {
    app: appSlice.reducer,
    notifications: notificationsSlice.reducer,
    gamification: gamificationSlice.reducer,
    settings: settingsSlice.reducer,
    ui: uiSlice.reducer,
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware({
      serializableCheck: {
        ignoredActions: ['persist/PERSIST'],
      },
    }),
});

// Export actions
export const {
  addNotification,
  markAsRead,
  markAllAsRead,
  removeNotification,
  clearAllNotifications,
} = notificationsSlice.actions;

export const {
  updatePoints,
  completeModule,
  completeExercise,
  addBadge,
  addAchievement,
  updateStreak,
  updateLeaderboardRank,
  resetGamification,
} = gamificationSlice.actions;

export const {
  updateNotificationSettings,
  updatePrivacySettings,
  updateAppearanceSettings,
  updateLearningSettings,
  resetSettings,
} = settingsSlice.actions;

export const {
  toggleSidebar,
  setCurrentPage,
  setLoading,
  setError,
} = uiSlice.actions;

export const {
  setUserClaims,
  addUserClaim,
  setLearningModules,
  updateLearningProgress,
} = appSlice.actions;

// Export types
export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;

// Selectors
export const selectNotifications = (state: RootState) => state.notifications;
export const selectUnreadNotifications = (state: RootState) => 
  state.notifications.filter(n => !n.read);
export const selectGamification = (state: RootState) => state.gamification;
export const selectSettings = (state: RootState) => state.settings;
export const selectUI = (state: RootState) => state.ui;
export const selectUserClaims = (state: RootState) => state.app.userClaims;
export const selectLearningProgress = (state: RootState) => state.app.learningProgress;

export default store;