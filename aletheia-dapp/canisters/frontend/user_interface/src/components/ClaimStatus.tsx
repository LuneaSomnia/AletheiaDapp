// src/components/ClaimStatus.tsx
import React from 'react';
import GoldButton from './GoldButton';

interface ClaimStatusProps {
  claimId: string;
  claimText: string;
  status: string;
  verdict?: string;
  onView: (claimId: string) => void;
}

const ClaimStatus: React.FC<ClaimStatusProps> = ({ 
  claimId, 
  claimText, 
  status,
  verdict,
  onView 
}) => {
  const statusColor = status === 'Pending' ? 'bg-yellow-500' : 
                     status === 'Processing' ? 'bg-blue-500' : 
                     'bg-green-500';
  
  const verdictColor = verdict === 'FALSE' ? 'bg-red-500' : 
                      verdict === 'TRUE' ? 'bg-green-500' : 
                      verdict === 'MISLEADING' ? 'bg-orange-500' : '';

  return (
    <div className="bg-red-900 bg-opacity-20 border border-gold rounded-lg p-4 transition-all hover:bg-red-900 hover:bg-opacity-30">
      <div className="flex justify-between items-start">
        <div>
          <div className="flex items-center gap-2 mb-2">
            <span className={`px-2 py-1 rounded text-xs ${statusColor}`}>{status}</span>
            {verdict && <span className={`px-2 py-1 rounded text-xs ${verdictColor}`}>{verdict}</span>}
          </div>
          <h3 className="text-lg font-semibold text-cream">Claim ID: {claimId}</h3>
          <p className="text-cream text-opacity-80 mt-2 line-clamp-2">{claimText}</p>
        </div>
        <GoldButton onClick={() => onView(claimId)}>View</GoldButton>
      </div>
    </div>
  );
};

export default ClaimStatus;