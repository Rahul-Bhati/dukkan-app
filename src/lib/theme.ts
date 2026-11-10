import { useColorScheme } from 'react-native';

// Interim tokens for Milestone 1. The full design system (type scale, motion, elevation)
// replaces these values before Milestone 3 — keep components reading from here.
const palette = {
  light: {
    background: '#FFFFFF',
    surface: '#F6F7F9',
    text: '#0F1115',
    textMuted: '#5B6270',
    border: '#E6E8EC',
    primary: '#0E7C66',
    primaryText: '#FFFFFF',
    danger: '#D93025',
  },
  dark: {
    background: '#0B0D10',
    surface: '#15181D',
    text: '#F2F4F7',
    textMuted: '#9AA1AD',
    border: '#252A31',
    primary: '#22B394',
    primaryText: '#04130F',
    danger: '#FF6B5E',
  },
} as const;

export type ThemeColors = { [K in keyof typeof palette.light]: string };

export const spacing = { xs: 4, sm: 8, md: 12, lg: 16, xl: 24, xxl: 32 } as const;
export const radius = { sm: 8, md: 12, lg: 16, pill: 999 } as const;

export function useThemeColors(): ThemeColors {
  return useColorScheme() === 'dark' ? palette.dark : palette.light;
}
