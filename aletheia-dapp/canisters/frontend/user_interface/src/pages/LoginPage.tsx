// src/pages/LoginPage.tsx
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import GlassCard from '../components/GlassCard';
import GoldButton from '../components/GoldButton';
import { useAuth } from '../services/auth';

const LoginPage: React.FC = () => {
  const [isLoading, setIsLoading] = useState(false);
  const [tutorialStep, setTutorialStep] = useState(0);
  const [showTutorial, setShowTutorial] = useState(true);
  const [acceptedTerms, setAcceptedTerms] = useState(false);
  const [showTermsModal, setShowTermsModal] = useState(false);
  const navigate = useNavigate();
  const { authenticate } = useAuth();

  useEffect(() => {
    // Check if user has completed tutorial before
    const tutorialCompleted = localStorage.getItem('aletheia_tutorial_completed');
    if (tutorialCompleted === 'true') {
      setShowTutorial(false);
    }
  }, []);

  const tutorialSteps = [
    {
      title: "Welcome to Aletheia",
      content: "A decentralized platform for truth discovery and critical thinking"
    },
    {
      title: "Your Digital Wallet",
      content: "Connect your wallet to interact with the platform securely"
    },
    {
      title: "Claim Verification",
      content: "Submit claims for community verification and earn rewards"
    }
  ];

  const handleLogin = async () => {
    setIsLoading(true);
    try {
      await authenticate();
      navigate('/dashboard');
    } catch (error) {
      console.error('Login failed:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleTutorialComplete = () => {
    localStorage.setItem('aletheia_tutorial_completed', 'true');
    setShowTutorial(false);
  };

  const handleNextStep = () => {
    if (tutorialStep < tutorialSteps.length - 1) {
      setTutorialStep(tutorialStep + 1);
    } else {
      handleTutorialComplete();
    }
  };

  const handleSkipTutorial = () => {
    handleTutorialComplete();
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4"
         style={{
           background: 'linear-gradient(135deg, #8B0000 0%, #4B0000 100%)',
         }}>
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

      {/* Terms Modal */}
      {showTermsModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-60">
          <div className="bg-white rounded-lg shadow-lg max-w-lg w-full p-6 relative overflow-y-auto max-h-[80vh]">
            <button
              className="absolute top-2 right-2 text-gray-600 hover:text-black text-xl font-bold"
              onClick={() => setShowTermsModal(false)}
              aria-label="Close Terms Modal"
            >
              &times;
            </button>
            <h2 className="text-2xl font-bold mb-4 text-center">Terms of Service & Privacy Policy</h2>
            <div className="text-gray-800 text-sm space-y-4 max-h-[60vh] overflow-y-auto">
              <p><strong>Terms of Service:</strong> By creating an account and using Aletheia, you agree to abide by our community guidelines, respect other users, and not misuse the platform. You acknowledge that your activity may be recorded for security and moderation purposes.</p>
              <p><strong>Privacy Policy:</strong> We value your privacy. Your personal data will be handled securely and will not be shared with third parties without your consent, except as required by law. For more details, please refer to our full privacy policy on our website.</p>
              <p>This is a summary. Please review the full Terms of Service and Privacy Policy for complete details.</p>
            </div>
            <div className="mt-6 flex justify-center">
              <button
                className="bg-gold text-white px-4 py-2 rounded hover:bg-yellow-600"
                onClick={() => setShowTermsModal(false)}
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      <GlassCard className="w-full max-w-md z-10">
        <h1 className="text-3xl font-bold text-center text-cream mb-2">
          Welcome to Aletheia
        </h1>
        <p className="text-cream text-opacity-80 text-center mb-8">
          The Decentralized Truth Platform
        </p>
        
        {showTutorial ? (
          <div className="tutorial-container">
            <div className="mb-6">
              <h2 className="text-xl font-semibold text-cream mb-2">
                {tutorialSteps[tutorialStep].title}
              </h2>
              <p className="text-cream text-opacity-80">
                {tutorialSteps[tutorialStep].content}
              </p>
            </div>
            
            <div className="tutorial-progress flex justify-center mb-4">
              {tutorialSteps.map((_, index) => (
                <div 
                  key={index} 
                  className={`w-2 h-2 mx-1 rounded-full ${
                    index === tutorialStep ? 'bg-gold' : 'bg-cream opacity-30'
                  }`}
                />
              ))}
            </div>
            
            <div className="flex justify-between">
              <button 
                className="text-gold hover:underline"
                onClick={handleSkipTutorial}
              >
                Skip Tutorial
              </button>
              <GoldButton onClick={handleNextStep}>
                {tutorialStep < tutorialSteps.length - 1 ? 'Next' : 'Get Started'}
              </GoldButton>
            </div>
          </div>
        ) : (
          <div className="flex flex-col gap-4">
            {/* Terms acceptance checkbox */}
            <div className="flex items-center mb-2">
              <input
                id="accept-terms"
                type="checkbox"
                checked={acceptedTerms}
                onChange={e => setAcceptedTerms(e.target.checked)}
                className="mr-2 accent-gold"
              />
              <label htmlFor="accept-terms" className="text-cream text-sm">
                I agree to the{' '}
                <button
                  type="button"
                  className="text-gold underline hover:text-yellow-400 focus:outline-none"
                  onClick={() => setShowTermsModal(true)}
                >
                  Terms of Service & Privacy Policy
                </button>
              </label>
            </div>
            <GoldButton onClick={handleLogin} disabled={isLoading || !acceptedTerms}>
              {isLoading ? 'Connecting...' : 'Login as User'}
            </GoldButton>
            <GoldButton 
              onClick={() => window.location.href = '/aletheian'}
              className="bg-purple-900 border-purple-700 hover:from-purple-900 hover:to-purple-800"
            >
              Login as Aletheian
            </GoldButton>
          </div>
        )}
      </GlassCard>
    </div>
  );
};

export default LoginPage;