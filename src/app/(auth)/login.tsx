import { Pressable, StyleSheet, Text, View } from 'react-native';

import { Placeholder } from '@/components/ui/Placeholder';
import { useAuth } from '@/lib/auth';
import { isSupabaseConfigured } from '@/lib/supabase';
import { radius, spacing, useThemeColors } from '@/lib/theme';
import type { UserRole } from '@/types';

const PREVIEW_ROLES: { role: UserRole; label: string }[] = [
  { role: 'customer', label: 'Customer' },
  { role: 'admin', label: 'Shopkeeper' },
  { role: 'delivery', label: 'Delivery' },
];

export default function LoginScreen() {
  const { setDevPreviewRole } = useAuth();
  const c = useThemeColors();

  return (
    <Placeholder
      title="Login"
      note={`Phone + OTP arrives in Milestone 2.${isSupabaseConfigured ? '' : '\nSupabase keys not set in .env yet.'}`}
    >
      {__DEV__ ? (
        <View style={styles.preview}>
          <Text style={[styles.previewLabel, { color: c.textMuted }]}>DEV · preview a module</Text>
          {PREVIEW_ROLES.map(({ role, label }) => (
            <Pressable
              key={role}
              accessibilityRole="button"
              onPress={() => setDevPreviewRole(role)}
              style={({ pressed }) => [
                styles.button,
                { backgroundColor: c.primary, opacity: pressed ? 0.85 : 1 },
              ]}
            >
              <Text style={[styles.buttonText, { color: c.primaryText }]}>{label}</Text>
            </Pressable>
          ))}
        </View>
      ) : null}
    </Placeholder>
  );
}

const styles = StyleSheet.create({
  preview: { marginTop: spacing.xl, alignSelf: 'stretch', gap: spacing.sm },
  previewLabel: { fontSize: 12, fontWeight: '600', letterSpacing: 0.6, textAlign: 'center' },
  button: { minHeight: 48, borderRadius: radius.md, alignItems: 'center', justifyContent: 'center' },
  buttonText: { fontSize: 16, fontWeight: '600' },
});
