import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { LinkTo } from '@ember/routing';
import { apiUrl } from 'frontend/utils/api';
import ClockTimePicker from 'frontend/components/clock-time-picker';
import DatePickerCalendar from 'frontend/components/date-picker-calendar';


const INPUT_CLS = 'mt-1 w-full rounded-lg border border-stone-200 bg-white px-3 py-2.5 text-stone-900 placeholder:text-stone-400 transition-[border-color,box-shadow] duration-150 focus:border-rose-500 focus:ring-4 focus:ring-rose-500/10 focus:outline-none';

const FUNCTION_TYPES = {
  FULL_DAY: [
    { value: 'MARRIAGE',         en: 'Marriage',             ta: 'திருமணம்' },
  ],
  HALF_DAY: [
    { value: 'RECEPTION',         en: 'Reception',            ta: 'வரவேற்பு' },
    { value: 'ENGAGEMENT',        en: 'Engagement',           ta: 'நிச்சயதார்த்தம்' },
    { value: 'BIRTHDAY_FUNCTION', en: 'Birthday Function',    ta: 'பிறந்தநாள் விழா' },
    { value: 'OTHER',             en: 'Other',                ta: 'மற்றவை' },
  ],
  HOURLY: [
    { value: 'MEETING',           en: 'Meeting',              ta: 'கூட்டம்' },
    { value: 'CONFERENCE',        en: 'Conference',           ta: 'மாநாடு' },
    { value: 'TRAINING_SESSION',  en: 'Training Session',     ta: 'பயிற்சி அமர்வு' },
    { value: 'SEMINAR',           en: 'Seminar',              ta: 'கருத்தரங்கு' },
    { value: 'WORKSHOP',          en: 'Workshop',             ta: 'பட்டறை' },
    { value: 'SMALL_GATHERING',   en: 'Small Gathering',      ta: 'சிறு கூட்டம்' },
    { value: 'OTHER_HOURLY',      en: 'Other Hourly Events',  ta: 'மற்ற மணிநேர நிகழ்வுகள்' },
  ],
};

