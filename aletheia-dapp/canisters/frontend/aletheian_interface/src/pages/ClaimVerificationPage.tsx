// src/pages/ClaimVerificationPage.tsx
import React, { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import VerificationInterface from '../components/VerificationInterface';
import GlassCard from '../components/GlassCard';

const ClaimVerificationPage: React.FC = () => {
  const { claimId } = useParams<{ claimId: string }>();
  const navigate = useNavigate();
  const [accepted, setAccepted] = useState(false);
  const [declined, setDeclined] = useState(false);
  const [aiSearchLoading, setAiSearchLoading] = useState(true);
  const [aiDuplicates, setAiDuplicates] = useState<any[]>([]);
  const [aiInfoLoading, setAiInfoLoading] = useState(true);
  const [aiSources, setAiSources] = useState<any[]>([]);
  const [aiSummary, setAiSummary] = useState('');
  const [selectedVerdict, setSelectedVerdict] = useState('');
  const [verdictSubmitted, setVerdictSubmitted] = useState(false);
  const [explanation, setExplanation] = useState('');
  const [evidenceList, setEvidenceList] = useState<any[]>([]);
  const [evidenceInput, setEvidenceInput] = useState('');
  const [evidenceType, setEvidenceType] = useState<'link' | 'file' | 'hash'>('link');
  const [evidenceFile, setEvidenceFile] = useState<File | null>(null);

  // Simulate AI blockchain search for duplicates
  React.useEffect(() => {
    setAiSearchLoading(true);
    setTimeout(() => {
      // Mock duplicate results
      setAiDuplicates([
        {
          id: 'claim-099',
          text: 'COVID-19 vaccine causes microchips',
          status: 'verified',
          verdict: 'FALSE',
          verifiedAt: '2024-06-01T10:00:00Z',
        },
        {
          id: 'claim-098',
          text: 'COVID-19 vaccine contains microchips',
          status: 'verified',
          verdict: 'FALSE',
          verifiedAt: '2024-05-15T14:30:00Z',
        },
      ]);
      setAiSearchLoading(false);
    }, 1200);
  }, [claimId]);

  // Simulate AI information retrieval
  React.useEffect(() => {
    setAiInfoLoading(true);
    setTimeout(() => {
      setAiSources([
        {
          title: 'WHO: COVID-19 Vaccines Do Not Contain Microchips',
          url: 'https://www.who.int/news-room/feature-stories/detail/covid-19-vaccines-microchips-myth',
        },
        {
          title: 'FactCheck.org: No Evidence of Microchips in Vaccines',
          url: 'https://www.factcheck.org/2021/03/scicheck-no-evidence-covid-19-vaccines-contain-microchips/',
        },
        {
          title: 'CDC: Myths and Facts about COVID-19 Vaccines',
          url: 'https://www.cdc.gov/coronavirus/2019-ncov/vaccines/facts.html',
        },
      ]);
      setAiSummary('Multiple reputable sources confirm that COVID-19 vaccines do not contain microchips. This myth has been debunked by the WHO, CDC, and independent fact-checkers.');
      setAiInfoLoading(false);
    }, 1400);
  }, [claimId]);

  // Mock prioritized claim queue
  const claimQueue = [
    { id: 'claim-101', text: 'COVID-19 vaccine causes microchips', priority: 1, deadline: '2024-07-01T12:00:00Z' },
    { id: 'claim-102', text: '5G towers linked to health issues', priority: 2, deadline: '2024-07-02T15:00:00Z' },
    { id: 'claim-103', text: 'Chocolate prevents aging', priority: 3, deadline: '2024-07-03T18:00:00Z' },
    { id: 'claim-104', text: 'Aliens built the pyramids', priority: 4, deadline: '2024-07-04T20:00:00Z' },
  ];

  // Find the current claim and the rest of the queue
  const currentClaim = claimQueue.find(c => c.id === claimId) || claimQueue[0];
  const queue = claimQueue.filter(c => c.id !== currentClaim.id);

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

  // Handle decline: move to next claim or show message
  const handleDecline = () => {
    setDeclined(true);
    setAccepted(false);
    if (queue.length > 0) {
      setTimeout(() => navigate(`/verify-claim/${queue[0].id}`), 1200);
    }
  };

  return (
    <div className="min-h-screen p-4 relative overflow-hidden">
      <div className="absolute inset-0 overflow-hidden pointer-events-none z-0">
        {[...Array(15)].map((_, i) => (
          <div
            key={i}
            className="absolute abstract-icon"
            style={{
              top: `${Math.random() * 100}%`,
              left: `${Math.random() * 100}%`,
              width: `${Math.random() * 100 + 50}px`,
              height: `${Math.random() * 100 + 50}px`,
              backgroundImage: `url(/assets/icons/${['torch', 'scales', 'magnifier', 'computer'][i % 4]}.svg)`,
              backgroundSize: 'contain',
              backgroundRepeat: 'no-repeat',
              filter: i % 2 === 0 ? 'invert(75%) sepia(40%) saturate(500%) hue-rotate(270deg) brightness(90%)' : 'invert(80%) sepia(80%) saturate(800%) hue-rotate(45deg) brightness(110%)',
              opacity: 0.12 + (i % 3) * 0.04,
              transform: `rotate(${Math.random() * 360}deg)`
            }}
          />
        ))}
      </div>
      <div className="max-w-4xl mx-auto">
        {/* Prioritized Claim Queue */}
        <GlassCard className="mb-8">
          <h2 className="text-xl font-bold text-gold mb-4">Prioritized Claim Queue</h2>
          <div className="mb-4 p-4 bg-gold bg-opacity-10 rounded-lg border border-gold flex flex-col gap-2">
            <div className="flex items-center gap-2 mb-2">
              <span className="bg-gold text-red-900 px-2 py-1 rounded-full text-xs font-bold">Current</span>
              <span className="font-semibold text-cream">{currentClaim.text}</span>
              <span className="text-xs text-gold ml-2">Deadline: {new Date(currentClaim.deadline).toLocaleString()}</span>
            </div>
            {/* Accept/Decline Workflow */}
            {!accepted && !declined && (
              <div className="flex gap-4 mt-4">
                <button
                  className="luxury-btn"
                  onClick={() => setAccepted(true)}
                >
                  Accept Task
                </button>
                <button
                  className="luxury-btn-outline"
                  onClick={handleDecline}
                >
                  Decline
                </button>
              </div>
            )}
            {declined && (
              <div className="text-center text-cream mt-4">
                <span className="bg-red-900 bg-opacity-30 px-4 py-2 rounded-lg">Task declined. {queue.length > 0 ? 'Moving to next claim...' : 'No more claims in queue.'}</span>
              </div>
            )}
          </div>
          {queue.length > 0 && (
            <div className="space-y-2">
              {queue.map((claim) => (
                <div
                  key={claim.id}
                  className="flex items-center justify-between bg-red-900 bg-opacity-20 rounded-lg px-4 py-2 border border-gold border-opacity-20 hover:border-gold cursor-pointer transition"
                  onClick={() => navigate(`/verify-claim/${claim.id}`)}
                >
                  <div className="flex items-center gap-2">
                    <span className="bg-yellow-500 text-red-900 px-2 py-1 rounded-full text-xs font-bold">Queued</span>
                    <span className="text-cream font-medium">{claim.text}</span>
                  </div>
                  <span className="text-xs text-gold">Deadline: {new Date(claim.deadline).toLocaleString()}</span>
                </div>
              ))}
            </div>
          )}
        </GlassCard>
        {/* AI Blockchain Search for Duplicates */}
        <GlassCard className="mb-8">
          <h2 className="text-xl font-bold text-gold mb-4">AI Blockchain Search: Duplicate Detection</h2>
          {aiSearchLoading ? (
            <div className="flex items-center gap-3 py-4">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-gold"></div>
              <span className="text-cream">Searching blockchain for similar claims...</span>
            </div>
          ) : aiDuplicates.length > 0 ? (
            <div className="space-y-3">
              <div className="text-cream mb-2">Possible duplicates found on blockchain:</div>
              {aiDuplicates.map(dup => (
                <div key={dup.id} className="flex items-center justify-between bg-red-900 bg-opacity-20 rounded-lg px-4 py-2 border border-gold border-opacity-20">
                  <div className="flex flex-col">
                    <span className="text-gold font-semibold">{dup.text}</span>
                    <span className="text-xs text-cream">Verified: {new Date(dup.verifiedAt).toLocaleDateString()}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className={`px-2 py-1 rounded-full text-xs font-bold ${dup.verdict === 'FALSE' ? 'bg-red-500 text-white' : 'bg-green-500 text-white'}`}>{dup.verdict}</span>
                    <button
                      className="luxury-btn-outline small-button"
                      onClick={() => navigate(`/claim-result/${dup.id}`)}
                    >
                      View
                    </button>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-cream py-4">No similar claims found on blockchain.</div>
          )}
        </GlassCard>
        {/* AI Information Retrieval: Suggested Sources & Summary */}
        <GlassCard className="mb-8">
          <h2 className="text-xl font-bold text-gold mb-4">AI Information Retrieval</h2>
          {aiInfoLoading ? (
            <div className="flex items-center gap-3 py-4">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-gold"></div>
              <span className="text-cream">Retrieving relevant sources and summary...</span>
            </div>
          ) : (
            <>
              <div className="mb-4">
                <h3 className="text-lg font-semibold text-gold mb-2">AI-Suggested Sources</h3>
                <ul className="space-y-2">
                  {aiSources.map((src, idx) => (
                    <li key={idx} className="flex items-center gap-2">
                      <span className="text-gold">🔗</span>
                      <a
                        href={src.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-cream underline hover:text-gold"
                      >
                        {src.title}
                      </a>
                    </li>
                  ))}
                </ul>
              </div>
              <div>
                <h3 className="text-lg font-semibold text-gold mb-2">AI Summary</h3>
                <p className="text-cream text-opacity-90">{aiSummary}</p>
              </div>
            </>
          )}
        </GlassCard>
        {accepted && (
          <>
            <GlassCard className="mb-8">
              <h2 className="text-xl font-bold text-gold mb-4">Classification</h2>
              <div className="flex flex-col md:flex-row md:items-center gap-4 mb-4">
                <select
                  className="bg-red-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream text-lg"
                  value={selectedVerdict}
                  onChange={e => setSelectedVerdict(e.target.value)}
                >
                  <option value="">Select a verdict...</option>
                  <option value="TRUE">True</option>
                  <option value="FALSE">False</option>
                  <option value="MISLEADING">Misleading</option>
                  <option value="UNPROVEN">Unproven</option>
                  <option value="SATIRE">Satire</option>
                  <option value="NEEDS_MORE_EVIDENCE">Needs More Evidence</option>
                  <option value="OPINION">Opinion</option>
                </select>
              </div>
              {/* Rich Text Editor for Explanation/Evidence */}
              <div className="mb-4">
                <label className="block text-cream font-semibold mb-2">Explanation & Evidence (Rich Text)</label>
                {/* Replace this textarea with a real rich text editor if needed */}
                <textarea
                  className="w-full min-h-[120px] bg-red-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream"
                  placeholder="Provide a detailed explanation and link to evidence..."
                  value={explanation}
                  onChange={e => setExplanation(e.target.value)}
                />
                <div className="text-xs text-gold mt-1">You can add links to evidence and format your explanation.</div>
              </div>
              {/* Evidence Linking UI */}
              <div className="mb-4">
                <label className="block text-cream font-semibold mb-2">Add Evidence</label>
                <div className="flex gap-2 mb-2">
                  <select
                    className="bg-red-900 bg-opacity-30 border border-gold rounded-lg p-2 text-cream"
                    value={evidenceType}
                    onChange={e => setEvidenceType(e.target.value as 'link' | 'file' | 'hash')}
                  >
                    <option value="link">Link</option>
                    <option value="file">File</option>
                    <option value="hash">Blockchain Hash</option>
                  </select>
                  {evidenceType === 'link' && (
                    <input
                      type="url"
                      className="flex-1 bg-red-900 bg-opacity-30 border border-gold rounded-lg p-2 text-cream"
                      placeholder="Paste evidence link..."
                      value={evidenceInput}
                      onChange={e => setEvidenceInput(e.target.value)}
                    />
                  )}
                  {evidenceType === 'hash' && (
                    <input
                      type="text"
                      className="flex-1 bg-red-900 bg-opacity-30 border border-gold rounded-lg p-2 text-cream"
                      placeholder="Enter blockchain hash..."
                      value={evidenceInput}
                      onChange={e => setEvidenceInput(e.target.value)}
                    />
                  )}
                  {evidenceType === 'file' && (
                    <input
                      type="file"
                      className="flex-1 text-cream"
                      onChange={e => setEvidenceFile(e.target.files && e.target.files[0] ? e.target.files[0] : null)}
                    />
                  )}
                  <button
                    className="luxury-btn-outline"
                    type="button"
                    onClick={() => {
                      if (evidenceType === 'file' && evidenceFile) {
                        setEvidenceList([...evidenceList, { type: 'file', name: evidenceFile.name, file: evidenceFile }]);
                        setEvidenceFile(null);
                      } else if (evidenceInput.trim()) {
                        setEvidenceList([...evidenceList, { type: evidenceType, value: evidenceInput.trim() }]);
                        setEvidenceInput('');
                      }
                    }}
                    disabled={
                      (evidenceType === 'file' && !evidenceFile) ||
                      ((evidenceType === 'link' || evidenceType === 'hash') && !evidenceInput.trim())
                    }
                  >
                    Add
                  </button>
                </div>
                {/* List of added evidence */}
                {evidenceList.length > 0 && (
                  <ul className="space-y-2 mt-2">
                    {evidenceList.map((ev, idx) => (
                      <li key={idx} className="flex items-center gap-2 bg-red-900 bg-opacity-20 border border-gold rounded-lg px-3 py-2">
                        {ev.type === 'link' && (
                          <a href={ev.value} target="_blank" rel="noopener noreferrer" className="text-gold underline break-all">{ev.value}</a>
                        )}
                        {ev.type === 'hash' && (
                          <span className="text-gold font-mono break-all">Hash: {ev.value}</span>
                        )}
                        {ev.type === 'file' && (
                          <span className="text-gold">File: {ev.name}</span>
                        )}
                        <button
                          className="luxury-btn-outline small-button ml-auto"
                          type="button"
                          onClick={() => setEvidenceList(evidenceList.filter((_, i) => i !== idx))}
                        >
                          Remove
                        </button>
                      </li>
                    ))}
                  </ul>
                )}
              </div>
              <div className="flex gap-4 mb-2">
                <button
                  className="luxury-btn"
                  disabled={!selectedVerdict || !explanation.trim() || verdictSubmitted}
                  onClick={() => setVerdictSubmitted(true)}
                >
                  Submit Verdict
                </button>
                <button
                  className="luxury-btn-outline"
                  onClick={handleDecline}
                  disabled={verdictSubmitted}
                >
                  Decline
                </button>
              </div>
              {verdictSubmitted && (
                <div className="text-green-400 font-bold mt-2">
                  Verdict submitted: {selectedVerdict.replace(/_/g, ' ')}
                  <div className="text-cream text-sm mt-2">Explanation: <span className="text-gold">{explanation}</span></div>
                  {evidenceList.length > 0 && (
                    <div className="text-cream text-sm mt-2">
                      Evidence:
                      <ul className="list-disc ml-6 mt-1">
                        {evidenceList.map((ev, idx) => (
                          <li key={idx} className="break-all">
                            {ev.type === 'link' && <a href={ev.value} target="_blank" rel="noopener noreferrer" className="text-gold underline">{ev.value}</a>}
                            {ev.type === 'hash' && <span className="text-gold font-mono">Hash: {ev.value}</span>}
                            {ev.type === 'file' && <span className="text-gold">File: {ev.name}</span>}
                          </li>
                        ))}
                      </ul>
                    </div>
                  )}
                </div>
              )}
            </GlassCard>
            <VerificationInterface claimId={claimId} />
          </>
        )}
      </div>
    </div>
  );
};

export default ClaimVerificationPage;