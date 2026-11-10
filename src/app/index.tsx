import { Redirect } from 'expo-router';

import { useAuth } from '@/lib/auth';
import { ROLE_HOME } from '@/lib/constants';

/** Entry point: send the user to the module that matches their auth state and role. */
export default function Index() {
  const { isAuthenticated, role } = useAuth();

  if (!isAuthenticated || !role) return <Redirect href="/login" />;
  return <Redirect href={ROLE_HOME[role]} />;
}
