// src/pages/ClaimResultPage.tsx
import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import FactCheckResult from '../components/FactCheckResult';
import GlassCard from '../components/GlassCard';
import { getClaimResult } from '../services/claims';

const ClaimResultPage: React.FC = () => {
  const { claimId } = useParams<{ claimId: string }>();
  const [result, setResult] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchClaimResult = async () => {
      if (claimId) {
        setIsLoading(true);
        try {
          const data = await getClaimResult(claimId);
          setResult(data);
        } catch (err) {
          setError('Failed to load claim result');
          console.error(err);
        } finally {
          setIsLoading(false);
        }
      }
    };

    fetchClaimResult();
  }, [claimId]);

  if (!claimId) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <GlassCard className="p-8">
          <h2 className="text-2xl font-bold text-cream mb-4">Error</h2>
          <p className="text-cream">Claim ID is missing</p>
        </GlassCard>
      </div>
    );
  }

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <GlassCard className="p-8 text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-gold mx-auto"></div>
          <p className="mt-4 text-cream">Loading claim result...</p>
        </GlassCard>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <GlassCard className="p-8">
          <h2 className="text-2xl font-bold text-cream mb-4">Error</h2>
          <p className="text-cream">{error}</p>
          <GoldButton onClick={() => navigate('/dashboard')} className="mt-4">
            Return to Dashboard
          </GoldButton>
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
        
        {result ? (
          <FactCheckResult result={result} />
        ) : (
          <GlassCard className="p-8 text-center">
            <h2 className="text-2xl font-bold text-cream mb-4">Result Not Found</h2>
            <p className="text-cream">The requested claim result could not be found.</p>
          </GlassCard>
        )}
      </div>
    </div>
  );
};

export default ClaimResultPage;