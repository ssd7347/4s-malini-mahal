import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { LinkTo } from '@ember/routing';
import { apiUrl } from 'frontend/utils/api';
import DatePickerCalendar from 'frontend/components/date-picker-calendar';

const FUNCTION_LABELS = {
  en: {
    MARRIAGE: 'Marriage', RECEPTION: 'Reception', ENGAGEMENT: 'Engagement',
    BIRTHDAY_FUNCTION: 'Birthday', OTHER: 'Other', MEETING: 'Meeting',
    CONFERENCE: 'Conference', TRAINING_SESSION: 'Training', SEMINAR: 'Seminar',
    WORKSHOP: 'Workshop', SMALL_GATHERING: 'Gathering', OTHER_HOURLY: 'Other',
  },
  ta: {
    MARRIAGE: 'திருமணம்', RECEPTION: 'வரவேற்பு', ENGAGEMENT: 'நிச்சயம்',
    BIRTHDAY_FUNCTION: 'பிறந்தநாள்', OTHER: 'மற்றவை', MEETING: 'கூட்டம்',
    CONFERENCE: 'மாநாடு', TRAINING_SESSION: 'பயிற்சி', SEMINAR: 'கருத்தரங்கு',
    WORKSHOP: 'பட்டறை', SMALL_GATHERING: 'கூட்டம்', OTHER_HOURLY: 'மற்றவை',
  },
};

const RENTAL_LABELS = {
  en: { FULL_DAY: 'Full Day', HALF_DAY: 'Half Day', HOURLY: 'Hourly' },
  ta: { FULL_DAY: 'முழு நாள்', HALF_DAY: 'அரை நாள்', HOURLY: 'மணிநேரம்' },
};

const STATUS_LABELS = {
  en: {
    AWAITING_PAYMENT: 'Awaiting Payment', CONFIRMED: 'Confirmed', COMPLETED: 'Completed',
    CANCELLED: 'Cancelled', REJECTED: 'Rejected', DECLINED: 'Declined', NEW: 'Pending',
  },
  ta: {
    AWAITING_PAYMENT: 'கட்டணம் காத்திருக்கிறது', CONFIRMED: 'உறுதிப்படுத்தப்பட்டது',
    COMPLETED: 'நிறைவுற்றது', CANCELLED: 'ரத்துசெய்யப்பட்டது',
    REJECTED: 'நிராகரிக்கப்பட்டது', DECLINED: 'மறுக்கப்பட்டது', NEW: 'நிலுவையில்',
  },
};

