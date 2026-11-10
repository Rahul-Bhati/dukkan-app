import { Stack } from 'expo-router';

export default function CustomerLayout() {
  return (
    <Stack screenOptions={{ headerShown: false, animation: 'slide_from_right' }}>
      <Stack.Screen name="(tabs)" />
      <Stack.Screen name="search" options={{ animation: 'fade' }} />
      <Stack.Screen name="order-success" options={{ animation: 'fade', gestureEnabled: false }} />
    </Stack>
  );
}
