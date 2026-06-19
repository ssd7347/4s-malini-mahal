import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { LinkTo } from '@ember/routing';
import { apiUrl } from 'frontend/utils/api';

const RENTAL_LABELS = {
  HOURLY:   { en: 'Hourly',   ta: 'மணிநேரம்' },
  HALF_DAY: { en: 'Half day', ta: 'அரை நாள்' },
  FULL_DAY: { en: 'Full day', ta: 'முழு நாள்' },
};

const FUNCTION_TYPE_LABELS = {
  MARRIAGE:         { en: 'Marriage',             ta: 'திருமணம்' },
  RECEPTION:        { en: 'Reception',             ta: 'வரவேற்பு' },
  ENGAGEMENT:       { en: 'Engagement',            ta: 'நிச்சயதார்த்தம்' },
  BIRTHDAY_FUNCTION:{ en: 'Birthday Function',     ta: 'பிறந்தநாள் விழா' },
  KARI_SAAPADU:     { en: 'Kari Saapadu',          ta: 'காரி சாப்பாடு' },
  OTHER:            { en: 'Other',                 ta: 'மற்றவை' },
  MEETING:          { en: 'Meeting',               ta: 'கூட்டம்' },
  CONFERENCE:       { en: 'Conference',            ta: 'மாநாடு' },
  TRAINING_SESSION: { en: 'Training Session',      ta: 'பயிற்சி அமர்வு' },
  SEMINAR:          { en: 'Seminar',               ta: 'கருத்தரங்கு' },
  WORKSHOP:         { en: 'Workshop',              ta: 'பட்டறை' },
  SMALL_GATHERING:  { en: 'Small Gathering',       ta: 'சிறு கூட்டம்' },
  OTHER_HOURLY:     { en: 'Other Hourly Events',   ta: 'மற்ற மணிநேர நிகழ்வுகள்' },
};

const STATUS_BADGE = {
  NEW:              { en: 'Received — under review',    ta: 'பெறப்பட்டது — மதிப்பாய்வில்',          cls: 'bg-stone-100 text-stone-600 border-stone-300' },
  UNDER_ENQUIRY:    { en: 'Under review',                ta: 'மதிப்பாய்வில்',                         cls: 'bg-amber-50 text-amber-700 border-amber-300' },
  AWAITING_PAYMENT: { en: 'Payment required',            ta: 'கட்டணம் தேவை',                         cls: 'bg-yellow-50 text-yellow-700 border-yellow-300' },
  CONFIRMED:        { en: 'Confirmed',                   ta: 'உறுதிப்படுத்தப்பட்டது',                cls: 'bg-green-50 text-green-700 border-green-300' },
  COMPLETED:        { en: 'Completed',                   ta: 'முடிந்தது',                             cls: 'bg-blue-50 text-blue-700 border-blue-300' },
  DECLINED:         { en: 'Not available for this date', ta: 'இந்த தேதிக்கு கிடைக்கவில்லை',        cls: 'bg-red-50 text-red-600 border-red-300' },
  CANCELLED:        { en: 'Cancelled',                   ta: 'ரத்துசெய்யப்பட்டது',                  cls: 'bg-stone-50 text-stone-400 border-stone-200' },
};

const T = {
  en: {
    track:           'Track',
    errNotFound:     'Could not find that booking.',
    errServer:       'Could not reach the server. Please try again.',
    reference:       'Reference',
    muhurtham:       '★ Muhurtham Day',
    eventDate:       'Event date',
    rentalType:      'Rental type',
    functionType:    'Function type',
    submitted:       'Submitted',
    payNow:          'Pay Now',
    viewInvoice:     'View Invoice',
    downloadReceipt: 'Download Receipt (PDF)',
  },
  ta: {
    track:           'கண்காணி',
    errNotFound:     'அந்த பதிவை கண்டுபிடிக்க முடியவில்லை.',
    errServer:       'சேவையகத்தை அடைய முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
    reference:       'குறிப்பு',
    muhurtham:       '★ முஹூர்த்தம் நாள்',
    eventDate:       'நிகழ்வு தேதி',
    rentalType:      'வாடகை வகை',
    functionType:    'செயல்பாட்டு வகை',
    submitted:       'சமர்ப்பிக்கப்பட்டது',
    payNow:          'இப்போது கட்டணம்',
    viewInvoice:     'விலைப்பட்டியல் காண',
    downloadReceipt: 'ரசீதை பதிவிறக்கவும் (PDF)',
  },
};

