import React, { useState } from 'react';
import GlassCard from './GlassCard';

interface EvidenceItem {
  source: string;
  url: string;
  summary: string;
  credibility: number;
}

interface EvidenceReviewProps {
  evidence: EvidenceItem[];
  onCredibilityChange: (index: number, credibility: number) => void;
  onEvidenceSubmit: () => void;
}

const EvidenceReview: React.FC<EvidenceReviewProps> = ({
  evidence,
  onCredibilityChange,
  onEvidenceSubmit
}) => {
  const [isSubmitting, setIsSubmitting] = useState(false);

  return (
    <GlassCard className="p-6">
      <h3 className="text-xl font-semibold text-cream mb-4">Review Evidence Credibility</h3>
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
              <div className="flex items-center">
                <span className="text-cream mr-2">Credibility:</span>
                <input
                  type="number"
                  min="0"
                  max="10"
                  step="0.1"
                  value={item.credibility}
                  onChange={(e) => onCredibilityChange(index, parseFloat(e.target.value))}
                  className="w-20 bg-purple-900 bg-opacity-30 border border-gold rounded p-2 text-cream"
                />
              </div>
            </div>
            <p className="text-cream text-opacity-90">{item.summary}</p>
          </div>
        ))}
      </div>
      
      <div className="mt-6 flex justify-end">
        <button
          onClick={() => {
            setIsSubmitting(true);
            onEvidenceSubmit();
          }}
          disabled={isSubmitting}
          className="bg-gradient-to-r from-purple-700 to-purple-900 text-cream py-3 px-6 rounded-lg font-bold hover:from-purple-800 hover:to-purple-950 transition-all disabled:opacity-50"
        >
          {isSubmitting ? 'Submitting...' : 'Confirm Evidence'}
        </button>
      </div>
    </GlassCard>
  );
};

export default EvidenceReview;