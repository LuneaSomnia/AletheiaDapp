// src/App.tsx
import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { Provider } from 'react-redux';
import store from './services/store';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import SubmitClaimPage from './pages/SubmitClaimPage';
import ClaimResultPage from './pages/ClaimResultPage';
import LearningGymPage from './pages/LearningGymPage';
import ProfilePage from './pages/ProfilePage';
import { AuthProvider } from './services/auth';
import './user.css';

const App: React.FC = () => {
  return (
    <Provider store={store}>
      <AuthProvider>
        <Router>
          <Routes>
            <Route path="/" element={<LoginPage />} />
            <Route path="/dashboard" element={<DashboardPage />} />
            <Route path="/submit-claim" element={<SubmitClaimPage />} />
            <Route path="/claim-result/:claimId" element={<ClaimResultPage />} />
            <Route path="/learning-gym" element={<LearningGymPage />} />
            <Route path="/profile" element={<ProfilePage />} />
          </Routes>
        </Router>
      </AuthProvider>
    </Provider>
  );
};

export default App;