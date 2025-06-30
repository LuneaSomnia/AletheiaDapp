// src/pages/AletheianLogin.tsx
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import GlassCard from '../components/GlassCard';
import PurpleButton from '../components/PurpleButton';
import { useAuth } from '../services/auth';

const AletheianLogin: React.FC = () => {
  const [isLoading, setIsLoading] = useState(false);
  const navigate = useNavigate();
  const { authenticate } = useAuth();

  const handleLogin = async () => {
    setIsLoading(true);
    try {
      await authenticate();
      navigate('/dashboard');
    } catch (error) {
      console.error('Login failed:', error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <div className="absolute inset-0 overflow-hidden">
        {[...Array(15)].map((_, i) => (
          <div 
            key={i} 
            className="absolute opacity-10"
            style={{
              top: `${Math.random() * 100}%`,
              left: `${Math.random() * 100}%`,
              width: `${Math.random() * 100 + 50}px`,
              height: `${Math.random() * 100 + 50}px`,
              backgroundImage: `url(/assets/icons/${['torch', 'scales', 'magnifier', 'computer'][i % 4]}.svg)`,
              backgroundSize: 'contain',
              backgroundRepeat: 'no-repeat',
              transform: `rotate(${Math.random() * 360}deg)`
            }} 
          />
        ))}
      </div>

      <GlassCard className="w-full max-w-md z-10">
        <h1 className="text-3xl font-bold text-center text-cream mb-2">
          Aletheian Portal
        </h1>
        <p className="text-cream text-opacity-80 text-center mb-8">
          Fact-Checking Platform
        </p>
        
        <PurpleButton 
          onClick={handleLogin} 
          disabled={isLoading}
          className="w-full py-4 text-xl"
        >
          {isLoading ? 'Authenticating...' : 'Login with Internet Identity'}
        </PurpleButton>
      </GlassCard>
    </div>
  );
};

export default AletheianLogin;