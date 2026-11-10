import { Button } from '@/components/ui/Button';
import { Placeholder } from '@/components/ui/Placeholder';
import { useAuth } from '@/lib/auth';

export default function ProfileScreen() {
  const { signOut } = useAuth();
  return (
    <Placeholder title="Profile" note="Milestone 10">
      <Button label="Sign out" variant="secondary" onPress={signOut} />
    </Placeholder>
  );
}
