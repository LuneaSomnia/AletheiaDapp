// src/components/ProfileSection.tsx
import React from 'react';
import GlassCard from './GlassCard';
import GoldButton from './GoldButton';

interface UserProfile {
  id: string;
  username: string;
  joinedDate: string;
  submittedClaims: number;
  learningPoints: number;
  accuracyRating: number;
  notificationPreferences?: {
    email: boolean;
    push: boolean;
  };
  activityHistory?: Array<{
    type: 'claim' | 'learning';
    description: string;
    date: string;
  }>;
  learningProgress?: {
    completed: number;
    total: number;
  };
}

const ProfileSection: React.FC<{ profile: Partial<UserProfile> | null }> = ({ profile }) => {
  if (!profile) {
    return <div>No profile data available</div>; // or some other default content
  }

  const {
    id = 'N/A',
    username = '',
    joinedDate = '',
    submittedClaims = 0,
    learningPoints = 0,
    accuracyRating = 0,
    notificationPreferences = { email: true, push: false },
    activityHistory = [],
    learningProgress = { completed: 0, total: 0 },
  } = profile;

  return (
    <GlassCard className="p-6">
      <div className="flex flex-col md:flex-row gap-8">
        <div className="flex-shrink-0">
          <div className="bg-gradient-to-br from-gold-light to-gold-dark w-32 h-32 rounded-full flex items-center justify-center">
            <span className="text-4xl font-bold text-red-900">
              <p className="text-4xl font-bold text-red-900">
                 {username?.charAt(0).toUpperCase()}
              </p>
            </span>
          </div>
          {/* Unique Identifier */}
          <div className="mt-4 text-xs text-center text-cream bg-red-900 bg-opacity-30 rounded p-2">
            <span className="font-semibold">User ID:</span> {id}
          </div>
        </div>
        
        <div className="flex-1">
          <h2 className="text-2xl font-bold text-cream mb-4">Your Profile</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
            <div className="bg-red-900 bg-opacity-30 border border-gold rounded-lg p-4">
              <p className="text-cream text-opacity-80">Username</p>
              <p className="text-xl font-bold text-cream">{username}</p>
            </div>
            
            <div className="bg-red-900 bg-opacity-30 border border-gold rounded-lg p-4">
              <p className="text-cream text-opacity-80">Member Since</p>
              <p className="text-xl font-bold text-cream">{joinedDate}</p>
            </div>
            
            <div className="bg-red-900 bg-opacity-30 border border-gold rounded-lg p-4">
              <p className="text-cream text-opacity-80">Claims Submitted</p>
              <p className="text-xl font-bold text-gold">{submittedClaims}</p>
            </div>
            
            <div className="bg-red-900 bg-opacity-30 border border-gold rounded-lg p-4">
              <p className="text-cream text-opacity-80">Learning Points</p>
              <p className="text-xl font-bold text-gold">{learningPoints}</p>
            </div>
          </div>
          
          <div className="mb-6">
            <div className="flex justify-between mb-2">
              <span className="text-cream">Fact-Checking Accuracy</span>
              <span className="text-gold">{accuracyRating}%</span>
            </div>
            <div className="w-full bg-red-900 bg-opacity-20 rounded-full h-4">
              <div 
                className="bg-gold h-4 rounded-full"
                style={{ width: `${accuracyRating}%` }}
              ></div>
            </div>
          </div>

          {/* Settings Section */}
          <div className="mb-6">
            <h3 className="text-lg font-semibold text-cream mb-2">Settings</h3>
            <div className="flex flex-col gap-2">
              <div className="flex items-center gap-2">
                <span className="text-cream">Email Notifications</span>
                <input
                  type="checkbox"
                  checked={notificationPreferences.email}
                  readOnly
                  className="accent-gold"
                />
              </div>
              <div className="flex items-center gap-2">
                <span className="text-cream">Push Notifications</span>
                <input
                  type="checkbox"
                  checked={notificationPreferences.push}
                  readOnly
                  className="accent-gold"
                />
              </div>
              <GoldButton className="w-fit mt-2" onClick={() => console.log('Privacy Settings button clicked')}>Privacy Settings</GoldButton>
            </div>
          </div>

          {/* Activity History Section */}
          <div className="mb-6">
            <h3 className="text-lg font-semibold text-cream mb-2">Activity History</h3>
            <div className="bg-red-900 bg-opacity-20 rounded-lg p-4 mb-2">
              <p className="text-cream text-opacity-80 mb-1 font-semibold">Recent Claims</p>
              <ul className="list-disc list-inside text-cream text-sm">
                {activityHistory.filter(a => a.type === 'claim').length > 0 ? (
                  activityHistory.filter(a => a.type === 'claim').map((item, idx) => (
                    <li key={idx}>{item.description} <span className="text-xs text-gold">({item.date})</span></li>
                  ))
                ) : (
                  <li>No recent claims.</li>
                )}
              </ul>
            </div>
            <div className="bg-red-900 bg-opacity-20 rounded-lg p-4">
              <p className="text-cream text-opacity-80 mb-1 font-semibold">Learning Progress</p>
              <div className="flex items-center gap-2">
                <span className="text-gold font-bold">{learningProgress.completed}</span>
                <span className="text-cream">/</span>
                <span className="text-cream">{learningProgress.total}</span>
                <span className="text-cream">modules completed</span>
              </div>
              <div className="w-full bg-gold bg-opacity-20 rounded-full h-2 mt-2">
                <div
                  className="bg-gold h-2 rounded-full"
                  style={{ width: `${learningProgress.total > 0 ? (learningProgress.completed / learningProgress.total) * 100 : 0}%` }}
                ></div>
              </div>
            </div>
          </div>

          <div className="flex gap-4">
            <GoldButton className="flex-1" onClick={() => console.log('Edit Profile button clicked')}>Edit Profile</GoldButton>
            <GoldButton className="flex-1" onClick={() => console.log('Privacy Settings button clicked')}>Privacy Settings</GoldButton>
          </div>
        </div>
      </div>
    </GlassCard>
  );
};

export default ProfileSection;