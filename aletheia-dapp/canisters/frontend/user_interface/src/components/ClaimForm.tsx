// src/components/ClaimForm.tsx
import React, { useState } from 'react';
import GlassCard from './GlassCard';
import GoldButton from './GoldButton';
import { submitClaim } from '../services/claims';

const ClaimForm: React.FC = () => {
  const [claimType, setClaimType] = useState('text');
  const [claimText, setClaimText] = useState('');
  const [sourceUrl, setSourceUrl] = useState('');
  const [context, setContext] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  
  const handleSubmit = async () => {
    setIsSubmitting(true);
    try {
      const result = await submitClaim(claimText, claimType, sourceUrl, context);
      setIsSubmitting(false);
      return result;
    } catch (error) {
      console.error('Submission failed:', error);
      setIsSubmitting(false);
      return null;
    }
  };
  
  return (
    <GlassCard className="p-8">
      <h2 className="text-2xl font-bold text-cream mb-6">Submit a Claim for Verification</h2>
      
      <div className="mb-6">
        <label className="block text-cream mb-2">Claim Type</label>
        <select 
          value={claimType}
          onChange={(e) => setClaimType(e.target.value)}
          className="w-full bg-red-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream"
        >
          <option value="text">Text</option>
          <option value="image">Image</option>
          <option value="video">Video</option>
          <option value="audio">Audio</option>
          <option value="link">Article Link</option>
          <option value="url">Fake News Site URL</option>
        </select>
      </div>
      
      <div className="mb-6">
        <label className="block text-cream mb-2">Claim Content</label>
        <textarea
          value={claimText}
          onChange={(e) => setClaimText(e.target.value)}
          rows={4}
          className="w-full bg-red-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream"
          placeholder="Paste the claim you want to verify..."
        />
      </div>
      
      <div className="mb-6">
        <label className="block text-cream mb-2">Source (Optional)</label>
        <input
          type="text"
          value={sourceUrl}
          onChange={(e) => setSourceUrl(e.target.value)}
          className="w-full bg-red-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream"
          placeholder="URL where you encountered this claim"
        />
      </div>
      
      <div className="mb-8">
        <label className="block text-cream mb-2">Context (Optional)</label>
        <textarea
          value={context}
          onChange={(e) => setContext(e.target.value)}
          rows={2}
          className="w-full bg-red-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream"
          placeholder="Why are you questioning this claim?"
        />
      </div>
      
      <GoldButton 
        onClick={handleSubmit} 
        disabled={isSubmitting || !claimText.trim()}
        className="w-full py-4 text-xl"
      >
        {isSubmitting ? 'Submitting...' : 'Verify Claim'}
      </GoldButton>
    </GlassCard>
  );
};

export default ClaimForm;