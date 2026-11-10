import { Pressable, StyleSheet, Text, type PressableProps } from 'react-native';

import { radius, spacing, useThemeColors } from '@/lib/theme';

interface ButtonProps extends Omit<PressableProps, 'children' | 'style'> {
  label: string;
  variant?: 'primary' | 'secondary';
}

export function Button({ label, variant = 'primary', disabled, ...rest }: ButtonProps) {
  const c = useThemeColors();
  const primary = variant === 'primary';
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ disabled: !!disabled }}
      disabled={disabled}
      style={({ pressed }) => [
        styles.base,
        primary
          ? { backgroundColor: c.primary }
          : { backgroundColor: 'transparent', borderWidth: 1, borderColor: c.border },
        { opacity: disabled ? 0.5 : pressed ? 0.85 : 1 },
      ]}
      {...rest}
    >
      <Text style={[styles.label, { color: primary ? c.primaryText : c.text }]}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  base: {
    minHeight: 48,
    paddingHorizontal: spacing.xl,
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
    alignSelf: 'stretch',
  },
  label: { fontSize: 16, fontWeight: '600' },
});
