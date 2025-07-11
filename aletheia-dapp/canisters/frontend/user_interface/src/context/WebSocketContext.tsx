import React, { createContext, useContext, useEffect, useState, useCallback } from 'react';

interface ClaimUpdate {
  claimId: string;
  status: 'processing' | 'pending' | 'completed';
  message?: string;
}

declare global {
  interface ImportMeta {
    env: {
      VITE_WS_URL: string;
    };
  }
}
interface WebSocketContextType {
  subscribeToClaimUpdates: (callback: (update: ClaimUpdate) => void) => () => void;
}

const WebSocketContext = createContext<WebSocketContextType | null>(null);

export const WebSocketProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [socket, setSocket] = useState<WebSocket | null>(null);
  const [listeners, setListeners] = useState<((update: ClaimUpdate) => void)[]>([]);

  useEffect(() => {
    const wsUrl = import.meta.env.VITE_WS_URL || 'wss://aletheia-ws.example.com';
    const ws = new WebSocket(wsUrl);

    ws.onopen = () => {
      console.log('WebSocket connected');
      setSocket(ws);
    };

    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        if (data.type === 'claimUpdate') {
          listeners.forEach(callback => callback(data.payload));
        }
      } catch (error) {
        console.error('Error processing WebSocket message:', error);
      }
    };

    ws.onclose = () => {
      console.log('WebSocket disconnected');
      setSocket(null);
    };

    ws.onerror = (error) => {
      console.error('WebSocket error:', error);
    };

    return () => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.close();
      }
    };
  }, []);

  const subscribeToClaimUpdates = useCallback((callback: (update: ClaimUpdate) => void) => {
    setListeners(prev => [...prev, callback]);
    return () => {
      setListeners(prev => prev.filter(cb => cb !== callback));
    };
  }, []);

  return (
    <WebSocketContext.Provider value={{ subscribeToClaimUpdates }}>
      {children}
    </WebSocketContext.Provider>
  );
};

export const useWebSocket = () => {
  const context = useContext(WebSocketContext);
  if (!context) {
    throw new Error('useWebSocket must be used within a WebSocketProvider');
  }
  return context;
};