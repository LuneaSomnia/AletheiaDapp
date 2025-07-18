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

// Import new page components (these will need to be created)
import OnboardingPage from './pages/OnboardingPage';
import TutorialPage from './pages/TutorialPage';
import SettingsPage from './pages/SettingsPage';
import NotificationCenterPage from './pages/NotificationCenterPage';
import ClaimHistoryPage from './pages/ClaimHistoryPage';
import LeaderboardPage from './pages/LeaderboardPage';
import HelpSupportPage from './pages/HelpSupportPage';
import PrivacyPolicyPage from './pages/PrivacyPolicyPage';
import TermsOfServicePage from './pages/TermsOfServicePage';
import NotFoundPage from './pages/NotFoundPage';

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
        path: '/onboarding',
        element: <OnboardingPage />
      },
      {
        path: '/tutorial',
        element: <TutorialPage />
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
        path: '/claim-history',
        element: <ClaimHistoryPage />
      },
      {
        path: '/learn',
        element: <LearningGymPage />
      },
      {
        path: '/profile',
        element: <ProfilePage />
      },
      {
        path: '/settings',
        element: <SettingsPage />
      },
      {
        path: '/notifications',
        element: <NotificationCenterPage />
      },
      {
        path: '/leaderboard',
        element: <LeaderboardPage />
      },
      {
        path: '/help',
        element: <HelpSupportPage />
      },
      {
        path: '/privacy',
        element: <PrivacyPolicyPage />
      },
      {
        path: '/terms',
        element: <TermsOfServicePage />
      },
      {
        path: '*',
        element: <NotFoundPage />
      }
    ]
  }
]);

export default router;