const T = {
  en: {
    title: 'Your Bookings',
    loading: 'Loading your bookings…',
    empty: 'You have no bookings yet.',
    bookNow: 'Book Now',
    payNow: 'Pay Now',
    invoice: 'Invoice',
    notify: 'Notify Hall',
    cancel: 'Cancel',
    cancelConfirmTitle: 'Cancel this booking?',
    cancelConfirmBody: 'This action cannot be undone.',
    cancelConfirmYes: 'Yes, Cancel Booking',
    cancelConfirmNo: 'Go Back',
    cancelling: 'Cancelling…',
    cancelledNoPayment: 'Booking cancelled. No payment had been made.',
    cancelledRefund: (amt) => `Booking cancelled. Refund of ₹${amt} will be processed by the admin.`,
    cancelledNoRefund: 'Booking cancelled. No refund applies (muhurtham date policy).',
    cancelError: 'Could not cancel. Please try again.',
    changeDate: 'Change Date',
    tooCloseToChange: 'Date changes require at least 3 days notice before the function.',
    tooCloseToChangeMuhurtham: 'Muhurtham date changes require at least 10 days notice before the function.',
    rescheduleTitle: 'Change Booking Date',
    rescheduleLabel: 'Select new date',
    rescheduleConfirm: 'Confirm Change',
    rescheduling: 'Updating…',
    rescheduleBack: 'Go Back',
    rescheduleSuccess: (date) => `Booking rescheduled to ${date}. Admin has been notified.`,
    rescheduleError: 'Could not reschedule. Please try again.',
  },
  ta: {
    title: 'உங்கள் பதிவுகள்',
    loading: 'பதிவுகள் ஏற்றுகிறது…',
    empty: 'இன்னும் பதிவுகள் இல்லை.',
    bookNow: 'பதிவிடுங்கள்',
    payNow: 'கட்டணம் செலுத்துங்கள்',
    invoice: 'விலைப்பட்டியல்',
    notify: 'மண்டபத்தை தெரியப்படுத்துங்கள்',
    cancel: 'ரத்துசெய்',
    cancelConfirmTitle: 'இந்த பதிவை ரத்துசெய்யவா?',
    cancelConfirmBody: 'இந்த செயல் மாற்ற முடியாது.',
    cancelConfirmYes: 'ஆம், பதிவை ரத்துசெய்',
    cancelConfirmNo: 'திரும்பு',
    cancelling: 'ரத்துசெய்கிறது…',
    cancelledNoPayment: 'பதிவு ரத்துசெய்யப்பட்டது. கட்டணம் செலுத்தப்படவில்லை.',
    cancelledRefund: (amt) => `பதிவு ரத்துசெய்யப்பட்டது. ₹${amt} திரும்பளிப்பு நிர்வாகியால் செயல்படுத்தப்படும்.`,
    cancelledNoRefund: 'பதிவு ரத்துசெய்யப்பட்டது. திரும்பளிப்பு இல்லை (முஹூர்த்தம் தேதி கொள்கை).',
    cancelError: 'ரத்துசெய்ய முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
    changeDate: 'தேதி மாற்று',
    tooCloseToChange: 'நிகழ்விற்கு குறைந்தது 3 நாட்களுக்கு முன்னர் மட்டுமே தேதி மாற்றலாம்.',
    tooCloseToChangeMuhurtham: 'முஹூர்த்தம் தேதிகளுக்கு நிகழ்விற்கு குறைந்தது 10 நாட்களுக்கு முன்னர் மட்டுமே தேதி மாற்றலாம்.',
    rescheduleTitle: 'பதிவு தேதியை மாற்றவும்',
    rescheduleLabel: 'புதிய தேதியை தேர்வு செய்யவும்',
    rescheduleConfirm: 'மாற்றத்தை உறுதிப்படுத்துங்கள்',
    rescheduling: 'புதுப்பிக்கிறது…',
    rescheduleBack: 'திரும்பு',
    rescheduleSuccess: (date) => `பதிவு ${date} க்கு மாற்றப்பட்டது.`,
    rescheduleError: 'மாற்ற முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
  },
};

const ADMIN_WA = '919443380023';

function daysUntilEvent(isoDate) {
  if (!isoDate) return 0;
  const [y, m, d] = isoDate.split('-').map(Number);
  const event = new Date(y, m - 1, d);
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return Math.floor((event - today) / (1000 * 60 * 60 * 24));
}

function fmtDate(iso) {
  if (!iso) return iso;
  const [y, m, d] = iso.split('-').map(Number);
  return new Date(y, m - 1, d).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
}

function statusCls(status) {
  switch (status) {
    case 'AWAITING_PAYMENT': return 'bg-amber-100 text-amber-800';
    case 'CONFIRMED':        return 'bg-green-100 text-green-800';
    case 'COMPLETED':        return 'bg-blue-100 text-blue-800';
    case 'CANCELLED':
    case 'REJECTED':
    case 'DECLINED':         return 'bg-red-100 text-red-800';
    default:                 return 'bg-stone-100 text-stone-600';
  }
}

