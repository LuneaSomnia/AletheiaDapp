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

// AI-powered question generation for claim refinement
export const generateAISuggestions = async (claim: string, context: string): Promise<string[]> => {
  try {
    // In production: 
    // const actor = await getLearningActor();
    // return await actor.generateCriticalQuestions(claim, context);
    
    // Simulate API call delay
    await new Promise(resolve => setTimeout(resolve, 800));
    
    // AI-generated questions based on claim content
    const baseQuestions = [
      "What evidence would support or refute this claim?",
      "Who would benefit from this claim being accepted?",
      "What alternative explanations might exist?",
      "How does this claim align with established knowledge?",
      "What are the potential biases in the source of this claim?"
    ];
    
    // Context-aware questions
    const contextQuestions = context.toLowerCase().includes('health') ? [
      "What do reputable health organizations say about this?",
      "Are there peer-reviewed studies supporting this claim?",
      "What are the potential health risks of this claim?"
    ] : context.toLowerCase().includes('politic') ? [
      "What political motivations might be behind this claim?",
      "How do different political groups interpret this?",
      "What legislation or policies relate to this claim?"
    ] : context.toLowerCase().includes('science') ? [
      "What scientific principles support or contradict this?",
      "Has this claim been tested experimentally?",
      "Are there any scientific papers about this topic?"
    ] : [];
    
    // Claim-type specific questions
    const claimSpecificQuestions = claim.length > 120 ? [
      "Can this claim be broken down into testable components?"
    ] : claim.includes('!') || claim.includes('always') || claim.includes('never') ? [
      "Are there exceptions to this absolute statement?",
      "What evidence would contradict this absolute claim?",
      "How might this claim be rephrased to be more accurate?"
    ] : claim.includes('statistic') ? [
      "What is the source of this statistic?",
      "How was this data collected and analyzed?",
      "Are there other studies with conflicting statistics?"
    ] : [];
    
    // Combine and return unique questions
    return [...baseQuestions, ...contextQuestions, ...claimSpecificQuestions]
      .filter((q, i, arr) => arr.indexOf(q) === i) // Remove duplicates
      .slice(0, 5); // Return max 5 questions
  } catch (error) {
    console.error('AI question generation failed:', error);
    return [
      "What evidence supports this claim?",
      "Who might dispute this claim and why?"
    ];
  }
};

// New function to get popular tags from community
export const getPopularTags = async (): Promise<string[]> => {
  try {
    // In production: 
    // const actor = await getLearningActor();
    // return await actor.getPopularTags();
    
    // Mock popular tags
    return [
      "Health", "Politics", "Science", 
      "Technology", "COVID-19", "Elections",
      "Climate", "Economy", "Education"
    ];
  } catch (error) {
    console.error('Failed to fetch popular tags:', error);
    return [];
  }
};