export default class EnquiryTracker extends Component {
  @service language;
  @tracked loading = false;
  @tracked error   = null;
  @tracked result  = null;

  get t()   { return T[this.language.lang]; }
  get lang(){ return this.language.lang; }

  get formattedEventDate() {
    if (!this.result?.eventDate) return '—';
    const [y, m, d] = this.result.eventDate.split('-').map(Number);
    return new Date(y, m - 1, d).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
  }

  get formattedRentalType() {
    if (!this.result?.rentalType) return '—';
    const labels = RENTAL_LABELS[this.result.rentalType];
    return labels ? labels[this.lang] : this.result.rentalType;
  }

  get formattedFunctionType() {
    if (!this.result?.functionType) return '—';
    const labels = FUNCTION_TYPE_LABELS[this.result.functionType];
    return labels ? labels[this.lang] : this.result.functionType;
  }

  get formattedCreatedAt() {
    if (!this.result?.createdAt) return '—';
    return new Date(this.result.createdAt).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
  }

  get badge() {
    if (!this.result) return null;
    const b = STATUS_BADGE[this.result.status];
    if (!b) return { label: this.result.status, cls: 'bg-stone-100 text-stone-600 border-stone-300' };
    return { label: b[this.lang], cls: b.cls };
  }

  get showPayNow()  { return this.result?.status === 'AWAITING_PAYMENT'; }
  get showInvoice() { return ['CONFIRMED', 'COMPLETED'].includes(this.result?.status); }