const T = {
  en: {
    nameLabel:          'Your name',
    namePlaceholder:    'e.g. Ravi Kumar',
    yourAccount:        'your account',
    eventDate:          'Event date',
    muhurthamBadge:     'Muhurtham Day — auspicious date',
    muhurthamTitle:     'Cancellation policy for muhurtham dates',
    muhurthamPolicy:    '0% refund if cancelled after booking. Non-muhurtham dates receive a full advance refund on cancellation.',
    muhurthamNoHourly:  'Hourly rental is not available on muhurtham dates',
    checkingAvail:      'Checking availability…',
    available:          'Available',
    pendingEnquiry:     'Another enquiry is pending — you may still submit yours',
    unavailable:        'This date is not available — our team will still review your booking request',
    bookedNote:         'Already reserved on this date:',
    nextSlotFrom:       'Next available slot from',
    gapNote:            '(2 hr gap required between bookings)',
    rentalType:         'Rental type',
    selectRental:       'Select a rental type…',
    fullDayOption:      'Full day — ₹32,000',
    halfDayOption:      'Half day — ₹23,000',
    hourlyOption:       'Hourly — ₹3,000 / hr  (2–4 hrs)',
    fullDayAutoTitle:   'Full Day — Auto-assigned time slot',
    fullDayEntry:       'Entry: 3:00 PM (day before event) · Exit: 2:00 PM on event day',
    fullDayDeposit:     'Advance deposit: ₹35,000  (₹32,000 rent + ₹3,000 security refundable)',
    fullDayEarlyKey:    'Early key (before 3 PM on setup day): extra ₹5,000 charge (T&C Rule 2)',
    fullDayCancel:      'Cancellation: full refund for non-muhurtham dates; 0% refund for muhurtham dates',
    halfDayTitle:       'Half Day — Select your time slot',
    halfDayRate:        'Rate: ₹23,000 · Pick any 6–8 hour window using the clocks below',
    timeSlot:           'Time slot',
    startTime:          'Start time',
    endTime:            'End time',
    hourlyHint:         'Duration must be 2–4 hours. Charged at ₹3,000/hour.',
    functionType:       'Function type',
    availFor:           'Available functions for',
    selectRentalFirst:  'Select rental type first',
    selectFunction:     'Select function type…',
    message:            'Message',
    optional:           '(optional)',
    msgPlaceholder:     'Any specific requirements…',
    submit:             'Book Now',
    submitting:         'Booking…',
    loginPrompt:        'Log in to confirm your booking',
    loginPromptHint:    'Your details above will be ready — just log in and submit.',
    loginBtn:           'Log In to Continue',
    timesRequired:      'Please select start and end times using the clock.',
    errServer:          'Could not reach the server. Please try again.',
    errGeneric:         'Something went wrong. Please try again.',
    successTitle:       'Booking submitted!',
    successBody:        'Your reference number is',
    successHint:        'Save it to track your booking status.',
    notifyWA:           'Notify the hall on WhatsApp',
    downloadReceipt:    'Download Receipt',
    rentalLabels: {
      FULL_DAY: 'full day rental',
      HALF_DAY: 'half day rental',
      HOURLY:   'hourly rental',
    },
  },
  ta: {
    nameLabel:          'உங்கள் பெயர்',
    namePlaceholder:    'உ.தா. ரவி குமார்',
    yourAccount:        'உங்கள் கணக்கு',
    eventDate:          'நிகழ்வு தேதி',
    muhurthamBadge:     'முஹூர்த்தம் நாள் — மங்களகரமான தேதி',
    muhurthamTitle:     'முஹூர்த்தம் தேதிகளுக்கான ரத்துக் கொள்கை',
    muhurthamPolicy:    'பதிவு செய்த பிறகு ரத்துசெய்தால் 0% திரும்பக்கொடுப்பு. முஹூர்த்தம் அல்லாத தேதிகளில் ரத்துசெய்தால் முழு முன்பண திரும்பக்கொடுப்பு.',
    muhurthamNoHourly:  'முஹூர்த்தம் நாட்களில் மணிநேர வாடகை கிடைக்காது',
    checkingAvail:      'கிடைக்கும் தன்மையை சரிபார்க்கிறது…',
    available:          'கிடைக்கிறது',
    pendingEnquiry:     'மற்றொரு விசாரணை நிலுவையில் உள்ளது — நீங்கள் இன்னும் சமர்ப்பிக்கலாம்',
    unavailable:        'இந்த தேதி கிடைக்கவில்லை — எங்கள் குழு உங்கள் பதிவு கோரிக்கையை மதிப்பாய்வு செய்யும்',
    bookedNote:         'இந்த தேதியில் ஏற்கனவே முன்பதிவு:',
    nextSlotFrom:       'அடுத்த கிடைக்கும் இடமிருந்து',
    gapNote:            '(பதிவுகளுக்கு இடையே 2 மணி நேர இடைவெளி தேவை)',
    rentalType:         'வாடகை வகை',
    selectRental:       'வாடகை வகையை தேர்வு செய்யுங்கள்…',
    fullDayOption:      'முழு நாள் — ₹32,000',
    halfDayOption:      'அரை நாள் — ₹23,000',
    hourlyOption:       'மணிநேரம் — ₹3,000 / மணி (2–4 மணி)',
    fullDayAutoTitle:   'முழு நாள் — தானாக ஒதுக்கப்பட்ட நேர இடைவெளி',
    fullDayEntry:       'நுழைவு: நிகழ்வுக்கு முந்தைய நாள் மாலை 3:00 · வெளியேறு: நிகழ்வு நாளில் பிற்பகல் 2:00',
    fullDayDeposit:     'முன்பணம்: ₹35,000 (₹32,000 வாடகை + ₹3,000 திரும்பக்கிடைக்கும் பாதுகாப்புத் தொகை)',
    fullDayEarlyKey:    'தொடக்க நாளில் மாலை 3 மணிக்கு முன் சாவி: கூடுதல் ₹5,000 கட்டணம் (T&C விதி 2)',
    fullDayCancel:      'ரத்துசெய்தல்: முஹூர்த்தம் அல்லாத தேதிகளுக்கு முழு திரும்பக்கொடுப்பு; முஹூர்த்தம் தேதிகளுக்கு 0%',
    halfDayTitle:       'அரை நாள் — உங்கள் நேர இடைவெளியை தேர்வு செய்யுங்கள்',
    halfDayRate:        'கட்டணம்: ₹23,000 · கீழே உள்ள கடிகாரங்களில் 6–8 மணி நேர சாளரத்தை தேர்வு செய்யுங்கள்',
    timeSlot:           'நேர இடைவெளி',
    startTime:          'தொடக்க நேரம்',
    endTime:            'முடிவு நேரம்',
    hourlyHint:         'காலம் 2–4 மணி நேரமாக இருக்க வேண்டும். ₹3,000/மணி வீதம் கட்டணம்.',
    functionType:       'செயல்பாட்டு வகை',
    availFor:           'கிடைக்கும் செயல்பாடுகள்:',
    selectRentalFirst:  'முதலில் வாடகை வகையை தேர்வு செய்யுங்கள்',
    selectFunction:     'செயல்பாட்டு வகையை தேர்வு செய்யுங்கள்…',
    message:            'செய்தி',
    optional:           '(விருப்பமானது)',
    msgPlaceholder:     'ஏதாவது குறிப்பிட்ட தேவைகள்…',
    submit:             'இப்போது பதிவிடுங்கள்',
    submitting:         'பதிவு செய்கிறது…',
    loginPrompt:        'பதிவை உறுதிப்படுத்த உள்நுழைக',
    loginPromptHint:    'மேலே உள்ள விவரங்கள் தயாராக இருக்கும் — உள்நுழைந்து சமர்ப்பிக்கவும்.',
    loginBtn:           'தொடர உள்நுழைக',
    timesRequired:      'கடிகாரத்தில் தொடக்க மற்றும் முடிவு நேரங்களை தேர்வு செய்யுங்கள்.',
    errServer:          'சேவையகத்தை அடைய முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
    errGeneric:         'ஏதோ தவறாகிவிட்டது. மீண்டும் முயற்சிக்கவும்.',
    successTitle:       'பதிவு சமர்ப்பிக்கப்பட்டது!',
    successBody:        'உங்கள் குறிப்பு எண்',
    successHint:        'பதிவு நிலையை கண்காணிக்க சேமிக்கவும்.',
    notifyWA:           'WhatsApp-ல் மண்டபத்தை தெரியப்படுத்துங்கள்',
    downloadReceipt:    'ரசீதை பதிவிறக்கவும்',
    rentalLabels: {
      FULL_DAY: 'முழு நாள் வாடகை',
      HALF_DAY: 'அரை நாள் வாடகை',
      HOURLY:   'மணிநேர வாடகை',
    },
  },
};

