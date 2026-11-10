import { Button } from '@/components/ui/Button';
import { Placeholder } from '@/components/ui/Placeholder';
import { useAuth } from '@/lib/auth';

export default function MyDeliveriesScreen() {
  const { signOut } = useAuth();
  return (
    <Placeholder title="My Deliveries" note="Milestone 7">
      <Button label="Sign out" variant="secondary" onPress={signOut} />
    </Placeholder>
  );
}
