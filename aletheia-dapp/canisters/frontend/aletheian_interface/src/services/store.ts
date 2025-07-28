// src/services/store.ts
import { configureStore, createSlice, PayloadAction } from '@reduxjs/toolkit';
import type { NotificationData } from './canisters';

interface AppState {
  assignments: [],
  notifications: NotificationData[],
  profile: null,
  finance: null,
  claimQueue: [],
  reputation: null,
  ui: {
    loading: boolean,
    error: string | null
  }
}

const initialState: AppState = {
  assignments: [],
  notifications: [],
  profile: null,
  finance: null,
  claimQueue: [],
  reputation: null,
  ui: {
    loading: false,
    error: null
  }
};

const notificationsSlice = createSlice({
  name: 'notifications',
  initialState: initialState.notifications,
  reducers: {
    setNotifications: (state, action: PayloadAction<NotificationData[]>) => {
      return action.payload;
    },
    addNotification: (state, action: PayloadAction<NotificationData>) => {
      state.unshift(action.payload);
    },
    markAsRead: (state, action: PayloadAction<number>) => {
      const notification = state.find(n => n.id === action.payload);
      if (notification) {
        notification.read = true;
      }
    },
    markAllAsRead: (state) => {
      state.forEach(notification => notification.read = true);
    },
    removeNotification: (state, action: PayloadAction<number>) => {
      return state.filter(n => n.id !== action.payload);
    }
  }
});

const appSlice = createSlice({
  name: 'app',
  initialState: {
    assignments: initialState.assignments,
    profile: initialState.profile,
    finance: initialState.finance,
    claimQueue: initialState.claimQueue,
    reputation: initialState.reputation,
    ui: initialState.ui
  },
  reducers: {
    setAssignments: (state, action) => {
      state.assignments = action.payload;
    },
    setProfile: (state, action) => {
      state.profile = action.payload;
    },
    setFinance: (state, action) => {
      state.finance = action.payload;
    },
    setClaimQueue: (state, action) => {
      state.claimQueue = action.payload;
    },
    setReputation: (state, action) => {
      state.reputation = action.payload;
    },
    setLoading: (state, action: PayloadAction<boolean>) => {
      state.ui.loading = action.payload;
    },
    setError: (state, action: PayloadAction<string | null>) => {
      state.ui.error = action.payload;
    }
  }
});

function legacyAppReducer(state = initialState, action: any) {
  switch (action.type) {
    case 'SET_ASSIGNMENTS':
      return { ...state, assignments: action.payload };
    case 'SET_PROFILE':
      return { ...state, profile: action.payload };
    case 'SET_FINANCE':
      return { ...state, finance: action.payload };
    case 'SET_CLAIM_QUEUE':
      return { ...state, claimQueue: action.payload };
    case 'SET_REPUTATION':
      return { ...state, reputation: action.payload };
    default:
      return state;
  }
}

const store = configureStore({
  reducer: {
    app: appSlice.reducer,
    notifications: notificationsSlice.reducer,
    legacy: legacyAppReducer
  }
});

export const {
  setNotifications,
  addNotification,
  markAsRead,
  markAllAsRead,
  removeNotification
} = notificationsSlice.actions;

export const {
  setAssignments,
  setProfile,
  setFinance,
  setClaimQueue,
  setReputation,
  setLoading,
  setError
} = appSlice.actions;

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;

export default store;