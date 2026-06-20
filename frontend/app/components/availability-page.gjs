import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { LinkTo } from '@ember/routing';
import { apiUrl } from 'frontend/utils/api';
import DatePickerCalendar from 'frontend/components/date-picker-calendar';

const T = {
  en: {
    pickPrompt:       'Pick a date above to check availability.',
    checking:         'Checking availability…',
    available:        'Available',
    availableHint:    'This date is open — you can book now.',
    pending:          'Enquiry Pending',
    pendingHint:      'Another enquiry is pending for this date. You may still submit yours.',
    unavailable:      'Not Available',
    unavailableHint:  'This date is fully booked.',
    muhurthamBadge:   'Muhurtham Day — auspicious date',
    muhurthamTitle:   'Cancellation policy for muhurtham dates',
    muhurthamPolicy:  '0% refund if cancelled after booking. Non-muhurtham dates receive a full advance refund.',
    muhurthamNoHourly:'Hourly rental is not available on muhurtham dates.',
    bookedNote:       'Already reserved:',
    nextSlotFrom:     'Next available from',
    gapNote:          '(2 hr gap required between bookings)',
    bookNow:          'Book this date',
  },
  ta: {
    pickPrompt:       'கிடைப்பை சரிபார்க்க மேலே ஒரு தேதியை தேர்வு செய்யுங்கள்.',
    checking:         'கிடைக்கும் தன்மையை சரிபார்க்கிறது…',
    available:        'கிடைக்கிறது',
    availableHint:    'இந்த தேதி திறந்திருக்கிறது — இப்போது பதிவு செய்யலாம்.',
    pending:          'விசாரணை நிலுவையில்',
    pendingHint:      'இந்த தேதிக்கு மற்றொரு விசாரணை நிலுவையில் உள்ளது. நீங்களும் சமர்ப்பிக்கலாம்.',
    unavailable:      'கிடைக்கவில்லை',
    unavailableHint:  'இந்த தேதி முழுவதுமாக முன்பதிவு செய்யப்பட்டது.',
    muhurthamBadge:   'முஹூர்த்தம் நாள் — மங்களகரமான தேதி',
    muhurthamTitle:   'முஹூர்த்தம் தேதிகளுக்கான ரத்துக் கொள்கை',
    muhurthamPolicy:  'பதிவு செய்த பிறகு ரத்துசெய்தால் 0% திரும்பக்கொடுப்பு.',
    muhurthamNoHourly:'முஹூர்த்தம் நாட்களில் மணிநேர வாடகை கிடைக்காது.',
    bookedNote:       'ஏற்கனவே முன்பதிவு:',
    nextSlotFrom:     'அடுத்த கிடைக்கும் இடம்',
    gapNote:          '(பதிவுகளுக்கு இடையே 2 மணி நேர இடைவெளி தேவை)',
    bookNow:          'இந்த தேதியை பதிவிடுங்கள்',
  },
};

const RENTAL_LABELS = {
  en: { FULL_DAY: 'Full Day', HALF_DAY: 'Half Day', HOURLY: 'Hourly' },
  ta: { FULL_DAY: 'முழு நாள்', HALF_DAY: 'அரை நாள்', HOURLY: 'மணிநேரம்' },
};

function fmtT(hhmm) {
  const [h, m] = hhmm.split(':').map(Number);
  const p  = h >= 12 ? 'PM' : 'AM';
  const dh = h > 12 ? h - 12 : (h === 0 ? 12 : h);
  return m === 0 ? `${dh} ${p}` : `${dh}:${String(m).padStart(2, '0')} ${p}`;
}

function todayIso() {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
}

export default class AvailabilityPage extends Component {
  @service language;

  @tracked selectedDate      = '';
  @tracked loading           = false;
  @tracked availability      = null;   // 'AVAILABLE' | 'UNDER_ENQUIRY' | 'UNAVAILABLE'
  @tracked isMuhurtham       = false;
  @tracked bookedSlots       = [];

  get t()             { return T[this.language.lang]; }
  get today()         { return todayIso(); }
  get isAvailable()   { return this.availability === 'AVAILABLE'; }
  get isPending()     { return this.availability === 'UNDER_ENQUIRY'; }
  get isUnavailable() { return this.availability === 'UNAVAILABLE'; }

  get slotSuggestion() {
    if (!this.bookedSlots || this.bookedSlots.length === 0) return null;
    const lang = this.language.lang;
    const rl   = RENTAL_LABELS[lang] || RENTAL_LABELS.en;
    const taken = this.bookedSlots
      .map(s => `${fmtT(s.startTime)}–${fmtT(s.endTime)} (${rl[s.rentalType] ?? s.rentalType})`)
      .join(', ');
    const last = this.bookedSlots[this.bookedSlots.length - 1];
    const [lh, lm] = last.endTime.split(':').map(Number);
    const afterMin = lh * 60 + lm + 120;
    const ah = Math.floor(afterMin / 60);
    const am = afterMin % 60;
    const nextAvail = ah < 24
      ? fmtT(`${String(ah).padStart(2,'0')}:${String(am).padStart(2,'0')}`)
      : null;
    return { taken, nextAvail };
  }

  @action
  async onDateChange(iso) {
    this.selectedDate = iso;
    this.loading      = true;
    this.availability = null;
    this.isMuhurtham  = false;
    this.bookedSlots  = [];
    try {
      const res = await fetch(apiUrl(`/api/availability?date=${encodeURIComponent(iso)}`));
      if (res.ok) {
        const data = await res.json();
        this.availability = data.status;
        this.isMuhurtham  = data.isMuhurtham || false;
        this.bookedSlots  = data.bookedSlots  || [];
      }
    } catch (_) {}
    finally { this.loading = false; }
  }

