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
  if (paise == null || paise === 0) return '₹0';
  return '₹' + (paise / 100).toLocaleString('en-IN', { minimumFractionDigits: 0, maximumFractionDigits: 0 });
}

function fmtDate(iso) {
  if (!iso) return '—';
  const [y, m, d] = iso.split('-').map(Number);
  return new Date(y, m - 1, d).toLocaleDateString('en-IN', { day: 'numeric', month: 'long', year: 'numeric' });
}

function fmtDateTime(isoStr) {
  if (!isoStr) return '—';
  return new Date(isoStr).toLocaleString('en-IN', {
    day: 'numeric', month: 'short', year: 'numeric',
    hour: '2-digit', minute: '2-digit', hour12: true, timeZone: 'Asia/Kolkata',
  });
}

const RENTAL_LABELS = { HOURLY: 'Hourly', HALF_DAY: 'Half Day', FULL_DAY: 'Full Day' };
const FUNCTION_LABELS = {
  MARRIAGE: 'Marriage', RECEPTION: 'Reception', ENGAGEMENT: 'Engagement',
  BIRTHDAY_FUNCTION: 'Birthday Function', KARI_SAAPADU: 'Kari Saapadu',
  MEETING: 'Meeting', CONFERENCE: 'Conference', TRAINING_SESSION: 'Training Session',
  SEMINAR: 'Seminar', WORKSHOP: 'Workshop', SMALL_GATHERING: 'Small Gathering',
  OTHER_HOURLY: 'Other Hourly Events',
};

export default class InvoicePage extends Component {
  @tracked loading = true;
  @tracked invoice = null;
  @tracked error = null;
  @tracked paying = false;
  @tracked balanceDone = false;
  @tracked paymentError = null;

  constructor() {
    super(...arguments);
    this.loadInvoice();
  }

  get reference() { return this.args.reference; }

  get canPayBalance() {
    return this.invoice?.billingReady
      && this.invoice?.remainingPaise > 0
      && this.invoice?.status === 'CONFIRMED'
      && !this.balanceDone;
  }
  get isCompleted() { return this.invoice?.status === 'COMPLETED' || this.balanceDone; }
  get rentalLabel() { return RENTAL_LABELS[this.invoice?.rentalType] ?? this.invoice?.rentalType ?? '—'; }
  get functionLabel() { return FUNCTION_LABELS[this.invoice?.functionType] ?? this.invoice?.functionType ?? '—'; }
  get balanceButtonLabel() { return this.paying ? 'Opening payment…' : `Pay Balance ${rupees(this.invoice?.remainingPaise)}`; }

  async loadInvoice() {
    this.loading = true;
    this.error = null;
    try {
      const res = await fetch(apiUrl(`/api/payments/invoice/${this.reference}`));
      if (res.ok) {
        this.invoice = await res.json();
        if (new URLSearchParams(window.location.search).get('print') === '1') {
          setTimeout(() => window.print(), 400);
        }
      } else {
        const d = await res.json().catch(() => ({}));
        this.error = d.error || 'Could not load invoice';
      }
    } catch {
      this.error = 'Could not connect to server';
    } finally {
      this.loading = false;
    }
  }

