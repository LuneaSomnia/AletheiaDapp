// src/components/EscalationReview.tsx
import React, { useState } from 'react';
import GlassCard from './GlassCard';
import PurpleButton from './PurpleButton';

const EscalationReview: React.FC = () => {
  // Controlled state for rationale and verdict
  const [verdict, setVerdict] = useState('');
  const [rationale, setRationale] = useState('');
  // Evidence linking state
  const [evidenceList, setEvidenceList] = useState<string[]>(['']);

  const handleEvidenceChange = (idx: number, value: string) => {
    setEvidenceList(list => list.map((ev, i) => (i === idx ? value : ev)));
  };
  const handleAddEvidence = () => setEvidenceList(list => [...list, '']);
  const handleRemoveEvidence = (idx: number) => setEvidenceList(list => list.filter((_, i) => i !== idx));

  const handleSubmit = () => {
    // TODO: Integrate with backend
    alert(`Submitted!\nVerdict: ${verdict}\nRationale: ${rationale}\nEvidence: ${evidenceList.filter(Boolean).join(', ')}`);
  };

  return (
    <GlassCard className="p-8">
      <h2 className="text-2xl font-bold text-cream mb-2">Escalation Review</h2>
      <div className="text-gold text-lg mb-6">Senior Aletheian Review Panel</div>
      <div className="mb-6">
        <h3 className="text-xl font-semibold text-cream mb-3">Original Claim</h3>
        <div className="bg-purple-900 bg-opacity-30 border border-gold rounded-lg p-4 text-cream">
          "Drinking bleach cures COVID-19"
        </div>
      </div>
      <div className="mb-6">
        <h3 className="text-xl font-semibold text-cream mb-3">Initial Verdicts</h3>
        <div className="space-y-4">
          <div className="bg-purple-900 bg-opacity-20 border border-red-500 rounded-lg p-4">
            <div className="flex justify-between items-start mb-2">
              <span className="font-semibold text-cream">Aletheian #1</span>
              <span className="bg-red-500 bg-opacity-20 text-red-300 px-2 py-1 rounded text-sm">
                False
              </span>
            </div>
            <p className="text-cream text-opacity-90">No scientific evidence supports this claim. WHO explicitly warns against it.</p>
          </div>
          <div className="bg-purple-900 bg-opacity-20 border border-green-500 rounded-lg p-4">
            <div className="flex justify-between items-start mb-2">
              <span className="font-semibold text-cream">Aletheian #2</span>
              <span className="bg-green-500 bg-opacity-20 text-green-300 px-2 py-1 rounded text-sm">
                True
              </span>
            </div>
            <p className="text-cream text-opacity-90">Some studies show bleach can kill viruses on surfaces.</p>
          </div>
        </div>
      </div>
      <div className="mb-6">
        <h3 className="text-xl font-semibold text-cream mb-3">Your Final Verdict</h3>
        <select
          className="w-full bg-purple-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream"
          value={verdict}
          onChange={e => setVerdict(e.target.value)}
        >
          <option value="">Select a verdict</option>
          <option value="false">False/Inaccurate</option>
          <option value="misleading">Misleading Context</option>
        </select>
      </div>
      <div className="mb-6">
        <h3 className="text-xl font-semibold text-cream mb-3">Resolution Explanation</h3>
        <textarea
          rows={6}
          className="w-full bg-purple-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream"
          placeholder="Explain your rationale for the final verdict..."
          value={rationale}
          onChange={e => setRationale(e.target.value)}
        />
      </div>
      <div className="mb-8">
        <h3 className="text-xl font-semibold text-cream mb-3">Evidence Linking</h3>
        <div className="space-y-2">
          {evidenceList.map((ev, idx) => (
            <div key={idx} className="flex gap-2 items-center">
              <input
                type="text"
                className="flex-1 bg-purple-900 bg-opacity-30 border border-gold rounded-lg p-2 text-cream"
                placeholder="Paste link, file hash, or description"
                value={ev}
                onChange={e => handleEvidenceChange(idx, e.target.value)}
              />
              {evidenceList.length > 1 && (
                <button
                  className="text-red-400 hover:text-red-600 text-lg px-2"
                  onClick={() => handleRemoveEvidence(idx)}
                  type="button"
                  aria-label="Remove evidence"
                >
                  &times;
                </button>
              )}
            </div>
          ))}
          <button
            className="text-gold hover:text-yellow-300 mt-2 text-sm underline"
            onClick={handleAddEvidence}
            type="button"
          >
            + Add Evidence
          </button>
        </div>
      </div>
      <div className="flex justify-end">
        <PurpleButton onClick={handleSubmit} className="py-4 px-8">
          Submit Resolution
        </PurpleButton>
      </div>
    </GlassCard>
  );
};

export default EscalationReview;