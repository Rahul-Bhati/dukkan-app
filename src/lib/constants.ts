import type { OrderStatus, ProductUnit, UserRole } from '@/types';

export const ORDER_STATUSES: Record<OrderStatus, { label: string; color: string }> = {
  placed: { label: 'Placed', color: '#2563EB' },
  confirmed: { label: 'Confirmed', color: '#7C3AED' },
  preparing: { label: 'Preparing', color: '#D97706' },
  ready: { label: 'Ready', color: '#EA580C' },
  out_for_delivery: { label: 'Out for delivery', color: '#4F46E5' },
  delivered: { label: 'Delivered', color: '#16A34A' },
  cancelled: { label: 'Cancelled', color: '#DC2626' },
};

export const UNITS: readonly ProductUnit[] = ['piece', 'kg', 'g', 'litre', 'ml', 'packet', 'dozen', 'box'];

export const ROLE_HOME = {
  customer: '/home',
  admin: '/admin/dashboard',
  delivery: '/delivery',
} as const satisfies Record<UserRole, string>;
