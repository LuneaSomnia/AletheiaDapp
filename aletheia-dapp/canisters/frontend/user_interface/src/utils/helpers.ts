// src/utils/helpers.ts

// Format date to readable string
export const formatDate = (timestamp: number): string => {
  const date = new Date(timestamp);
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
};

// Truncate text with ellipsis
export const truncateText = (text: string, maxLength: number): string => {
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength) + '...';
};

// Calculate time difference for claims
export const timeSinceSubmission = (submittedAt: number): string => {
  const now = Date.now();
  const diffMs = now - submittedAt;
  const diffMins = Math.floor(diffMs / 60000);
  
  if (diffMins < 1) return 'Just now';
  if (diffMins < 60) return `${diffMins} min ago`;
  
  const diffHours = Math.floor(diffMins / 60);
  if (diffHours < 24) return `${diffHours} hr ago`;
  
  const diffDays = Math.floor(diffHours / 24);
  return `${diffDays} days ago`;
};

// Generate AI questions for claim
export const generateAIQuestions = (claim: string): { question: string; reason: string }[] => {
  const questions = [];
  
  if (claim.toLowerCase().includes("cure") || claim.toLowerCase().includes("health")) {
    questions.push({
      question: "What scientific evidence from reputable health organizations supports this claim?",
      reason: "Medical claims require scientific backing from authoritative sources."
    });
  }
  
  if (claim.toLowerCase().includes("study") || claim.toLowerCase().includes("research")) {
    questions.push({
      question: "Has this study been peer-reviewed and published in a reputable journal?",
      reason: "Peer review is essential for validating scientific research."
    });
  }
  
  questions.push({
    question: "Who is making this claim, and what are their qualifications or potential biases?",
    reason: "Source credibility is crucial for evaluating information."
  });
  
  questions.push({
    question: "Are there multiple independent sources confirming this information?",
    reason: "Corroboration from diverse sources increases reliability."
  });
  
  return questions.slice(0, 3);
};

// Calculate user accuracy rating
export const calculateAccuracy = (
  correctClaims: number, 
  totalClaims: number
): number => {
  if (totalClaims === 0) return 0;
  return Math.round((correctClaims / totalClaims) * 100);
};

// Format numbers with commas
export const formatNumber = (num: number): string => {
  return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
};