import React from 'react';
import { useNavigate } from 'react-router-dom';
import GlassCard from '../components/GlassCard';
import GoldButton from '../components/GoldButton';

const NotFoundPage: React.FC = () => {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-gradient-to-br from-red-900 via-red-800 to-red-900 flex items-center justify-center p-4">
      <GlassCard className="max-w-2xl w-full p-8 text-center">
        <div className="text-8xl mb-6">🔍</div>
        <h1 className="text-4xl font-bold text-gold mb-4">404 - Page Not Found</h1>
        <p className="text-xl text-cream mb-6">
          The page you're looking for seems to have wandered off into the realm of misinformation.
        </p>
        <p className="text-cream mb-8">
          Don't worry! Let's get you back on track to finding the truth.
        </p>
        
        <div className="flex flex-col sm:flex-row gap-4 justify-center">
          <GoldButton onClick={() => navigate('/dashboard')}>
            Go to Dashboard
          </GoldButton>
          <GoldButton onClick={() => navigate('/')} className="bg-transparent border-gold text-gold hover:bg-gold hover:text-red-900">
            Go Home
          </GoldButton>
        </div>
      </GlassCard>
    </div>
  );
};

export default NotFoundPage; 