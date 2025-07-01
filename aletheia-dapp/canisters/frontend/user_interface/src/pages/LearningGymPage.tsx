// src/pages/LearningGymPage.tsx
import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import CriticalThinkingExercise from '../components/CriticalThinkingExercise';
import GlassCard from '../components/GlassCard';
import GoldButton from '../components/GoldButton';
import { getLearningModules, getExercise, completeExercise } from '../services/learning';

const LearningGymPage: React.FC = () => {
  const [modules, setModules] = useState<any[]>([]);
  const [currentExercise, setCurrentExercise] = useState<any>(null);
  const [completedExercises, setCompletedExercises] = useState<string[]>([]);
  const [pointsEarned, setPointsEarned] = useState<number | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchModules = async () => {
      setIsLoading(true);
      try {
        const data = await getLearningModules();
        setModules(data);
      } catch (error) {
        console.error('Failed to fetch modules:', error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchModules();
  }, []);

  const handleStartExercise = async (exerciseId: string) => {
    setIsLoading(true);
    try {
      const exercise = await getExercise(exerciseId);
      setCurrentExercise(exercise);
      setPointsEarned(null);
    } catch (error) {
      console.error('Failed to load exercise:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSubmitExercise = async (answers: number[]) => {
    if (currentExercise) {
      setIsLoading(true);
      try {
        const result = await completeExercise(currentExercise.id, answers);
        setPointsEarned(result.pointsEarned);
        setCompletedExercises([...completedExercises, currentExercise.id]);
      } catch (error) {
        console.error('Failed to submit exercise:', error);
      } finally {
        setIsLoading(false);
      }
    }
  };

  if (isLoading && !currentExercise) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <GlassCard className="p-8 text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-gold mx-auto"></div>
          <p className="mt-4 text-cream">Loading learning modules...</p>
        </GlassCard>
      </div>
    );
  }

  return (
    <div className="min-h-screen p-4">
      <div className="max-w-4xl mx-auto">
        <GoldButton 
          onClick={() => navigate('/dashboard')}
          className="mb-6"
        >
          &larr; Back to Dashboard
        </GoldButton>
        
        {currentExercise ? (
          <>
            {pointsEarned !== null ? (
              <GlassCard className="p-8 text-center">
                <h2 className="text-2xl font-bold text-cream mb-4">Exercise Completed!</h2>
                <div className="text-5xl text-gold mb-4">✓</div>
                <p className="text-3xl text-gold mb-2">+{pointsEarned} LP</p>
                <p className="text-cream mb-6">You've earned {pointsEarned} Learning Points</p>
                <GoldButton 
                  onClick={() => setCurrentExercise(null)}
                  className="w-full max-w-md mx-auto"
                >
                  Continue Learning
                </GoldButton>
              </GlassCard>
            ) : (
              <CriticalThinkingExercise 
                exercise={currentExercise} 
                onSubmit={handleSubmitExercise} 
              />
            )}
          </>
        ) : (
          <GlassCard className="p-8">
            <h1 className="text-3xl font-bold text-cream mb-6">Critical Thinking Gym</h1>
            <p className="text-cream mb-8">
              Improve your ability to identify misinformation through these interactive exercises.
              Earn Learning Points (LP) for each completed module!
            </p>
            
            <div className="space-y-6">
              {modules.map((module) => (
                <div 
                  key={module.id} 
                  className={`p-6 rounded-lg border ${
                    module.completed 
                      ? 'border-green-500 bg-green-500 bg-opacity-10' 
                      : 'border-gold bg-red-900 bg-opacity-20 hover:bg-red-900 hover:bg-opacity-30'
                  } transition-all cursor-pointer`}
                  onClick={() => handleStartExercise(module.id)}
                >
                  <div className="flex justify-between items-center">
                    <div>
                      <h2 className="text-xl font-semibold text-cream mb-1">{module.title}</h2>
                      <p className="text-cream text-opacity-80">{module.description}</p>
                    </div>
                    <div className="flex items-center gap-3">
                      <span className="bg-gold bg-opacity-20 text-gold px-3 py-1 rounded-full">
                        +{module.points} LP
                      </span>
                      {module.completed && (
                        <span className="bg-green-500 bg-opacity-20 text-green-300 px-3 py-1 rounded-full">
                          Completed
                        </span>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </GlassCard>
        )}
      </div>
    </div>
  );
};

export default LearningGymPage;