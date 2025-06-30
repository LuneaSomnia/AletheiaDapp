// src/components/PurpleButton.tsx
import React from 'react';

interface PurpleButtonProps {
  onClick: () => void;
  children: React.ReactNode;
  className?: string;
  disabled?: boolean;
}

const PurpleButton: React.FC<PurpleButtonProps> = ({ 
  onClick, 
  children, 
  className = '',
  disabled = false
}) => {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className={`py-3 px-6 rounded-full font-bold text-cream 
                bg-gradient-to-r from-purple-700 to-purple-900
                hover:from-purple-800 hover:to-purple-950
                transition-all duration-300
                shadow-lg hover:shadow-xl
                transform hover:-translate-y-1
                disabled:opacity-50 disabled:cursor-not-allowed
                ${className}`}
      style={{
        border: '1px solid rgba(212, 175, 55, 0.5)',
        textShadow: '0 1px 2px rgba(0, 0, 0, 0.25)'
      }}>
      {children}
    </button>
  );
};

export default PurpleButton;