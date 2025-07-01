// src/routes.tsx
import React from 'react';
import { createBrowserRouter } from 'react-router-dom';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import SubmitClaimPage from './pages/SubmitClaimPage';
import ClaimResultPage from './pages/ClaimResultPage';
import LearningGymPage from './pages/LearningGymPage';
import ProfilePage from './pages/ProfilePage';
import App from './App';

const router = createBrowserRouter([
  {
    path: '/',
    element: <App />,
    children: [
      {
        path: '/',
        element: <LoginPage />
      },
      {
        path: '/dashboard',
        element: <DashboardPage />
      },
      {
        path: '/submit-claim',
        element: <SubmitClaimPage />
      },
      {
        path: '/claim-result/:claimId',
        element: <ClaimResultPage />
      },
      {
        path: '/learn',
        element: <LearningGymPage />
      },
      {
        path: '/profile',
        element: <ProfilePage />
      }
    ]
  }
]);

export default router;