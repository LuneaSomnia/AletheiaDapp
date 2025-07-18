import React, { useState } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import GlassCard from '../components/GlassCard';
import GoldButton from '../components/GoldButton';
import { RootState, markAsRead, markAllAsRead, removeNotification, clearAllNotifications } from '../services/store';

const NotificationCenterPage: React.FC = () => {
  const dispatch = useDispatch();
  const notifications = useSelector((state: RootState) => state.notifications);
  const [filter, setFilter] = useState<'all' | 'unread' | 'read'>('all');

  const filteredNotifications = notifications.filter(notification => {
    if (filter === 'unread') return !notification.read;
    if (filter === 'read') return notification.read;
    return true;
  });

  const handleMarkAsRead = (id: string) => {
    dispatch(markAsRead(id));
  };

  const handleMarkAllAsRead = () => {
    dispatch(markAllAsRead());
  };

  const handleRemoveNotification = (id: string) => {
    dispatch(removeNotification(id));
  };

  const handleClearAll = () => {
    dispatch(clearAllNotifications());
  };

  const getNotificationIcon = (type: string) => {
    switch (type) {
      case 'success': return '✅';
      case 'warning': return '⚠️';
      case 'error': return '❌';
      default: return 'ℹ️';
    }
  };

  const getNotificationColor = (type: string) => {
    switch (type) {
      case 'success': return 'border-green-500 bg-green-900 bg-opacity-20';
      case 'warning': return 'border-yellow-500 bg-yellow-900 bg-opacity-20';
      case 'error': return 'border-red-500 bg-red-900 bg-opacity-20';
      default: return 'border-blue-500 bg-blue-900 bg-opacity-20';
    }
  };

  const formatTimestamp = (timestamp: string) => {
    const date = new Date(timestamp);
    const now = new Date();
    const diffInMinutes = Math.floor((now.getTime() - date.getTime()) / (1000 * 60));
    
    if (diffInMinutes < 1) return 'Just now';
    if (diffInMinutes < 60) return `${diffInMinutes}m ago`;
    if (diffInMinutes < 1440) return `${Math.floor(diffInMinutes / 60)}h ago`;
    return date.toLocaleDateString();
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-red-900 via-red-800 to-red-900 p-4">
      <div className="max-w-4xl mx-auto">
        <GlassCard className="p-8">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-8">
            <h1 className="text-3xl font-bold text-gold mb-4 md:mb-0">Notification Center</h1>
            <div className="flex flex-wrap gap-2">
              <select
                value={filter}
                onChange={(e) => setFilter(e.target.value as any)}
                className="bg-red-900 bg-opacity-30 border border-gold rounded-lg p-2 text-cream"
              >
                <option value="all">All Notifications</option>
                <option value="unread">Unread Only</option>
                <option value="read">Read Only</option>
              </select>
              <GoldButton onClick={handleMarkAllAsRead} className="bg-transparent border-gold text-gold hover:bg-gold hover:text-red-900">
                Mark All Read
              </GoldButton>
              <GoldButton onClick={handleClearAll} className="bg-transparent border-red-500 text-red-400 hover:bg-red-500 hover:text-white">
                Clear All
              </GoldButton>
            </div>
          </div>

          {filteredNotifications.length === 0 ? (
            <div className="text-center py-12">
              <div className="text-6xl mb-4">🔔</div>
              <h3 className="text-xl font-bold text-gold mb-2">No Notifications</h3>
              <p className="text-cream">
                {filter === 'all' 
                  ? "You're all caught up! No notifications to show."
                  : filter === 'unread'
                  ? "No unread notifications."
                  : "No read notifications."
                }
              </p>
            </div>
          ) : (
            <div className="space-y-4">
              {filteredNotifications.map((notification) => (
                <div
                  key={notification.id}
                  className={`p-4 rounded-lg border-2 transition-all ${
                    getNotificationColor(notification.type)
                  } ${notification.read ? 'opacity-75' : ''}`}
                >
                  <div className="flex items-start justify-between">
                    <div className="flex items-start gap-3 flex-1">
                      <div className="text-2xl mt-1">
                        {getNotificationIcon(notification.type)}
                      </div>
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-1">
                          <h3 className="font-bold text-cream">{notification.title}</h3>
                          {!notification.read && (
                            <span className="bg-gold text-red-900 text-xs px-2 py-1 rounded-full font-bold">
                              NEW
                            </span>
                          )}
                        </div>
                        <p className="text-cream mb-2">{notification.message}</p>
                        <div className="flex items-center gap-4 text-sm text-cream opacity-75">
                          <span>{formatTimestamp(notification.timestamp)}</span>
                          {notification.action && (
                            <button
                              onClick={() => window.open(notification.action!.url, '_blank')}
                              className="text-gold hover:underline"
                            >
                              {notification.action.label}
                            </button>
                          )}
                        </div>
                      </div>
                    </div>
                    <div className="flex gap-2 ml-4">
                      {!notification.read && (
                        <button
                          onClick={() => handleMarkAsRead(notification.id)}
                          className="text-gold hover:text-yellow-400 text-sm"
                        >
                          Mark Read
                        </button>
                      )}
                      <button
                        onClick={() => handleRemoveNotification(notification.id)}
                        className="text-red-400 hover:text-red-300 text-sm"
                      >
                        Remove
                      </button>
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

export default NotificationCenterPage; 