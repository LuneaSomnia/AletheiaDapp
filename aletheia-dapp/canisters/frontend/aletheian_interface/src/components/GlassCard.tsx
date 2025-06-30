// src/components/GlassCard.tsx
import React from 'react';

interface GlassCardProps {
  children: React.ReactNode;
  className?: string;
}

const GlassCard: React.FC<GlassCardProps> = ({ children, className = '' }) => {
  return (
    <div className={`bg-opacity-20 bg-purple-900 backdrop-blur-lg 
                    border border-gold border-opacity-30 
                    rounded-xl shadow-xl p-6 ${className}`}
         style={{
           background: 'rgba(75, 0, 130, 0.15)',
           boxShadow: '0 8px 32px rgba(75, 0, 130, 0.37)'
         }}>
      {children}
    </div>
  );
};

export default GlassCard;