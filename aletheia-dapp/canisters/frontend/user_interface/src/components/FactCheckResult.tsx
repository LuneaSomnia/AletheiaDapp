// src/components/FactCheckResult.tsx
import React from 'react';
import GlassCard from './GlassCard';

interface EvidenceItem {
  source: string;
  url: string;
  content: string;
}

interface FactCheckResultProps {
  result: {
    id: string;
    claim: string;
    verdict: string;
    summary: string;
    evidence: EvidenceItem[];
    aletheiansVerified: string;
    submittedAt: string;
    verifiedAt: string;
  };
}

const FactCheckResult: React.FC<FactCheckResultProps> = ({ result }) => {
  const verdictColor = result.verdict === 'FALSE' ? 'bg-red-500' : 
                      result.verdict === 'TRUE' ? 'bg-green-500' : 
                      'bg-orange-500';
  
  return (
    <GlassCard className="p-8">
      <div className="mb-6">
        <h1 className={`text-3xl font-bold ${verdictColor} text-white px-4 py-2 rounded-lg inline-block`}>
          {result.verdict}: {result.claim}
        </h1>
      </div>
      
      <div className="mb-8">
        <h2 className="text-xl font-semibold text-cream mb-3">Summary</h2>
        <p className="text-cream">{result.summary}</p>
      </div>
      
      <div className="mb-8">
        <h2 className="text-xl font-semibold text-cream mb-3">Evidence</h2>
        <div className="space-y-4">
          {result.evidence.map((item, index) => (
            <div key={index} className="bg-red-900 bg-opacity-20 border border-gold rounded-lg p-4">
              <div className="flex justify-between items-start mb-2">
                <a 
                  href={item.url} 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="text-gold hover:underline"
                >
                  {item.source}
                </a>
              </div>
              <p className="text-cream text-opacity-90">{item.content}</p>
            </div>
          ))}
        </div>
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-red-900 bg-opacity-20 rounded-lg p-4">
          <h3 className="text-lg font-semibold text-cream mb-2">Verification Details</h3>
          <p className="text-cream">Verified by: {result.aletheiansVerified}</p>
          <p className="text-cream">Submitted: {new Date(result.submittedAt).toLocaleString()}</p>
          <p className="text-cream">Verified: {new Date(result.verifiedAt).toLocaleString()}</p>
        </div>
        
        <div className="bg-red-900 bg-opacity-20 rounded-lg p-4">
          <h3 className="text-lg font-semibold text-cream mb-2">Share This Result</h3>
          <div className="flex gap-3 mt-3">
            <button className="bg-blue-500 text-white px-4 py-2 rounded-lg">Twitter</button>
            <button className="bg-gray-800 text-white px-4 py-2 rounded-lg">Copy Link</button>
            <button className="bg-red-600 text-white px-4 py-2 rounded-lg">Report Issue</button>
          </div>
        </div>
      </div>
    </GlassCard>
  );
};

export default FactCheckResult;