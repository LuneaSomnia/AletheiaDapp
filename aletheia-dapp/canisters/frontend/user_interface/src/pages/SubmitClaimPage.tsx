// src/pages/SubmitClaimPage.tsx
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import ClaimForm from '../components/ClaimForm';
import QuestionMirror from '../components/QuestionMirror';
import GlassCard from '../components/GlassCard';
import GoldButton from '../components/GoldButton';
import { submitClaim } from '../services/claims';

const SubmitClaimPage: React.FC = () => {
  const [submissionResult, setSubmissionResult] = useState<{ claimId: string; questions: string[] } | null>(null);
  const [isLearning, setIsLearning] = useState(false);
  const [showSuccessModal, setShowSuccessModal] = useState(false);
  const navigate = useNavigate();

  const handleFormSubmit = async (data: {
    claim: string;
    claimType: string;
    source?: string;
    context?: string;
    tags: string[];
  }) => {
    const result = await submitClaim(
      data.claim, 
      data.claimType, 
      data.source, 
      data.context,
      data.tags
    );
    if (result) {
      setSubmissionResult(result);
      setShowSuccessModal(true);
    }
  };

  return (
    <div className="min-h-screen p-4">
      <div className="max-w-4xl mx-auto">
        {/* Success Modal */}
        {showSuccessModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-60">
            <div className="bg-white rounded-lg shadow-lg max-w-md w-full p-6 relative">
              <button
                className="absolute top-2 right-2 text-gray-600 hover:text-black text-xl font-bold"
                onClick={() => setShowSuccessModal(false)}
                aria-label="Close Success Modal"
              >
                &times;
              </button>
              <h2 className="text-2xl font-bold mb-4 text-center text-gold">Claim Submitted Successfully!</h2>
              <div className="text-gray-800 text-base mb-4 text-center">
                Your claim has been submitted for verification.<br />
                <span className="text-sm text-gray-600">Next steps: Track your claim status in your dashboard. You will be notified when the verification is complete.</span>
              </div>
              <div className="flex justify-center">
                <GoldButton onClick={() => setShowSuccessModal(false)}>
                  Close
                </GoldButton>
              </div>
            </div>
          </div>
        )}
        {!submissionResult ? (
          <ClaimForm onSubmit={handleFormSubmit} />
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