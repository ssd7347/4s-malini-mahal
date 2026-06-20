import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { apiUrl } from 'frontend/utils/api';

function loadRazorpay() {
  return new Promise((resolve, reject) => {
    if (window.Razorpay) { resolve(); return; }
    const s = document.createElement('script');
    s.src = 'https://checkout.razorpay.com/v1/checkout.js';
    s.onload = resolve;
    s.onerror = () => reject(new Error('Could not load payment gateway'));
    document.head.appendChild(s);
  });
}

function rupees(paise) {
  if (paise == null) return '—';
  return '₹' + (paise / 100).toLocaleString('en-IN', { minimumFractionDigits: 0, maximumFractionDigits: 0 });
}

function fmtDate(iso) {
  if (!iso) return '—';
  const [y, m, d] = iso.split('-').map(Number);
  return new Date(y, m - 1, d).toLocaleDateString('en-IN', { day: 'numeric', month: 'long', year: 'numeric' });
}

export default class PaymentPage extends Component {
  @tracked loading = true;
  @tracked invoice = null;
  @tracked error = null;
  @tracked paying = false;
  @tracked paymentDone = false;
  @tracked paymentError = null;
  @tracked terms = null;
  @tracked termsAccepted = false;

  constructor() {
    super(...arguments);
    this.loadInvoice();
    this.loadTerms();
  }

  get reference() { return this.args.reference; }
  get canPay() { return this.invoice?.status === 'AWAITING_PAYMENT'; }
  get alreadyPaid() { return ['CONFIRMED', 'COMPLETED'].includes(this.invoice?.status); }
  get termsVersionId() { return this.terms?.id ?? 0; }

  async loadTerms() {
    try {
      const res = await fetch(apiUrl('/api/terms/current'));
      if (res.ok) this.terms = await res.json();
    } catch (_) {}
  }

  async loadInvoice() {
    this.loading = true;
    this.error = null;
    try {
      const res = await fetch(apiUrl(`/api/payments/invoice/${this.reference}`));
      if (res.ok) {
        this.invoice = await res.json();
      } else {
        const d = await res.json().catch(() => ({}));
        this.error = d.error || 'Could not load booking details';
      }
    } catch {
      this.error = 'Could not connect to server';
    } finally {
      this.loading = false;
    }
  }

  @action
  toggleTerms(event) {
    this.termsAccepted = event.target.checked;
  }

