// src/services/store.ts
import { configureStore } from '@reduxjs/toolkit';

const initialState = {
  assignments: [],
  notifications: [],
  profile: null,
  finance: null
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
    default:
      return state;
  }
}

const store = configureStore({
  reducer: appReducer
});

export default store;