  @action
  async payBalance() {
    if (this.paying) return;
    this.paying = true;
    this.paymentError = null;

    try {
      const orderRes = await fetch(apiUrl('/api/payments/create-order'), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ reference: this.reference, paymentType: 'BALANCE' }),
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
        description: 'Balance Payment',
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
              paymentType:       'BALANCE',
            }),
          });
          if (verifyRes.ok) {
            this.balanceDone = true;
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
      <div class="w-full max-w-lg">

        {{#if this.loading}}
          <div class="text-center py-16 text-stone-400">Loading invoice…</div>

        {{else if this.error}}
          <div class="rounded-xl border border-red-200 bg-red-50 p-6 text-center">
            <p class="text-sm text-red-700">{{this.error}}</p>
          </div>

        {{else}}
          <div class="rounded-2xl border border-stone-200 bg-white shadow-sm overflow-hidden">

            <div class="bg-rose-700 px-6 py-5 text-white">
              <p class="text-xs font-semibold uppercase tracking-wide opacity-70">4S Malini Mahal — Invoice</p>
              <h1 class="mt-1 text-xl font-bold font-mono">{{this.reference}}</h1>
            </div>

            <div class="px-6 py-5 border-b border-stone-100 space-y-2">
              <div class="flex justify-between text-sm">
                <span class="text-stone-500">Customer</span>
                <span class="font-medium text-stone-900">{{this.invoice.customerName}}</span>
              </div>
              <div class="flex justify-between text-sm">
                <span class="text-stone-500">Mobile</span>
                <span class="font-medium text-stone-900">{{this.invoice.mobile}}</span>
              </div>
              <div class="flex justify-between text-sm">
                <span class="text-stone-500">Event Date</span>
                <span class="font-medium text-stone-900">{{fmtDate this.invoice.eventDate}}</span>
              </div>
              <div class="flex justify-between text-sm">
                <span class="text-stone-500">Rental</span>
                <span class="font-medium text-stone-900">{{this.rentalLabel}}</span>
              </div>
              <div class="flex justify-between text-sm">
                <span class="text-stone-500">Function</span>
                <span class="font-medium text-stone-900">{{this.functionLabel}}</span>
              </div>
              {{#if this.invoice.startDatetime}}
                <div class="flex justify-between text-sm">
                  <span class="text-stone-500">Slot</span>
                  <span class="font-medium text-stone-900 text-right text-xs leading-5">
                    {{fmtDateTime this.invoice.startDatetime}}<br/>
                    to {{fmtDateTime this.invoice.endDatetime}}
                  </span>
                </div>
              {{/if}}
            </div>

            <div class="px-6 py-5 space-y-2 border-b border-stone-100">
              <div class="flex justify-between text-sm">
                <span class="text-stone-600">Hall Rent</span>
                <span class="font-medium text-stone-900">{{rupees this.invoice.baseRentPaise}}</span>
              </div>
              {{#if this.invoice.billingReady}}
                <div class="flex justify-between text-sm">
                  <span class="text-stone-600">Electricity ({{this.invoice.elecUnits}} units × ₹40)</span>
                  <span class="font-medium text-stone-900">{{rupees this.invoice.elecChargePaise}}</span>
                </div>
                <div class="flex justify-between text-sm">
                  <span class="text-stone-600">Gas ({{this.invoice.gasKg}} kg × ₹180)</span>
                  <span class="font-medium text-stone-900">{{rupees this.invoice.gasChargePaise}}</span>
                </div>
                {{#if this.invoice.decorationChargePaise}}
                  <div class="flex justify-between text-sm">
                    <span class="text-stone-600">Decoration</span>
                    <span class="font-medium text-stone-900">{{rupees this.invoice.decorationChargePaise}}</span>
                  </div>
                {{/if}}
                {{#if this.invoice.earlyEntryChargePaise}}
                  <div class="flex justify-between text-sm">
                    <span class="text-stone-600">Early Entry (key before 3 PM)</span>
                    <span class="font-medium text-stone-900">{{rupees this.invoice.earlyEntryChargePaise}}</span>
                  </div>
                {{/if}}
                {{#if this.invoice.keyLossChargePaise}}
                  <div class="flex justify-between text-sm">
                    <span class="text-stone-600">Lost Room Key</span>
                    <span class="font-medium text-stone-900">{{rupees this.invoice.keyLossChargePaise}}</span>
                  </div>
                {{/if}}
              {{else}}
                <p class="text-xs text-stone-400 italic py-1">Post-event charges (electricity, gas, decoration, etc.) will appear after the event.</p>
              {{/if}}
              <div class="pt-2 border-t border-stone-100 flex justify-between text-base font-bold">
                <span>Total</span>
                <span>{{rupees this.invoice.totalPaise}}</span>
              </div>
            </div>

            <div class="px-6 py-5 space-y-2 border-b border-stone-100">
              <div class="flex justify-between text-sm text-green-700">
                <span>Advance Paid</span>
                <span class="font-medium">− {{rupees this.invoice.advancePaidPaise}}</span>
              </div>
              {{#if this.invoice.balancePaidPaise}}
                <div class="flex justify-between text-sm text-green-700">
                  <span>Balance Paid</span>
                  <span class="font-medium">− {{rupees this.invoice.balancePaidPaise}}</span>
                </div>
              {{/if}}
              <div class="pt-2 border-t border-stone-100 flex justify-between text-base font-bold">
                <span class="text-stone-900">Remaining Balance</span>
                <span class="{{if this.invoice.remainingPaise 'text-rose-700' 'text-green-700'}}">
                  {{rupees this.invoice.remainingPaise}}
                </span>
              </div>
            </div>

            <div class="px-6 py-5">
              {{#if this.isCompleted}}
                <div class="rounded-xl bg-blue-50 border border-blue-200 p-4 text-center">
                  <p class="text-blue-700 font-semibold">Booking Completed</p>
                  <p class="text-sm text-blue-600 mt-1">All payments received. Thank you for choosing 4S Malini Mahal!</p>
                </div>

              {{else if this.canPayBalance}}
                {{#if this.paymentError}}
                  <div class="mb-3 rounded-lg border border-red-200 bg-red-50 px-4 py-2.5 text-sm text-red-700">
                    {{this.paymentError}}
                  </div>
                {{/if}}
                <button type="button"
                  disabled={{this.paying}}
                  class="w-full rounded-xl bg-rose-700 px-6 py-3.5 text-base font-bold text-white shadow-md transition-all duration-150 hover:bg-rose-800 active:scale-[0.98] disabled:opacity-60 disabled:cursor-not-allowed"
                  {{on "click" this.payBalance}}
                >
                  {{this.balanceButtonLabel}}
                </button>
                <p class="mt-2 text-center text-xs text-stone-400">Secured by Razorpay · UPI, Cards, Net Banking</p>

              {{else}}
                <div class="text-center text-xs text-stone-400 py-2">Status: {{this.invoice.status}}</div>
              {{/if}}
            </div>

          </div>
        {{/if}}
      </div>
    </div>
  </template>
}
