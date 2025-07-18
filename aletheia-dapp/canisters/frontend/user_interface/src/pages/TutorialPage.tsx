import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import GlassCard from '../components/GlassCard';
import GoldButton from '../components/GoldButton';

const TutorialPage: React.FC = () => {
  const navigate = useNavigate();
  const [currentStep, setCurrentStep] = useState(0);

  const tutorialSteps = [
    {
      title: "How to Submit a Claim",
      content: "Learn how to submit claims for verification. You can submit text, images, videos, or links that you want fact-checked.",
      action: "Try submitting a claim",
      actionUrl: "/submit-claim"
    },
    {
      title: "Understanding Claim Results",
      content: "Learn how to read and interpret claim verification results, including evidence breakdown and consensus information.",
      action: "View sample results",
      actionUrl: "/claim-result/sample"
    },
    {
      title: "Using the Learning Gym",
      content: "Improve your critical thinking skills through interactive exercises, scenarios, and quizzes.",
      action: "Visit Learning Gym",
      actionUrl: "/learn"
    },
    {
      title: "Managing Your Profile",
      content: "Customize your profile, track your progress, and manage your notification preferences.",
      action: "View your profile",
      actionUrl: "/profile"
    }
  ];

  const handleNext = () => {
    if (currentStep < tutorialSteps.length - 1) {
      setCurrentStep(currentStep + 1);
    } else {
      // Mark tutorial as completed
      localStorage.setItem('tutorialCompleted', 'true');
      navigate('/dashboard');
    }
  };

  const handleSkip = () => {
    localStorage.setItem('tutorialCompleted', 'true');
    navigate('/dashboard');
  };

  const handleAction = () => {
    const step = tutorialSteps[currentStep];
    if (step.actionUrl) {
      navigate(step.actionUrl);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-red-900 via-red-800 to-red-900 flex items-center justify-center p-4">
      <GlassCard className="max-w-2xl w-full p-8">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-gold mb-4">Interactive Tutorial</h1>
          <div className="mb-6">
            <span className="text-cream">Step {currentStep + 1} of {tutorialSteps.length}</span>
          </div>
        </div>

        <div className="mb-8">
          <h2 className="text-2xl font-bold text-gold mb-4">{tutorialSteps[currentStep].title}</h2>
          <p className="text-cream text-lg leading-relaxed mb-6">{tutorialSteps[currentStep].content}</p>
          
          {tutorialSteps[currentStep].action && (
            <div className="text-center">
              <GoldButton onClick={handleAction} className="mb-4">
                {tutorialSteps[currentStep].action}
              </GoldButton>
            </div>
          )}
        </div>

        <div className="flex justify-center mb-8">
          <div className="flex space-x-2">
            {tutorialSteps.map((_, index) => (
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
            Skip Tutorial
          </GoldButton>
          <GoldButton onClick={handleNext}>
            {currentStep === tutorialSteps.length - 1 ? 'Complete Tutorial' : 'Next Step'}
          </GoldButton>
        </div>
      </GlassCard>
    </div>
  );
};

export default TutorialPage; 