// src/App.tsx
import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { Provider } from 'react-redux';
import store from './services/store';
import AletheianLogin from './pages/AletheianLogin';
import AletheianDashboard from './pages/AletheianDashboard';
import ClaimVerificationPage from './pages/ClaimVerificationPage';
import EscalationPage from './pages/EscalationPage';
import FinancePage from './pages/FinancePage';
import ProfilePage from './pages/ProfilePage';
import { AuthProvider } from './services/auth';
import { initializeAgent } from './services/canisters';
import './aletheian.css';

const App: React.FC = () => {
  // Initialize agent on app start
  React.useEffect(() => {
    initializeAgent().catch(console.error);
  }, []);

  return (
    <Provider store={store}>
      <AuthProvider>
        <Router>
          <Routes>
            <Route path="/" element={<AletheianLogin />} />
            <Route path="/dashboard" element={<AletheianDashboard />} />
            <Route path="/verify-claim/:claimId" element={<ClaimVerificationPage />} />
            <Route path="/escalation/:claimId" element={<EscalationPage />} />
            <Route path="/finance" element={<FinancePage />} />
            <Route path="/profile" element={<ProfilePage />} />
          </Routes>
        </Router>
      </AuthProvider>
    </Provider>
  );
};

export default App;