// src/components/FactCheckResult.tsx
import React, { useState } from 'react';
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

const verdictIcon = (verdict: string) => {
  if (verdict === 'TRUE') return <span className="inline-block align-middle text-green-500 mr-2">✔️</span>;
  if (verdict === 'FALSE') return <span className="inline-block align-middle text-red-500 mr-2">❌</span>;
  return <span className="inline-block align-middle text-orange-400 mr-2">⚠️</span>;
};

const FactCheckResult: React.FC<FactCheckResultProps> = ({ result }) => {
  const [expandedEvidence, setExpandedEvidence] = useState<number | null>(null);
  const [feedback, setFeedback] = useState<null | 'up' | 'down'>(null);
  const verdictColor = result.verdict === 'FALSE' ? 'bg-red-700' : 
                      result.verdict === 'TRUE' ? 'bg-green-700' : 
                      'bg-orange-600';
  const verdictTextColor = result.verdict === 'FALSE' ? 'text-red-100' : 
                          result.verdict === 'TRUE' ? 'text-green-100' : 
                          'text-orange-100';
  return (
    <GlassCard className="p-8">
      <div className="mb-10 text-center">
        <div className={`inline-flex items-center px-8 py-6 rounded-3xl shadow-2xl ${verdictColor} ${verdictTextColor} text-5xl font-extrabold tracking-widest border-8 border-gold drop-shadow-xl tabloid-headline`}>
          {verdictIcon(result.verdict)}
          <span className="uppercase drop-shadow-lg ml-2">{result.verdict}</span>
        </div>
        <div className="mt-6 text-3xl text-cream font-extrabold italic max-w-2xl mx-auto tabloid-claim" style={{textShadow:'2px 2px 8px #000'}}>“{result.claim}”</div>
      </div>
      
      <div className="mb-8">
        <h2 className="text-2xl font-extrabold text-gold mb-3">Summary</h2>
        <p className="text-cream text-lg leading-relaxed">{result.summary}</p>
      </div>
      
      <div className="mb-8">
        <h2 className="text-2xl font-extrabold text-gold mb-3">Evidence Highlights</h2>
        <div className="space-y-4">
          {result.evidence.map((item, index) => {
            const expanded = expandedEvidence === index;
            return (
              <div key={index} className={`border-2 ${expanded ? 'border-gold' : 'border-gold border-opacity-40'} rounded-lg p-4 bg-gradient-to-br from-yellow-900 via-red-900 to-red-900 bg-opacity-30 shadow-lg transition-all`}> 
                <div className="flex justify-between items-center mb-2 cursor-pointer" onClick={() => setExpandedEvidence(expanded ? null : index)}>
                  <div className="flex items-center gap-2">
                    <span className="bg-gold text-red-900 font-bold px-2 py-1 rounded-full text-xs shadow">HIGHLIGHT</span>
                    <a 
                      href={item.url} 
                      target="_blank" 
                      rel="noopener noreferrer"
                      className="text-gold hover:underline font-bold text-lg"
                      onClick={e => e.stopPropagation()}
                    >
                      {item.source}
                    </a>
                  </div>
                  <span className="text-gold text-xl font-bold">{expanded ? '−' : '+'}</span>
                </div>
                {expanded && (
                  <div className="mt-2">
                    <p className="text-cream text-opacity-90 font-semibold mb-2">{item.content}</p>
                    <a
                      href={item.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-xs text-blue-400 underline hover:text-blue-600 mr-4"
                    >
                      View Source
                    </a>
                    <a
                      href={`https://blockchain.explorer/tx/${encodeURIComponent(item.url)}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-xs text-blue-400 underline hover:text-blue-600"
                    >
                      View on Blockchain
                    </a>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
        <div className="bg-red-900 bg-opacity-20 rounded-lg p-4">
          <h3 className="text-lg font-semibold text-cream mb-2">Verification Details</h3>
          <p className="text-cream">Verified by: {result.aletheiansVerified}</p>
          <p className="text-cream">Submitted: {new Date(result.submittedAt).toLocaleString()}</p>
          <p className="text-cream">Verified: {new Date(result.verifiedAt).toLocaleString()}</p>
        </div>
        <div className="bg-red-900 bg-opacity-20 rounded-lg p-4">
          <h3 className="text-lg font-semibold text-cream mb-2">Share This Result</h3>
          <div className="flex gap-3 mt-3">
            <button className="bg-blue-500 text-white px-4 py-2 rounded-lg" onClick={() => window.open(`https://twitter.com/intent/tweet?text=Check out this fact-check: ${window.location.href}`, '_blank')}>Twitter</button>
            <button className="bg-gray-800 text-white px-4 py-2 rounded-lg" onClick={() => {navigator.clipboard.writeText(window.location.href)}}>Copy Link</button>
            <button className="bg-red-600 text-white px-4 py-2 rounded-lg">Report Issue</button>
          </div>
        </div>
      </div>
      {/* Feedback */}
      <div className="flex gap-2 items-center justify-center mt-4">
        <span className="text-cream font-semibold mr-2">Was this helpful?</span>
        <button
          className={`text-2xl px-2 ${feedback === 'up' ? 'text-green-400' : 'text-cream'}`}
          onClick={() => setFeedback('up')}
          aria-label="Thumbs up"
        >👍</button>
        <button
          className={`text-2xl px-2 ${feedback === 'down' ? 'text-red-400' : 'text-cream'}`}
          onClick={() => setFeedback('down')}
          aria-label="Thumbs down"
        >👎</button>
      </div>
    </GlassCard>
  );
};

export default FactCheckResult;