function buildWaUrl(b, lang) {
  const fl = FUNCTION_LABELS[lang] || FUNCTION_LABELS.en;
  const func = fl[b.functionType] || b.functionType;
  if (b.status === 'CANCELLED') {
    const text =
      `Hi, I have cancelled my booking at 4S Malini Mahal.\n` +
      `Reference: ${b.reference}\nName: ${b.customerName}\n` +
      `Date: ${fmtDate(b.eventDate)}\nFunction: ${func}\n` +
      `Please acknowledge my cancellation. Thank you.`;
    return `https://wa.me/${ADMIN_WA}?text=${encodeURIComponent(text)}`;
  }
  const text =
    `Hi, I have booked 4S Malini Mahal.\n` +
    `Reference: ${b.reference}\nName: ${b.customerName}\n` +
    `Date: ${fmtDate(b.eventDate)}\nFunction: ${func}\n` +
    `Kindly confirm my booking. Thank you.`;
  return `https://wa.me/${ADMIN_WA}?text=${encodeURIComponent(text)}`;
}

export default class MyBookings extends Component {
  @service language;

  @tracked bookings      = null;
  @tracked loadError     = false;
  @tracked cancellingRef = null;
  @tracked cancelling    = false;
  @tracked cancelMsg     = null;  // { type: 'success'|'error', text: '...' }
  @tracked rescheduleRef  = null;
  @tracked rescheduleDate = '';
  @tracked rescheduling   = false;
  @tracked rescheduleMsg  = null;

  constructor(owner, args) {
    super(owner, args);
    this.load();
  }

  async load() {
    try {
      const res = await fetch(apiUrl('/api/enquiries/my'));
      if (res.ok) {
        this.bookings = await res.json();
      } else {
        this.loadError = true;
      }
    } catch (_) {
      this.loadError = true;
    }
  }

  get t()                  { return T[this.language.lang]; }
  get isLoading()          { return this.bookings === null && !this.loadError; }
  get isEmpty()            { return Array.isArray(this.bookings) && this.bookings.length === 0; }
  get cancelMsgIsSuccess() { return this.cancelMsg?.type === 'success'; }
  get rescheduleMsgIsSuccess() { return this.rescheduleMsg?.type === 'success'; }
  get minRescheduleDate() {
    const d = new Date();
    d.setDate(d.getDate() + 1);
    return d.toISOString().split('T')[0];
  }

  get rows() {
    if (!Array.isArray(this.bookings)) return [];
    const lang         = this.language.lang;
    const cancellingRef = this.cancellingRef;
    const fl = FUNCTION_LABELS[lang] || FUNCTION_LABELS.en;
    const rl = RENTAL_LABELS[lang]   || RENTAL_LABELS.en;
    const sl = STATUS_LABELS[lang]   || STATUS_LABELS.en;
    const t  = T[lang]               || T.en;
    return this.bookings.map(b => {
      const minDays = b.isMuhurtham ? 10 : 3;
      const days    = daysUntilEvent(b.eventDate);
      return {
        reference:    b.reference,
        customerName: b.customerName,
        functionType: b.functionType,
        rentalType:   b.rentalType,
        eventDate:    b.eventDate,
        isMuhurtham:  b.isMuhurtham,
        status:       b.status,
        formattedDate: fmtDate(b.eventDate),
        funcLabel:    fl[b.functionType]  || b.functionType,
        rentalLabel:  rl[b.rentalType]    || b.rentalType,
        statusLabel:  sl[b.status]        || b.status,
        statusCls:    statusCls(b.status),
        waHref:       buildWaUrl(b, lang),
        canPay:       b.status === 'AWAITING_PAYMENT',
        canInvoice:   b.status === 'CONFIRMED' || b.status === 'COMPLETED',
        canCancel:    b.status === 'AWAITING_PAYMENT' || b.status === 'CONFIRMED',
        isConfirming: b.reference === cancellingRef,
        canReschedule: b.status === 'CONFIRMED' && days >= minDays,
        tooCloseToChange: b.status === 'CONFIRMED' && days >= 0 && days < minDays,
        tooCloseMsg:  b.isMuhurtham ? t.tooCloseToChangeMuhurtham : t.tooCloseToChange,
        isRescheduling: b.reference === this.rescheduleRef,
      };
    });
  }

  @action startCancel(ref) {
    this.cancellingRef = ref;
    this.cancelMsg     = null;
  }

