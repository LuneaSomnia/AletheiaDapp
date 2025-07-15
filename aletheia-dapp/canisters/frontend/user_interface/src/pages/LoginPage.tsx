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
            <GoldButton onClick={handleLogin} disabled={isLoading}>
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