  @action
  async track(event) {
    event.preventDefault();
    this.error  = null;
    this.result = null;
    this.loading = true;

    const ref = new FormData(event.currentTarget).get('reference').trim().toUpperCase();
    try {
      const res = await fetch(apiUrl(`/api/enquiries/${encodeURIComponent(ref)}`));
      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        this.error = data.error || this.t.errNotFound;
      } else {
        this.result = await res.json();
      }
    } catch (_) {
      this.error = this.t.errServer;
    } finally {
      this.loading = false;
    }
  }

  <template>
    <form class="mt-2 flex gap-2" {{on "submit" this.track}}>
      <input
        name="reference"
        type="text"
        required
        placeholder="MM-XXXXXX"
        maxlength="9"
        pattern="[Mm][Mm]-[A-Za-z0-9]{6}"
        title="Format: MM-XXXXXX (e.g. MM-7K4QPX)"
        class="flex-1 rounded-lg border border-stone-200 bg-white px-3 py-2.5 font-mono uppercase tracking-wider text-stone-900 placeholder:text-stone-400 placeholder:normal-case placeholder:tracking-normal transition-[border-color,box-shadow] duration-150 focus:border-rose-500 focus:ring-4 focus:ring-rose-500/10 focus:outline-none"
      />
      <button
        type="submit"
        disabled={{this.loading}}
        class="inline-flex items-center gap-1.5 rounded-lg bg-rose-700 px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition-all duration-150 hover:bg-rose-800 hover:shadow-md active:scale-[0.98] disabled:opacity-60 disabled:cursor-not-allowed"
      >
        {{#if this.loading}}
          <svg class="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none" aria-hidden="true">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
          </svg>
        {{else}}
          {{this.t.track}}
        {{/if}}
      </button>
    </form>

    {{#if this.error}}
      <p class="mt-4 flex items-center gap-2 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 animate-fade-in">
        <svg class="h-4 w-4 shrink-0" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" d="M9.75 9.75l4.5 4.5m0-4.5l-4.5 4.5M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
        </svg>
        {{this.error}}
      </p>
    {{/if}}

    {{#if this.result}}
      <div class="mt-5 rounded-xl border border-stone-200 bg-white shadow-sm overflow-hidden animate-slide-up">
        <div class="border-b border-stone-100 px-6 py-4 flex items-center justify-between gap-4">
          <div>
            <p class="text-xs font-medium text-stone-400 uppercase tracking-wide">{{this.t.reference}}</p>
            <p class="mt-0.5 font-mono font-semibold text-stone-900 tracking-wide">{{this.result.reference}}</p>
            {{#if this.result.isMuhurtham}}
              <span class="mt-1 inline-flex items-center gap-1 rounded-full border border-yellow-300 bg-yellow-50 px-2 py-0.5 text-xs font-semibold text-yellow-700">
                {{this.t.muhurtham}}
              </span>
            {{/if}}
          </div>
          <div class="flex flex-col items-end gap-2">
            <span class="inline-flex items-center rounded-full border px-3 py-1 text-xs font-semibold {{this.badge.cls}}">
              {{this.badge.label}}
            </span>
            {{#if this.showPayNow}}
              <LinkTo
                @route="payment"
                @model={{this.result.reference}}
                class="inline-flex items-center gap-1.5 rounded-lg bg-rose-700 px-4 py-2 text-sm font-bold text-white shadow-md hover:bg-rose-800 active:scale-[0.97] transition-all duration-150"
              >
                {{this.t.payNow}}
              </LinkTo>
            {{/if}}
            {{#if this.showInvoice}}
              <LinkTo
                @route="invoice"
                @model={{this.result.reference}}
                class="text-xs font-medium text-emerald-600 hover:text-emerald-800 transition-colors underline"
              >
                {{this.t.viewInvoice}}
              </LinkTo>
            {{/if}}
          </div>
        </div>

        <div class="grid grid-cols-2 gap-px bg-stone-100">
          <div class="bg-white px-6 py-4">
            <p class="text-xs font-medium text-stone-400 uppercase tracking-wide">{{this.t.eventDate}}</p>
            <p class="mt-0.5 text-sm font-medium text-stone-900">{{this.formattedEventDate}}</p>
          </div>
          <div class="bg-white px-6 py-4">
            <p class="text-xs font-medium text-stone-400 uppercase tracking-wide">{{this.t.rentalType}}</p>
            <p class="mt-0.5 text-sm font-medium text-stone-900">{{this.formattedRentalType}}</p>
          </div>
          <div class="col-span-2 bg-white px-6 py-4">
            <p class="text-xs font-medium text-stone-400 uppercase tracking-wide">{{this.t.functionType}}</p>
            <p class="mt-0.5 text-sm font-medium text-stone-900">{{this.formattedFunctionType}}</p>
          </div>
          <div class="col-span-2 bg-white px-6 py-4 border-t border-stone-100">
            <p class="text-xs font-medium text-stone-400 uppercase tracking-wide">{{this.t.submitted}}</p>
            <p class="mt-0.5 text-sm font-medium text-stone-900">{{this.formattedCreatedAt}}</p>
          </div>
        </div>

        {{! Download Receipt }}
        <div class="border-t border-stone-100 px-6 py-4 bg-stone-50 flex justify-center">
          <LinkTo
            @route="receipt"
            @model={{this.result.reference}}
            class="inline-flex items-center gap-2 rounded-lg border border-stone-200 bg-white px-4 py-2 text-sm font-semibold text-stone-700 shadow-sm hover:bg-stone-50 hover:border-rose-200 hover:text-rose-700 transition-colors"
          >
            <svg class="h-4 w-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
              <path stroke-linecap="round" stroke-linejoin="round" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3"/>
            </svg>
            {{this.t.downloadReceipt}}
          </LinkTo>
        </div>
      </div>
    {{/if}}
  </template>
}
