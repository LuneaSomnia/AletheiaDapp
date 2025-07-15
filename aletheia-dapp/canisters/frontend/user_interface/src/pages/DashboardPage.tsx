import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import GlassCard from '../components/GlassCard';
import GoldButton from '../components/GoldButton';
import ClaimStatus from '../components/ClaimStatus';
import ProfileSection from '../components/ProfileSection';
import { useAuth } from '../services/auth';
import { useDispatch, useSelector } from 'react-redux';
import { getLearningModules } from '../services/learning';
import { useWebSocket } from '../context/WebSocketContext';
import { submitClaim } from '../services/claimService';
import '../user.css';

// Types matching your existing data structures
interface UserProfile {
  id: string;
  username: string;
  trustScore: number;
  expertise: string;
  joinDate: string;
}

interface Claim {
  id: string;
  title: string;
  status: 'pending' | 'verified' | 'disputed' | 'rejected';
  timestamp: string;
  topic: string;
}

interface Topic {
  id: string;
  title: string;
  claimCount: number;
  trustIndex: number;
}

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
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [claims, setClaims] = useState<Claim[]>([]);
  const [trendingTopics, setTrendingTopics] = useState<Topic[]>([]);
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const { subscribeToClaimUpdates } = useWebSocket();

  const dashboardTutorialSteps = [
    {
      title: "Dashboard Overview",
      content: "Welcome to your dashboard! Here you can track your claims, see trending topics, and manage your profile."
    },
    {
      title: "Your Profile",
      content: "View your trust score and profile information. Your trust score grows as your claims are verified."
    },
    {
      title: "Verification Status",
      content: "See how many claims are pending, verified, disputed, or rejected at a glance."
    },
    {
      title: "Claim History",
      content: "Track all your submitted claims. Click on any claim to see detailed results."
    },
    {
      title: "Trending Truths",
      content: "See what topics are currently being discussed and verified in the community."
    }
  ];

  useEffect(() => {
    if (user && !user.hasCompletedTutorial) {
      setShowDashboardTutorial(true);
    }
    
    // Mock data for dashboard - in a real app this would come from services
    if (user) {
      setProfile({
        id: user.principal,
        username: user.username || 'TruthSeeker',
        trustScore: 85,
        expertise: 'Technology & Science',
        joinDate: '2025-01-15'
      });
      
      setClaims([
        { id: '1', title: 'Quantum computing will revolutionize encryption by 2030', status: 'verified', timestamp: '2025-06-10', topic: 'Technology' },
        { id: '2', title: 'Global temperatures have risen 1.5°C since pre-industrial times', status: 'disputed', timestamp: '2025-06-15', topic: 'Climate' },
        { id: '3', title: 'Neuralink implants have been approved for human trials', status: 'pending', timestamp: '2025-07-05', topic: 'Science' },
        { id: '4', title: 'Renewable energy now accounts for 35% of global electricity', status: 'verified', timestamp: '2025-07-10', topic: 'Energy' },
        { id: '5', title: 'New study shows AI can predict diseases with 95% accuracy', status: 'rejected', timestamp: '2025-07-12', topic: 'Health' }
      ]);
      
      setTrendingTopics([
        { id: '1', title: 'AI Regulation', claimCount: 142, trustIndex: 68 },
        { id: '2', title: 'Mars Colonization', claimCount: 89, trustIndex: 72 },
        { id: '3', title: 'Global Food Security', claimCount: 117, trustIndex: 45 },
        { id: '4', title: 'Quantum Computing', claimCount: 63, trustIndex: 81 }
      ]);
      
      setIsLoading(false);
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

        {isLoading ? (
          <div className="flex justify-center items-center min-h-[50vh]">
            <div className="animate-spin rounded-full h-16 w-16 border-t-2 border-b-2 border-gold mx-auto"></div>
          </div>
        ) : (
          <div className="dashboard-container">
            {/* Header Section */}
            <div className="dashboard-header mb-8 text-center">
              <h1 className="text-3xl font-bold text-cream">TruthSeeker Dashboard</h1>
              <p className="text-cream text-lg">
                Welcome back, {profile?.username || 'TruthSeeker'}. Your current trust score: 
                <span className="trust-score font-bold ml-2">{profile?.trustScore || 0}</span>
              </p>
            </div>

            <div className="dashboard-grid grid grid-cols-1 lg:grid-cols-3 gap-6">
              {/* Profile Section */}
              <div className="dashboard-column lg:col-span-1">
                <GlassCard title="Your Profile" className="h-full">
                  <ProfileSection profile={profile!} />
                  <GoldButton 
                     onClick={() => navigate('/profile')} 
                     className="mt-4 w-full"
                    >
                     Edit Profile
                  </GoldButton>
                </GlassCard>
              </div>

              {/* Main Content - Claims and Statuses */}
              <div className="dashboard-column lg:col-span-2 space-y-6">
                {/* Claim Status Overview */}
                <GlassCard title="Verification Status">
                  <div className="status-grid grid grid-cols-2 md:grid-cols-4 gap-4">
                    <div className="status-item pending p-4 rounded-lg">
                      <h3 className="font-bold text-lg">Pending</h3>
                      <p className="text-2xl mt-2">{claims.filter(c => c.status === 'pending').length}</p>
                    </div>
                    <div className="status-item verified p-4 rounded-lg">
                      <h3 className="font-bold text-lg">Verified</h3>
                      <p className="text-2xl mt-2">{claims.filter(c => c.status === 'verified').length}</p>
                    </div>
                    <div className="status-item disputed p-4 rounded-lg">
                      <h3 className="font-bold text-lg">Disputed</h3>
                      <p className="text-2xl mt-2">{claims.filter(c => c.status === 'disputed').length}</p>
                    </div>
                    <div className="status-item rejected p-4 rounded-lg">
                      <h3 className="font-bold text-lg">Rejected</h3>
                      <p className="text-2xl mt-2">{claims.filter(c => c.status === 'rejected').length}</p>
                    </div>
                  </div>
                </GlassCard>

                {/* Claim History */}
                <GlassCard 
                  title="Your Claim History"
                  action={
                    <GoldButton 
  onClick={() => navigate('/submit-claim')} 
>
  New Claim
</GoldButton>
                  }
                >
                  <div className="claim-history max-h-[400px] overflow-y-auto">
                    {claims.length === 0 ? (
                      <p className="no-claims text-center py-8">
                        You haven't submitted any claims yet.
                      </p>
                    ) : (
                      <ul>
                        {claims.map(claim => (
                          <li 
                            key={claim.id} 
                            className="claim-item py-4 px-2 border-b border-gold border-opacity-20 hover:bg-gold hover:bg-opacity-10 cursor-pointer transition-colors"
                            onClick={() => handleViewClaim(claim.id)}
                          >
                            <div className="flex justify-between items-start">
                              <div className="claim-info flex-1">
                                <h4 className="font-semibold text-lg">{claim.title}</h4>
                                <div className="flex items-center mt-1">
                                  <span className="claim-topic text-gold text-sm mr-4">
                                    {claim.topic}
                                  </span>
                                  <span className="claim-date text-cream text-opacity-70 text-sm">
                                    {new Date(claim.timestamp).toLocaleDateString()}
                                  </span>
                                </div>
                              </div>
                              <ClaimStatus
  claimId={claim.id}
  claimText={claim.title}
  status={claim.status}
  onView={() => handleViewClaim(claim.id)}
/>
                            </div>
                          </li>
                        ))}
                      </ul>
                    )}
                  </div>
                </GlassCard>
              </div>

              {/* Trending Topics */}
              <div className="dashboard-column lg:col-span-3">
                <GlassCard title="Trending Truths">
                  <div className="trending-topics grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                    {trendingTopics.map(topic => (
                      <div 
                        key={topic.id} 
                        className="topic-item p-4 rounded-lg transition-transform hover:scale-[1.02]"
                      >
                        <h4 className="font-bold text-lg mb-2">{topic.title}</h4>
                        <div className="topic-stats flex justify-between text-sm">
                          <span className="claim-count text-gold">
                            {topic.claimCount} claims
                          </span>
                          <span className={`trust-index font-bold ${
                            topic.trustIndex > 70 ? 'text-green-400' : 
                            topic.trustIndex > 40 ? 'text-yellow-400' : 'text-red-400'
                          }`}>
                            {topic.trustIndex}% trust
                          </span>
                        </div>
                        <GoldButton 
  onClick={() => navigate('/submit-claim')} 
  className="mt-4 w-full"
>
  New Claim
</GoldButton>
                      </div>
                    ))}
                  </div>
                </GlassCard>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default DashboardPage;