interface Theme {
  primary: string;
  secondary: string;
  text: string;
  background: string;
  glassEffect: string;
  error: string;
  success: string;
  warning: string;
  info: string;
  glassBorder: string;
  buttonPrimary: string;
  buttonSecondary: string;
  buttonText: string;
  cardBackground: string;
  cardShadow: string;
}

export const userTheme: Theme = {
  primary: '#8B0000',       // Deep red
  secondary: '#D4AF37',     // Gold
  text: '#FFFDD0',          // Cream text
  background: '#1a0000',    // Dark red background
  glassEffect: 'rgba(139, 0, 0, 0.25)',
  glassBorder: '1px solid rgba(212, 175, 55, 0.3)',
  error: '#ff4d4f',
  success: '#52c41a',
  warning: '#faad14',
  info: '#1890ff',
  buttonPrimary: '#D4AF37',
  buttonSecondary: '#8B0000',
  buttonText: '#1a0000',
  cardBackground: 'rgba(26, 0, 0, 0.7)',
  cardShadow: '0 8px 32px rgba(139, 0, 0, 0.3)'
};

export const aletheianTheme: Theme = {
  primary: '#4B0082',       // Indigo
  secondary: '#D4AF37',     // Gold
  text: '#FFFDD0',          // Cream text
  background: '#1a001a',    // Dark purple background
  glassEffect: 'rgba(75, 0, 130, 0.25)',
  glassBorder: '1px solid rgba(212, 175, 55, 0.3)',
  error: '#ff4d4f',
  success: '#52c41a',
  warning: '#faad14',
  info: '#1890ff',
  buttonPrimary: '#D4AF37',
  buttonSecondary: '#4B0082',
  buttonText: '#1a001a',
  cardBackground: 'rgba(26, 0, 26, 0.7)',
  cardShadow: '0 8px 32px rgba(75, 0, 130, 0.3)'
};

export type { Theme };