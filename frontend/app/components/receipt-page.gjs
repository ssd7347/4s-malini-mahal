import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { LinkTo } from '@ember/routing';
import { apiUrl } from 'frontend/utils/api';

const RENTAL_LABELS = {
  FULL_DAY: { en: 'Full Day',  ta: 'முழு நாள்' },
  HALF_DAY: { en: 'Half Day',  ta: 'அரை நாள்' },
  HOURLY:   { en: 'Hourly',    ta: 'மணிநேரம்' },
};

const FUNCTION_TYPE_LABELS = {
  MARRIAGE:         { en: 'Marriage',             ta: 'திருமணம்' },
  RECEPTION:        { en: 'Reception',             ta: 'வரவேற்பு' },
  ENGAGEMENT:       { en: 'Engagement',            ta: 'நிச்சயதார்த்தம்' },
  BIRTHDAY_FUNCTION:{ en: 'Birthday Function',     ta: 'பிறந்தநாள் விழா' },
  OTHER:            { en: 'Other',                 ta: 'மற்றவை' },
  MEETING:          { en: 'Meeting',               ta: 'கூட்டம்' },
  CONFERENCE:       { en: 'Conference',            ta: 'மாநாடு' },
  TRAINING_SESSION: { en: 'Training Session',      ta: 'பயிற்சி அமர்வு' },
  SEMINAR:          { en: 'Seminar',               ta: 'கருத்தரங்கு' },
  WORKSHOP:         { en: 'Workshop',              ta: 'பட்டறை' },
  SMALL_GATHERING:  { en: 'Small Gathering',       ta: 'சிறு கூட்டம்' },
  OTHER_HOURLY:     { en: 'Other Hourly Events',   ta: 'மற்ற மணிநேர நிகழ்வுகள்' },
};

const STATUS_LABELS = {
  NEW:              { en: 'Received — Under Review',          ta: 'பெறப்பட்டது — மதிப்பாய்வில்' },
  UNDER_ENQUIRY:    { en: 'Under Review',                      ta: 'மதிப்பாய்வில்' },
  AWAITING_PAYMENT: { en: 'Payment Required',                  ta: 'கட்டணம் தேவை' },
  CONFIRMED:        { en: 'Confirmed',                         ta: 'உறுதிப்படுத்தப்பட்டது' },
  COMPLETED:        { en: 'Completed',                         ta: 'முடிந்தது' },
  DECLINED:         { en: 'Not Available for This Date',       ta: 'இந்த தேதிக்கு கிடைக்கவில்லை' },
  REJECTED:         { en: 'Rejected',                          ta: 'நிராகரிக்கப்பட்டது' },
  CANCELLED:        { en: 'Cancelled',                         ta: 'ரத்துசெய்யப்பட்டது' },
};

const T = {
  en: {
    pageTitle:      'Booking Receipt',
    back:           '← Back',
    downloadPdf:    'Download PDF',
    loading:        'Loading receipt…',
    errLoad:        'Could not load receipt.',
    errServer:      'Could not reach the server. Please try again.',
    receiptNo:      'Receipt No:',
    generated:      'Generated:',
    customerDetails:'Customer Details',
    fullName:       'Full Name',
    mobileNumber:   'Mobile Number',
    bookingDetails: 'Booking Details',
    bookingId:      'Booking ID',
    bookingDate:    'Booking Date',
    functionType:   'Function Type',
    rentalType:     'Rental Type',
    eventDate:      'Event Date',
    timeSlot:       'Time Slot',
    bookingStatus:  'Booking Status',
    advancePaid:    'Advance Paid',
    muhurthamNote:  '★ Muhurtham Day — Special Refund Policy Applies',
    hallDetails:    'Hall Details',
    hallName:       'Hall Name',
    address:        'Address',
    contact:        'Contact',
    terms:          'Terms & Conditions',
    termsEn:        'English',
    termsTa:        'தமிழ் / Tamil',
    footer:         'This receipt serves as an acknowledgement of the booking request and acceptance of the Mahal Terms & Conditions.',
  },
  ta: {
    pageTitle:      'பதிவு ரசீது',
    back:           '← பின்செல்',
    downloadPdf:    'PDF பதிவிறக்கவும்',
    loading:        'ரசீது ஏற்றுகிறது…',
    errLoad:        'ரசீதை ஏற்ற முடியவில்லை.',
    errServer:      'சேவையகத்தை அடைய முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
    receiptNo:      'ரசீது எண்:',
    generated:      'உருவாக்கப்பட்ட தேதி:',
    customerDetails:'வாடிக்கையாளர் விவரங்கள்',
    fullName:       'முழு பெயர்',
    mobileNumber:   'கைபேசி எண்',
    bookingDetails: 'பதிவு விவரங்கள்',
    bookingId:      'பதிவு எண்',
    bookingDate:    'பதிவு தேதி',
    functionType:   'செயல்பாட்டு வகை',
    rentalType:     'வாடகை வகை',
    eventDate:      'நிகழ்வு தேதி',
    timeSlot:       'நேர இடைவெளி',
    bookingStatus:  'பதிவு நிலை',
    advancePaid:    'முன்பணம் செலுத்தப்பட்டது',
    muhurthamNote:  '★ முஹூர்த்தம் நாள் — சிறப்பு திரும்பக்கொடுப்பு கொள்கை',
    hallDetails:    'மண்டப விவரங்கள்',
    hallName:       'மண்டப பெயர்',
    address:        'முகவரி',
    contact:        'தொடர்பு',
    terms:          'விதிமுறைகள் & நிபந்தனைகள்',
    termsEn:        'ஆங்கிலம்',
    termsTa:        'தமிழ் / Tamil',
    footer:         'இந்த ரசீது பதிவு கோரிக்கையை உறுதிப்படுத்தவும் மண்டப விதிமுறைகளை ஒப்புக்கொண்டதற்கும் ஆவணமாக செயல்படுகிறது.',
  },
};

