// src/pages/DashboardPage.tsx
import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import GlassCard from '../components/GlassCard';
import GoldButton from '../components/GoldButton';
import ClaimStatus from '../components/ClaimStatus';
import { useAuth } from '../services/auth';
import { useDispatch, useSelector } from 'react-redux';
import { getLearningModules } from '../services/learning';
import { useWebSocket } from '../context/WebSocketContext'; // New import
import { submitClaim } from '../services/claimService'; // New import

// New type for claim tracking
type PendingClaim = {
  id: string;
  text: string;
  submittedAt: string;
};

const DashboardPage: React.FC = () => {
  const { user } = useAuth();
  const [isLoading, setIsLoading] = useState(true);
  const [modules, setModules] = useState<any[]>([]);
  const [submissionStatus, setSubmissionStatus] = useState<'idle' | 'processing' | 'pending' | 'completed' | 'error'>('idle');
  const [pendingClaims, setPendingClaims] = useState<PendingClaim[]>([]); // New state for pending claims
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const { subscribeToClaimUpdates } = useWebSocket(); // WebSocket hook

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

  // New effect for WebSocket subscription
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

  // New function to simulate claim submission
  const handleSubmitTestClaim = async () => {
    setSubmissionStatus('processing');
    try {
      // Simulate API call to submit claim
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
            <div className="flex flex-col gap-4">
              <GoldButton 
                className="w-full py-4 text-xl"
                onClick={() => navigate('/submit-claim')}
              >
                Verify Information
              </GoldButton>
              
              {/* New: Test claim submission button */}
              <GoldButton 
                className="w-full py-3 text-lg bg-opacity-70"
                onClick={handleSubmitTestClaim}
                disabled={submissionStatus === 'processing' || submissionStatus === 'pending'}
              >
                {submissionStatus === 'processing' ? 'Submitting Test Claim...' : 
                 submissionStatus === 'pending' ? 'Claim Processing' : 'Submit Test Claim'}
              </GoldButton>
              
              {/* New: Status indicators */}
              {submissionStatus === 'error' && (
                <div className="text-red-400 text-center mt-2">
                  Submission failed. Please try again.
                </div>
              )}
            </div>
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

          {/* New: Pending claims section */}
          {pendingClaims.length > 0 && (
            <GlassCard className="lg:col-span-3">
              <h2 className="text-2xl font-semibold text-cream mb-4">Pending Claims</h2>
              <div className="space-y-4">
                {pendingClaims.map((claim) => (
                  <div key={claim.id} className="flex justify-between items-center p-4 bg-dark-red bg-opacity-30 rounded-lg">
                    <div>
                      <h3 className="text-cream font-medium">{claim.text}</h3>
                      <p className="text-gold text-sm mt-1">
                        Submitted: {new Date(claim.submittedAt).toLocaleString()}
                      </p>
                    </div>
                    <div className="flex items-center">
                      <div className="animate-pulse bg-gold rounded-full h-3 w-3 mr-2"></div>
                      <span className="text-gold">Processing</span>
                    </div>
                  </div>
                ))}
              </div>
            </GlassCard>
          )}

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