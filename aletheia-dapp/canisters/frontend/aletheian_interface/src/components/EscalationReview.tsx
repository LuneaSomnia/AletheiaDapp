// src/components/EscalationReview.tsx
import React from 'react';
import GlassCard from './GlassCard';
import PurpleButton from './PurpleButton';

const EscalationReview: React.FC = () => {
  return (
    <GlassCard className="p-8">
      <h2 className="text-2xl font-bold text-cream mb-6">Escalation Review</h2>
      
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
        <select className="w-full bg-purple-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream">
          <option value="">Select a verdict</option>
          <option value="false">False/Inaccurate</option>
          <option value="misleading">Misleading Context</option>
        </select>
      </div>
      
      <div className="mb-8">
        <h3 className="text-xl font-semibold text-cream mb-3">Resolution Explanation</h3>
        <textarea
          rows={6}
          className="w-full bg-purple-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream"
          placeholder="Explain why the claim is false and why the second verification was incorrect..."
        >
          The claim is categorically false. While bleach can kill viruses on surfaces, it is dangerous and ineffective for internal use. The second verification incorrectly extrapolated surface cleaning properties to internal consumption.
        </textarea>
      </div>
      
      <div className="flex justify-end">
       <PurpleButton onClick={() => { /* handle click event */ }} className="py-4 px-8">
  Submit Resolution
</PurpleButton>
      </div>
    </GlassCard>
  );
};

export default EscalationReview;