// src/pages/FinancePage.tsx
import React, { useEffect, useState } from 'react';
import FinanceDashboard from '../components/FinanceDashboard';
import { useAuth } from '../services/auth';
import { getAletheianEarnings } from '../services/finance';
import GlassCard from '../components/GlassCard';

const FinancePage: React.FC = () => {
  const { user } = useAuth();
  const [earnings, setEarnings] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchEarnings = async () => {
      if (user) {
        setIsLoading(true);
        try {
          const data = await getAletheianEarnings(user.principal);
          setEarnings(data);
        } catch (error) {
          console.error('Failed to fetch earnings:', error);
        } finally {
          setIsLoading(false);
        }
      }
    };

    fetchEarnings();
  }, [user]);

  if (!user) return null;

  return (
    <div className="min-h-screen p-4">
      <div className="max-w-6xl mx-auto">
        <h1 className="text-3xl font-bold text-cream mb-8">Finance Dashboard</h1>
        
        {isLoading ? (
          <div className="text-center py-12">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-gold mx-auto"></div>
            <p className="mt-4 text-cream">Loading financial data...</p>
          </div>
        ) : earnings ? (
          <FinanceDashboard earnings={earnings} />
        ) : (
          <GlassCard className="p-8">
            <p className="text-cream text-center">No financial data available</p>
          </GlassCard>
        )}
      </div>
    </div>
  );
};

export default FinancePage;