// src/pages/ProfilePage.tsx
import React, { useState } from 'react';
import ProfileSection from '../components/ProfileSection';
import GlassCard from '../components/GlassCard';
import GoldButton from '../components/GoldButton';

const activityData = [
  { date: 'Jun 15', type: 'Claim', activity: 'Claim Submitted', details: '"Chocolate prevents aging"', points: 25 },
  { date: 'Jun 14', type: 'Learning', activity: 'Learning Exercise', details: 'Source Evaluation', points: 50 },
  { date: 'Jun 12', type: 'Claim', activity: 'Fact Shared', details: 'Bleach COVID myth', points: 15 },
  { date: 'Jun 10', type: 'Other', activity: 'Accuracy Bonus', details: '5 verified claims', points: 100 },
  { date: 'Jun 09', type: 'Claim', activity: 'Claim Verified', details: '"Coffee cures headaches"', points: 30 },
  { date: 'Jun 08', type: 'Learning', activity: 'Module Completed', details: 'Bias Recognition', points: 40 },
  { date: 'Jun 07', type: 'Other', activity: 'Profile Updated', details: 'Changed username', points: 0 },
];

const activityTypes = ['All', 'Claim', 'Learning', 'Other'];

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

  const [activityFilter, setActivityFilter] = useState('All');

  const handleNotificationChange = (key: string) => {
    setNotifications(prev => ({
      ...prev,
      [key as keyof typeof prev]: !prev[key as keyof typeof prev]
    }));
  };

  const filteredActivity = activityFilter === 'All'
    ? activityData
    : activityData.filter(a => a.type === activityFilter);

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
              {/* Privacy Settings Section */}
              <div className="mt-8">
                <h2 className="text-2xl font-bold text-cream mb-4">Privacy Settings</h2>
                <div className="space-y-4">
                  <GoldButton onClick={() => console.log('Privacy Settings clicked')} className="w-full bg-purple-900 border-purple-700">
                    Manage Privacy
                  </GoldButton>
                  <GoldButton onClick={() => console.log('Profile Visibility clicked')} className="w-full bg-purple-900 border-purple-700">
                    Profile Visibility
                  </GoldButton>
                  <GoldButton onClick={() => console.log('Data Download clicked')} className="w-full bg-purple-900 border-purple-700">
                    Download My Data
                  </GoldButton>
                </div>
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
            <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-4 gap-4">
              <h2 className="text-2xl font-bold text-cream">Recent Activity</h2>
              <div>
                <label htmlFor="activityFilter" className="text-cream mr-2">Filter:</label>
                <select
                  id="activityFilter"
                  value={activityFilter}
                  onChange={e => setActivityFilter(e.target.value)}
                  className="bg-red-900 bg-opacity-30 border border-gold rounded-lg p-2 text-cream"
                >
                  {activityTypes.map(type => (
                    <option key={type} value={type}>{type}</option>
                  ))}
                </select>
              </div>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="bg-red-900 bg-opacity-30">
                    <th className="py-3 px-4 text-left text-cream">Date</th>
                    <th className="py-3 px-4 text-left text-cream">Type</th>
                    <th className="py-3 px-4 text-left text-cream">Activity</th>
                    <th className="py-3 px-4 text-left text-cream">Details</th>
                    <th className="py-3 px-4 text-left text-cream">Points</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredActivity.map((row, idx) => (
                    <tr key={idx} className="border-b border-red-800">
                      <td className="py-3 px-4 text-cream">{row.date}</td>
                      <td className="py-3 px-4 text-cream">{row.type}</td>
                      <td className="py-3 px-4 text-cream">{row.activity}</td>
                      <td className="py-3 px-4 text-gold">{row.details}</td>
                      <td className="py-3 px-4 text-gold">{row.points > 0 ? `+${row.points}` : row.points}</td>
                    </tr>
                  ))}
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