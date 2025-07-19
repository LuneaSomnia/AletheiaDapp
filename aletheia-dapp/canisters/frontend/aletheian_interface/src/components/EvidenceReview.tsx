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

const craapDetails = [
  { label: 'Currency', desc: 'How recent is the information? Is it up to date?' },
  { label: 'Relevance', desc: 'Does the evidence relate directly to the claim?' },
  { label: 'Authority', desc: 'Who is the author/source? Are they reputable?' },
  { label: 'Accuracy', desc: 'Is the information supported by evidence? Is it correct?' },
  { label: 'Purpose', desc: 'Why was this information created? Is there bias?' },
];

const EvidenceReview: React.FC<EvidenceReviewProps> = ({
  evidence,
  onCredibilityChange,
  onEvidenceSubmit
}) => {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [craapOpen, setCraapOpen] = useState(false);
  const [craapTipsOpen, setCraapTipsOpen] = useState<number | null>(null);
  // State for adding new evidence
  const [newEvidence, setNewEvidence] = useState({ source: '', url: '', summary: '', credibility: 5 });
  const [localEvidence, setLocalEvidence] = useState<EvidenceItem[]>(evidence);

  const handleAddEvidence = () => {
    if (!newEvidence.source || !newEvidence.url || !newEvidence.summary) return;
    setLocalEvidence([...localEvidence, { ...newEvidence }]);
    setNewEvidence({ source: '', url: '', summary: '', credibility: 5 });
  };

  return (
    <GlassCard className="p-6">
      <div className="mb-4">
        <button
          className="text-gold underline text-sm mb-2"
          onClick={() => setCraapOpen(open => !open)}
        >
          {craapOpen ? 'Hide CRAAP Model Help' : 'What is the CRAAP Model?'}
        </button>
        {craapOpen && (
          <div className="bg-purple-900 bg-opacity-40 border border-gold rounded-lg p-4 text-cream mb-2">
            <div className="font-bold mb-2">CRAAP Model for Evaluating Evidence:</div>
            <ul className="list-disc ml-6">
              {craapDetails.map(c => (
                <li key={c.label}><span className="text-gold font-semibold">{c.label}:</span> {c.desc}</li>
              ))}
            </ul>
          </div>
        )}
      </div>
      <h3 className="text-xl font-semibold text-cream mb-4">Review Evidence Credibility</h3>
      <div className="space-y-4">
        {localEvidence.map((item, index) => (
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
              <div className="flex items-center gap-2">
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
                <button
                  className="text-gold underline text-xs"
                  onClick={() => setCraapTipsOpen(craapTipsOpen === index ? null : index)}
                  type="button"
                >
                  CRAAP Tips
                </button>
              </div>
            </div>
            <p className="text-cream text-opacity-90 mb-2">{item.summary}</p>
            {craapTipsOpen === index && (
              <div className="bg-purple-900 bg-opacity-40 border border-gold rounded-lg p-3 text-cream mt-2">
                <div className="font-bold mb-1">How to assess this evidence:</div>
                <ul className="list-disc ml-5">
                  {craapDetails.map(c => (
                    <li key={c.label}><span className="text-gold font-semibold">{c.label}:</span> {c.desc}</li>
                  ))}
                </ul>
              </div>
            )}
          </div>
        ))}
      </div>
      {/* Add Evidence Section */}
      <div className="mt-8">
        <h4 className="text-lg font-semibold text-cream mb-2">Link New Evidence</h4>
        <div className="flex flex-col md:flex-row gap-2 mb-2">
          <input
            type="text"
            className="flex-1 bg-purple-900 bg-opacity-30 border border-gold rounded p-2 text-cream"
            placeholder="Source (e.g. NY Times)"
            value={newEvidence.source}
            onChange={e => setNewEvidence({ ...newEvidence, source: e.target.value })}
          />
          <input
            type="text"
            className="flex-1 bg-purple-900 bg-opacity-30 border border-gold rounded p-2 text-cream"
            placeholder="URL"
            value={newEvidence.url}
            onChange={e => setNewEvidence({ ...newEvidence, url: e.target.value })}
          />
        </div>
        <textarea
          className="w-full bg-purple-900 bg-opacity-30 border border-gold rounded p-2 text-cream mb-2"
          placeholder="Summary of evidence"
          value={newEvidence.summary}
          onChange={e => setNewEvidence({ ...newEvidence, summary: e.target.value })}
          rows={2}
        />
        <div className="flex items-center gap-2 mb-2">
          <span className="text-cream">Credibility:</span>
          <input
            type="number"
            min="0"
            max="10"
            step="0.1"
            value={newEvidence.credibility}
            onChange={e => setNewEvidence({ ...newEvidence, credibility: parseFloat(e.target.value) })}
            className="w-20 bg-purple-900 bg-opacity-30 border border-gold rounded p-2 text-cream"
          />
          <button
            className="bg-gold text-purple-900 font-bold px-4 py-2 rounded hover:bg-yellow-300 transition-all"
            onClick={handleAddEvidence}
            type="button"
          >
            Add Evidence
          </button>
        </div>
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