function fmtDate(isoDate) {
  if (!isoDate) return '—';
  const [y, m, d] = isoDate.split('-').map(Number);
  return new Date(y, m - 1, d).toLocaleDateString('en-IN', {
    day: 'numeric', month: 'long', year: 'numeric',
  });
}

function fmtDateTime(isoStr) {
  if (!isoStr) return '—';
  return new Date(isoStr).toLocaleString('en-IN', {
    day: 'numeric', month: 'long', year: 'numeric',
    hour: '2-digit', minute: '2-digit', hour12: true,
    timeZone: 'Asia/Kolkata',
  });
}

function fmtTime(isoStr) {
  if (!isoStr) return '—';
  return new Date(isoStr).toLocaleString('en-IN', {
    hour: '2-digit', minute: '2-digit', hour12: true,
    timeZone: 'Asia/Kolkata',
  });
}

function rupees(paise) {
  if (!paise || paise <= 0) return null;
  return '₹' + (paise / 100).toLocaleString('en-IN');
}

export default class ReceiptPage extends Component {
  @service language;
  @tracked loading = true;
  @tracked error   = null;
  @tracked data    = null;

  generatedAt = new Date().toLocaleString('en-IN', {
    day: 'numeric', month: 'long', year: 'numeric',
    hour: '2-digit', minute: '2-digit', hour12: true,
    timeZone: 'Asia/Kolkata',
  });

  constructor() {
    super(...arguments);
    this.load();
  }

  async load() {
    try {
      const res = await fetch(apiUrl(`/api/receipts/${encodeURIComponent(this.args.reference)}`));
      if (!res.ok) {
        const d = await res.json().catch(() => ({}));
        this.error = d.error || T.en.errLoad;
      } else {
        this.data = await res.json();
      }
    } catch (_) {
      this.error = T.en.errServer;
    } finally {
      this.loading = false;
    }
  }

  get t()    { return T[this.language.lang]; }
  get lang() { return this.language.lang; }

  get rentalLabel() {
    const r = RENTAL_LABELS[this.data?.rentalType];
    return r ? r[this.lang] : (this.data?.rentalType ?? '—');
  }
  get functionLabel() {
    const f = FUNCTION_TYPE_LABELS[this.data?.functionType];
    return f ? f[this.lang] : (this.data?.functionType ?? '—');
  }
  get statusLabel() {
    const s = STATUS_LABELS[this.data?.status];
    return s ? s[this.lang] : (this.data?.status ?? '—');
  }
  get eventDate()   { return fmtDate(this.data?.eventDate); }
  get createdAt()   { return fmtDateTime(this.data?.createdAt); }
  get startTime()   { return fmtTime(this.data?.startDatetime); }
  get endTime()     { return fmtTime(this.data?.endDatetime); }
  get advancePaid() { return rupees(this.data?.advancePaidPaise); }
  get hasTerms()    { return !!(this.data?.termsEnglish); }

  @action printReceipt() { window.print(); }

  <template>
    <div class="max-w-3xl mx-auto animate-slide-up">

