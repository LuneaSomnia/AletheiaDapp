// src/components/NotificationBell.tsx
import React, { useState } from 'react';
import { useNotifications } from '../hooks/useNotifications';
import GlassCard from './GlassCard';

const NotificationBell: React.FC = () => {
  const { notifications, unreadCount, markRead, markAllRead } = useNotifications();
  const [showDropdown, setShowDropdown] = useState(false);

  const formatTimestamp = (timestamp: number) => {
    const date = new Date(timestamp);
    const now = new Date();
    const diffInMinutes = Math.floor((now.getTime() - date.getTime()) / (1000 * 60));
    
    if (diffInMinutes < 1) return 'Just now';
    if (diffInMinutes < 60) return `${diffInMinutes}m ago`;
    
    const diffInHours = Math.floor(diffInMinutes / 60);
    if (diffInHours < 24) return `${diffInHours}h ago`;
    
    const diffInDays = Math.floor(diffInHours / 24);
    return `${diffInDays}d ago`;
  };

  const getNotificationIcon = (type: string) => {
    switch (type) {
      case 'new_assignment': return '📋';
      case 'payment_received': return '💰';
      case 'escalation_assignment': return '⚡';
      case 'badge_earned': return '🏆';
      default: return 'ℹ️';
    }
  };

  return (
    <div className="relative">
      <button
        className="relative focus:outline-none"
        onClick={() => setShowDropdown(!showDropdown)}
        aria-label="Notifications"
      >
        <span className="text-3xl text-gold">🔔</span>
        {unreadCount > 0 && (
          <span className="absolute -top-1 -right-1 bg-gold text-red-900 text-xs font-bold rounded-full px-2 py-0.5 border-2 border-red-900 min-w-[20px] text-center">
            {unreadCount > 99 ? '99+' : unreadCount}
          </span>
        )}
      </button>

      {showDropdown && (
        <div className="absolute right-0 top-full mt-2 w-80 z-50">
          <GlassCard className="max-h-96 overflow-y-auto">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-bold text-gold">Notifications</h3>
              {unreadCount > 0 && (
                <button
                  onClick={markAllRead}
                  className="text-sm text-gold hover:underline"
                >
                  Mark all read
                </button>
              )}
            </div>

            {notifications.length === 0 ? (
              <p className="text-cream text-center py-4">No notifications</p>
            ) : (
              <div className="space-y-3">
                {notifications.slice(0, 10).map((notification) => (
                  <div
                    key={notification.id}
                    className={`p-3 rounded-lg border cursor-pointer transition-colors ${
                      notification.read
                        ? 'bg-purple-900 bg-opacity-20 border-purple-700'
                        : 'bg-gold bg-opacity-10 border-gold'
                    }`}
                    onClick={() => {
                      if (!notification.read) {
                        markRead(notification.id);
                      }
                    }}
                  >
                    <div className="flex items-start gap-3">
                      <span className="text-xl">
                        {getNotificationIcon(notification.notificationType)}
                      </span>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 mb-1">
                          <h4 className="font-semibold text-cream text-sm truncate">
                            {notification.title}
                          </h4>
                          {!notification.read && (
                            <span className="bg-gold text-red-900 text-xs px-1 rounded-full font-bold">
                              NEW
                            </span>
                          )}
                        </div>
                        <p className="text-cream text-xs opacity-90 line-clamp-2">
                          {notification.message}
                        </p>
                        <p className="text-gold text-xs mt-1">
                          {formatTimestamp(notification.timestamp)}
                        </p>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {notifications.length > 10 && (
              <div className="mt-4 text-center">
                <button
                  onClick={() => setShowDropdown(false)}
                  className="text-gold hover:underline text-sm"
                >
                  View all notifications
                </button>
              </div>
            )}
          </GlassCard>
        </div>
      )}

      {/* Backdrop to close dropdown */}
      {showDropdown && (
        <div
          className="fixed inset-0 z-40"
          onClick={() => setShowDropdown(false)}
        />
      )}
    </div>
  );
};

export default NotificationBell;