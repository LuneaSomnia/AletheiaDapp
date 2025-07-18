import React, { useState } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import GlassCard from '../components/GlassCard';
import GoldButton from '../components/GoldButton';
import { RootState, updateNotificationSettings, updatePrivacySettings, updateAppearanceSettings, updateLearningSettings } from '../services/store';

const SettingsPage: React.FC = () => {
  const dispatch = useDispatch();
  const settings = useSelector((state: RootState) => state.settings);
  const [activeTab, setActiveTab] = useState('notifications');

  const tabs = [
    { id: 'notifications', label: 'Notifications', icon: '🔔' },
    { id: 'privacy', label: 'Privacy', icon: '🔒' },
    { id: 'appearance', label: 'Appearance', icon: '🎨' },
    { id: 'learning', label: 'Learning', icon: '📚' }
  ];

  const handleNotificationChange = (key: string, value: boolean) => {
    dispatch(updateNotificationSettings({ [key]: value }));
  };

  const handlePrivacyChange = (key: string, value: any) => {
    dispatch(updatePrivacySettings({ [key]: value }));
  };

  const handleAppearanceChange = (key: string, value: any) => {
    dispatch(updateAppearanceSettings({ [key]: value }));
  };

  const handleLearningChange = (key: string, value: any) => {
    dispatch(updateLearningSettings({ [key]: value }));
  };

  const renderNotificationsTab = () => (
    <div className="space-y-6">
      <h3 className="text-xl font-bold text-gold mb-4">Notification Preferences</h3>
      
      <div className="space-y-4">
        {Object.entries(settings.notifications).map(([key, value]) => (
          <div key={key} className="flex items-center justify-between p-4 bg-red-900 bg-opacity-20 rounded-lg">
            <div>
              <label className="text-cream font-medium capitalize">
                {key.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
              </label>
              <p className="text-cream text-sm opacity-75">
                {key === 'claimUpdates' && 'Get notified when your claims are updated'}
                {key === 'learningRewards' && 'Receive notifications for learning achievements'}
                {key === 'weeklyDigest' && 'Get a weekly summary of your activity'}
                {key === 'newFeatures' && 'Be notified about new features and updates'}
                {key === 'emailNotifications' && 'Receive notifications via email'}
                {key === 'pushNotifications' && 'Receive push notifications in browser'}
              </p>
            </div>
            <label className="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                checked={value}
                onChange={(e) => handleNotificationChange(key, e.target.checked)}
                className="sr-only peer"
              />
              <div className="w-11 h-6 bg-red-900 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-gold"></div>
            </label>
          </div>
        ))}
      </div>
    </div>
  );

  const renderPrivacyTab = () => (
    <div className="space-y-6">
      <h3 className="text-xl font-bold text-gold mb-4">Privacy Settings</h3>
      
      <div className="space-y-4">
        <div className="p-4 bg-red-900 bg-opacity-20 rounded-lg">
          <label className="text-cream font-medium block mb-2">Profile Visibility</label>
          <select
            value={settings.privacy.profileVisibility}
            onChange={(e) => handlePrivacyChange('profileVisibility', e.target.value)}
            className="bg-red-900 bg-opacity-30 border border-gold rounded-lg p-2 text-cream w-full"
          >
            <option value="public">Public</option>
            <option value="private">Private</option>
            <option value="friends">Friends Only</option>
          </select>
        </div>

        {Object.entries(settings.privacy).filter(([key]) => key !== 'profileVisibility').map(([key, value]) => (
          <div key={key} className="flex items-center justify-between p-4 bg-red-900 bg-opacity-20 rounded-lg">
            <div>
              <label className="text-cream font-medium capitalize">
                {key.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
              </label>
            </div>
            <label className="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                checked={value as boolean}
                onChange={(e) => handlePrivacyChange(key, e.target.checked)}
                className="sr-only peer"
              />
              <div className="w-11 h-6 bg-red-900 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-gold"></div>
            </label>
          </div>
        ))}
      </div>
    </div>
  );

  const renderAppearanceTab = () => (
    <div className="space-y-6">
      <h3 className="text-xl font-bold text-gold mb-4">Appearance Settings</h3>
      
      <div className="space-y-4">
        <div className="p-4 bg-red-900 bg-opacity-20 rounded-lg">
          <label className="text-cream font-medium block mb-2">Theme</label>
          <select
            value={settings.appearance.theme}
            onChange={(e) => handleAppearanceChange('theme', e.target.value)}
            className="bg-red-900 bg-opacity-30 border border-gold rounded-lg p-2 text-cream w-full"
          >
            <option value="light">Light</option>
            <option value="dark">Dark</option>
            <option value="auto">Auto</option>
          </select>
        </div>

        <div className="p-4 bg-red-900 bg-opacity-20 rounded-lg">
          <label className="text-cream font-medium block mb-2">Font Size</label>
          <select
            value={settings.appearance.fontSize}
            onChange={(e) => handleAppearanceChange('fontSize', e.target.value)}
            className="bg-red-900 bg-opacity-30 border border-gold rounded-lg p-2 text-cream w-full"
          >
            <option value="small">Small</option>
            <option value="medium">Medium</option>
            <option value="large">Large</option>
          </select>
        </div>

        <div className="flex items-center justify-between p-4 bg-red-900 bg-opacity-20 rounded-lg">
          <label className="text-cream font-medium">Animations</label>
          <label className="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              checked={settings.appearance.animations}
              onChange={(e) => handleAppearanceChange('animations', e.target.checked)}
              className="sr-only peer"
            />
            <div className="w-11 h-6 bg-red-900 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-gold"></div>
          </label>
        </div>
      </div>
    </div>
  );

  const renderLearningTab = () => (
    <div className="space-y-6">
      <h3 className="text-xl font-bold text-gold mb-4">Learning Preferences</h3>
      
      <div className="space-y-4">
        <div className="p-4 bg-red-900 bg-opacity-20 rounded-lg">
          <label className="text-cream font-medium block mb-2">Difficulty Level</label>
          <select
            value={settings.learning.difficulty}
            onChange={(e) => handleLearningChange('difficulty', e.target.value)}
            className="bg-red-900 bg-opacity-30 border border-gold rounded-lg p-2 text-cream w-full"
          >
            <option value="beginner">Beginner</option>
            <option value="intermediate">Intermediate</option>
            <option value="advanced">Advanced</option>
          </select>
        </div>

        <div className="p-4 bg-red-900 bg-opacity-20 rounded-lg">
          <label className="text-cream font-medium block mb-2">Time Limit (minutes)</label>
          <input
            type="number"
            min="1"
            max="60"
            value={settings.learning.timeLimit}
            onChange={(e) => handleLearningChange('timeLimit', parseInt(e.target.value))}
            className="bg-red-900 bg-opacity-30 border border-gold rounded-lg p-2 text-cream w-full"
          />
        </div>

        {Object.entries(settings.learning).filter(([key]) => !['difficulty', 'timeLimit'].includes(key)).map(([key, value]) => (
          <div key={key} className="flex items-center justify-between p-4 bg-red-900 bg-opacity-20 rounded-lg">
            <div>
              <label className="text-cream font-medium capitalize">
                {key.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
              </label>
            </div>
            <label className="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                checked={value as boolean}
                onChange={(e) => handleLearningChange(key, e.target.checked)}
                className="sr-only peer"
              />
              <div className="w-11 h-6 bg-red-900 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-gold"></div>
            </label>
          </div>
        ))}
      </div>
    </div>
  );

  const renderTabContent = () => {
    switch (activeTab) {
      case 'notifications':
        return renderNotificationsTab();
      case 'privacy':
        return renderPrivacyTab();
      case 'appearance':
        return renderAppearanceTab();
      case 'learning':
        return renderLearningTab();
      default:
        return renderNotificationsTab();
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-red-900 via-red-800 to-red-900 p-4">
      <div className="max-w-4xl mx-auto">
        <GlassCard className="p-8">
          <h1 className="text-3xl font-bold text-gold mb-8 text-center">Settings</h1>

          {/* Tab Navigation */}
          <div className="flex flex-wrap gap-2 mb-8">
            {tabs.map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
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

          {/* Tab Content */}
          <div className="min-h-[400px]">
            {renderTabContent()}
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

export default SettingsPage; 