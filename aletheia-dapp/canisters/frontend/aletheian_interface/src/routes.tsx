import { lazy } from 'react';
import { RouteObject } from 'react-router-dom';

const AletheianLogin = lazy(() => import('./pages/AletheianLogin'));
const AletheianDashboard = lazy(() => import('./pages/AletheianDashboard'));
const ClaimVerificationPage = lazy(() => import('./pages/ClaimVerificationPage'));
const EscalationPage = lazy(() => import('./pages/EscalationPage'));
const FinancePage = lazy(() => import('./pages/FinancePage'));
const ProfilePage = lazy(() => import('./pages/ProfilePage'));

const routes: RouteObject[] = [
  {
    path: '/',
    element: <AletheianLogin />,
  },
  {
    path: '/dashboard',
    element: <AletheianDashboard />,
  },
  {
    path: '/verify-claim/:claimId',
    element: <ClaimVerificationPage />,
  },
  {
    path: '/escalation/:claimId',
    element: <EscalationPage />,
  },
  {
    path: '/finance',
    element: <FinancePage />,
  },
  {
    path: '/profile',
    element: <ProfilePage />,
  },
];

export default routes;