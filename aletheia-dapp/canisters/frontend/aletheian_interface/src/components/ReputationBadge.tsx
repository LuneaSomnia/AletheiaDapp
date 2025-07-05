// src/components/ReputationBadge.tsx
import React from 'react';
import GlassCard from './GlassCard';

const ReputationBadge: React.FC<{ xp: number; rank: string; badges: string[] }> = ({ 
  xp, 
  rank, 
  badges 
}) => {
  const getRankColor = () => {
    switch (rank) {
      case 'Master Aletheian': return 'from-purple-900 to-black';
      case 'Expert Aletheian': return 'from-purple-800 to-purple-900';
      case 'Senior Aletheian': return 'from-purple-700 to-purple-800';
      case 'Associate Aletheian': return 'from-blue-600 to-blue-700';
      case 'Junior Aletheian': return 'from-green-600 to-green-700';
      default: return 'from-gray-600 to-gray-700';
    }
  };

  return (
    <GlassCard className="p-6">
      <div className="flex items-center mb-6">
        <div className={`bg-gradient-to-br ${getRankColor()} w-24 h-24 rounded-full flex items-center justify-center mr-6`}>
          <span className="text-3xl font-bold text-gold">{xp}</span>
        </div>
        <div>
          <h3 className="text-2xl font-bold text-cream">{rank}</h3>
          <p className="text-gold">Reputation Points</p>
        </div>
      </div>
      
      <div>
        <h4 className="text-lg font-semibold text-cream mb-3">Expertise Badges</h4>
        <div className="flex flex-wrap gap-2">
          {badges.map((badge, index) => (
            <span 
              key={index} 
              className="bg-gold bg-opacity-20 text-gold px-3 py-1 rounded-full text-sm"
            >
              {badge}
            </span>
          ))}
        </div>
      </div>
    </GlassCard>
  );
};

export default ReputationBadge;