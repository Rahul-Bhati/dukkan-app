import { StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { spacing, useThemeColors } from '@/lib/theme';

interface PlaceholderProps {
  title: string;
  note?: string;
  children?: React.ReactNode;
}

/** Temporary screen body used until each screen's milestone is built. */
export function Placeholder({ title, note, children }: PlaceholderProps) {
  const c = useThemeColors();
  return (
    <SafeAreaView style={[styles.root, { backgroundColor: c.background }]} edges={['top']}>
      <View style={styles.body}>
        <Text style={[styles.title, { color: c.text }]}>{title}</Text>
        {note ? <Text style={[styles.note, { color: c.textMuted }]}>{note}</Text> : null}
        {children}
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  body: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: spacing.xl, gap: spacing.sm },
  title: { fontSize: 24, fontWeight: '700', textAlign: 'center' },
  note: { fontSize: 14, textAlign: 'center' },
});
