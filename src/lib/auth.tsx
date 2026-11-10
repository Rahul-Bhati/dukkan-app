import type { Session } from '@supabase/supabase-js';
import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react';

import { isSupabaseConfigured, supabase } from '@/lib/supabase';
import type { Profile, UserRole } from '@/types';

interface AuthContextValue {
  session: Session | null;
  profile: Profile | null;
  role: UserRole | null;
  /** True only once the session AND its profile are known — routing keys off this. */
  isAuthenticated: boolean;
  /** True while the stored session is being restored on launch. */
  loading: boolean;
  signInWithOtp: (phone: string) => Promise<void>;
  verifyOtp: (phone: string, token: string) => Promise<void>;
  signOut: () => Promise<void>;
  refreshProfile: () => Promise<void>;
  /** Dev builds only: browse a module's navigation without signing in. */
  devPreviewRole: UserRole | null;
  setDevPreviewRole: (role: UserRole | null) => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

async function fetchProfile(userId: string): Promise<Profile | null> {
  const { data, error } = await supabase.from('profiles').select('*').eq('id', userId).single();
  if (error) {
    console.warn('[auth] profile fetch failed:', error.message);
    return null;
  }
  return data as Profile;
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  // userId whose profile fetch has finished (success or not). Prevents routing a user
  // into the wrong module while their role is still unknown.
  const [profileUserId, setProfileUserId] = useState<string | null>(null);
  const [restoring, setRestoring] = useState(isSupabaseConfigured);
  const [devPreviewRole, setDevPreviewRoleState] = useState<UserRole | null>(null);
  const latestUserId = useRef<string | null>(null);

  const loadProfile = useCallback(async (userId: string) => {
    latestUserId.current = userId;
    const p = await fetchProfile(userId);
    if (latestUserId.current !== userId) return; // signed out / switched meanwhile
    setProfile(p);
    setProfileUserId(userId);
  }, []);

  useEffect(() => {
    if (!isSupabaseConfigured) return;
    let active = true;

    supabase.auth.getSession().then(async ({ data }) => {
      if (!active) return;
      setSession(data.session);
      if (data.session) await loadProfile(data.session.user.id);
      if (active) setRestoring(false);
    });

    const { data: listener } = supabase.auth.onAuthStateChange((_event, newSession) => {
      setSession(newSession);
      if (!newSession) {
        latestUserId.current = null;
        setProfile(null);
        setProfileUserId(null);
        return;
      }
      if (newSession.user.id !== latestUserId.current) {
        // Don't await Supabase calls inside this callback — it can deadlock the auth client.
        setTimeout(() => void loadProfile(newSession.user.id), 0);
      }
    });

    return () => {
      active = false;
      listener.subscription.unsubscribe();
    };
  }, [loadProfile]);

  const signInWithOtp = useCallback(async (phone: string) => {
    const { error } = await supabase.auth.signInWithOtp({ phone });
    if (error) throw error;
  }, []);

  const verifyOtp = useCallback(
    async (phone: string, token: string) => {
      const { data, error } = await supabase.auth.verifyOtp({ phone, token, type: 'sms' });
      if (error) throw error;
      if (data.session) await loadProfile(data.session.user.id);
    },
    [loadProfile],
  );

  const signOut = useCallback(async () => {
    setDevPreviewRoleState(null);
    latestUserId.current = null;
    if (isSupabaseConfigured) await supabase.auth.signOut();
    setSession(null);
    setProfile(null);
    setProfileUserId(null);
  }, []);

  const refreshProfile = useCallback(async () => {
    if (session) await loadProfile(session.user.id);
  }, [session, loadProfile]);

  const setDevPreviewRole = useCallback((role: UserRole | null) => {
    if (__DEV__) setDevPreviewRoleState(role);
  }, []);

  const value = useMemo<AuthContextValue>(() => {
    const previewing = __DEV__ && devPreviewRole !== null;
    const profileReady = session !== null && profileUserId === session.user.id;
    // A signed-in user whose profile row is missing falls back to the least-privileged role.
    const role: UserRole | null = previewing
      ? devPreviewRole
      : profileReady
        ? (profile?.role ?? 'customer')
        : null;

    return {
      session,
      profile,
      role,
      isAuthenticated: previewing || profileReady,
      loading: restoring,
      signInWithOtp,
      verifyOtp,
      signOut,
      refreshProfile,
      devPreviewRole,
      setDevPreviewRole,
    };
  }, [
    session,
    profile,
    profileUserId,
    restoring,
    devPreviewRole,
    signInWithOtp,
    verifyOtp,
    signOut,
    refreshProfile,
    setDevPreviewRole,
  ]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used inside <AuthProvider>');
  return ctx;
}
