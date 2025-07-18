import React, { useState } from 'react';
import { useSelector } from 'react-redux';
import { useNavigate } from 'react-router-dom';
import GlassCard from '../components/GlassCard';
import GoldButton from '../components/GoldButton';
import { RootState } from '../services/store';

const ClaimHistoryPage: React.FC = () => {
  const navigate = useNavigate();
  const userClaims = useSelector((state: RootState) => state.app.userClaims);
  const [filter, setFilter] = useState<'all' | 'pending' | 'completed' | 'rejected'>('all');

  // Mock data for demonstration
  const mockClaims = [
    {
      id: '1',
      title: 'COVID-19 Vaccine Effectiveness',
      content: 'Claim about vaccine effectiveness rates...',
      status: 'completed',
      submittedAt: '2024-01-15T10:30:00Z',
      result: 'verified',
      type: 'text'
    },
    {
      id: '2',
      title: 'Climate Change Data',
      content: 'Analysis of global temperature trends...',
      status: 'pending',
      submittedAt: '2024-01-14T15:45:00Z',
      type: 'link'
    },
    {
      id: '3',
      title: 'Social Media Post',
      content: 'Viral post about economic policies...',
      status: 'completed',
      submittedAt: '2024-01-13T09:20:00Z',
      result: 'disputed',
      type: 'image'
    }
  ];

  const claims = userClaims.length > 0 ? userClaims : mockClaims;

  const filteredClaims = claims.filter(claim => {
    if (filter === 'all') return true;
    return claim.status === filter;
  });

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pending': return 'bg-yellow-600';
      case 'completed': return 'bg-green-600';
      case 'rejected': return 'bg-red-600';
      default: return 'bg-gray-600';
    }
  };

  const getResultColor = (result: string) => {
    switch (result) {
      case 'verified': return 'text-green-400';
      case 'disputed': return 'text-red-400';
      case 'inconclusive': return 'text-yellow-400';
      default: return 'text-gray-400';
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-red-900 via-red-800 to-red-900 p-4">
      <div className="max-w-6xl mx-auto">
        <GlassCard className="p-8">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-8">
            <h1 className="text-3xl font-bold text-gold mb-4 md:mb-0">Claim History</h1>
            <div className="flex gap-2">
              <select
                value={filter}
                onChange={(e) => setFilter(e.target.value as any)}
                className="bg-red-900 bg-opacity-30 border border-gold rounded-lg p-2 text-cream"
              >
                <option value="all">All Claims</option>
                <option value="pending">Pending</option>
                <option value="completed">Completed</option>
                <option value="rejected">Rejected</option>
              </select>
              <GoldButton onClick={() => navigate('/submit-claim')}>
                Submit New Claim
              </GoldButton>
            </div>
          </div>

          {filteredClaims.length === 0 ? (
            <div className="text-center py-12">
              <div className="text-6xl mb-4">📝</div>
              <h3 className="text-xl font-bold text-gold mb-2">No Claims Found</h3>
              <p className="text-cream mb-4">
                {filter === 'all' 
                  ? "You haven't submitted any claims yet."
                  : `No ${filter} claims found.`
                }
              </p>
              <GoldButton onClick={() => navigate('/submit-claim')}>
                Submit Your First Claim
              </GoldButton>
            </div>
          ) : (
            <div className="space-y-4">
              {filteredClaims.map((claim) => (
                <div
                  key={claim.id}
                  className="p-6 bg-red-900 bg-opacity-20 rounded-lg border border-gold border-opacity-30 hover:border-opacity-60 transition-all cursor-pointer"
                  onClick={() => navigate(`/claim-result/${claim.id}`)}
                >
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-2">
                        <h3 className="text-xl font-bold text-cream">{claim.title}</h3>
                        <span className={`px-2 py-1 rounded-full text-xs font-bold text-white ${getStatusColor(claim.status)}`}>
                          {claim.status.toUpperCase()}
                        </span>
                        {claim.result && (
                          <span className={`text-sm font-semibold ${getResultColor(claim.result)}`}>
                            {claim.result.toUpperCase()}
                          </span>
                        )}
                      </div>
                      <p className="text-cream mb-3 line-clamp-2">{claim.content}</p>
                      <div className="flex items-center gap-4 text-sm text-cream opacity-75">
                        <span>Type: {claim.type}</span>
                        <span>Submitted: {formatDate(claim.submittedAt)}</span>
                      </div>
                    </div>
                    <div className="text-gold text-2xl ml-4">
                      →
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}

          <div className="mt-8 text-center">
            <GoldButton onClick={() => window.history.back()}>
              Back to Dashboard
            </GoldButton>
          </div>
        </GlassCard>
      </div>
    </div>
  );
};

export default ClaimHistoryPage; 