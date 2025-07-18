import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import GlassCard from '../components/GlassCard';
import GoldButton from '../components/GoldButton';

const OnboardingPage: React.FC = () => {
  const navigate = useNavigate();
  const [currentStep, setCurrentStep] = useState(0);

  const steps = [
    {
      title: "Welcome to Aletheia",
      description: "Your gateway to truth verification and critical thinking",
      content: "Join our community of truth-seekers and fact-checkers. Learn to distinguish fact from fiction in today's information landscape.",
      icon: "🔍"
    },
    {
      title: "Submit Claims",
      description: "Question everything, verify everything",
      content: "Submit claims you want verified - from news articles to social media posts. Our AI and human experts will help you find the truth.",
      icon: "📝"
    },
    {
      title: "Learn & Grow",
      description: "Develop your critical thinking skills",
      content: "Access our Learning Gym to improve your fact-checking abilities, earn badges, and become a more discerning information consumer.",
      icon: "🎓"
    },
    {
      title: "Join the Community",
      description: "Connect with fellow truth-seekers",
      content: "Participate in discussions, share insights, and help others develop their critical thinking skills.",
      icon: "🤝"
    }
  ];

  const handleNext = () => {
    if (currentStep < steps.length - 1) {
      setCurrentStep(currentStep + 1);
    } else {
      navigate('/tutorial');
    }
  };

  const handleSkip = () => {
    navigate('/dashboard');
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-red-900 via-red-800 to-red-900 flex items-center justify-center p-4">
      <GlassCard className="max-w-2xl w-full p-8">
        <div className="text-center mb-8">
          <div className="text-6xl mb-4">{steps[currentStep].icon}</div>
          <h1 className="text-3xl font-bold text-gold mb-2">{steps[currentStep].title}</h1>
          <p className="text-xl text-cream mb-4">{steps[currentStep].description}</p>
          <p className="text-cream text-lg leading-relaxed">{steps[currentStep].content}</p>
        </div>

        <div className="flex justify-center mb-8">
          <div className="flex space-x-2">
            {steps.map((_, index) => (
              <div
                key={index}
                className={`w-3 h-3 rounded-full ${
                  index === currentStep ? 'bg-gold' : 'bg-gold bg-opacity-30'
                }`}
              />
            ))}
          </div>
        </div>

        <div className="flex justify-between">
          <GoldButton onClick={handleSkip} className="bg-transparent border-gold text-gold hover:bg-gold hover:text-red-900">
            Skip Onboarding
          </GoldButton>
          <GoldButton onClick={handleNext}>
            {currentStep === steps.length - 1 ? 'Start Tutorial' : 'Next'}
          </GoldButton>
        </div>
      </GlassCard>
    </div>
  );
};

export default OnboardingPage; 