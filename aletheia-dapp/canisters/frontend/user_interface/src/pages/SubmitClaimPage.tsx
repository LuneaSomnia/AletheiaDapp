// src/pages/SubmitClaimPage.tsx
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import ClaimForm from '../components/ClaimForm';
import QuestionMirror from '../components/QuestionMirror';
import GlassCard from '../components/GlassCard';
import GoldButton from '../components/GoldButton';

const SubmitClaimPage: React.FC = () => {
  const [submissionResult, setSubmissionResult] = useState<{ claimId: string; questions: string[] } | null>(null);
  const [isLearning, setIsLearning] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (
    claim: string, 
    claimType: string, 
    source?: string, 
    context?: string
  ) => {
    const result = await ClaimForm.handleSubmit();
    if (result) {
      setSubmissionResult(result);
    }
  };

  return (
    <div className="min-h-screen p-4">
      <div className="max-w-4xl mx-auto">
        {!submissionResult ? (
          <ClaimForm onSubmit={handleSubmit} />
        ) : (
          <div className="space-y-8">
            <GlassCard className="p-8 text-center">
              <div className="text-5xl text-gold mb-4">✓</div>
              <h1 className="text-2xl font-bold text-cream mb-2">Claim Submitted Successfully!</h1>
              <p className="text-cream">
                Your claim is now being processed by Aletheians. This should take around 5 minutes.
              </p>
            </GlassCard>
            
            <QuestionMirror 
              questions={submissionResult.questions} 
              claimId={submissionResult.claimId} 
            />
            
            <div className="text-center">
              <GoldButton 
                onClick={() => setIsLearning(true)}
                className="w-full max-w-md mx-auto py-4"
              >
                Sharpen Your Skills While You Wait
              </GoldButton>
            </div>
            
            {isLearning && (
              <GlassCard className="p-8">
                <h2 className="text-2xl font-bold text-cream mb-4">Critical Thinking Exercise</h2>
                <p className="text-cream mb-6">
                  Let's practice identifying misinformation. Analyze the following claim:
                </p>
                
                <div className="bg-red-900 bg-opacity-30 border border-gold rounded-lg p-4 mb-6">
                  <p className="text-cream">
                    "A recent study proves that 5G towers spread COVID-19. Governments are hiding this truth to protect telecom companies."
                  </p>
                </div>
                
                <div className="mb-6">
                  <h3 className="text-xl font-semibold text-cream mb-3">What makes this claim suspicious?</h3>
                  <div className="space-y-2">
                    {[
                      "It cites a specific study but provides no reference",
                      "It makes a scientifically implausible connection",
                      "It suggests a conspiracy without evidence",
                      "All of the above"
                    ].map((option, index) => (
                      <div 
                        key={index} 
                        className="p-3 bg-red-900 bg-opacity-20 rounded-lg hover:bg-red-900 hover:bg-opacity-30 cursor-pointer"
                      >
                        <p className="text-cream">{option}</p>
                      </div>
                    ))}
                  </div>
                </div>
                
                <GoldButton 
                  onClick={() => navigate('/learning-gym')}
                  className="w-full"
                >
                  Continue to Learning Gym
                </GoldButton>
              </GlassCard>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default SubmitClaimPage;