const ADMIN_WA = '919443380023';

function fmtDate(iso) {
  if (!iso) return iso;
  const [y, m, d] = iso.split('-').map(Number);
  return new Date(y, m - 1, d).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
}

export default class EnquiryForm extends Component {
  @service auth;
  @service language;
  @service router;

  _pendingPayload = null;

  @tracked submitting         = false;
  @tracked showLoginPrompt    = false;
  @tracked error              = null;
  @tracked reference          = null;
  @tracked submission         = null;
  @tracked availability       = null;
  @tracked isMuhurtham        = false;
  @tracked bookedSlots        = [];
  @tracked availabilityLoading= false;
  @tracked rentalType         = '';
  @tracked selectedDate       = '';

  constructor(owner, args) {
    super(owner, args);
    const saved = sessionStorage.getItem('mm_pending_booking');
    if (saved && this.auth.isLoggedIn) {
      sessionStorage.removeItem('mm_pending_booking');
      const payload = JSON.parse(saved);
      payload.mobile = this.auth.user?.mobile;
      Promise.resolve().then(() => this._submitPayload(payload));
    }
  }

  async _submitPayload(payload) {
    this.submitting = true;
    try {
      const res = await fetch(apiUrl('/api/enquiries'), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        this.error = data.error || this.t.errGeneric;
      } else {
        const data = await res.json();
        this.router.transitionTo('payment', data.reference);
      }
    } catch (_) {
      this.error = this.t.errServer;
    } finally {
      this.submitting = false;
    }
  }

