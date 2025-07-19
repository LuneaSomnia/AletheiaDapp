// src/pages/EscalationPage.tsx
import React, { useState } from 'react';
import { useParams } from 'react-router-dom';
import EscalationReview from '../components/EscalationReview';
import GlassCard from '../components/GlassCard';

const EscalationPage: React.FC = () => {
  const { claimId } = useParams<{ claimId: string }>();
  // Mock claim data
  const claim = {
    id: claimId || 'claim-101',
    text: 'COVID-19 vaccine causes microchips',
    submittedBy: 'User123',
    originalVerdict: 'FALSE',
    escalationReason: 'New evidence submitted by claimant',
    submittedAt: '2024-07-01T12:00:00Z',
  };
  const [decision, setDecision] = useState('');
  const [explanation, setExplanation] = useState('');
  const [evidence, setEvidence] = useState('');
  const [submitted, setSubmitted] = useState(false);
  // Council of Elders mock data
  const councilMembers = [
    { id: 'elder-1', name: 'Elder Sophia', avatar: '🦉' },
    { id: 'elder-2', name: 'Elder Marcus', avatar: '🦁' },
    { id: 'elder-3', name: 'Elder Amina', avatar: '🐘' },
  ];
  const [councilVotes, setCouncilVotes] = useState<{ [id: string]: string }>({});
  const [councilSummary, setCouncilSummary] = useState('');
  const [councilSubmitted, setCouncilSubmitted] = useState(false);

  // Tally votes
  const tally = councilMembers.reduce(
    (acc, member) => {
      const v = councilVotes[member.id];
      if (v === 'UPHOLD') acc.uphold++;
      else if (v === 'OVERTURN') acc.overturn++;
      else if (v === 'ABSTAIN') acc.abstain++;
      return acc;
    },
    { uphold: 0, overturn: 0, abstain: 0 }
  );
  const majority = Math.ceil(councilMembers.length / 2);
  let finalDecision = '';
  if (tally.uphold >= majority) finalDecision = 'UPHOLD';
  else if (tally.overturn >= majority) finalDecision = 'OVERTURN';
  else if (tally.abstain >= majority) finalDecision = 'ABSTAIN';

  return (
    <div className="min-h-screen p-4">
      <div className="max-w-4xl mx-auto">
        <GlassCard className="mb-8">
          <h1 className="text-2xl font-bold text-gold mb-4">Escalation Review</h1>
          <div className="mb-4">
            <div className="text-cream mb-2"><span className="font-bold">Claim:</span> {claim.text}</div>
            <div className="text-cream text-sm mb-1">Submitted by: {claim.submittedBy}</div>
            <div className="text-cream text-sm mb-1">Original Verdict: <span className="text-gold font-bold">{claim.originalVerdict}</span></div>
            <div className="text-cream text-sm mb-1">Escalation Reason: {claim.escalationReason}</div>
            <div className="text-cream text-xs">Submitted: {new Date(claim.submittedAt).toLocaleString()}</div>
          </div>
          {!submitted ? (
            <>
              <div className="mb-4">
                <label className="block text-cream font-semibold mb-2">Escalation Decision</label>
                <select
                  className="bg-red-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream text-lg"
                  value={decision}
                  onChange={e => setDecision(e.target.value)}
                >
                  <option value="">Select a decision...</option>
                  <option value="UPHOLD">Uphold Original Verdict</option>
                  <option value="OVERTURN">Overturn Verdict</option>
                  <option value="REQUEST_MORE_EVIDENCE">Request More Evidence</option>
                </select>
              </div>
              <div className="mb-4">
                <label className="block text-cream font-semibold mb-2">Explanation (Rich Text)</label>
                <textarea
                  className="w-full min-h-[100px] bg-red-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream"
                  placeholder="Provide a detailed explanation for your decision..."
                  value={explanation}
                  onChange={e => setExplanation(e.target.value)}
                />
              </div>
              <div className="mb-4">
                <label className="block text-cream font-semibold mb-2">Evidence (Links, Hashes, or Files)</label>
                <input
                  className="w-full bg-red-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream mb-2"
                  type="text"
                  placeholder="Paste evidence link, hash, or filename..."
                  value={evidence}
                  onChange={e => setEvidence(e.target.value)}
                />
              </div>
              <button
                className="luxury-btn"
                disabled={!decision || !explanation.trim()}
                onClick={() => setSubmitted(true)}
              >
                Submit Escalation Decision
              </button>
            </>
          ) : (
            <div className="text-green-400 font-bold mt-4">
              Escalation decision submitted: {decision.replace(/_/g, ' ')}
              <div className="text-cream text-sm mt-2">Explanation: <span className="text-gold">{explanation}</span></div>
              {evidence && (
                <div className="text-cream text-sm mt-2">Evidence: <span className="text-gold">{evidence}</span></div>
              )}
            </div>
          )}
        </GlassCard>
        {/* Council of Elders Final Review */}
        <GlassCard className="mb-8">
          <h2 className="text-xl font-bold text-gold mb-4">Council of Elders: Final Review</h2>
          <div className="mb-4">
            <div className="text-cream mb-2"><span className="font-bold">Claim:</span> {claim.text}</div>
            <div className="text-cream text-sm mb-1">Escalation Reason: {claim.escalationReason}</div>
            <div className="text-cream text-sm mb-1">Original Verdict: <span className="text-gold font-bold">{claim.originalVerdict}</span></div>
          </div>
          <div className="mb-4">
            <h3 className="text-gold font-semibold mb-2">Council Votes</h3>
            <div className="flex flex-col gap-3">
              {councilMembers.map(member => (
                <div key={member.id} className="flex items-center gap-3 bg-red-900 bg-opacity-20 rounded-lg px-3 py-2">
                  <span className="text-2xl">{member.avatar}</span>
                  <span className="text-cream font-semibold flex-1">{member.name}</span>
                  {councilSubmitted ? (
                    <span className={`px-2 py-1 rounded-full text-xs font-bold ${councilVotes[member.id] === 'UPHOLD' ? 'bg-green-600' : councilVotes[member.id] === 'OVERTURN' ? 'bg-red-600' : 'bg-yellow-600'} text-white`}>
                      {councilVotes[member.id] || 'No Vote'}
                    </span>
                  ) : (
                    <select
                      className="bg-red-900 bg-opacity-30 border border-gold rounded-lg p-2 text-cream"
                      value={councilVotes[member.id] || ''}
                      onChange={e => setCouncilVotes({ ...councilVotes, [member.id]: e.target.value })}
                    >
                      <option value="">Vote...</option>
                      <option value="UPHOLD">Uphold</option>
                      <option value="OVERTURN">Overturn</option>
                      <option value="ABSTAIN">Abstain</option>
                    </select>
                  )}
                </div>
              ))}
            </div>
          </div>
          <div className="mb-4">
            <div className="text-cream">Tally: <span className="text-gold font-bold">Uphold {tally.uphold}</span> | <span className="text-gold font-bold">Overturn {tally.overturn}</span> | <span className="text-gold font-bold">Abstain {tally.abstain}</span></div>
            {finalDecision && (
              <div className="text-xl font-bold mt-2 text-green-400">Final Decision: {finalDecision.replace(/_/g, ' ')}</div>
            )}
          </div>
          {!councilSubmitted ? (
            <>
              <div className="mb-4">
                <label className="block text-cream font-semibold mb-2">Council Summary (Rich Text)</label>
                <textarea
                  className="w-full min-h-[80px] bg-red-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream"
                  placeholder="Council's explanation for the final decision..."
                  value={councilSummary}
                  onChange={e => setCouncilSummary(e.target.value)}
                />
              </div>
              <button
                className="luxury-btn"
                disabled={Object.values(councilVotes).filter(Boolean).length < councilMembers.length || !councilSummary.trim()}
                onClick={() => setCouncilSubmitted(true)}
              >
                Submit Final Decision
              </button>
            </>
          ) : (
            <div className="text-green-400 font-bold mt-4">
              Council decision submitted: {finalDecision.replace(/_/g, ' ')}
              <div className="text-cream text-sm mt-2">Summary: <span className="text-gold">{councilSummary}</span></div>
            </div>
          )}
        </GlassCard>
        {/* Optionally, show the full escalation review component below */}
        <EscalationReview />
      </div>
    </div>
  );
};

export default EscalationPage;