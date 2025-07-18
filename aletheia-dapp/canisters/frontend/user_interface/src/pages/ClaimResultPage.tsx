// src/pages/ClaimResultPage.tsx
import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import FactCheckResult from '../components/FactCheckResult';
import GlassCard from '../components/GlassCard';
import { getClaimResult } from '../services/claims';
import GoldButton from '../components/GoldButton';

const ClaimResultPage: React.FC = () => {
  const { claimId } = useParams<{ claimId: string }>();
  const [result, setResult] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showSummary, setShowSummary] = useState(true);
  const [showEvidence, setShowEvidence] = useState(false);
  const [feedback, setFeedback] = useState<null | 'up' | 'down'>(null);
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

  // Placeholder for related questions
  const relatedQuestions = result?.relatedQuestions || [
    'What evidence supports this claim?',
    'Who verified this claim?',
    'How recent is the evidence?',
  ];

  // Placeholder for blockchain link
  const getBlockchainLink = (evidenceUrl: string) => `https://blockchain.explorer/tx/${encodeURIComponent(evidenceUrl)}`;

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
          <>
            {/* Tabloid-style verdict headline is in FactCheckResult */}
            <FactCheckResult result={result} />

            {/* Consensus */}
            <div className="my-6 text-center">
              <span className="inline-block bg-gold text-red-900 font-bold px-4 py-2 rounded-full shadow">
                Verified by {result.aletheiansVerified || '3/3 Aletheians'}
              </span>
            </div>

            {/* Expandable Summary */}
            <div className="mb-6">
              <button
                className="w-full flex justify-between items-center bg-red-900 bg-opacity-30 border border-gold rounded-lg p-4 text-left focus:outline-none"
                onClick={() => setShowSummary(s => !s)}
              >
                <span className="text-xl font-semibold text-gold">Summary</span>
                <span className="text-gold text-2xl">{showSummary ? '−' : '+'}</span>
              </button>
              {showSummary && (
                <div className="bg-red-900 bg-opacity-10 border-l-4 border-gold rounded-b-lg p-4 text-cream">
                  {result.summary}
                </div>
              )}
            </div>

            {/* Expandable Evidence */}
            <div className="mb-6">
              <button
                className="w-full flex justify-between items-center bg-red-900 bg-opacity-30 border border-gold rounded-lg p-4 text-left focus:outline-none"
                onClick={() => setShowEvidence(e => !e)}
              >
                <span className="text-xl font-semibold text-gold">Evidence</span>
                <span className="text-gold text-2xl">{showEvidence ? '−' : '+'}</span>
              </button>
              {showEvidence && (
                <div className="space-y-4 mt-2">
                  {result.evidence.map((item: any, index: number) => (
                    <div key={index} className="bg-yellow-900 bg-opacity-20 border-2 border-gold rounded-lg p-4 shadow-lg">
                      <div className="flex justify-between items-center mb-2">
                        <a 
                          href={item.url} 
                          target="_blank" 
                          rel="noopener noreferrer"
                          className="text-gold hover:underline font-bold text-lg"
                        >
                          {item.source}
                        </a>
                        {/* Blockchain link */}
                        <a
                          href={getBlockchainLink(item.url)}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="ml-4 text-xs text-blue-400 underline hover:text-blue-600"
                        >
                          View on Blockchain
                        </a>
                      </div>
                      <div className="text-cream text-opacity-90 font-semibold">
                        <span className="bg-gold bg-opacity-30 px-2 py-1 rounded mr-2">Highlight</span>
                        {item.content}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Related Questions */}
            <div className="mb-8">
              <div className="bg-red-900 bg-opacity-30 border border-gold rounded-lg p-4">
                <h3 className="text-lg font-bold text-gold mb-2">Right Questions to Ask</h3>
                <ul className="list-disc list-inside text-cream space-y-1">
                  {relatedQuestions.map((q: string, i: number) => (
                    <li key={i}>{q}</li>
                  ))}
                </ul>
              </div>
            </div>

            {/* Share & Feedback */}
            <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 mb-8">
              <div className="flex gap-3">
                <button className="bg-blue-500 text-white px-4 py-2 rounded-lg" onClick={() => window.open(`https://twitter.com/intent/tweet?text=Check out this fact-check: ${window.location.href}`, '_blank')}>Share on Twitter</button>
                <button className="bg-gray-800 text-white px-4 py-2 rounded-lg" onClick={() => {navigator.clipboard.writeText(window.location.href)}}>Copy Link</button>
              </div>
              <div className="flex gap-2 items-center">
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
            </div>
          </>
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