  <template>
    <div class="space-y-4">

      <DatePickerCalendar
        @value={{this.selectedDate}}
        @min={{this.today}}
        @onChange={{this.onDateChange}}
      />

      {{! Status panel — shown after a date is picked }}
      {{#if this.loading}}
        <div class="flex items-center gap-2.5 rounded-xl border border-stone-200 bg-white px-4 py-3.5 text-sm text-stone-400 shadow-sm animate-pulse">
          <svg class="animate-spin h-4 w-4 shrink-0" viewBox="0 0 24 24" fill="none" aria-hidden="true">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
          </svg>
          {{this.t.checking}}
        </div>

      {{else if this.selectedDate}}
        {{#if this.isAvailable}}
          <div class="rounded-xl border border-green-200 bg-green-50 px-4 py-4 shadow-sm animate-fade-in">
            <div class="flex items-start gap-3">
              <svg class="h-5 w-5 text-green-600 mt-0.5 shrink-0" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
              </svg>
              <div class="flex-1">
                <p class="font-semibold text-green-800">{{this.t.available}}</p>
                <p class="mt-0.5 text-sm text-green-700">{{this.t.availableHint}}</p>
                {{#if this.isMuhurtham}}
                  <p class="mt-2 flex items-center gap-1.5 text-xs font-semibold text-amber-700">
                    <svg class="h-3.5 w-3.5 text-amber-500" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                      <path d="M12 2a10 10 0 100 20A10 10 0 0012 2zm0 3l1.5 4.5h4.5l-3.5 2.5 1.5 4.5L12 14l-4 2.5 1.5-4.5L6 9.5h4.5z"/>
                    </svg>
                    {{this.t.muhurthamBadge}}
                  </p>
                  <div class="mt-1.5 rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-xs">
                    <p class="font-semibold text-amber-800">{{this.t.muhurthamTitle}}</p>
                    <p class="mt-0.5 text-amber-700">{{this.t.muhurthamPolicy}}</p>
                    <p class="mt-0.5 text-amber-700">{{this.t.muhurthamNoHourly}}</p>
                  </div>
                {{/if}}
                <LinkTo
                  @route="booking"
                  class="mt-3 inline-flex items-center gap-1.5 rounded-lg bg-rose-700 px-4 py-2 text-sm font-semibold text-white hover:bg-rose-800 transition-colors active:scale-[0.97]"
                >
                  {{this.t.bookNow}}
                  <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24" aria-hidden="true">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3"/>
                  </svg>
                </LinkTo>
              </div>
            </div>
          </div>

        {{else if this.isPending}}
          <div class="rounded-xl border border-amber-200 bg-amber-50 px-4 py-4 shadow-sm animate-fade-in">
            <div class="flex items-start gap-3">
              <svg class="h-5 w-5 text-amber-600 mt-0.5 shrink-0" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z"/>
              </svg>
              <div class="flex-1">
                <p class="font-semibold text-amber-800">{{this.t.pending}}</p>
                <p class="mt-0.5 text-sm text-amber-700">{{this.t.pendingHint}}</p>
                {{#if this.slotSuggestion}}
                  <div class="mt-2 rounded-lg border border-amber-200 bg-white px-3 py-2 text-xs text-amber-800">
                    <p class="font-semibold">{{this.t.bookedNote}} {{this.slotSuggestion.taken}}</p>
                    {{#if this.slotSuggestion.nextAvail}}
                      <p class="mt-0.5">{{this.t.nextSlotFrom}} {{this.slotSuggestion.nextAvail}} — {{this.t.gapNote}}</p>
                    {{/if}}
                  </div>
                {{/if}}
                <LinkTo
                  @route="booking"
                  class="mt-3 inline-flex items-center gap-1.5 rounded-lg bg-rose-700 px-4 py-2 text-sm font-semibold text-white hover:bg-rose-800 transition-colors active:scale-[0.97]"
                >
                  {{this.t.bookNow}}
                  <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24" aria-hidden="true">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3"/>
                  </svg>
                </LinkTo>
              </div>
            </div>
          </div>

        {{else if this.isUnavailable}}
          <div class="rounded-xl border border-red-200 bg-red-50 px-4 py-4 shadow-sm animate-fade-in">
            <div class="flex items-start gap-3">
              <svg class="h-5 w-5 text-red-500 mt-0.5 shrink-0" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9.75 9.75l4.5 4.5m0-4.5l-4.5 4.5M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
              </svg>
              <div class="flex-1">
                <p class="font-semibold text-red-700">{{this.t.unavailable}}</p>
                <p class="mt-0.5 text-sm text-red-600">{{this.t.unavailableHint}}</p>
                {{#if this.slotSuggestion}}
                  <div class="mt-2 rounded-lg border border-red-200 bg-white px-3 py-2 text-xs text-red-700">
                    <p class="font-semibold">{{this.t.bookedNote}} {{this.slotSuggestion.taken}}</p>
                    {{#if this.slotSuggestion.nextAvail}}
                      <p class="mt-0.5">{{this.t.nextSlotFrom}} {{this.slotSuggestion.nextAvail}} — {{this.t.gapNote}}</p>
                    {{/if}}
                  </div>
                {{/if}}
              </div>
            </div>
          </div>
        {{/if}}

      {{else}}
        <p class="text-center text-sm text-stone-400 py-2">{{this.t.pickPrompt}}</p>
      {{/if}}

    </div>
  </template>
}
