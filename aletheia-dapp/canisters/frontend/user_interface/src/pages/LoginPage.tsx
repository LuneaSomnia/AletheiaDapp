// src/pages/LoginPage.tsx
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import GlassCard from '../components/GlassCard';
import GoldButton from '../components/GoldButton';
import { useAuth } from '../services/auth';

const LoginPage: React.FC = () => {
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
    <div className="min-h-screen flex items-center justify-center p-4"
         style={{
           background: 'linear-gradient(135deg, #8B0000 0%, #4B0000 100%)',
         }}>
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
          Welcome to Aletheia
        </h1>
        <p className="text-cream text-opacity-80 text-center mb-8">
          The Decentralized Truth Platform
        </p>
        
        <div className="flex flex-col gap-4">
          <GoldButton onClick={handleLogin} disabled={isLoading}>
            {isLoading ? 'Connecting...' : 'Login as User'}
          </GoldButton>
          
          <GoldButton 
            onClick={() => window.location.href = '/aletheian'}
            className="bg-purple-900 border-purple-700 hover:from-purple-900 hover:to-purple-800"
          >
            Login as Aletheian
          </GoldButton>
        </div>
      </GlassCard>
    </div>
  );
};

export default LoginPage;