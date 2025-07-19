// src/services/store.ts
import { configureStore } from '@reduxjs/toolkit';

const initialState = {
  assignments: [],
  notifications: [],
  profile: null,
  finance: null,
  claimQueue: [], // Added claim queue state
  reputation: null // Added reputation state
};

function appReducer(state = initialState, action: any) {
  switch (action.type) {
    case 'SET_ASSIGNMENTS':
      return { ...state, assignments: action.payload };
    case 'SET_NOTIFICATIONS':
      return { ...state, notifications: action.payload };
    case 'SET_PROFILE':
      return { ...state, profile: action.payload };
    case 'SET_FINANCE':
      return { ...state, finance: action.payload };
    case 'SET_CLAIM_QUEUE': // Action for claim queue
      return { ...state, claimQueue: action.payload };
    case 'SET_REPUTATION': // Action for reputation
      return { ...state, reputation: action.payload };
    default:
      return state;
  }
}

const store = configureStore({
  reducer: appReducer
});

export default store;