// src/pages/DashboardPage.tsx
import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import GlassCard from '../components/GlassCard';
import GoldButton from '../components/GoldButton';
import ClaimStatus from '../components/ClaimStatus';
import { useAuth } from '../services/auth';
import { useDispatch, useSelector } from 'react-redux';
import { getLearningModules } from '../services/learning';

const DashboardPage: React.FC = () => {
  const { user } = useAuth();
  const [isLoading, setIsLoading] = useState(true);
  const [modules, setModules] = useState<any[]>([]);
  const navigate = useNavigate();
  const dispatch = useDispatch();
  
  // Mock user claims
  const userClaims = [
    {
      id: 'claim-001',
      text: "Drinking bleach cures COVID-19",
      status: "Completed",
      verdict: "FALSE",
      submittedAt: "2023-05-15T10:30:00Z"
    },
    {
      id: 'claim-002',
      text: "New study shows chocolate prevents aging",
      status: "Processing",
      submittedAt: "2023-05-15T10:45:00Z"
    },
    {
      id: 'claim-003',
      text: "Government announces universal basic income",
      status: "Completed",
      verdict: "MISLEADING",
      submittedAt: "2023-05-15T11:00:00Z"
    }
  ];

  useEffect(() => {
    const fetchLearningModules = async () => {
      setIsLoading(true);
      try {
        const data = await getLearningModules();
        setModules(data);
      } catch (error) {
        console.error('Failed to fetch modules:', error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchLearningModules();
  }, []);

  const handleViewClaim = (claimId: string) => {
    navigate(`/claim-result/${claimId}`);
  };

  if (!user) {
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
          <h1 className="text-3xl font-bold text-cream">Aletheia Dashboard</h1>
          <div className="flex gap-4">
            <GoldButton onClick={() => navigate('/profile')}>
              My Profile
            </GoldButton>
          </div>
        </header>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <GlassCard className="lg:col-span-2">
            <h2 className="text-2xl font-semibold text-cream mb-4">Submit New Claim</h2>
            <GoldButton 
              className="w-full py-4 text-xl"
              onClick={() => navigate('/submit-claim')}
            >
              Verify Information
            </GoldButton>
          </GlassCard>

          <GlassCard>
            <h2 className="text-2xl font-semibold text-cream mb-4">Critical Thinking Gym</h2>
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <p className="text-cream">Learning Points</p>
                <span className="text-gold font-bold">{user.learningPoints} LP</span>
              </div>
              <div className="h-4 bg-gold bg-opacity-20 rounded-full">
                <div 
                  className="h-full bg-gold rounded-full" 
                  style={{ width: `${(user.learningPoints / 200) * 100}%` }}
                ></div>
              </div>
              <GoldButton 
                className="w-full"
                onClick={() => navigate('/learning-gym')}
              >
                Start Exercises
              </GoldButton>
            </div>
          </GlassCard>

          <GlassCard className="lg:col-span-3">
            <h2 className="text-2xl font-semibold text-cream mb-4">Your Recent Claims</h2>
            {isLoading ? (
              <div className="text-center py-8">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-gold mx-auto"></div>
                <p className="mt-4 text-cream">Loading claims...</p>
              </div>
            ) : userClaims.length === 0 ? (
              <p className="text-cream text-center py-8">No claims submitted yet</p>
            ) : (
              <div className="space-y-4">
                {userClaims.map((claim) => (
                  <ClaimStatus 
                    key={claim.id}
                    claimId={claim.id}
                    claimText={claim.text}
                    status={claim.status}
                    verdict={claim.verdict}
                    onView={handleViewClaim}
                  />
                ))}
              </div>
            )}
          </GlassCard>
        </div>
      </div>
    </div>
  );
};

export default DashboardPage;