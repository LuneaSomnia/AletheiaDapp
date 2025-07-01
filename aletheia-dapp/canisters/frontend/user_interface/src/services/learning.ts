// src/services/learning.ts
import { getLearningActor } from './canisters';

export const getLearningModules = async () => {
  // In production: call canister method
  return [
    {
      id: "module-1",
      title: "Identifying Misinformation",
      description: "Learn to spot common characteristics of false information",
      points: 20,
      completed: true
    },
    {
      id: "module-2",
      title: "Source Credibility",
      description: "Evaluate the reliability of information sources",
      points: 30,
      completed: false
    },
    {
      id: "module-3",
      title: "Logical Fallacies",
      description: "Recognize common patterns of flawed reasoning",
      points: 25,
      completed: false
    }
  ];
};

export const getExercise = async (exerciseId: string) => {
  // In production: call canister method
  return {
    id: exerciseId,
    title: "Spot the Red Flags",
    content: `A social media post claims: "Miracle cure discovered! Doctors hate this one trick for curing COVID! No scientific studies needed because big pharma is hiding the truth!"`,
    questions: [
      {
        id: "q1",
        text: "What emotional language is used in this claim?",
        options: ["Miracle cure", "Doctors hate this", "Big pharma hiding truth", "All of the above"],
        correctAnswer: 3
      },
      {
        id: "q2",
        text: "What is missing from this claim that would make it more credible?",
        options: ["Scientific references", "Emotional language", "Celebrity endorsement", "Exclamation points"],
        correctAnswer: 0
      }
    ]
  };
};

export const completeExercise = async (exerciseId: string, answers: number[]) => {
  const actor = await getLearningActor();
  // In production: await actor.completeExercise(exerciseId, answers);
  return {
    success: true,
    pointsEarned: 15,
    correctAnswers: answers.length // Mocking all correct
  };
};