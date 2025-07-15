// src/components/ClaimForm.tsx
import React, { useState, useEffect } from 'react';
import GlassCard from './GlassCard';
import GoldButton from './GoldButton';
import QuestionMirror from './QuestionMirror';
import { generateAISuggestions } from '../services/learning';

interface ClaimFormProps {
  onSubmit: (data: {
    claim: string;
    claimType: string;
    source?: string;
    context?: string;
    tags: string[];
  }) => Promise<void>;
}

const ClaimForm: React.FC<ClaimFormProps> = ({ onSubmit }) => {
  const [claimType, setClaimType] = useState('text');
  const [claimText, setClaimText] = useState('');
  const [sourceUrl, setSourceUrl] = useState('');
  const [context, setContext] = useState('');
  const [tags, setTags] = useState<string[]>([]);
  const [newTag, setNewTag] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [aiSuggestions, setAiSuggestions] = useState<string[]>([]);
  const [isGeneratingSuggestions, setIsGeneratingSuggestions] = useState(false);

  // Generate AI suggestions when claim text or context changes
  useEffect(() => {
    const generateSuggestions = async () => {
      if (claimText.trim().length > 10) {
        setIsGeneratingSuggestions(true);
        try {
          const suggestions = await generateAISuggestions(claimText, context);
          setAiSuggestions(suggestions);
        } catch (error) {
          console.error('Failed to generate AI suggestions:', error);
          setAiSuggestions([]);
        } finally {
          setIsGeneratingSuggestions(false);
        }
      } else {
        setAiSuggestions([]);
      }
    };

    const debounceTimer = setTimeout(generateSuggestions, 800);
    return () => clearTimeout(debounceTimer);
  }, [claimText, context]);

  const handleAddTag = () => {
    if (newTag.trim() && !tags.includes(newTag.trim())) {
      setTags([...tags, newTag.trim()]);
      setNewTag('');
    }
  };

  const handleRemoveTag = (tagToRemove: string) => {
    setTags(tags.filter(tag => tag !== tagToRemove));
  };

  const handleSubmit = async () => {
  setIsSubmitting(true);
  try {
    await onSubmit({
      claim: claimText,
      claimType,
      source: sourceUrl,
      context,
      tags
    });
    // Reset form on success
    setClaimText('');
    setSourceUrl('');
    setContext('');
    setTags([]);
  } catch (error) {
    console.error('Submission failed:', error);
  } finally {
    setIsSubmitting(false);
  }
};

  return (
    <GlassCard className="p-8">
      <h2 className="text-2xl font-bold text-cream mb-6">Submit a Claim for Verification</h2>
      
      <form onSubmit={handleSubmit}>
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
          <label className="block text-cream mb-2">Claim Content*</label>
          <textarea
            value={claimText}
            onChange={(e) => setClaimText(e.target.value)}
            rows={4}
            className="w-full bg-red-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream"
            placeholder="Paste the claim you want to verify..."
            required
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
        
        <div className="mb-6">
          <label className="block text-cream mb-2">Context (Optional)</label>
          <textarea
            value={context}
            onChange={(e) => setContext(e.target.value)}
            rows={2}
            className="w-full bg-red-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream"
            placeholder="Why are you questioning this claim? Provide background info..."
          />
        </div>
        
        <div className="mb-6">
          <label className="block text-cream mb-2">Tags</label>
          <div className="flex mb-2">
            <input
              type="text"
              value={newTag}
              onChange={(e) => setNewTag(e.target.value)}
              className="flex-1 bg-red-900 bg-opacity-30 border border-gold rounded-l-lg p-3 text-cream"
              placeholder="Add tags to categorize your claim..."
              onKeyDown={(e) => e.key === 'Enter' && handleAddTag()}
            />
            <button
              type="button"
              onClick={handleAddTag}
              className="bg-gold text-dark-900 px-4 rounded-r-lg font-medium hover:bg-opacity-90"
            >
              Add
            </button>
          </div>
          
          <div className="flex flex-wrap gap-2">
            {tags.map(tag => (
              <span 
                key={tag} 
                className="tag-pill flex items-center bg-gold bg-opacity-20 text-gold px-3 py-1 rounded-full"
              >
                {tag}
                <button 
                  type="button"
                  onClick={() => handleRemoveTag(tag)}
                  className="ml-2 text-xs hover:text-white"
                >
                  ×
                </button>
              </span>
            ))}
          </div>
        </div>
        
        {/* AI Question Mirror */}
        {claimText && (
          <div className="mb-6">
            <QuestionMirror 
              questions={aiSuggestions} 
              isLoading={isGeneratingSuggestions}
            />
          </div>
        )}
        
        <GoldButton 
  onClick={handleSubmit}
  disabled={isSubmitting || !claimText.trim()}
  className="w-full py-4 text-xl"
>
  {isSubmitting ? 'Submitting...' : 'Verify Claim'}
</GoldButton>
      </form>
    </GlassCard>
  );
};

export default ClaimForm;