// src/pages/ProfilePage.tsx
import React from 'react';
import GlassCard from '../components/GlassCard';
import ReputationBadge from '../components/ReputationBadge';
import PurpleButton from '../components/PurpleButton';
import { useAuth } from '../services/auth';

const ProfilePage: React.FC = () => {
  const { user } = useAuth();

  if (!user) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-gold mx-auto"></div>
          <p className="mt-4 text-cream">Loading profile...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen p-4">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-3xl font-bold text-cream mb-8">Your Profile</h1>
        
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-1">
            <ReputationBadge 
              xp={user.xp} 
              rank={user.rank} 
              badges={user.badges} 
            />
          </div>
          
          <div className="lg:col-span-2">
            <GlassCard className="p-8">
              <h2 className="text-2xl font-bold text-cream mb-6">Account Information</h2>
              
              <div className="mb-6">
                <label className="block text-cream mb-2">Principal ID</label>
                <div className="bg-purple-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream truncate">
                  {user.principal}
                </div>
              </div>
              
              <div className="mb-6">
                <label className="block text-cream mb-2">Username</label>
                <input
                  type="text"
                  defaultValue={user.username || 'Not set'}
                  className="w-full bg-purple-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream"
                />
              </div>
              
              <div className="mb-8">
                <label className="block text-cream mb-2">Email (Optional)</label>
                <input
                  type="email"
                  placeholder="your@email.com"
                  className="w-full bg-purple-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream"
                />
              </div>
              
              <PurpleButton className="w-full py-4">
                Update Profile
              </PurpleButton>
            </GlassCard>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ProfilePage;