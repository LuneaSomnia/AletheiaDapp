// src/components/QuestionMirror.tsx
import React from 'react';
import GlassCard from './GlassCard';

interface QuestionMirrorProps {
  questions: string[];
  claimId: string;
}

const QuestionMirror: React.FC<QuestionMirrorProps> = ({ questions, claimId }) => {
  return (
    <GlassCard className="p-6">
      <h3 className="text-xl font-semibold text-gold mb-4">Question Mirror</h3>
      <p className="text-cream mb-4">
        To better understand claims like this, consider asking these questions:
      </p>
      
      <ul className="space-y-3">
        {questions.map((question, index) => (
          <li key={index} className="flex items-start">
            <span className="text-gold font-bold mr-2 mt-1">•</span>
            <span className="text-cream">{question}</span>
          </li>
        ))}
      </ul>
      
      <div className="mt-6">
        <button className="text-gold hover:underline">
          Learn more about asking good questions
        </button>
      </div>
    </GlassCard>
  );
};

export default QuestionMirror;