  @action dismissCancel() {
    this.cancellingRef = null;
  }

  @action async confirmCancel(ref) {
    this.cancelling = true;
    try {
      const res  = await fetch(apiUrl(`/api/enquiries/${ref}/cancel`), { method: 'POST' });
      const data = await res.json().catch(() => ({}));
      if (res.ok) {
        const t = this.t;
        let text;
        if (!data.hadPayment) {
          text = t.cancelledNoPayment;
        } else if (data.refundPaise > 0) {
          const rupees = Math.floor(data.refundPaise / 100).toLocaleString('en-IN');
          text = t.cancelledRefund(rupees);
        } else {
          text = t.cancelledNoRefund;
        }
        this.cancelMsg     = { type: 'success', text };
        this.cancellingRef = null;
        // reload the list so the cancelled booking shows updated status
        this.bookings = null;
        await this.load();
      } else {
        this.cancelMsg = { type: 'error', text: data.error || this.t.cancelError };
        this.cancellingRef = null;
      }
    } catch (_) {
      this.cancelMsg = { type: 'error', text: this.t.cancelError };
      this.cancellingRef = null;
    } finally {
      this.cancelling = false;
    }
  }

  @action startReschedule(ref) {
    this.rescheduleRef  = ref;
    this.rescheduleDate = '';
    this.rescheduleMsg  = null;
    this.cancellingRef  = null;
  }

  @action dismissReschedule() {
    this.rescheduleRef = null;
  }

  @action setRescheduleDate(iso) {
    this.rescheduleDate = iso;
  }

