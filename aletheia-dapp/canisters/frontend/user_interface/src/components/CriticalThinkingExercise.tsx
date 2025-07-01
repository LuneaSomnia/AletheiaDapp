// src/components/CriticalThinkingExercise.tsx
import React, { useState } from 'react';
import GlassCard from './GlassCard';
import GoldButton from './GoldButton';

interface ExerciseProps {
  exercise: {
    id: string;
    title: string;
    content: string;
    questions: {
      id: string;
      text: string;
      options: string[];
    }[];
  };
  onSubmit: (answers: number[]) => void;
}

const CriticalThinkingExercise: React.FC<ExerciseProps> = ({ exercise, onSubmit }) => {
  const [answers, setAnswers] = useState<number[]>(Array(exercise.questions.length).fill(-1));
  
  const handleOptionSelect = (questionIndex: number, optionIndex: number) => {
    const newAnswers = [...answers];
    newAnswers[questionIndex] = optionIndex;
    setAnswers(newAnswers);
  };
  
  const handleSubmit = () => {
    if (answers.every(a => a !== -1)) {
      onSubmit(answers);
    }
  };
  
  return (
    <GlassCard className="p-8">
      <h2 className="text-2xl font-bold text-cream mb-4">{exercise.title}</h2>
      
      <div className="bg-red-900 bg-opacity-30 border border-gold rounded-lg p-4 mb-6">
        <p className="text-cream">{exercise.content}</p>
      </div>
      
      <div className="space-y-6">
        {exercise.questions.map((question, qIndex) => (
          <div key={question.id} className="mb-6">
            <h3 className="text-lg font-semibold text-cream mb-3">{qIndex + 1}. {question.text}</h3>
            <div className="space-y-2">
              {question.options.map((option, oIndex) => (
                <div 
                  key={oIndex} 
                  className={`p-3 rounded-lg cursor-pointer transition-all ${
                    answers[qIndex] === oIndex 
                      ? 'bg-gold bg-opacity-30 border-2 border-gold' 
                      : 'bg-red-900 bg-opacity-20 hover:bg-red-900 hover:bg-opacity-30'
                  }`}
                  onClick={() => handleOptionSelect(qIndex, oIndex)}
                >
                  <p className="text-cream">{option}</p>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
      
      <GoldButton 
        onClick={handleSubmit} 
        disabled={answers.some(a => a === -1)}
        className="w-full py-4 mt-4"
      >
        Submit Answers
      </GoldButton>
    </GlassCard>
  );
};

export default CriticalThinkingExercise;