  get t()                    { return T[this.language.lang]; }
  get availabilityIsGood()   { return this.availability === 'AVAILABLE'; }
  get availabilityIsPending(){ return this.availability === 'UNDER_ENQUIRY'; }
  get availabilityIsBlocked(){ return this.availability === 'UNAVAILABLE'; }

  get todayIso() {
    const d = new Date();
    return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
  }

  get functionTypeOptions() {
    const lang = this.language.lang;
    return (FUNCTION_TYPES[this.rentalType] ?? []).map(o => ({ value: o.value, label: o[lang] }));
  }

  get functionTypeDisabled() { return !this.rentalType; }

  get rentalTypeLabel() {
    return this.t.rentalLabels[this.rentalType] ?? '';
  }

  get isMarriage()      { return this.rentalType === 'FULL_DAY'; }
  get isHalfDay()       { return this.rentalType === 'HALF_DAY'; }
  get showTimePickers() { return this.rentalType === 'HALF_DAY' || this.rentalType === 'HOURLY'; }
  get showHourlyHint()  { return this.rentalType === 'HOURLY'; }

  get slotSuggestion() {
    const slots = this.bookedSlots;
    if (!slots || slots.length === 0) return null;
    const lang = this.language.lang;
    const RENTAL = {
      FULL_DAY: lang === 'ta' ? 'முழு நாள்' : 'Full Day',
      HALF_DAY: lang === 'ta' ? 'அரை நாள்' : 'Half Day',
      HOURLY:   lang === 'ta' ? 'மணிநேரம்' : 'Hourly',
    };
    const fmtT = (hhmm) => {
      const [h, m] = hhmm.split(':').map(Number);
      const p  = h >= 12 ? 'PM' : 'AM';
      const dh = h > 12 ? h - 12 : (h === 0 ? 12 : h);
      return m === 0 ? `${dh} ${p}` : `${dh}:${String(m).padStart(2, '0')} ${p}`;
    };
    const taken = slots
      .map(s => `${fmtT(s.startTime)}–${fmtT(s.endTime)} (${RENTAL[s.rentalType] ?? s.rentalType})`)
      .join(', ');
    const last  = slots[slots.length - 1];
    const [lh, lm] = last.endTime.split(':').map(Number);
    const afterMin  = lh * 60 + lm + 120;
    const ah = Math.floor(afterMin / 60);
    const am = afterMin % 60;
    const nextAvail = ah < 24
      ? fmtT(`${String(ah).padStart(2, '0')}:${String(am).padStart(2, '0')}`)
      : null;
    return { taken, nextAvail };
  }

  get whatsappUrl() {
    if (!this.submission) return '#';
    const { reference, customerName, eventDate, functionTypeLabel } = this.submission;
    const text =
      `Hi, I submitted a booking request at 4S Malini Mahal.\n` +
      `Reference: ${reference}\n` +
      `Name: ${customerName}\n` +
      `Date: ${fmtDate(eventDate)}\n` +
      `Function: ${functionTypeLabel}\n` +
      `Kindly confirm. Thank you.`;
    return `https://wa.me/${ADMIN_WA}?text=${encodeURIComponent(text)}`;
  }