  @action async confirmReschedule(ref) {
    if (!this.rescheduleDate || this.rescheduling) return;
    this.rescheduling = true;
    try {
      const res = await fetch(apiUrl(`/api/enquiries/${ref}/reschedule`), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ newEventDate: this.rescheduleDate }),
      });
      const data = await res.json().catch(() => ({}));
      if (res.ok) {
        this.rescheduleMsg = { type: 'success', text: this.t.rescheduleSuccess(fmtDate(this.rescheduleDate)) };
        this.rescheduleRef = null;
        this.bookings = null;
        await this.load();
      } else {
        this.rescheduleMsg = { type: 'error', text: data.error || this.t.rescheduleError };
        this.rescheduleRef = null;
      }
    } catch (_) {
      this.rescheduleMsg = { type: 'error', text: this.t.rescheduleError };
      this.rescheduleRef = null;
    } finally {
      this.rescheduling = false;
    }
  }

  <template>
    <div class="rounded-xl border border-stone-200 bg-white shadow-sm overflow-hidden">

      <div class="px-5 py-4 border-b border-stone-100 flex items-center justify-between">
        <h2 class="font-semibold text-stone-900">{{this.t.title}}</h2>
        <LinkTo @route="booking" class="text-xs font-semibold text-rose-700 hover:text-rose-900 transition-colors">
          + {{this.t.bookNow}}
        </LinkTo>
      </div>

      {{! Cancel result banner }}
      {{#if this.cancelMsg}}
        <div class="mx-4 mt-4 rounded-lg px-4 py-3 text-sm font-medium {{if this.cancelMsgIsSuccess 'bg-green-50 border border-green-200 text-green-800' 'bg-red-50 border border-red-200 text-red-700'}}">
          {{this.cancelMsg.text}}
        </div>
      {{/if}}

      {{#if this.rescheduleMsg}}
        <div class="mx-4 mt-4 rounded-lg px-4 py-3 text-sm font-medium {{if this.rescheduleMsgIsSuccess 'bg-green-50 border border-green-200 text-green-800' 'bg-red-50 border border-red-200 text-red-700'}}">
          {{this.rescheduleMsg.text}}
        </div>
      {{/if}}

      {{#if this.loadError}}
        <p class="px-5 py-8 text-sm text-center text-stone-400">Could not load bookings. Please refresh the page.</p>
      {{else if this.isLoading}}
        <p class="px-5 py-8 text-sm text-center text-stone-400 animate-pulse">{{this.t.loading}}</p>
      {{else if this.isEmpty}}
        <div class="px-5 py-10 text-center">
          <p class="text-sm text-stone-400">{{this.t.empty}}</p>
          <LinkTo
            @route="booking"
            class="mt-3 inline-flex items-center gap-1.5 rounded-lg bg-rose-700 px-4 py-2 text-sm font-semibold text-white hover:bg-rose-800 transition-colors"
          >
            {{this.t.bookNow}}
            <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24" aria-hidden="true">
              <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3"/>
            </svg>
          </LinkTo>
        </div>
      {{else}}
        <div class="divide-y divide-stone-100">
          {{#each this.rows as |b|}}
            <div class="px-5 py-4 flex flex-col gap-3">

              <div class="flex flex-col sm:flex-row sm:items-center gap-3">
                <div class="flex-1 min-w-0">
                  <div class="flex flex-wrap items-center gap-2 mb-1">
                    <span class="font-mono text-sm font-bold text-stone-800">{{b.reference}}</span>
                    <span class="inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium {{b.statusCls}}">
                      {{b.statusLabel}}
                    </span>
                  </div>
                  <p class="text-xs text-stone-500">
                    {{b.formattedDate}} · {{b.funcLabel}} · {{b.rentalLabel}}
                  </p>
                </div>

                <div class="flex flex-wrap items-center gap-2 shrink-0">
                  {{#if b.canPay}}
                    <LinkTo
                      @route="payment"
                      @model={{b.reference}}
                      class="inline-flex items-center gap-1.5 rounded-lg bg-rose-700 px-3 py-1.5 text-xs font-bold text-white hover:bg-rose-800 transition-colors active:scale-[0.97]"
                    >
                      <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24" aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6 2.25h3m-3.75 3h15a2.25 2.25 0 002.25-2.25V6.75A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25v10.5A2.25 2.25 0 004.5 19.5z"/>
                      </svg>
                      {{this.t.payNow}}
                    </LinkTo>
                  {{/if}}

                  {{#if b.canInvoice}}
                    <LinkTo
                      @route="invoice"
                      @model={{b.reference}}
                      class="inline-flex items-center gap-1.5 rounded-lg border border-stone-200 bg-white px-3 py-1.5 text-xs font-medium text-stone-700 hover:bg-stone-50 hover:border-stone-300 transition-colors"
                    >
                      <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3"/>
                      </svg>
                      {{this.t.invoice}}
                    </LinkTo>
                  {{/if}}

                  <a
                    href={{b.waHref}}
                    target="_blank"
                    rel="noopener noreferrer"
                    class="inline-flex items-center gap-1.5 rounded-lg border border-green-200 bg-green-50 px-3 py-1.5 text-xs font-medium text-green-800 hover:bg-green-100 transition-colors"
                  >
                    <svg class="h-3.5 w-3.5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                      <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
                    </svg>
                    {{this.t.notify}}
                  </a>

                  {{#if b.canReschedule}}
                    <button
                      type="button"
                      class="inline-flex items-center gap-1.5 rounded-lg border border-blue-200 bg-blue-50 px-3 py-1.5 text-xs font-medium text-blue-700 hover:bg-blue-100 transition-colors"
                      {{on "click" (fn this.startReschedule b.reference)}}
                    >
                      <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v11.25m-18 0A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75m-18 0v-7.5A2.25 2.25 0 015.25 9h13.5A2.25 2.25 0 0121 9v7.5"/>
                      </svg>
                      {{this.t.changeDate}}
                    </button>
                  {{else if b.tooCloseToChange}}
                    <span class="inline-flex items-center gap-1 rounded-lg border border-amber-200 bg-amber-50 px-3 py-1.5 text-xs text-amber-700 cursor-not-allowed" title={{b.tooCloseMsg}}>
                      <svg class="h-3.5 w-3.5 shrink-0" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z"/>
                      </svg>
                      {{this.t.changeDate}}
                    </span>
                  {{/if}}

                  {{#if b.canCancel}}
                    <button
                      type="button"
                      class="inline-flex items-center gap-1.5 rounded-lg border border-red-200 bg-red-50 px-3 py-1.5 text-xs font-medium text-red-700 hover:bg-red-100 transition-colors"
                      {{on "click" (fn this.startCancel b.reference)}}
                    >
                      <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
                      </svg>
                      {{this.t.cancel}}
                    </button>
                  {{/if}}
                </div>
              </div>

              {{! Inline confirmation panel }}
              {{#if b.isConfirming}}
                <div class="rounded-lg border border-red-200 bg-red-50 px-4 py-3">
                  <p class="text-sm font-semibold text-red-800">{{this.t.cancelConfirmTitle}}</p>
                  <p class="mt-0.5 text-xs text-red-600">{{this.t.cancelConfirmBody}}</p>
                  <div class="mt-3 flex items-center gap-2">
                    <button
                      type="button"
                      disabled={{this.cancelling}}
                      class="inline-flex items-center gap-1.5 rounded-lg bg-red-700 px-3 py-1.5 text-xs font-bold text-white hover:bg-red-800 transition-colors disabled:opacity-60"
                      {{on "click" (fn this.confirmCancel b.reference)}}
                    >
                      {{#if this.cancelling}}
                        {{this.t.cancelling}}
                      {{else}}
                        {{this.t.cancelConfirmYes}}
                      {{/if}}
                    </button>
                    <button
                      type="button"
                      disabled={{this.cancelling}}
                      class="inline-flex items-center rounded-lg border border-red-200 bg-white px-3 py-1.5 text-xs font-medium text-red-700 hover:bg-red-50 transition-colors disabled:opacity-60"
                      {{on "click" this.dismissCancel}}
                    >
                      {{this.t.cancelConfirmNo}}
                    </button>
                  </div>
                </div>
              {{/if}}

              {{#if b.tooCloseToChange}}
                <div class="rounded-lg border border-amber-200 bg-amber-50 px-4 py-2.5 text-xs text-amber-800">
                  <svg class="inline h-3.5 w-3.5 mr-1 text-amber-600" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z"/>
                  </svg>
                  {{b.tooCloseMsg}}
                </div>
              {{/if}}

              {{#if b.isRescheduling}}
                <div class="rounded-lg border border-blue-200 bg-blue-50 px-4 py-3">
                  <p class="text-sm font-semibold text-blue-800">{{this.t.rescheduleTitle}}</p>
                  <div class="mt-3">
                    <label class="text-xs font-medium text-blue-700 mb-1.5 block">{{this.t.rescheduleLabel}}</label>
                    <DatePickerCalendar
                      @value={{this.rescheduleDate}}
                      @min={{this.minRescheduleDate}}
                      @onChange={{this.setRescheduleDate}}
                    />
                  </div>
                  <div class="mt-3 flex items-center gap-2">
                    <button
                      type="button"
                      disabled={{this.rescheduling}}
                      class="inline-flex items-center gap-1.5 rounded-lg bg-blue-700 px-3 py-1.5 text-xs font-bold text-white hover:bg-blue-800 transition-colors disabled:opacity-60"
                      {{on "click" (fn this.confirmReschedule b.reference)}}
                    >
                      {{#if this.rescheduling}}
                        {{this.t.rescheduling}}
                      {{else}}
                        {{this.t.rescheduleConfirm}}
                      {{/if}}
                    </button>
                    <button
                      type="button"
                      disabled={{this.rescheduling}}
                      class="inline-flex items-center rounded-lg border border-blue-200 bg-white px-3 py-1.5 text-xs font-medium text-blue-700 hover:bg-blue-50 transition-colors disabled:opacity-60"
                      {{on "click" this.dismissReschedule}}
                    >
                      {{this.t.rescheduleBack}}
                    </button>
                  </div>
                </div>
              {{/if}}

            </div>
          {{/each}}
        </div>
      {{/if}}

    </div>
  </template>
}
