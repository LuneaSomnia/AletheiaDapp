// src/components/ProfileSection.tsx
import React from 'react';
import GlassCard from './GlassCard';
import GoldButton from './GoldButton';

interface UserProfile {
  username: string;
  joinedDate: string;
  submittedClaims: number;
  learningPoints: number;
  accuracyRating: number;
}

const ProfileSection: React.FC<{ profile: UserProfile }> = ({ profile }) => {
  return (
    <GlassCard className="p-6">
      <div className="flex flex-col md:flex-row gap-8">
        <div className="flex-shrink-0">
          <div className="bg-gradient-to-br from-gold-light to-gold-dark w-32 h-32 rounded-full flex items-center justify-center">
            <span className="text-4xl font-bold text-red-900">
              {profile.username.charAt(0).toUpperCase()}
            </span>
          </div>
        </div>
        
        <div className="flex-1">
          <h2 className="text-2xl font-bold text-cream mb-4">Your Profile</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
            <div className="bg-red-900 bg-opacity-30 border border-gold rounded-lg p-4">
              <p className="text-cream text-opacity-80">Username</p>
              <p className="text-xl font-bold text-cream">{profile.username}</p>
            </div>
            
            <div className="bg-red-900 bg-opacity-30 border border-gold rounded-lg p-4">
              <p className="text-cream text-opacity-80">Member Since</p>
              <p className="text-xl font-bold text-cream">{profile.joinedDate}</p>
            </div>
            
            <div className="bg-red-900 bg-opacity-30 border border-gold rounded-lg p-4">
              <p className="text-cream text-opacity-80">Claims Submitted</p>
              <p className="text-xl font-bold text-gold">{profile.submittedClaims}</p>
            </div>
            
            <div className="bg-red-900 bg-opacity-30 border border-gold rounded-lg p-4">
              <p className="text-cream text-opacity-80">Learning Points</p>
              <p className="text-xl font-bold text-gold">{profile.learningPoints}</p>
            </div>
          </div>
          
          <div className="mb-6">
            <div className="flex justify-between mb-2">
              <span className="text-cream">Fact-Checking Accuracy</span>
              <span className="text-gold">{profile.accuracyRating}%</span>
            </div>
            <div className="w-full bg-red-900 bg-opacity-20 rounded-full h-4">
              <div 
                className="bg-gradient-to-r from-gold-light to-gold-dark h-4 rounded-full" 
                style={{ width: `${profile.accuracyRating}%` }}
              ></div>
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