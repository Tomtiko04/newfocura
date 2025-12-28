// Adaptive color palette for UI
export const AdaptiveColors = {
  // Rest/Recovery states
  REST_DEEP_PURPLE: '#4A148C',
  REST_LIGHT_PURPLE: '#7B1FA2',
  
  // Peak Focus states
  PEAK_VIBRANT_ORANGE: '#FF6F00',
  PEAK_WARM_ORANGE: '#FF8F00',
  
  // Admin/Low Energy states
  ADMIN_CREAM: '#FFF8E1',
  ADMIN_BEIGE: '#F5E6D3',
  
  // Paper-like textures
  PAPER_CREAM: '#FDF6E3',
  PAPER_PARCHMENT: '#F4E4BC',
  
  // Accent colors
  PRIMARY: '#5E35B1',
  SECONDARY: '#FF6F00',
  SUCCESS: '#2E7D32',
  WARNING: '#F57C00',
  ERROR: '#C62828',
} as const;

export type AdaptiveColorKey = keyof typeof AdaptiveColors;