      {{! Action bar — hidden in print }}
      <div class="receipt-toolbar flex items-center justify-between mb-5">
        <div>
          <h1 class="text-xl font-bold text-stone-900">{{this.t.pageTitle}}</h1>
          {{#if this.data}}
            <p class="text-sm text-stone-500 mt-0.5">{{this.data.reference}}</p>
          {{/if}}
        </div>
        <div class="flex items-center gap-2">
          <LinkTo @route="track" class="rounded-lg border border-stone-200 px-3 py-2 text-sm font-medium text-stone-600 hover:bg-stone-50 transition-colors">
            {{this.t.back}}
          </LinkTo>
          {{#if this.data}}
            <button
              type="button"
              class="inline-flex items-center gap-2 rounded-lg bg-rose-700 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-rose-800 transition-colors active:scale-[0.97]"
              {{on "click" this.printReceipt}}
            >
              <svg class="h-4 w-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3"/>
              </svg>
              {{this.t.downloadPdf}}
            </button>
          {{/if}}
        </div>
      </div>

      {{#if this.loading}}
        <div class="flex items-center justify-center gap-3 py-24 text-stone-400">
          <svg class="animate-spin h-5 w-5" viewBox="0 0 24 24" fill="none" aria-hidden="true">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
          </svg>
          <span class="text-sm">{{this.t.loading}}</span>
        </div>

      {{else if this.error}}
        <div class="rounded-xl border border-red-200 bg-red-50 px-5 py-4 text-sm text-red-700">
          {{this.error}}
        </div>

      {{else if this.data}}
        <div class="receipt-body bg-white rounded-2xl border border-stone-200 shadow-sm overflow-hidden">

          {{! Header }}
          <div class="bg-rose-700 px-8 py-7 text-center text-white">
            <div class="flex items-center justify-center gap-3 mb-1">
              <img src="/logo.jpg" alt="" class="receipt-logo h-10 w-10 rounded-lg object-cover shadow-sm" aria-hidden="true"/>
              <h2 class="text-2xl font-bold tracking-tight">4S Malini Mahal</h2>
            </div>
            <p class="text-rose-200 text-sm mt-1">Virudhunagar Main Rd, Thiruthangal, Sivakasi — 626 130, Tamil Nadu</p>
            <p class="text-rose-200 text-sm">+91 94433 80023</p>
            <div class="mt-4 inline-block rounded-full border border-rose-400 bg-rose-600 px-7 py-1.5">
              <span class="text-xs font-bold tracking-[0.2em] uppercase">{{this.t.pageTitle}}</span>
            </div>
          </div>

          {{! Receipt meta }}
          <div class="flex items-center justify-between bg-stone-50 border-b border-stone-200 px-8 py-3">
            <span class="text-xs text-stone-500">
              {{this.t.receiptNo}} <span class="font-mono font-bold text-stone-800">{{this.data.reference}}</span>
            </span>
            <span class="text-xs text-stone-500">
              {{this.t.generated}} <span class="font-medium text-stone-700">{{this.generatedAt}}</span>
            </span>
          </div>

          {{! Customer + Booking two-column }}
          <div class="grid sm:grid-cols-2 divide-y sm:divide-y-0 sm:divide-x divide-stone-100">

            {{! Customer Details }}
            <div class="px-8 py-6">
              <h3 class="text-xs font-bold uppercase tracking-widest text-rose-700 mb-4 pb-2 border-b border-stone-100">
                {{this.t.customerDetails}}
              </h3>
              <dl class="space-y-3">
                <div>
                  <dt class="text-xs text-stone-400 mb-0.5">{{this.t.fullName}}</dt>
                  <dd class="text-sm font-semibold text-stone-900">{{this.data.customerName}}</dd>
                </div>
                <div>
                  <dt class="text-xs text-stone-400 mb-0.5">{{this.t.mobileNumber}}</dt>
                  <dd class="text-sm font-semibold text-stone-900">+91 {{this.data.mobile}}</dd>
                </div>
              </dl>
            </div>

            {{! Booking Details }}
            <div class="px-8 py-6">
              <h3 class="text-xs font-bold uppercase tracking-widest text-rose-700 mb-4 pb-2 border-b border-stone-100">
                {{this.t.bookingDetails}}
              </h3>
              <dl class="space-y-3">
                <div class="grid grid-cols-2 gap-x-4">
                  <div>
                    <dt class="text-xs text-stone-400 mb-0.5">{{this.t.bookingId}}</dt>
                    <dd class="font-mono text-sm font-bold text-stone-900">{{this.data.reference}}</dd>
                  </div>
                  <div>
                    <dt class="text-xs text-stone-400 mb-0.5">{{this.t.bookingDate}}</dt>
                    <dd class="text-xs font-medium text-stone-700">{{this.createdAt}}</dd>
                  </div>
                </div>
                <div class="grid grid-cols-2 gap-x-4">
                  <div>
                    <dt class="text-xs text-stone-400 mb-0.5">{{this.t.functionType}}</dt>
                    <dd class="text-sm font-medium text-stone-900">{{this.functionLabel}}</dd>
                  </div>
                  <div>
                    <dt class="text-xs text-stone-400 mb-0.5">{{this.t.rentalType}}</dt>
                    <dd class="text-sm font-medium text-stone-900">{{this.rentalLabel}}</dd>
                  </div>
                </div>
                <div class="grid grid-cols-2 gap-x-4">
                  <div>
                    <dt class="text-xs text-stone-400 mb-0.5">{{this.t.eventDate}}</dt>
                    <dd class="text-sm font-semibold text-stone-900">{{this.eventDate}}</dd>
                  </div>
                  <div>
                    <dt class="text-xs text-stone-400 mb-0.5">{{this.t.timeSlot}}</dt>
                    <dd class="text-sm font-medium text-stone-900">{{this.startTime}} – {{this.endTime}}</dd>
                  </div>
                </div>
                <div class="grid grid-cols-2 gap-x-4">
                  <div>
                    <dt class="text-xs text-stone-400 mb-0.5">{{this.t.bookingStatus}}</dt>
                    <dd class="text-sm font-semibold text-stone-900">{{this.statusLabel}}</dd>
                  </div>
                  {{#if this.advancePaid}}
                    <div>
                      <dt class="text-xs text-stone-400 mb-0.5">{{this.t.advancePaid}}</dt>
                      <dd class="text-sm font-bold text-green-700">{{this.advancePaid}}</dd>
                    </div>
                  {{/if}}
                </div>
                {{#if this.data.muhurtham}}
                  <div>
                    <span class="inline-flex items-center gap-1.5 rounded-full border border-yellow-300 bg-yellow-50 px-3 py-1 text-xs font-semibold text-yellow-800">
                      {{this.t.muhurthamNote}}
                    </span>
                  </div>
                {{/if}}
              </dl>
            </div>
          </div>

          {{! Hall Details }}
          <div class="border-t border-stone-100 bg-stone-50 px-8 py-5">
            <h3 class="text-xs font-bold uppercase tracking-widest text-rose-700 mb-3">{{this.t.hallDetails}}</h3>
            <div class="grid sm:grid-cols-3 gap-3 text-sm">
              <div>
                <p class="text-xs text-stone-400 mb-0.5">{{this.t.hallName}}</p>
                <p class="font-semibold text-stone-900">4S Malini Mahal</p>
              </div>
              <div>
                <p class="text-xs text-stone-400 mb-0.5">{{this.t.address}}</p>
                <p class="text-stone-700 text-xs leading-relaxed">Virudhunagar Main Rd, Thiruthangal, Sivakasi — 626 130, Tamil Nadu</p>
              </div>
              <div>
                <p class="text-xs text-stone-400 mb-0.5">{{this.t.contact}}</p>
                <p class="text-stone-700">+91 94433 80023</p>
              </div>
            </div>
          </div>

          {{! Terms & Conditions }}
          {{#if this.hasTerms}}
            <div class="border-t border-stone-200 px-8 py-6">
              <h3 class="text-xs font-bold uppercase tracking-widest text-rose-700 mb-5">
                {{this.t.terms}}
              </h3>
              <div class="mb-5">
                <p class="text-xs font-semibold uppercase tracking-wide text-stone-400 mb-2">{{this.t.termsEn}}</p>
                <div class="rounded-xl border border-stone-100 bg-stone-50 p-5 text-xs leading-relaxed text-stone-700 whitespace-pre-wrap">{{this.data.termsEnglish}}</div>
              </div>
              {{#if this.data.termsTamil}}
                <div>
                  <p class="text-xs font-semibold uppercase tracking-wide text-stone-400 mb-2">{{this.t.termsTa}}</p>
                  <div class="rounded-xl border border-stone-100 bg-stone-50 p-5 text-xs leading-relaxed text-stone-700 whitespace-pre-wrap">{{this.data.termsTamil}}</div>
                </div>
              {{/if}}
            </div>
          {{/if}}

          {{! Footer }}
          <div class="border-t border-stone-200 bg-rose-50 px-8 py-5 text-center">
            <p class="text-xs text-stone-600 leading-relaxed max-w-lg mx-auto">
              {{this.t.footer}}
            </p>
            <p class="mt-2 text-xs font-semibold text-stone-800">
              4S Malini Mahal · Thiruthangal, Sivakasi · +91 94433 80023
            </p>
          </div>

        </div>
      {{/if}}
    </div>
  </template>
}
