// src/components/QuestionMirror.tsx
import React from 'react';
import GlassCard from './GlassCard';

interface QuestionMirrorProps {
  questions: string[];
  claimId?: string;
  isLoading?: boolean;
}

const QuestionMirror: React.FC<QuestionMirrorProps> = ({ 
  questions, 
  claimId,
  isLoading = false
}) => {
  if (!questions.length && !isLoading) return null;

  return (
    <GlassCard className="p-6 question-mirror">
      <div className="flex items-center mb-4">
        <img 
          src="/assets/icons/torch.svg" 
          alt="Critical Thinking" 
          className="w-6 h-6 mr-2"
        />
        <h3 className="text-xl font-semibold text-gold">Critical Thinking Guide</h3>
      </div>
      
      {isLoading ? (
        <div className="text-center py-4">
          <div className="animate-pulse flex flex-col space-y-3">
            <div className="h-4 bg-gold bg-opacity-20 rounded w-5/6"></div>
            <div className="h-4 bg-gold bg-opacity-20 rounded w-3/4"></div>
            <div className="h-4 bg-gold bg-opacity-20 rounded w-4/5"></div>
          </div>
        </div>
      ) : questions.length > 0 ? (
        <>
          <p className="text-cream mb-4">
            Consider these questions to strengthen your claim:
          </p>
          
          <ul className="space-y-3">
            {questions.map((question, index) => (
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
          <button className="text-gold hover:underline">
            Learn more about asking good questions
          </button>
        </div>
      )}
    </GlassCard>
  );
};

export default QuestionMirror;