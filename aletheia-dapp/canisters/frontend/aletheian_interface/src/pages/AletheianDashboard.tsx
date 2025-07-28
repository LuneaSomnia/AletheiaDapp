// src/pages/AletheianDashboard.tsx
import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import GlassCard from '../components/GlassCard';
import PurpleButton from '../components/PurpleButton';
import ClaimAssignment from '../components/ClaimAssignment';
import ReputationBadge from '../components/ReputationBadge';
import { useAuth } from '../services/auth';
import { getAletheianClaims } from '../services/claims';
import { getNotifications } from '../services/notifications';
import NotificationBell from '../components/NotificationBell';

const AletheianDashboard: React.FC = () => {
  const { user } = useAuth();
  const [assignments, setAssignments] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [notifications, setNotifications] = useState<any[]>([]);
  const [stats, setStats] = useState({
    claimsVerified: 0,
    accuracy: 0,
    escalationsResolved: 0
  });
  const navigate = useNavigate(); // Correct usage

  useEffect(() => {
    const fetchDashboardData = async () => {
      if (user) {
        setIsLoading(true);
        try {
          const [claims, notifs] = await Promise.all([
            getAletheianClaims(user.principal),
            getNotifications(true) // unread only
          ]);
          
          setAssignments(claims);
          setNotifications(notifs);
          
          // Set stats from user profile
          setStats({
            claimsVerified: user.claimsVerified,
            accuracy: Math.round(user.accuracy),
            escalationsResolved: Math.floor(user.claimsVerified * 0.1) // Estimate
          });
        } catch (error) {
          console.error('Failed to fetch claims:', error);
        } finally {
          setIsLoading(false);
        }
      }
    };

    fetchDashboardData();
  }, [user]);

  const handleClaimSelect = (claimId: string) => {
    navigate(`/verify-claim/${claimId}`);
  };

  if (!user) {
    const unreadCount = notifications.filter(n => !n.read).length;

    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-gold mx-auto"></div>
          <p className="mt-4 text-cream">Loading user data...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen p-4 pb-20">
      <div className="absolute inset-0 overflow-hidden">
        {[...Array(15)].map((_, i) => (
          <div 
            key={i} 
            className="absolute opacity-10"
            style={{
              top: `${Math.random() * 100}%`,
              left: `${Math.random() * 100}%`,
              width: `${Math.random() * 100 + 50}px`,
              height: `${Math.random() * 100 + 50}px`,
              backgroundImage: `url(/assets/icons/${['torch', 'scales', 'magnifier', 'computer'][i % 4]}.svg)`,
              backgroundSize: 'contain',
              backgroundRepeat: 'no-repeat',
              transform: `rotate(${Math.random() * 360}deg)`
            }} 
          />
        ))}
      </div>

      <div className="max-w-6xl mx-auto">
        <header className="flex justify-between items-center py-6 mb-8">
          <h1 className="text-3xl font-bold text-cream">Aletheian Dashboard</h1>
          <div className="flex gap-4 items-center">
            <NotificationBell />
            <ReputationBadge 
              xp={user.xp} 
              rank={user.rank} 
              badges={user.badges} 
            />
            <PurpleButton onClick={() => navigate('/profile')}>
              My Profile
            </PurpleButton>
          </div>
        </header>

        {/* Ongoing Tasks Section */}
        <div className="mb-10">
          <GlassCard className="border-2 border-gold bg-gold bg-opacity-10 shadow-lg">
            <div className="flex items-center gap-3 mb-4">
              <span className="text-2xl">⏳</span>
              <h2 className="text-2xl font-bold text-gold">Ongoing Tasks</h2>
            </div>
            {isLoading ? (
              <div className="text-center py-6">
                <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-gold mx-auto"></div>
                <p className="mt-2 text-cream">Loading active claims...</p>
              </div>
            ) : assignments.length === 0 ? (
              <p className="text-cream text-center py-4">No ongoing tasks at the moment.</p>
            ) : (
              <div className="flex flex-col gap-3">
                {assignments.map((assignment) => (
                  <div key={assignment.id} className="flex items-center justify-between bg-red-900 bg-opacity-20 rounded-lg px-4 py-3 border border-gold border-opacity-30 hover:border-gold transition cursor-pointer" onClick={() => handleClaimSelect(assignment.id)}>
                    <div className="flex items-center gap-3">
                      <span className="inline-block px-2 py-1 rounded-full text-xs font-bold bg-yellow-500 text-red-900">Active</span>
                      <span className="font-semibold text-cream">{assignment.text}</span>
                    </div>
                    <div className="flex items-center gap-4">
                      <span className="text-xs text-gold font-bold">Deadline: {assignment.deadline ? new Date(assignment.deadline).toLocaleString() : 'N/A'}</span>
                      <PurpleButton
                        className="small-button"
                        onClick={() => handleClaimSelect(assignment.id)}
                      >
                        Review
                      </PurpleButton>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </GlassCard>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <GlassCard className="lg:col-span-2">
            <h2 className="text-2xl font-semibold text-cream mb-4">Active Assignments</h2>
            {isLoading ? (
              <div className="text-center py-8">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-gold mx-auto"></div>
                <p className="mt-4 text-cream">Loading assignments...</p>
              </div>
            ) : assignments.length === 0 ? (
              <p className="text-cream text-center py-8">No active assignments</p>
            ) : (
              <div className="space-y-4">
                {assignments.map((assignment) => (
                  <ClaimAssignment 
                    key={assignment.id}
                    claimId={assignment.id}
                    claimText={assignment.text}
                    deadline={assignment.deadline}
                    status={assignment.status}
                    complexity={assignment.complexity}
                    onSelect={handleClaimSelect}
                  />
                ))}
              </div>
            )}
          </GlassCard>

          <GlassCard>
            <h2 className="text-2xl font-semibold text-cream mb-4">Quick Actions</h2>
            <div className="space-y-4">
              <PurpleButton 
                className="w-full" 
                onClick={() => navigate('/finance')}
              >
                View Finance
              </PurpleButton>
              <PurpleButton 
  className="w-full" 
  onClick={() => navigate('/escalations')}
>
  Check Escalations
</PurpleButton>
<PurpleButton 
  className="w-full" 
  onClick={() => navigate('/profile/edit')}
>
  Update Profile
</PurpleButton>
            </div>
          </GlassCard>

          <GlassCard className="lg:col-span-3">
            <h2 className="text-2xl font-semibold text-cream mb-4">Performance Stats</h2>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="bg-purple-900 bg-opacity-30 rounded-lg p-4 text-center">
                <p className="text-3xl font-bold text-gold">{stats.claimsVerified}</p>
                <p className="text-cream">Claims Verified</p>
              </div>
              <div className="bg-purple-900 bg-opacity-30 rounded-lg p-4 text-center">
                <p className="text-3xl font-bold text-gold">{stats.accuracy}%</p>
                <p className="text-cream">Accuracy</p>
              </div>
              <div className="bg-purple-900 bg-opacity-30 rounded-lg p-4 text-center">
                <p className="text-3xl font-bold text-gold">{stats.escalationsResolved}</p>
                <p className="text-cream">Escalations Resolved</p>
              </div>
            </div>
          </GlassCard>
        </div>
      </div>
    </div>
  );
};

export default AletheianDashboard;