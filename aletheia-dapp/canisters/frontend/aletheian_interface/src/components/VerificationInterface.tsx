// src/components/VerificationInterface.tsx
import React, { useState, useEffect } from 'react';
import GlassCard from './GlassCard';
import PurpleButton from './PurpleButton';
import { getClaimDetails } from '../services/claims';

interface EvidenceItem {
  source: string;
  url: string;
  summary: string;
  credibility: number;
}

const VerificationInterface: React.FC<{ claimId: string }> = ({ claimId }) => {
  const [claim, setClaim] = useState<any>(null);
  const [evidence, setEvidence] = useState<EvidenceItem[]>([]);
  const [verdict, setVerdict] = useState('');
  const [explanation, setExplanation] = useState('');
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      setIsLoading(true);
      try {
        const data = await getClaimDetails(claimId);
        setClaim(data);
        setEvidence(data.evidence || []);
        setIsLoading(false);
      } catch (error) {
        console.error('Failed to load claim:', error);
        setIsLoading(false);
      }
    };

    fetchData();
  }, [claimId]);

  const handleSubmit = async () => {
    // Submit verification to canister
    console.log('Submitting verification:', { verdict, explanation });
  };

  if (isLoading) {
    return (
      <GlassCard className="p-8">
        <div className="text-center py-12">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-gold mx-auto"></div>
          <p className="mt-4 text-cream">Loading claim details...</p>
        </div>
      </GlassCard>
    );
  }

  return (
    <GlassCard className="p-8">
      <h2 className="text-2xl font-bold text-cream mb-6">Verify Claim: {claimId}</h2>
      
      <div className="mb-6">
        <h3 className="text-xl font-semibold text-cream mb-3">Original Claim</h3>
        <div className="bg-purple-900 bg-opacity-30 border border-gold rounded-lg p-4 text-cream">
          {claim.text}
        </div>
      </div>
      
      <div className="mb-6">
        <h3 className="text-xl font-semibold text-cream mb-3">AI-Gathered Evidence</h3>
        <div className="space-y-4">
          {evidence.map((item, index) => (
            <div key={index} className="bg-purple-900 bg-opacity-20 border border-gold rounded-lg p-4">
              <div className="flex justify-between items-start mb-2">
                <a 
                  href={item.url} 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="text-gold hover:underline"
                >
                  {item.source}
                </a>
                <span className="bg-gold bg-opacity-20 text-gold px-2 py-1 rounded text-sm">
                  Credibility: {item.credibility}/10
                </span>
              </div>
              <p className="text-cream text-opacity-90">{item.summary}</p>
            </div>
          ))}
        </div>
      </div>
      
      <div className="mb-6">
        <h3 className="text-xl font-semibold text-cream mb-3">Your Verdict</h3>
        <select 
          value={verdict}
          onChange={(e) => setVerdict(e.target.value)}
          className="w-full bg-purple-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream"
        >
          <option value="">Select a verdict</option>
          <option value="true">True/Accurate</option>
          <option value="mostly-true">Mostly True</option>
          <option value="half-truth">Half Truth/Cherry-Picking</option>
          <option value="misleading">Misleading Context</option>
          <option value="false">False/Inaccurate</option>
          <option value="mostly-false">Mostly False</option>
          <option value="unsubstantiated">Unsubstantiated/Unproven</option>
          <option value="outdated">Outdated</option>
          <option value="satire">Satire/Parody</option>
          <option value="opinion">Opinion/Commentary</option>
        </select>
      </div>
      
      <div className="mb-8">
        <h3 className="text-xl font-semibold text-cream mb-3">Explanation</h3>
        <textarea
          value={explanation}
          onChange={(e) => setExplanation(e.target.value)}
          rows={6}
          className="w-full bg-purple-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream"
          placeholder="Explain your reasoning and cite key evidence..."
        />
      </div>
      
      <div className="flex gap-4">
        <PurpleButton 
          onClick={handleSubmit} 
          disabled={!verdict || !explanation.trim()}
          className="flex-1 py-4"
        >
          Submit Verification
        </PurpleButton>
        
        <PurpleButton 
          onClick={() => {}} 
          className="flex-1 py-4 bg-purple-800 border-purple-600"
        >
          Request Escalation
        </PurpleButton>
      </div>
    </GlassCard>
  );
};

export default VerificationInterface;