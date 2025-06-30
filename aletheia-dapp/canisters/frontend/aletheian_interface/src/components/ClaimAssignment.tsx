// src/components/ClaimAssignment.tsx
import React from 'react';
import PurpleButton from './PurpleButton';

interface ClaimAssignmentProps {
  claimId: string;
  claimText: string;
  deadline: string;
  status: string;
  complexity: string;
  onSelect: (claimId: string) => void;
}

const ClaimAssignment: React.FC<ClaimAssignmentProps> = ({ 
  claimId, 
  claimText, 
  deadline,
  status,
  complexity,
  onSelect 
}) => {
  const statusColor = status === 'Pending' ? 'bg-yellow-500' : 
                     status === 'In Progress' ? 'bg-blue-500' : 
                     'bg-green-500';
  
  const complexityColor = complexity === 'High' ? 'bg-red-500' : 
                         complexity === 'Medium' ? 'bg-yellow-500' : 
                         'bg-green-500';

  return (
    <div className="bg-purple-900 bg-opacity-20 border border-gold rounded-lg p-4 transition-all hover:bg-purple-900 hover:bg-opacity-30">
      <div className="flex justify-between items-start">
        <div>
          <div className="flex items-center gap-2 mb-2">
            <span className={`px-2 py-1 rounded text-xs ${statusColor}`}>{status}</span>
            <span className={`px-2 py-1 rounded text-xs ${complexityColor}`}>{complexity}</span>
          </div>
          <h3 className="text-lg font-semibold text-cream">Claim ID: {claimId}</h3>
          <p className="text-cream text-opacity-80 mt-2 line-clamp-2">{claimText}</p>
        </div>
        <PurpleButton onClick={() => onSelect(claimId)}>Review</PurpleButton>
      </div>
      <div className="mt-4 flex justify-between items-center">
        <span className="text-sm text-gold">Deadline: {deadline}</span>
      </div>
    </div>
  );
};

export default ClaimAssignment;