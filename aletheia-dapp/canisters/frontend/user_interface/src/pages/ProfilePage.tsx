// src/pages/ProfilePage.tsx
import React, { useState } from 'react';
import ProfileSection from '../components/ProfileSection';
import GlassCard from '../components/GlassCard';
import GoldButton from '../components/GoldButton';

const ProfilePage: React.FC = () => {
  const [profile, setProfile] = useState({
    username: "TruthSeeker42",
    joinedDate: "May 15, 2023",
    submittedClaims: 27,
    learningPoints: 1845,
    accuracyRating: 86
  });
  
  const [notifications, setNotifications] = useState({
    claimUpdates: true,
    learningRewards: true,
    weeklyDigest: false,
    newFeatures: true
  });
  
  const handleNotificationChange = (key: string) => {
    setNotifications(prev => ({
      ...prev,
      [key]: !prev[key as keyof typeof prev]
    }));
  };

  return (
    <div className="min-h-screen p-4"
         style={{
           background: 'linear-gradient(135deg, #8B0000 0%, #4B0000 100%), url(/assets/textures/red-gold-bg.jpg)',
           backgroundBlendMode: 'overlay',
           backgroundSize: 'cover'
         }}>
      <div className="max-w-6xl mx-auto">
        <h1 className="text-3xl font-bold text-cream mb-8">Your Profile</h1>
        
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2">
            <ProfileSection profile={profile} />
          </div>
          
          <div className="lg:col-span-1">
            <GlassCard className="p-6">
              <h2 className="text-2xl font-bold text-cream mb-4">Notification Settings</h2>
              
              <div className="space-y-4">
                {Object.entries(notifications).map(([key, value]) => (
                  <div key={key} className="flex items-center justify-between">
                    <span className="text-cream capitalize">
                      {key.replace(/([A-Z])/g, ' $1').trim()}
                    </span>
                    <label className="switch">
                      <input 
                        type="checkbox" 
                        checked={value} 
                        onChange={() => handleNotificationChange(key)}
                      />
                      <span className="slider round"></span>
                    </label>
                  </div>
                ))}
              </div>
              
              <div className="mt-8">
                <h2 className="text-2xl font-bold text-cream mb-4">Account Security</h2>
                <div className="space-y-4">
                  <GoldButton onClick={() => console.log('Button clicked')} className="w-full">Change Password</GoldButton>
                  <GoldButton onClick={() => console.log('Button clicked')} className="w-full bg-red-900 border-red-700">
                     Two-Factor Authentication
                  </GoldButton>
                  <GoldButton onClick={() => console.log('Button clicked')} className="w-full bg-red-900 border-red-700">
                     Connected Wallets
                  </GoldButton>
                </div>
              </div>
            </GlassCard>
          </div>
          
          <GlassCard className="lg:col-span-3 p-6">
            <h2 className="text-2xl font-bold text-cream mb-4">Recent Activity</h2>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="bg-red-900 bg-opacity-30">
                    <th className="py-3 px-4 text-left text-cream">Date</th>
                    <th className="py-3 px-4 text-left text-cream">Activity</th>
                    <th className="py-3 px-4 text-left text-cream">Details</th>
                    <th className="py-3 px-4 text-left text-cream">Points</th>
                  </tr>
                </thead>
                <tbody>
                  <tr className="border-b border-red-800">
                    <td className="py-3 px-4 text-cream">Jun 15</td>
                    <td className="py-3 px-4 text-cream">Claim Submitted</td>
                    <td className="py-3 px-4 text-gold">"Chocolate prevents aging"</td>
                    <td className="py-3 px-4 text-gold">+25</td>
                  </tr>
                  <tr className="border-b border-red-800">
                    <td className="py-3 px-4 text-cream">Jun 14</td>
                    <td className="py-3 px-4 text-cream">Learning Exercise</td>
                    <td className="py-3 px-4 text-gold">Source Evaluation</td>
                    <td className="py-3 px-4 text-gold">+50</td>
                  </tr>
                  <tr className="border-b border-red-800">
                    <td className="py-3 px-4 text-cream">Jun 12</td>
                    <td className="py-3 px-4 text-cream">Fact Shared</td>
                    <td className="py-3 px-4 text-gold">Bleach COVID myth</td>
                    <td className="py-3 px-4 text-gold">+15</td>
                  </tr>
                  <tr>
                    <td className="py-3 px-4 text-cream">Jun 10</td>
                    <td className="py-3 px-4 text-cream">Accuracy Bonus</td>
                    <td className="py-3 px-4 text-gold">5 verified claims</td>
                    <td className="py-3 px-4 text-gold">+100</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </GlassCard>
        </div>
      </div>
    </div>
  );
};

export default ProfilePage;