// Mirrors supabase/migrations. Money is always in paisa (integer).

export type UserRole = 'customer' | 'admin' | 'delivery';

export type OrderStatus =
  | 'placed'
  | 'confirmed'
  | 'preparing'
  | 'ready'
  | 'out_for_delivery'
  | 'delivered'
  | 'cancelled';

export type PaymentMethod = 'razorpay' | 'cod';

export type PaymentStatus = 'pending' | 'paid' | 'failed' | 'refund_pending' | 'refunded';

export type ProductUnit = 'piece' | 'kg' | 'g' | 'litre' | 'ml' | 'packet' | 'dozen' | 'box';

export interface ShopConfig {
  id: 1;
  shop_name: string;
  shop_tagline: string;
  shop_logo_url: string | null;
  shop_banner_url: string | null;
  phone: string;
  whatsapp: string | null;
  address: string;
  latitude: number | null;
  longitude: number | null;
  delivery_fee: number;
  free_delivery_above: number;
  min_order_amount: number;
  delivery_radius_km: number;
  is_open: boolean;
  opening_time: string;
  closing_time: string;
  razorpay_enabled: boolean;
  cod_enabled: boolean;
}

export interface Category {
  id: string;
  name: string;
  name_hi: string | null;
  image_url: string | null;
  sort_order: number;
  is_active: boolean;
}

export interface Product {
  id: string;
  category_id: string | null;
  name: string;
  name_hi: string | null;
  description: string;
  price: number;
  mrp: number | null;
  stock_quantity: number;
  unit: ProductUnit;
  stock_alert_threshold: number;
  is_in_stock: boolean;
  image_urls: string[];
  is_active: boolean;
  is_featured: boolean;
  sort_order: number;
}

export interface Profile {
  id: string;
  phone: string;
  full_name: string;
  avatar_url: string | null;
  role: UserRole;
  expo_push_token: string | null;
  notifications_enabled: boolean;
  is_available: boolean;
}

export interface Address {
  id: string;
  user_id: string;
  label: 'Home' | 'Work' | 'Other';
  full_address: string;
  landmark: string | null;
  city: string;
  pincode: string | null;
  latitude: number;
  longitude: number;
  is_default: boolean;
}

export interface OrderItem {
  product_id: string;
  name: string;
  price: number;
  mrp: number | null;
  quantity: number;
  unit: ProductUnit;
  image_url: string | null;
}

export interface DeliveryAddressSnapshot {
  full_address: string;
  landmark: string | null;
  city: string;
  pincode: string | null;
  latitude: number;
  longitude: number;
  phone: string;
  name: string;
}

export interface Order {
  id: string;
  order_number: number;
  user_id: string;
  status: OrderStatus;
  status_updated_at: string;
  items: OrderItem[];
  subtotal: number;
  delivery_fee: number;
  discount: number;
  total: number;
  payment_method: PaymentMethod;
  payment_status: PaymentStatus;
  razorpay_order_id: string | null;
  paid_at: string | null;
  delivery_address: DeliveryAddressSnapshot;
  delivery_person_id: string | null;
  estimated_delivery_minutes: number;
  delivered_at: string | null;
  customer_note: string | null;
  admin_note: string | null;
  cancellation_reason: string | null;
  created_at: string;
}

export interface OrderStatusLog {
  id: string;
  order_id: string;
  from_status: OrderStatus | null;
  to_status: OrderStatus;
  changed_by: string | null;
  note: string | null;
  created_at: string;
}
