// src/components/QuestionMirror.tsx
import React, { useState, useEffect } from 'react';
import GlassCard from './GlassCard';
import GoldButton from './GoldButton';

interface QuestionMirrorProps {
  questions: string[];
  claimId?: string;
  isLoading?: boolean;
  claimText?: string;
  context?: string;
}

const QuestionMirror: React.FC<QuestionMirrorProps> = ({ 
  questions, 
  claimId,
  isLoading = false,
  claimText,
  context
}) => {
  const [aiQuestions, setAiQuestions] = useState<string[]>([]);
  const [isGeneratingQuestions, setIsGeneratingQuestions] = useState(false);
  const [showLearningModal, setShowLearningModal] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Generate AI questions if not provided
  useEffect(() => {
    const generateQuestions = async () => {
      if (!questions.length && claimText && !isGeneratingQuestions) {
        setIsGeneratingQuestions(true);
        setError(null);
        try {
          // Import the AI service function
          const { generateAISuggestions } = await import('../services/learning');
          const suggestions = await generateAISuggestions(claimText, context || '');
          setAiQuestions(suggestions);
        } catch (err) {
          console.error('Failed to generate AI questions:', err);
          setError('Failed to generate questions. Please try again.');
        } finally {
          setIsGeneratingQuestions(false);
        }
      }
    };

    generateQuestions();
  }, [questions.length, claimText, context, isGeneratingQuestions]);

  const displayQuestions = questions.length > 0 ? questions : aiQuestions;
  const isActuallyLoading = isLoading || isGeneratingQuestions;

  if (!displayQuestions.length && !isActuallyLoading && !error) return null;

  return (
    <>
      <GlassCard className="p-6 question-mirror">
        <div className="flex items-center mb-4">
          <img 
            src="/assets/icons/torch.svg" 
            alt="Critical Thinking" 
            className="w-6 h-6 mr-2"
          />
          <h3 className="text-xl font-semibold text-gold">Critical Thinking Guide</h3>
        </div>
        
        {isActuallyLoading ? (
          <div className="text-center py-4">
            <div className="animate-pulse flex flex-col space-y-3">
              <div className="h-4 bg-gold bg-opacity-20 rounded w-5/6"></div>
              <div className="h-4 bg-gold bg-opacity-20 rounded w-3/4"></div>
              <div className="h-4 bg-gold bg-opacity-20 rounded w-4/5"></div>
            </div>
            <p className="text-cream text-sm mt-2">Generating AI-powered questions...</p>
          </div>
        ) : error ? (
          <div className="text-center py-4">
            <p className="text-red-400 mb-2">{error}</p>
            <GoldButton 
              onClick={() => window.location.reload()} 
              className="text-sm"
            >
              Retry
            </GoldButton>
          </div>
        ) : displayQuestions.length > 0 ? (
          <>
            <p className="text-cream mb-4">
              Consider these questions to strengthen your claim:
            </p>
            
            <ul className="space-y-3">
              {displayQuestions.map((question, index) => (
                <li key={index} className="flex items-start">
                  <span className="text-gold font-bold mr-2 mt-1">•</span>
                  <span className="text-cream">{question}</span>
                </li>
              ))}
            </ul>
          </>
        ) : null}
        
        {claimId && (
          <div className="mt-6">
            <button 
              className="text-gold hover:underline"
              onClick={() => setShowLearningModal(true)}
            >
              Learn more about asking good questions
            </button>
          </div>
        )}
      </GlassCard>

      {/* Learning Modal */}
      {showLearningModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-60">
          <div className="bg-white rounded-lg shadow-lg max-w-2xl w-full p-6 relative max-h-[80vh] overflow-y-auto">
            <button
              className="absolute top-2 right-2 text-gray-600 hover:text-black text-xl font-bold"
              onClick={() => setShowLearningModal(false)}
              aria-label="Close Learning Modal"
            >
              &times;
            </button>
            <h2 className="text-2xl font-bold mb-4 text-center text-gold">How to Ask Good Questions</h2>
            <div className="text-gray-800 space-y-4">
              <div>
                <h3 className="text-lg font-semibold text-gold mb-2">1. Question the Source</h3>
                <p>Who is making this claim? What are their credentials? Do they have a vested interest?</p>
              </div>
              <div>
                <h3 className="text-lg font-semibold text-gold mb-2">2. Look for Evidence</h3>
                <p>What evidence supports this claim? Is it recent, relevant, and from reliable sources?</p>
              </div>
              <div>
                <h3 className="text-lg font-semibold text-gold mb-2">3. Consider Alternative Views</h3>
                <p>What do experts say? Are there conflicting opinions or studies?</p>
              </div>
              <div>
                <h3 className="text-lg font-semibold text-gold mb-2">4. Check for Logical Fallacies</h3>
                <p>Does the argument use emotional appeals, false analogies, or other logical errors?</p>
              </div>
              <div>
                <h3 className="text-lg font-semibold text-gold mb-2">5. Verify Context</h3>
                <p>Is the claim being presented in its proper context? Are important details being omitted?</p>
              </div>
            </div>
            <div className="mt-6 flex justify-center">
              <GoldButton onClick={() => setShowLearningModal(false)}>
                Got it!
              </GoldButton>
            </div>
          </div>
        </div>
      )}
    </>
  );
};

export default QuestionMirror;