  @action
  selectRental(event) {
    this.rentalType = event.target.value;
    const form = event.target.form;
    if (form) {
      const ft = form.elements.namedItem('functionType');
      if (ft) ft.value = '';
      const st = form.elements.namedItem('startTime');
      if (st) st.value = '';
      const et = form.elements.namedItem('endTime');
      if (et) et.value = '';
    }
  }

  @action
  async checkDate(date) {
    if (!date) { this.availability = null; this.bookedSlots = []; return; }
    this.availabilityLoading = true;
    this.availability  = null;
    this.isMuhurtham   = false;
    this.bookedSlots   = [];
    try {
      const res = await fetch(apiUrl(`/api/availability?date=${encodeURIComponent(date)}`));
      if (res.ok) {
        const data = await res.json();
        this.availability = data.status;
        this.isMuhurtham  = data.isMuhurtham || false;
        this.bookedSlots  = data.bookedSlots  || [];
        if (this.isMuhurtham && this.rentalType === 'HOURLY') {
          this.rentalType = '';
        }
      }
    } catch (_) {}
    finally { this.availabilityLoading = false; }
  }

  @action
  onDateChange(iso) {
    this.selectedDate = iso;
    this.checkDate(iso);
  }

  @action
  goToLogin() {
    if (this._pendingPayload) {
      sessionStorage.setItem('mm_pending_booking', JSON.stringify(this._pendingPayload));
    }
    this.auth.returnTo = 'booking';
    this.router.transitionTo('login');
  }

  @action
  async submit(event) {
    event.preventDefault();
    this.error = null;

    // Require login before submitting — capture form data so we can auto-submit after OTP
    if (!this.auth.isLoggedIn) {
      const fd = new FormData(event.currentTarget);
      this._pendingPayload = {
        customerName: fd.get('customerName'),
        eventDate:    this.selectedDate,
        rentalType:   fd.get('rentalType'),
        functionType: fd.get('functionType'),
        startTime:    fd.get('startTime') || null,
        endTime:      fd.get('endTime')   || null,
        message:      fd.get('message'),
      };
      this.showLoginPrompt = true;
      return;
    }

    if (!this.selectedDate) {
      this.error = this.language.lang === 'ta' ? 'நிகழ்வு தேதியை தேர்வு செய்யுங்கள்.' : 'Please select an event date.';
      return;
    }

    const fd = new FormData(event.currentTarget);
    const payload = {
      customerName: fd.get('customerName'),
      mobile:       this.auth.user?.mobile,
      eventDate:    this.selectedDate,
      rentalType:   fd.get('rentalType'),
      functionType: fd.get('functionType'),
      startTime:    fd.get('startTime') || null,
      endTime:      fd.get('endTime')   || null,
      message:      fd.get('message'),
    };

    if (payload.rentalType !== 'FULL_DAY' && (!payload.startTime || !payload.endTime)) {
      this.error = this.t.timesRequired;
      return;
    }

    await this._submitPayload(payload);
  }

