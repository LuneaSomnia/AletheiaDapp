import React, { useState } from 'react';
import GlassCard from '../components/GlassCard';
import GoldButton from '../components/GoldButton';

const LeaderboardPage: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'points' | 'badges' | 'streaks'>('points');

  // Mock leaderboard data
  const leaderboardData = {
    points: [
      { rank: 1, username: 'TruthSeeker_42', points: 15420, level: 15, avatar: '👑' },
      { rank: 2, username: 'FactChecker_Pro', points: 12850, level: 12, avatar: '🥈' },
      { rank: 3, username: 'CriticalThinker', points: 11230, level: 11, avatar: '🥉' },
      { rank: 4, username: 'VerificationMaster', points: 9870, level: 10, avatar: '🎯' },
      { rank: 5, username: 'EvidenceHunter', points: 8540, level: 9, avatar: '🔍' },
    ],
    badges: [
      { rank: 1, username: 'BadgeCollector', badges: 25, rareBadges: 8, avatar: '🏆' },
      { rank: 2, username: 'AchievementHunter', badges: 22, rareBadges: 6, avatar: '🎖️' },
      { rank: 3, username: 'MasterVerifier', badges: 20, rareBadges: 5, avatar: '⭐' },
      { rank: 4, username: 'TruthGuardian', badges: 18, rareBadges: 4, avatar: '🛡️' },
      { rank: 5, username: 'FactFinder', badges: 16, rareBadges: 3, avatar: '🔎' },
    ],
    streaks: [
      { rank: 1, username: 'StreakMaster', currentStreak: 45, longestStreak: 67, avatar: '🔥' },
      { rank: 2, username: 'DailyLearner', currentStreak: 38, longestStreak: 52, avatar: '📚' },
      { rank: 3, username: 'ConsistentChecker', currentStreak: 32, longestStreak: 48, avatar: '⚡' },
      { rank: 4, username: 'RegularVerifier', currentStreak: 28, longestStreak: 41, avatar: '🎯' },
      { rank: 5, username: 'SteadySeeker', currentStreak: 25, longestStreak: 35, avatar: '📈' },
    ]
  };

  const tabs = [
    { id: 'points', label: 'Points', icon: '🏆' },
    { id: 'badges', label: 'Badges', icon: '🎖️' },
    { id: 'streaks', label: 'Streaks', icon: '🔥' }
  ];

  const renderLeaderboardItem = (item: any, type: string) => {
    const getRankColor = (rank: number) => {
      switch (rank) {
        case 1: return 'bg-gradient-to-r from-yellow-400 to-yellow-600 text-yellow-900';
        case 2: return 'bg-gradient-to-r from-gray-300 to-gray-500 text-gray-900';
        case 3: return 'bg-gradient-to-r from-orange-400 to-orange-600 text-orange-900';
        default: return 'bg-red-900 bg-opacity-30';
      }
    };

    return (
      <div
        key={item.rank}
        className={`flex items-center p-4 rounded-lg border border-gold border-opacity-30 ${getRankColor(item.rank)}`}
      >
        <div className="text-2xl mr-4">{item.avatar}</div>
        <div className="flex-1">
          <div className="flex items-center gap-2">
            <span className="font-bold text-cream">#{item.rank}</span>
            <span className="font-semibold text-cream">{item.username}</span>
          </div>
          <div className="text-sm text-cream opacity-75">
            {type === 'points' && `Level ${item.level} • ${item.points.toLocaleString()} points`}
            {type === 'badges' && `${item.badges} badges • ${item.rareBadges} rare`}
            {type === 'streaks' && `${item.currentStreak} days • Longest: ${item.longestStreak} days`}
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-red-900 via-red-800 to-red-900 p-4">
      <div className="max-w-4xl mx-auto">
        <GlassCard className="p-8">
          <h1 className="text-3xl font-bold text-gold mb-8 text-center">Leaderboard</h1>

          {/* Tab Navigation */}
          <div className="flex justify-center mb-8">
            <div className="flex gap-2">
              {tabs.map((tab) => (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id as any)}
                  className={`flex items-center gap-2 px-4 py-2 rounded-lg transition-colors ${
                    activeTab === tab.id
                      ? 'bg-gold text-red-900 font-semibold'
                      : 'bg-red-900 bg-opacity-30 text-cream hover:bg-opacity-50'
                  }`}
                >
                  <span>{tab.icon}</span>
                  <span>{tab.label}</span>
                </button>
              ))}
            </div>
          </div>

          {/* Leaderboard Content */}
          <div className="space-y-4">
            {leaderboardData[activeTab].map((item) => renderLeaderboardItem(item, activeTab))}
          </div>

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

export default LeaderboardPage; 