// src/components/ClaimAssignment.tsx
import React, { useState } from 'react';
import PurpleButton from './PurpleButton';

interface ClaimAssignmentProps {
  claimId: string;
  claimText: string;
  deadline: string; // ISO string or readable date
  status: string;
  complexity: string;
  onSelect: (claimId: string) => void;
  onAccept?: (claimId: string) => void;
  onDecline?: (claimId: string) => void;
  details?: string; // Optional extra details
}

const ClaimAssignment: React.FC<ClaimAssignmentProps> = ({ 
  claimId, 
  claimText, 
  deadline,
  status,
  complexity,
  onSelect,
  onAccept,
  onDecline,
  details
}) => {
  const [showDetails, setShowDetails] = useState(false);
  // Status color
  const statusColor = status === 'Pending' ? 'bg-yellow-500' : 
                     status === 'In Progress' ? 'bg-blue-500' : 
                     'bg-green-500';
  // Complexity color
  const complexityColor = complexity === 'High' ? 'bg-red-500' : 
                         complexity === 'Medium' ? 'bg-yellow-500' : 
                         'bg-green-500';
  // Urgency indicator
  let urgencyColor = 'bg-green-500';
  let urgencyLabel = 'Low';
  try {
    const now = new Date();
    const due = new Date(deadline);
    const hours = (due.getTime() - now.getTime()) / (1000 * 60 * 60);
    if (hours < 24) {
      urgencyColor = 'bg-red-500'; urgencyLabel = 'High';
    } else if (hours < 72) {
      urgencyColor = 'bg-yellow-500'; urgencyLabel = 'Medium';
    }
  } catch {}

  return (
    <div className="bg-purple-900 bg-opacity-20 border border-gold rounded-lg p-4 transition-all hover:bg-purple-900 hover:bg-opacity-30">
      <div className="flex justify-between items-start">
        <div>
          <div className="flex items-center gap-2 mb-2">
            <span className={`px-2 py-1 rounded text-xs ${statusColor}`}>{status}</span>
            <span className={`px-2 py-1 rounded text-xs ${complexityColor}`}>{complexity}</span>
            {/* Urgency indicator */}
            <span className={`flex items-center gap-1 px-2 py-1 rounded text-xs ${urgencyColor} text-white`}>
              <span className="w-2 h-2 rounded-full inline-block bg-white opacity-80"></span>
              {urgencyLabel} Urgency
            </span>
          </div>
          <h3 className="text-lg font-semibold text-cream">Claim ID: {claimId}</h3>
          <p className="text-cream text-opacity-80 mt-2 line-clamp-2">{claimText}</p>
          <div className="mt-2 flex gap-2">
            <PurpleButton onClick={() => setShowDetails(true)} className="small-button">View Details</PurpleButton>
            <PurpleButton onClick={() => onSelect(claimId)} className="small-button">Review</PurpleButton>
            {onAccept && <PurpleButton onClick={() => onAccept(claimId)} className="small-button">Accept</PurpleButton>}
            {onDecline && <PurpleButton onClick={() => onDecline(claimId)} className="small-button bg-red-700 hover:bg-red-800">Decline</PurpleButton>}
          </div>
        </div>
      </div>
      <div className="mt-4 flex justify-between items-center">
        <span className="text-sm text-gold">Deadline: {deadline}</span>
      </div>
      {/* Details Modal */}
      {showDetails && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-60">
          <div className="bg-purple-900 border border-gold rounded-lg p-6 max-w-lg w-full relative">
            <button className="absolute top-2 right-2 text-gold text-xl" onClick={() => setShowDetails(false)}>&times;</button>
            <h2 className="text-xl font-bold text-gold mb-4">Claim Details</h2>
            <div className="text-cream whitespace-pre-line mb-4">{details || claimText}</div>
            <div className="flex justify-end">
              <PurpleButton onClick={() => setShowDetails(false)} className="small-button">Close</PurpleButton>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ClaimAssignment;