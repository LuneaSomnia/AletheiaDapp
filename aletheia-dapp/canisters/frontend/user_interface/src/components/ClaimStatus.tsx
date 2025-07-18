// src/components/ClaimStatus.tsx
import React from 'react';
import GoldButton from './GoldButton';

enum ClaimStatusEnum {
  Pending = 'pending',
  Verified = 'verified',
  Disputed = 'disputed',
  Rejected = 'rejected',
  Processing = 'processing',
  InProgress = 'in progress',
  UnderReview = 'under review',
  Completed = 'completed',
  Escalated = 'escalated',
}
interface ClaimStatusProps {
  claimId: string;
  claimText: string;
  status: string; // Update the type to string
  verdict?: string;
  onView: (claimId: string) => void;
  estimatedTime?: string;
  history?: Array<{
    claimId: string;
    claimText: string;
    status: string;
    verdict?: string;
    estimatedTime?: string;
  }>;
}

const statusMeta: Record<string, { color: string; icon: string; label: string }> = {
  [ClaimStatusEnum.Pending]: { color: 'bg-yellow-500', icon: '⏳', label: 'Pending' },
  [ClaimStatusEnum.Processing]: { color: 'bg-blue-500', icon: '🔄', label: 'Processing' },
  [ClaimStatusEnum.InProgress]: { color: 'bg-blue-400', icon: '🚧', label: 'In Progress' },
  [ClaimStatusEnum.UnderReview]: { color: 'bg-purple-500', icon: '🧐', label: 'Under Review' },
  [ClaimStatusEnum.Verified]: { color: 'bg-green-500', icon: '✅', label: 'Verified' },
  [ClaimStatusEnum.Completed]: { color: 'bg-green-700', icon: '🏁', label: 'Completed' },
  [ClaimStatusEnum.Disputed]: { color: 'bg-orange-500', icon: '⚠️', label: 'Disputed' },
  [ClaimStatusEnum.Rejected]: { color: 'bg-red-500', icon: '❌', label: 'Rejected' },
  [ClaimStatusEnum.Escalated]: { color: 'bg-pink-500', icon: '🚨', label: 'Escalated' },
};

const ClaimStatus: React.FC<ClaimStatusProps> = ({ 
  claimId, 
  claimText, 
  status,
  verdict,
  onView,
  estimatedTime,
  history
}) => {
  const meta = statusMeta[status] || { color: 'bg-gray-500', icon: '❓', label: status };
  const verdictColor = verdict === 'FALSE' ? 'bg-red-500' : 
                    verdict === 'TRUE' ? 'bg-green-500' : 
                    verdict === 'MISLEADING' ? 'bg-orange-500' : '';

  return (
    <div>
      <div className="bg-red-900 bg-opacity-20 border border-gold rounded-lg p-4 transition-all hover:bg-red-900 hover:bg-opacity-30 mb-4">
        <div className="flex justify-between items-start">
          <div>
            <div className="flex items-center gap-2 mb-2">
              <span className={`px-2 py-1 rounded text-xs flex items-center gap-1 ${meta.color}`}>
                <span>{meta.icon}</span>
                {meta.label}
                {estimatedTime && (
                  <span className="ml-2 text-xs text-cream bg-black bg-opacity-20 px-2 py-0.5 rounded-full">{estimatedTime} left</span>
                )}
              </span>
              {verdict && <span className={`px-2 py-1 rounded text-xs ${verdictColor}`}>{verdict}</span>}
            </div>
            <h3 className="text-lg font-semibold text-cream">Claim ID: {claimId}</h3>
            <p className="text-cream text-opacity-80 mt-2 line-clamp-2">{claimText}</p>
          </div>
          <GoldButton onClick={() => onView(claimId)}>View</GoldButton>
        </div>
      </div>
      {/* Claim Status Tracker */}
      {history && history.length > 0 && (
        <div className="mt-2">
          <h4 className="text-cream text-md font-semibold mb-2">Claim Status Tracker</h4>
          <div className="flex flex-col gap-2">
            {history.map((claim, idx) => {
              const metaH = statusMeta[claim.status] || { color: 'bg-gray-500', icon: '❓', label: claim.status };
              const vColor = claim.verdict === 'FALSE' ? 'bg-red-500' : 
                              claim.verdict === 'TRUE' ? 'bg-green-500' : 
                              claim.verdict === 'MISLEADING' ? 'bg-orange-500' : '';
              return (
                <div key={claim.claimId || idx} className="bg-red-900 bg-opacity-10 border border-gold rounded-lg p-3 flex justify-between items-center">
                  <div>
                    <div className="flex items-center gap-2 mb-1">
                      <span className={`px-2 py-1 rounded text-xs flex items-center gap-1 ${metaH.color}`}>
                        <span>{metaH.icon}</span>
                        {metaH.label}
                        {claim.estimatedTime && (
                          <span className="ml-2 text-xs text-cream bg-black bg-opacity-20 px-2 py-0.5 rounded-full">{claim.estimatedTime} left</span>
                        )}
                      </span>
                      {claim.verdict && <span className={`px-2 py-1 rounded text-xs ${vColor}`}>{claim.verdict}</span>}
                    </div>
                    <div className="text-cream text-xs font-mono">ID: {claim.claimId}</div>
                    <div className="text-cream text-opacity-80 text-sm line-clamp-1">{claim.claimText}</div>
                  </div>
                  <GoldButton onClick={() => onView(claim.claimId)}>View</GoldButton>
                </div>
              );
            })}
          </div>
        </div>
      )}
      {history && history.length === 0 && (
        <div className="text-cream text-opacity-60 text-sm mt-2">No ongoing or past claims to display.</div>
      )}
    </div>
  );
};

export default ClaimStatus;