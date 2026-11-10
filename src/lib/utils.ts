/** 9950 paisa → "₹99.50"; whole rupees drop the decimals ("₹85"). Indian digit grouping. */
export function formatPrice(paisa: number): string {
  const rupees = Math.floor(Math.abs(paisa) / 100);
  const fraction = Math.abs(paisa) % 100;
  const digits = String(rupees);
  const lastThree = digits.slice(-3);
  const rest = digits.slice(0, -3);
  const grouped = rest ? `${rest.replace(/\B(?=(\d{2})+(?!\d))/g, ',')},${lastThree}` : lastThree;
  const sign = paisa < 0 ? '-' : '';
  return `${sign}₹${grouped}${fraction ? `.${String(fraction).padStart(2, '0')}` : ''}`;
}

/** "2 Oct, 3:45 pm" */
export function formatDate(iso: string): string {
  const d = new Date(iso);
  const date = d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' });
  const time = d.toLocaleTimeString('en-IN', { hour: 'numeric', minute: '2-digit', hour12: true });
  return `${date}, ${time}`;
}

/** "919876543210" / "+919876543210" → "+91 98765 43210" */
export function formatPhone(phone: string): string {
  const digits = phone.replace(/\D/g, '');
  const local = digits.length > 10 ? digits.slice(-10) : digits;
  if (local.length !== 10) return phone;
  return `+91 ${local.slice(0, 5)} ${local.slice(5)}`;
}

/** 10-digit Indian mobile → E.164 "+919876543210" (what Supabase phone auth expects). */
export function toE164India(localNumber: string): string {
  return `+91${localNumber.replace(/\D/g, '').slice(-10)}`;
}
