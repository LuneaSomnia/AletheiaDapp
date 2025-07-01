// src/services/store.ts
import { configureStore } from '@reduxjs/toolkit';

const initialState = {
  userClaims: [],
  learningProgress: 0,
  learningModules: [],
  notifications: []
};

function appReducer(state = initialState, action: any) {
  switch (action.type) {
    case 'SET_USER_CLAIMS':
      return { ...state, userClaims: action.payload };
    case 'SET_LEARNING_MODULES':
      return { ...state, learningModules: action.payload };
    case 'UPDATE_LEARNING_PROGRESS':
      return { ...state, learningProgress: state.learningProgress + action.payload };
    case 'ADD_NOTIFICATION':
      return { ...state, notifications: [...state.notifications, action.payload] };
    default:
      return state;
  }
}

const store = configureStore({
  reducer: appReducer
});

export default store;