  <template>
    {{#if this.reference}}
      <div class="mt-2 rounded-xl border border-green-200 bg-green-50 p-6 animate-fade-in">
        <div class="flex items-start gap-3">
          <svg class="h-5 w-5 text-green-600 mt-0.5 shrink-0" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
          </svg>
          <div class="flex-1">
            <p class="font-semibold text-green-800">{{this.t.successTitle}}</p>
            <p class="mt-1 text-sm text-green-700">
              {{this.t.successBody}}
              <span class="font-mono font-bold tracking-wide">{{this.reference}}</span>.
              {{this.t.successHint}}
            </p>
            <div class="mt-4 flex flex-wrap gap-3">
              <a
                href={{this.whatsappUrl}}
                target="_blank"
                rel="noopener noreferrer"
                class="inline-flex items-center gap-2 rounded-lg bg-green-600 hover:bg-green-700 px-4 py-2 text-sm font-semibold text-white shadow-sm transition-all duration-150 active:scale-[0.97]"
              >
                <svg class="h-4 w-4" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                  <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
                </svg>
                {{this.t.notifyWA}}
              </a>
              <LinkTo
                @route="receipt"
                @model={{this.reference}}
                class="inline-flex items-center gap-2 rounded-lg border border-stone-200 bg-white hover:bg-stone-50 hover:border-rose-200 hover:text-rose-700 px-4 py-2 text-sm font-semibold text-stone-700 shadow-sm transition-colors"
              >
                <svg class="h-4 w-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3"/>
                </svg>
                {{this.t.downloadReceipt}}
              </LinkTo>
            </div>
          </div>
        </div>
      </div>
    {{else}}
      <form class="mt-2 space-y-5" {{on "submit" this.submit}}>
        {{#if this.error}}
          <p class="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 animate-fade-in">
            {{this.error}}
          </p>
        {{/if}}

        {{! Name }}
        <div>
          <label class="block text-sm font-medium text-stone-700">{{this.t.nameLabel}}</label>
          <input name="customerName" type="text" required placeholder={{this.t.namePlaceholder}} class={{INPUT_CLS}} />
        </div>

        {{! Mobile — only shown when logged in }}
        {{#if this.auth.isLoggedIn}}
          <div class="flex items-center gap-2.5 rounded-lg bg-stone-50 border border-stone-200 px-3 py-2.5">
            <svg class="h-4 w-4 text-stone-400 shrink-0" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
              <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 6.75c0 8.284 6.716 15 15 15h2.25a2.25 2.25 0 002.25-2.25v-1.372c0-.516-.351-.966-.852-1.091l-4.423-1.106c-.44-.11-.902.055-1.173.417l-.97 1.293c-.282.376-.769.542-1.21.38a12.035 12.035 0 01-7.143-7.143c-.162-.441.004-.928.38-1.21l1.293-.97c.363-.271.527-.734.417-1.173L6.963 3.102a1.125 1.125 0 00-1.091-.852H4.5A2.25 2.25 0 002.25 4.5v2.25z"/>
            </svg>
            <span class="text-sm font-semibold text-stone-800">{{this.auth.user.mobile}}</span>
            <span class="ml-auto text-xs text-stone-400">{{this.t.yourAccount}}</span>
          </div>
        {{/if}}

        {{! Event date }}
        <div>
          <label class="block text-sm font-medium text-stone-700 mb-1.5">{{this.t.eventDate}}</label>
          <DatePickerCalendar
            @value={{this.selectedDate}}
            @min={{this.todayIso}}
            @onChange={{this.onDateChange}}
          />
          {{#if this.isMuhurtham}}
            <p class="mt-1.5 flex items-center gap-1.5 text-xs font-semibold text-yellow-700 animate-fade-in">
              <svg class="h-3.5 w-3.5 text-yellow-500" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                <path d="M12 2a10 10 0 100 20A10 10 0 0012 2zm0 3l1.5 4.5h4.5l-3.5 2.5 1.5 4.5L12 14l-4 2.5 1.5-4.5L6 9.5h4.5z"/>
              </svg>
              {{this.t.muhurthamBadge}}
            </p>
            <div class="mt-2 rounded-lg border border-yellow-200 bg-yellow-50 px-3 py-2.5 text-xs animate-fade-in">
              <p class="font-semibold text-yellow-800">{{this.t.muhurthamTitle}}</p>
              <p class="mt-0.5 text-yellow-700">{{this.t.muhurthamPolicy}}</p>
            </div>
          {{/if}}
          {{#if this.availabilityLoading}}
            <p class="mt-1.5 flex items-center gap-1.5 text-xs text-stone-400">
              <svg class="animate-spin h-3.5 w-3.5" viewBox="0 0 24 24" fill="none" aria-hidden="true">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
              </svg>
              {{this.t.checkingAvail}}
            </p>
          {{else if this.availabilityIsGood}}
            <p class="mt-1.5 flex items-center gap-1.5 text-xs font-medium text-green-700 animate-fade-in">
              <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
              </svg>
              {{this.t.available}}
            </p>
          {{else if this.availabilityIsPending}}
            <p class="mt-1.5 flex items-center gap-1.5 text-xs font-medium text-amber-700 animate-fade-in">
              <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z"/>
              </svg>
              {{this.t.pendingEnquiry}}
            </p>
          {{else if this.availabilityIsBlocked}}
            <p class="mt-1.5 flex items-center gap-1.5 text-xs font-medium text-red-700 animate-fade-in">
              <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9.75 9.75l4.5 4.5m0-4.5l-4.5 4.5M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
              </svg>
              {{this.t.unavailable}}
            </p>
          {{/if}}
          {{#if this.slotSuggestion}}
            <div class="mt-2 rounded-lg border border-amber-100 bg-amber-50 px-3 py-2.5 text-xs text-amber-800 animate-fade-in">
              <p class="font-semibold">{{this.t.bookedNote}} {{this.slotSuggestion.taken}}</p>
              {{#if this.slotSuggestion.nextAvail}}
                <p class="mt-0.5">{{this.t.nextSlotFrom}} {{this.slotSuggestion.nextAvail}} — {{this.t.gapNote}}</p>
              {{/if}}
            </div>
          {{/if}}
        </div>

        {{! Rental type }}
        <div>
          <label class="block text-sm font-medium text-stone-700">{{this.t.rentalType}}</label>
          <select name="rentalType" required class={{INPUT_CLS}} {{on "change" this.selectRental}}>
            <option value="">{{this.t.selectRental}}</option>
            <option value="FULL_DAY">{{this.t.fullDayOption}}</option>
            <option value="HALF_DAY">{{this.t.halfDayOption}}</option>
            {{#unless this.isMuhurtham}}
              <option value="HOURLY">{{this.t.hourlyOption}}</option>
            {{/unless}}
          </select>
          {{#if this.isMuhurtham}}
            <p class="mt-1.5 flex items-center gap-1.5 text-xs text-amber-700 animate-fade-in">
              <svg class="h-3.5 w-3.5 shrink-0" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636"/>
              </svg>
              {{this.t.muhurthamNoHourly}}
            </p>
          {{/if}}
        </div>

        {{! Time info / pickers }}
        {{#if this.isMarriage}}
          <div class="rounded-lg border border-rose-100 bg-rose-50 px-4 py-3 text-sm space-y-2">
            <p class="font-medium text-rose-800">{{this.t.fullDayAutoTitle}}</p>
            <div class="text-xs text-rose-700 space-y-1">
              <p>{{this.t.fullDayEntry}}</p>
              <p>{{this.t.fullDayDeposit}}</p>
              <p>{{this.t.fullDayEarlyKey}}</p>
              <p>{{this.t.fullDayCancel}}</p>
            </div>
          </div>
        {{else if this.showTimePickers}}
          {{#if this.isHalfDay}}
            <div class="rounded-lg border border-blue-100 bg-blue-50 px-4 py-3 text-sm space-y-1">
              <p class="font-medium text-blue-800">{{this.t.halfDayTitle}}</p>
              <p class="text-xs text-blue-700">{{this.t.halfDayRate}}</p>
            </div>
          {{/if}}
          <div>
            <label class="block text-sm font-medium text-stone-700">{{this.t.timeSlot}}</label>
            <div class="mt-1 space-y-3">
              <div>
                <label class="block text-xs text-stone-500 mb-0.5">{{this.t.startTime}}</label>
                <ClockTimePicker @name="startTime" />
              </div>
              <div>
                <label class="block text-xs text-stone-500 mb-0.5">{{this.t.endTime}}</label>
                <ClockTimePicker @name="endTime" />
              </div>
            </div>
            {{#if this.showHourlyHint}}
              <p class="mt-1.5 text-xs text-stone-400">{{this.t.hourlyHint}}</p>
            {{/if}}
          </div>
        {{/if}}

        {{! Function type }}
        <div>
          <label class="block text-sm font-medium {{if this.functionTypeDisabled 'text-stone-400' 'text-stone-700'}}">
            {{this.t.functionType}}
          </label>

          {{#if this.functionTypeDisabled}}
            <div class="mt-1 w-full rounded-lg border border-stone-200 bg-stone-50 px-3 py-2.5 text-sm text-stone-400 flex items-center gap-2">
              <svg class="h-4 w-4 shrink-0 text-stone-300" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 10-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H6.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z"/>
              </svg>
              {{this.t.selectRentalFirst}}
            </div>
            <select name="functionType" required class="sr-only" tabindex="-1" aria-hidden="true">
              <option value="">placeholder</option>
            </select>
          {{else}}
            <p class="mt-1 mb-1 text-xs text-stone-400">
              {{this.t.availFor}} {{this.rentalTypeLabel}}
            </p>
            <select name="functionType" required class={{INPUT_CLS}}>
              <option value="">{{this.t.selectFunction}}</option>
              {{#each this.functionTypeOptions as |opt|}}
                <option value={{opt.value}}>{{opt.label}}</option>
              {{/each}}
            </select>
          {{/if}}
        </div>

        {{! Message }}
        <div>
          <label class="block text-sm font-medium text-stone-700">
            {{this.t.message}} <span class="font-normal text-stone-400">{{this.t.optional}}</span>
          </label>
          <textarea name="message" rows="3" placeholder={{this.t.msgPlaceholder}} class={{INPUT_CLS}}></textarea>
        </div>

        {{#if this.showLoginPrompt}}
          <div class="rounded-xl border border-amber-200 bg-amber-50 px-4 py-4 animate-fade-in">
            <div class="flex items-start gap-3">
              <svg class="h-5 w-5 text-amber-600 mt-0.5 shrink-0" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0013.5 3h-6a2.25 2.25 0 00-2.25 2.25v13.5A2.25 2.25 0 007.5 21h6a2.25 2.25 0 002.25-2.25V15m3 0l3-3m0 0l-3-3m3 3H9"/>
              </svg>
              <div class="flex-1">
                <p class="text-sm font-semibold text-amber-800">{{this.t.loginPrompt}}</p>
                <p class="mt-0.5 text-xs text-amber-700">{{this.t.loginPromptHint}}</p>
                <button
                  type="button"
                  class="mt-3 inline-flex items-center gap-2 rounded-lg bg-rose-700 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-rose-800 transition-colors active:scale-[0.97]"
                  {{on "click" this.goToLogin}}
                >
                  {{this.t.loginBtn}}
                  <svg class="h-4 w-4" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24" aria-hidden="true">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3"/>
                  </svg>
                </button>
              </div>
            </div>
          </div>
        {{else}}
          <button
            type="submit"
            disabled={{this.submitting}}
            class="inline-flex w-full items-center justify-center gap-2 rounded-lg bg-rose-700 px-4 py-2.5 text-sm font-semibold text-white shadow-sm transition-all duration-150 hover:bg-rose-800 hover:shadow-md active:scale-[0.98] disabled:opacity-60 disabled:cursor-not-allowed"
          >
            {{#if this.submitting}}
              <svg class="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none" aria-hidden="true">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
              </svg>
              {{this.t.submitting}}
            {{else}}
              {{this.t.submit}}
            {{/if}}
          </button>
        {{/if}}
      </form>
    {{/if}}
  </template>
}
