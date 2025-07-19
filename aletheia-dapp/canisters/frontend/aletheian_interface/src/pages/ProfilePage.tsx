// src/pages/ProfilePage.tsx
import React from 'react';
import GlassCard from '../components/GlassCard';
import ReputationBadge from '../components/ReputationBadge';
import PurpleButton from '../components/PurpleButton';
import { useAuth } from '../services/auth';

const ProfilePage: React.FC = () => {
  const { user } = useAuth();

  // Use local penalties array to avoid linter error if not present on user
  const penalties = (user as any)?.penalties ?? [];

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
        <h1 className="text-3xl font-bold text-cream mb-8">Your Profile</h1>
        
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-1 flex flex-col gap-6">
            <ReputationBadge 
              xp={user.xp} 
              rank={user.rank} 
              badges={user.badges} 
            />
            {/* XP Progression */}
            <GlassCard className="p-4">
              <h3 className="text-lg font-bold text-gold mb-2">XP Progression</h3>
              <div className="mb-2 text-cream text-sm">Rank: <span className="text-gold font-bold">{user.rank || 'Acolyte'}</span></div>
              <div className="w-full bg-purple-900 bg-opacity-30 rounded-full h-4 mb-1">
                <div
                  className="bg-gold h-4 rounded-full"
                  style={{ width: `${Math.min(100, Math.round(((user.xp ?? 0) % 1000) / 10))}%` }}
                ></div>
              </div>
              <div className="text-xs text-right text-cream">{user.xp ?? 0} XP / {((Math.floor((user.xp ?? 0) / 1000) + 1) * 1000)} XP to next rank</div>
            </GlassCard>
            {/* Badge Gallery */}
            <GlassCard className="p-4">
              <h3 className="text-lg font-bold text-gold mb-2">Badges</h3>
              <div className="flex flex-wrap gap-2">
                {(user.badges && user.badges.length > 0) ? user.badges.map((badge: any, idx: number) => (
                  <span key={idx} className="inline-block bg-gold bg-opacity-20 border border-gold rounded-full px-3 py-1 text-xs text-gold font-semibold">{badge}</span>
                )) : <span className="text-cream text-xs">No badges yet</span>}
              </div>
            </GlassCard>
            {/* Warnings/Penalties Card */}
            <GlassCard className="p-4">
              <h3 className="text-lg font-bold text-gold mb-2">Warnings & Penalties</h3>
              <div className="space-y-2">
                {(penalties.length > 0) ? penalties.map((pen: any, idx: number) => (
                  <div key={idx} className="bg-red-900 bg-opacity-30 border border-red-400 rounded-lg p-2 text-red-300 text-xs">
                    <span className="font-bold">{pen.type}:</span> {pen.reason} <span className="ml-2 text-cream">({pen.date})</span>
                  </div>
                )) : (
                  <div className="text-cream text-xs">No warnings or penalties.</div>
                )}
                {/* Mock penalty if none present */}
                {penalties.length === 0 && (
                  <div className="bg-red-900 bg-opacity-30 border border-red-400 rounded-lg p-2 text-red-300 text-xs mt-2">
                    <span className="font-bold">Warning:</span> Example warning for late claim review. <span className="ml-2 text-cream">(2024-06-01)</span>
                  </div>
                )}
              </div>
            </GlassCard>
            {/* Analytics Card */}
            <GlassCard className="p-6">
              <h3 className="text-xl font-bold text-gold mb-4">Analytics</h3>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <div className="text-lg text-gold font-bold">42</div>
                  <div className="text-cream text-sm">Claims Submitted</div>
                </div>
                <div>
                  <div className="text-lg text-gold font-bold">98%</div>
                  <div className="text-cream text-sm">Accuracy</div>
                </div>
                <div>
                  <div className="text-lg text-gold font-bold">1845</div>
                  <div className="text-cream text-sm">Learning Points</div>
                </div>
                <div>
                  <div className="text-lg text-gold font-bold">12</div>
                  <div className="text-cream text-sm">Streak (days)</div>
                </div>
              </div>
            </GlassCard>
            {/* Security Settings Card */}
            <GlassCard className="p-6">
              <h3 className="text-xl font-bold text-gold mb-4">Security Settings</h3>
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-cream">Password</span>
                  <PurpleButton className="small-button" onClick={() => console.log('Change password')}>Change</PurpleButton>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-cream">Two-Factor Auth</span>
                  <PurpleButton className="small-button" onClick={() => console.log('2FA settings')}>Manage</PurpleButton>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-cream">Connected Wallets</span>
                  <PurpleButton className="small-button" onClick={() => console.log('Wallet settings')}>Manage</PurpleButton>
                </div>
              </div>
            </GlassCard>
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
              <div className="mb-6">
                <label className="block text-cream mb-2">Location</label>
                <input
                  type="text"
                  defaultValue={'Nairobi, Kenya'}
                  placeholder="Enter your location"
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
              <PurpleButton
                className="w-full py-4"
                onClick={() => console.log('Button clicked!')}
              >
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