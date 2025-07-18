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
    file?: File;
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
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [videoFile, setVideoFile] = useState<File | null>(null);
  const [audioFile, setAudioFile] = useState<File | null>(null);
  const [screenshotFile, setScreenshotFile] = useState<File | null>(null);
  const [mediaAnalysis, setMediaAnalysis] = useState<string>('');
  const [deepfakeResult, setDeepfakeResult] = useState<string>('');
  const [showSuccessModal, setShowSuccessModal] = useState(false);

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

  // Simulate media analysis and deepfake detection (placeholder)
  useEffect(() => {
    if (imageFile || videoFile || audioFile || screenshotFile) {
      setMediaAnalysis('Media analysis complete. No suspicious content detected.');
      setDeepfakeResult('No deepfake detected.');
    } else {
      setMediaAnalysis('');
      setDeepfakeResult('');
    }
  }, [imageFile, videoFile, audioFile, screenshotFile]);

  const handleAddTag = (tagFromClick?: string) => {
    const tag = tagFromClick || newTag.trim();
    if (tag && !tags.includes(tag)) {
      setTags([...tags, tag]);
      setNewTag('');
    }
  };

  const handleRemoveTag = (tagToRemove: string) => {
    setTags(tags.filter(tag => tag !== tagToRemove));
  };

  const handleSubmit = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    setIsSubmitting(true);
    try {
      await onSubmit({
        claim: claimText,
        claimType,
        source: claimType === 'article' || claimType === 'url' ? sourceUrl : undefined,
        context,
        tags,
        ...(imageFile ? { imageFile } : {}),
        ...(videoFile ? { videoFile } : {}),
        ...(audioFile ? { audioFile } : {}),
        ...(screenshotFile ? { screenshotFile } : {}),
      });
      // Reset form on success
      setClaimText('');
      setSourceUrl('');
      setContext('');
      setTags([]);
      setImageFile(null);
      setVideoFile(null);
      setAudioFile(null);
      setScreenshotFile(null);
      setShowSuccessModal(true);
    } catch (error) {
      console.error('Submission failed:', error);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <GlassCard className="p-8">
      <h2 className="text-2xl font-bold text-cream mb-6">Submit a Claim for Verification</h2>
      {/* Success Modal */}
      {showSuccessModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-60">
          <div className="bg-white rounded-lg shadow-lg max-w-md w-full p-6 relative">
            <button
              className="absolute top-2 right-2 text-gray-600 hover:text-black text-xl font-bold"
              onClick={() => setShowSuccessModal(false)}
              aria-label="Close Success Modal"
            >
              &times;
            </button>
            <h2 className="text-2xl font-bold mb-4 text-center text-gold">Claim Submitted Successfully!</h2>
            <div className="text-gray-800 text-base mb-4 text-center">
              Your claim has been submitted for verification.<br />
              <span className="text-sm text-gray-600">Next steps: Track your claim status in your dashboard. You will be notified when the verification is complete.</span>
            </div>
            <div className="flex justify-center">
              <GoldButton onClick={() => setShowSuccessModal(false)}>
                Close
              </GoldButton>
            </div>
          </div>
        </div>
      )}
      <form onSubmit={handleSubmit}>
        <div className="mb-6">
          <label className="block text-cream mb-2">Claim Type</label>
          <select 
            value={claimType}
            onChange={(e) => {
              setClaimType(e.target.value);
              setClaimText('');
              setSourceUrl('');
              setImageFile(null);
              setVideoFile(null);
              setAudioFile(null);
              setScreenshotFile(null);
            }}
            className="w-full bg-red-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream"
          >
            <option value="text">Text</option>
            <option value="image">Image</option>
            <option value="video">Video</option>
            <option value="audio">Audio</option>
            <option value="article">Article Link</option>
            <option value="url">Fake News Site URL</option>
          </select>
        </div>
        {/* Dynamic claim input based on type */}
        {claimType === 'text' && (
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
        )}
        {claimType === 'image' && (
          <>
            <div className="mb-6">
              <label className="block text-cream mb-2">Upload Image*</label>
              <input
                type="file"
                accept="image/*"
                onChange={e => setImageFile(e.target.files && e.target.files[0] ? e.target.files[0] : null)}
                className="w-full bg-red-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream"
                required
              />
              {imageFile && <div className="text-cream text-xs mt-2">Selected: {imageFile.name}</div>}
            </div>
            <div className="mb-6">
              <label className="block text-cream mb-2">Upload Screenshot (Optional)</label>
              <input
                type="file"
                accept="image/*"
                onChange={e => setScreenshotFile(e.target.files && e.target.files[0] ? e.target.files[0] : null)}
                className="w-full bg-red-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream"
              />
              {screenshotFile && <div className="text-cream text-xs mt-2">Selected: {screenshotFile.name}</div>}
            </div>
          </>
        )}
        {claimType === 'video' && (
          <div className="mb-6">
            <label className="block text-cream mb-2">Upload Video*</label>
            <input
              type="file"
              accept="video/*"
              onChange={e => setVideoFile(e.target.files && e.target.files[0] ? e.target.files[0] : null)}
              className="w-full bg-red-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream"
              required
            />
            {videoFile && <div className="text-cream text-xs mt-2">Selected: {videoFile.name}</div>}
          </div>
        )}
        {claimType === 'audio' && (
          <div className="mb-6">
            <label className="block text-cream mb-2">Upload Audio*</label>
            <input
              type="file"
              accept="audio/*"
              onChange={e => setAudioFile(e.target.files && e.target.files[0] ? e.target.files[0] : null)}
              className="w-full bg-red-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream"
              required
            />
            {audioFile && <div className="text-cream text-xs mt-2">Selected: {audioFile.name}</div>}
          </div>
        )}
        {(claimType === 'article' || claimType === 'url') && (
          <div className="mb-6">
            <label className="block text-cream mb-2">{claimType === 'article' ? 'Article Link*' : 'Fake News Site URL*'}</label>
            <input
              type="url"
              value={sourceUrl}
              onChange={e => setSourceUrl(e.target.value)}
              className="w-full bg-red-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream"
              placeholder={claimType === 'article' ? 'Paste the article link...' : 'Paste the fake news site URL...'}
              required
            />
          </div>
        )}
        {/* Context and Source fields always shown */}
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
          <label className="block text-cream mb-2">Source (Optional)</label>
          <input
            type="text"
            value={sourceUrl}
            onChange={e => setSourceUrl(e.target.value)}
            className="w-full bg-red-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream"
            placeholder="URL or reference where you encountered this claim"
          />
        </div>
        {/* Media Analysis & Deepfake Detection Results */}
        {(imageFile || videoFile || audioFile || screenshotFile) && (
          <div className="mb-6">
            <h3 className="text-lg font-semibold text-gold mb-2">Media Analysis Results</h3>
            <div className="bg-red-900 bg-opacity-20 rounded-lg p-4 text-cream">
              <div><strong>Analysis:</strong> {mediaAnalysis}</div>
              <div><strong>Deepfake Detection:</strong> {deepfakeResult}</div>
            </div>
          </div>
        )}
        {/* Tags with AI Suggestions */}
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
              onClick={() => handleAddTag()}
              className="bg-gold text-dark-900 px-4 rounded-r-lg font-medium hover:bg-opacity-90"
            >
              Add
            </button>
          </div>
          {/* AI-Suggested Tags/Categories */}
          {aiSuggestions.length > 0 && (
            <div className="flex flex-wrap gap-2 mb-2">
              {aiSuggestions.map((suggestion, idx) => (
                <button
                  key={suggestion + idx}
                  type="button"
                  className="bg-gold bg-opacity-20 text-gold px-3 py-1 rounded-full hover:bg-opacity-40 transition"
                  onClick={() => handleAddTag(suggestion)}
                  disabled={tags.includes(suggestion)}
                >
                  + {suggestion}
                </button>
              ))}
            </div>
          )}
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
        {/* AI Question Mirror only for text claims */}
        {claimType === 'text' && claimText && (
          <div className="mb-6">
            <QuestionMirror 
              questions={aiSuggestions} 
              isLoading={isGeneratingSuggestions}
            />
          </div>
        )}
        <GoldButton 
          onClick={handleSubmit}
          disabled={isSubmitting ||
            (claimType === 'text' && !claimText.trim()) ||
            (claimType === 'image' && !imageFile) ||
            (claimType === 'video' && !videoFile) ||
            (claimType === 'audio' && !audioFile) ||
            ((claimType === 'article' || claimType === 'url') && !sourceUrl.trim())
          }
          className="w-full py-4 text-xl"
        >
          {isSubmitting ? 'Submitting...' : 'Verify Claim'}
        </GoldButton>
      </form>
    </GlassCard>
  );
};

export default ClaimForm;