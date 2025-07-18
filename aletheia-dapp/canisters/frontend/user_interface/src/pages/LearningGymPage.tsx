// src/pages/LearningGymPage.tsx
import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import CriticalThinkingExercise from '../components/CriticalThinkingExercise';
import GlassCard from '../components/GlassCard';
import GoldButton from '../components/GoldButton';
import { getLearningModules, getExercise, completeExercise } from '../services/learning';

const badgeList = [
  { id: 'first', label: 'First Exercise', condition: (completed: number) => completed >= 1 },
  { id: 'tenlp', label: '10 LP', condition: (points: number) => points >= 10 },
  { id: 'all', label: 'All Modules', condition: (completed: number, total: number) => completed === total },
];

const LearningGymPage: React.FC = () => {
  const [modules, setModules] = useState<any[]>([]);
  const [currentExercise, setCurrentExercise] = useState<any>(null);
  const [completedExercises, setCompletedExercises] = useState<string[]>([]);
  const [pointsEarned, setPointsEarned] = useState<number | null>(null);
  const [totalPoints, setTotalPoints] = useState<number>(0);
  const [isLoading, setIsLoading] = useState(true);
  const [feedbackMsg, setFeedbackMsg] = useState<string | null>(null);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchModules = async () => {
      setIsLoading(true);
      try {
        const data = await getLearningModules();
        setModules(data);
        // Calculate total points and completed
        let total = 0;
        let completed = 0;
        data.forEach((m: any) => {
          if (m.completed) {
            total += m.points;
            completed++;
          }
        });
        setTotalPoints(total);
        setCompletedExercises(data.filter((m: any) => m.completed).map((m: any) => m.id));
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
      setFeedbackMsg(null);
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
        let feedback: string | null = null;
        if ('feedback' in result && typeof result.feedback === 'string' && result.feedback) {
          feedback = result.feedback;
        } else if ('correct' in result) {
          feedback = result.correct ? 'Correct! Well done.' : 'Incorrect. Review the explanation.';
        } else {
          feedback = 'Exercise submitted.';
        }
        setFeedbackMsg(feedback);
        setCompletedExercises([...completedExercises, currentExercise.id]);
        setTotalPoints(tp => tp + (result.pointsEarned || 0));
      } catch (error) {
        console.error('Failed to submit exercise:', error);
      } finally {
        setIsLoading(false);
      }
    }
  };

  const totalModules = modules.length;
  const completedCount = completedExercises.length;
  const progressPercent = totalModules > 0 ? Math.round((completedCount / totalModules) * 100) : 0;
  const earnedBadges = badgeList.filter(b => b.condition(completedCount, totalModules) || b.condition(totalPoints, totalModules));

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

        {/* Gamification UI: Points, Progress, Badges */}
        <div className="mb-8">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 mb-2">
            <div className="flex items-center gap-4">
              <span className="text-gold text-xl font-bold">Total Points: {totalPoints} LP</span>
              <div className="flex gap-2">
                {earnedBadges.map(badge => (
                  <span key={badge.id} className="bg-gold text-red-900 px-3 py-1 rounded-full font-semibold shadow">🏅 {badge.label}</span>
                ))}
              </div>
            </div>
            <div className="flex-1">
              <div className="w-full bg-red-900 bg-opacity-20 rounded-full h-4 mt-2 md:mt-0">
                <div
                  className="bg-gold h-4 rounded-full"
                  style={{ width: `${progressPercent}%` }}
                ></div>
              </div>
              <div className="text-cream text-xs mt-1 text-right">{completedCount}/{totalModules} modules completed</div>
            </div>
          </div>
        </div>
        {currentExercise ? (
          <>
            {pointsEarned !== null ? (
              <GlassCard className="p-8 text-center">
                <h2 className="text-2xl font-bold text-cream mb-4">Exercise Completed!</h2>
                <div className="text-5xl text-gold mb-4">✓</div>
                <p className="text-3xl text-gold mb-2">+{pointsEarned} LP</p>
                <p className="text-cream mb-6">You've earned {pointsEarned} Learning Points</p>
                {feedbackMsg && <div className="mb-4 text-lg text-cream font-semibold">{feedbackMsg}</div>}
                <GoldButton 
                  onClick={() => setCurrentExercise(null)}
                  className="w-full max-w-md mx-auto"
                >
                  Continue Learning
                </GoldButton>
              </GlassCard>
            ) : (
              <>
                {/* AI-Driven Interactive Learning: scenario/mock article/quiz/feedback */}
                <GlassCard className="p-8 mb-6">
                  <h2 className="text-2xl font-bold text-gold mb-4">Scenario</h2>
                  <div className="bg-red-900 bg-opacity-20 rounded-lg p-4 mb-4 text-cream">
                    {currentExercise.scenario || 'Read the following scenario and answer the questions below.'}
                  </div>
                  {currentExercise.mockArticle && (
                    <div className="bg-yellow-900 bg-opacity-20 border-l-4 border-gold rounded-lg p-4 mb-4 text-cream">
                      <h3 className="text-lg font-semibold text-gold mb-2">Mock Article</h3>
                      <div>{currentExercise.mockArticle}</div>
                    </div>
                  )}
                </GlassCard>
                <CriticalThinkingExercise 
                  exercise={currentExercise} 
                  onSubmit={handleSubmitExercise} 
                />
                {feedbackMsg && <div className="mt-4 text-lg text-cream font-semibold text-center">{feedbackMsg}</div>}
              </>
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