// src/pages/ClaimVerificationPage.tsx
import React from 'react';
import { useParams } from 'react-router-dom';
import VerificationInterface from '../components/VerificationInterface';

const ClaimVerificationPage: React.FC = () => {
  const { claimId } = useParams<{ claimId: string }>();

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

  return (
    <div className="min-h-screen p-4">
      <div className="max-w-4xl mx-auto">
        <VerificationInterface claimId={claimId} />
      </div>
    </div>
  );
};

export default ClaimVerificationPage;