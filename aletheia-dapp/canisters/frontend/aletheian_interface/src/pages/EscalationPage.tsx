// src/pages/EscalationPage.tsx
import React from 'react';
import { useParams } from 'react-router-dom';
import EscalationReview from '../components/EscalationReview';

const EscalationPage: React.FC = () => {
  const { claimId } = useParams<{ claimId: string }>();

  return (
    <div className="min-h-screen p-4">
      <div className="max-w-4xl mx-auto">
        <EscalationReview />
      </div>
    </div>
  );
};

export default EscalationPage;