  @action
  async pay() {
    if (this.paying) return;
    if (this.terms && !this.termsAccepted) {
      this.paymentError = 'Please accept the Terms & Conditions before paying';
      return;
    }
    this.paying = true;
    this.paymentError = null;

    try {
      const orderRes = await fetch(apiUrl('/api/payments/create-order'), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ reference: this.reference, paymentType: 'ADVANCE', termsVersionId: this.termsVersionId }),
      });
      if (!orderRes.ok) {
        const d = await orderRes.json().catch(() => ({}));
        this.paymentError = d.error || 'Could not create payment order';
        this.paying = false;
        return;
      }
      const order = await orderRes.json();

      await loadRazorpay();

      const rzp = new window.Razorpay({
        key:         order.keyId,
        amount:      order.amount,
        currency:    'INR',
        order_id:    order.orderId,
        name:        '4S Malini Mahal',
        description: 'Hall Advance Payment',
        image:       window.location.origin + '/logo.jpg',
        prefill:     { name: order.customerName, contact: '91' + order.mobile },
        theme:       { color: '#be123c' },
        handler: async (response) => {
          const verifyRes = await fetch(apiUrl('/api/payments/verify'), {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              reference:         this.reference,
              razorpayOrderId:   response.razorpay_order_id,
              razorpayPaymentId: response.razorpay_payment_id,
              razorpaySignature: response.razorpay_signature,
              paymentType:       'ADVANCE',
            }),
          });
          if (verifyRes.ok) {
            this.paymentDone = true;
            await this.loadInvoice();
          } else {
            const d = await verifyRes.json().catch(() => ({}));
            this.paymentError = d.error || 'Payment verification failed. Please contact support.';
          }
          this.paying = false;
        },
        modal: { ondismiss: () => { this.paying = false; } },
      });
      rzp.open();
    } catch (err) {
      this.paymentError = err.message || 'Payment failed';
      this.paying = false;
    }
  }

  <template>
    <div class="min-h-screen bg-stone-50 flex items-center justify-center p-4">
      <div class="w-full max-w-md">

        {{#if this.loading}}
          <div class="text-center py-16 text-stone-400">Loading booking details…</div>

        {{else if this.error}}
          <div class="rounded-xl border border-red-200 bg-red-50 p-6 text-center">
            <p class="text-sm text-red-700">{{this.error}}</p>
          </div>

        {{else}}
          <div class="rounded-2xl border border-stone-200 bg-white shadow-sm overflow-hidden">

            <div class="bg-rose-700 px-6 py-5 text-white">
              <p class="text-xs font-semibold uppercase tracking-wide opacity-70">4S Malini Mahal</p>
              <h1 class="mt-1 text-xl font-bold">Advance Payment</h1>
              <p class="mt-0.5 text-sm opacity-80 font-mono">{{this.reference}}</p>
            </div>

            <div class="px-6 py-5 space-y-3 border-b border-stone-100">
              <div class="flex justify-between text-sm">
                <span class="text-stone-500">Customer</span>
                <span class="font-medium text-stone-900">{{this.invoice.customerName}}</span>
              </div>
              <div class="flex justify-between text-sm">
                <span class="text-stone-500">Event Date</span>
                <span class="font-medium text-stone-900">{{fmtDate this.invoice.eventDate}}</span>
              </div>
              <div class="flex justify-between text-sm">
                <span class="text-stone-500">Function</span>
                <span class="font-medium text-stone-900">{{this.invoice.functionType}}</span>
              </div>
              <div class="flex justify-between text-sm">
                <span class="text-stone-500">Rental Type</span>
                <span class="font-medium text-stone-900">{{this.invoice.rentalType}}</span>
              </div>
            </div>

            <div class="px-6 py-5 border-b border-stone-100">
              <div class="flex justify-between items-start">
                <div>
                  <p class="text-sm text-stone-500 font-medium">Advance Deposit</p>
                  <p class="text-xs text-stone-400 mt-0.5">₹32,000 hall rent + ₹3,000 security</p>
                </div>
                <span class="text-2xl font-bold text-stone-900">{{rupees this.invoice.baseRentPaise}}</span>
              </div>
            </div>

            <div class="px-6 py-5">
              {{#if this.paymentDone}}
                <div class="rounded-xl bg-green-50 border border-green-200 p-4 text-center">
                  <p class="text-green-700 font-semibold">Payment Successful!</p>
                  <p class="text-sm text-green-600 mt-1">Your slot is now confirmed.
                    <a href="/invoice/{{this.reference}}" class="underline font-medium">View invoice</a>
                  </p>
                </div>

              {{else if this.alreadyPaid}}
                <div class="rounded-xl bg-green-50 border border-green-200 p-4 text-center">
                  <p class="text-green-700 font-semibold">Payment already received</p>
                  <p class="text-sm text-green-600 mt-1">Your booking is confirmed.
                    <a href="/invoice/{{this.reference}}" class="underline font-medium">View invoice</a>
                  </p>
                </div>

              {{else if this.canPay}}
                {{#if this.terms}}
                  <div class="mb-4 rounded-xl border border-stone-200 bg-stone-50 p-4 text-xs text-stone-700 max-h-48 overflow-y-auto space-y-3">
                    {{#if this.terms.englishText}}
                      <div>
                        <p class="font-semibold text-stone-800 mb-1 text-sm">Terms & Conditions</p>
                        <p class="whitespace-pre-wrap leading-relaxed">{{this.terms.englishText}}</p>
                      </div>
                    {{/if}}
                    {{#if this.terms.tamilText}}
                      <div class="border-t border-stone-200 pt-3">
                        <p class="font-semibold text-stone-800 mb-1 text-sm">விதிமுறைகள்</p>
                        <p class="whitespace-pre-wrap leading-relaxed">{{this.terms.tamilText}}</p>
                      </div>
                    {{/if}}
                  </div>
                  <label class="mb-4 flex items-start gap-3 cursor-pointer">
                    <input type="checkbox" class="mt-0.5 h-4 w-4 rounded border-stone-300 text-rose-700 focus:ring-rose-500"
                      {{on "change" this.toggleTerms}} />
                    <span class="text-sm text-stone-700">
                      I have read and agree to the Terms & Conditions
                      <span class="text-xs text-stone-400">(Version {{this.terms.version}})</span>
                    </span>
                  </label>
                {{/if}}
                {{#if this.paymentError}}
                  <div class="mb-3 rounded-lg border border-red-200 bg-red-50 px-4 py-2.5 text-sm text-red-700">
                    {{this.paymentError}}
                  </div>
                {{/if}}
                <button type="button"
                  disabled={{this.paying}}
                  class="w-full rounded-xl bg-rose-700 px-6 py-3.5 text-base font-bold text-white shadow-md transition-all duration-150 hover:bg-rose-800 active:scale-[0.98] disabled:opacity-60 disabled:cursor-not-allowed"
                  {{on "click" this.pay}}
                >
                  {{if this.paying "Opening payment…" "Pay Now"}}
                </button>
                <p class="mt-2 text-center text-xs text-stone-400">Secured by Razorpay · UPI, Cards, Net Banking</p>

              {{else}}
                <div class="rounded-xl bg-amber-50 border border-amber-200 p-4 text-center">
                  <p class="text-amber-700 text-sm font-medium">Payment link not active</p>
                  <p class="text-xs text-amber-500 mt-1">Status: {{this.invoice.status}}</p>
                </div>
              {{/if}}
            </div>

          </div>
        {{/if}}
      </div>
    </div>
  </template>
}
