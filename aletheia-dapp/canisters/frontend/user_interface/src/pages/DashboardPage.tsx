// src/pages/DashboardPage.tsx
import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import GlassCard from '../components/GlassCard';
import GoldButton from '../components/GoldButton';
import ClaimStatus from '../components/ClaimStatus';
import { useAuth } from '../services/auth';
import { useDispatch, useSelector } from 'react-redux';
import { getLearningModules } from '../services/learning';
import { useWebSocket } from '../context/WebSocketContext';
import { submitClaim } from '../services/claimService';

type PendingClaim = {
  id: string;
  text: string;
  submittedAt: string;
};

const DashboardPage: React.FC = () => {
  const { user, completeTutorial } = useAuth();
  const [isLoading, setIsLoading] = useState(true);
  const [modules, setModules] = useState<any[]>([]);
  const [submissionStatus, setSubmissionStatus] = useState<'idle' | 'processing' | 'pending' | 'completed' | 'error'>('idle');
  const [pendingClaims, setPendingClaims] = useState<PendingClaim[]>([]);
  const [showDashboardTutorial, setShowDashboardTutorial] = useState(false);
  const [dashboardTutorialStep, setDashboardTutorialStep] = useState(0);
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const { subscribeToClaimUpdates } = useWebSocket();

  const dashboardTutorialSteps = [
    {
      title: "Dashboard Overview",
      content: "Welcome to your dashboard! Here you can submit claims, track your progress, and access learning resources."
    },
    {
      title: "Submit Claims",
      content: "Click here to submit new claims for verification by the community."
    },
    {
      title: "Critical Thinking Gym",
      content: "Improve your critical thinking skills and earn Learning Points (LP) by completing exercises."
    },
    {
      title: "Your Claims",
      content: "Track the status of your submitted claims here."
    }
  ];

  useEffect(() => {
    if (user && !user.hasCompletedTutorial) {
      setShowDashboardTutorial(true);
    }
  }, [user]);

  useEffect(() => {
    if (!user) return;
    
    const unsubscribe = subscribeToClaimUpdates((update) => {
      if (update.status === 'completed' && pendingClaims.some(claim => claim.id === update.claimId)) {
        setPendingClaims(prev => prev.filter(claim => claim.id !== update.claimId));
        setSubmissionStatus('completed');
      }
    });
    
    return unsubscribe;
  }, [subscribeToClaimUpdates, pendingClaims, user]);

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

  const handleSubmitTestClaim = async () => {
    setSubmissionStatus('processing');
    try {
      const testClaim = {
        content: "Test claim about important news",
        type: "text",
        source: "https://example.com",
        context: "Testing claim submission flow"
      };
      
      const result = await submitClaim(testClaim);
      if (result.status === 'success') {
        setSubmissionStatus('pending');
        setPendingClaims(prev => [...prev, {
          id: result.claimId as string,
          text: testClaim.content,
          submittedAt: new Date().toISOString()
        }]);
      } else {
        setSubmissionStatus('error');
      }
    } catch (error) {
      setSubmissionStatus('error');
      console.error('Claim submission failed:', error);
    }
  };

  const handleNextDashboardStep = () => {
    if (dashboardTutorialStep < dashboardTutorialSteps.length - 1) {
      setDashboardTutorialStep(dashboardTutorialStep + 1);
    } else {
      completeTutorial();
      setShowDashboardTutorial(false);
    }
  };

  const handleSkipDashboardTutorial = () => {
    completeTutorial();
    setShowDashboardTutorial(false);
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
    <div className="min-h-screen p-4 pb-20 relative">
      {showDashboardTutorial && (
        <div className="tutorial-overlay fixed inset-0 bg-black bg-opacity-70 z-50 flex items-center justify-center">
          <GlassCard className="tutorial-card w-full max-w-2xl">
            <div className="p-6">
              <h2 className="text-2xl font-bold text-cream mb-4">
                {dashboardTutorialSteps[dashboardTutorialStep].title}
              </h2>
              <p className="text-cream mb-6">
                {dashboardTutorialSteps[dashboardTutorialStep].content}
              </p>
              
              <div className="tutorial-progress flex justify-center mb-4">
                {dashboardTutorialSteps.map((_, index) => (
                  <div 
                    key={index} 
                    className={`w-3 h-3 mx-1 rounded-full ${
                      index === dashboardTutorialStep ? 'bg-gold' : 'bg-cream opacity-30'
                    }`}
                  />
                ))}
              </div>
              
              <div className="flex justify-between">
                <button 
                  className="text-gold hover:underline"
                  onClick={handleSkipDashboardTutorial}
                >
                  Skip Tutorial
                </button>
                <GoldButton onClick={handleNextDashboardStep}>
                  {dashboardTutorialStep < dashboardTutorialSteps.length - 1 ? 'Next' : 'Finish Tutorial'}
                </GoldButton>
              </div>
            </div>
          </GlassCard>
        </div>
      )}

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

      <div className="max-w-6xl mx-auto relative z-10">
        <header className="flex justify-between items-center py-6 mb-8">
          <h1 className="text-3xl font-bold text-cream">Aletheia Dashboard</h1>
          <div className="flex gap-4">
            <GoldButton onClick={() => navigate('/profile')}>
              My Profile
            </GoldButton>
          </div>
        </header>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* ... existing dashboard content ... */}
        </div>
      </div>
    </div>
  );
};

export default DashboardPage;