import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';

function pad(n) { return String(n).padStart(2, '0'); }
function isoOf(y, m, d) { return `${y}-${pad(m + 1)}-${pad(d)}`; }

const MONTH_NAMES = [
  'January','February','March','April','May','June',
  'July','August','September','October','November','December',
];

const STATUS_PILL = {
  NEW:              'bg-stone-100 text-stone-600',
  UNDER_ENQUIRY:    'bg-amber-50 text-amber-700',
  AWAITING_PAYMENT: 'bg-yellow-50 text-yellow-700',
  CONFIRMED:        'bg-green-50 text-green-700',
  COMPLETED:        'bg-blue-50 text-blue-700',
  DECLINED:         'bg-red-50 text-red-600',
  REJECTED:         'bg-orange-50 text-orange-700',
  CANCELLED:        'bg-stone-50 text-stone-400',
};

const STATUS_LABELS = {
  NEW: 'Received',
  UNDER_ENQUIRY: 'Under enquiry',
  AWAITING_PAYMENT: 'Awaiting payment',
  CONFIRMED: 'Confirmed',
  COMPLETED: 'Completed',
  DECLINED: 'Declined',
  REJECTED: 'Rejected',
  CANCELLED: 'Cancelled',
};

const RENTAL_LABELS = { FULL_DAY: 'Full day', HALF_DAY: 'Half day', HOURLY: 'Hourly' };

// Priority order for cell background (highest = most important)
const STATUS_PRIORITY = {
  CONFIRMED: 5, AWAITING_PAYMENT: 4, UNDER_ENQUIRY: 3, NEW: 2, COMPLETED: 1,
  DECLINED: 0, REJECTED: 0, CANCELLED: 0,
};

function todayIso() {
  const d = new Date();
  return isoOf(d.getFullYear(), d.getMonth(), d.getDate());
}

function fmtDt(isoStr) {
  if (!isoStr) return null;
  return new Date(isoStr).toLocaleString('en-IN', {
    hour: '2-digit', minute: '2-digit', hour12: true, timeZone: 'Asia/Kolkata',
  });
}

function fmtDateLong(iso) {
  if (!iso) return '';
  const [y, m, d] = iso.split('-').map(Number);
  return new Date(y, m - 1, d).toLocaleDateString('en-IN', {
    weekday: 'long', day: 'numeric', month: 'long', year: 'numeric',
  });
}

export default class AdminCalendar extends Component {
  @tracked viewYear;
  @tracked viewMonth;
  @tracked selectedIso = null;

  constructor(owner, args) {
    super(owner, args);
    const d = new Date();
    this.viewYear = d.getFullYear();
    this.viewMonth = d.getMonth();
  }

  get headerLabel() { return `${MONTH_NAMES[this.viewMonth]} ${this.viewYear}`; }
  get dayLabels()   { return ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']; }

  get byDate() {
    const map = {};
    for (const e of (this.args.enquiries ?? [])) {
      if (!e.eventDate) continue;
      (map[e.eventDate] ??= []).push(e);
    }
    return map;
  }

  get muhurthamSet() {
    return new Set((this.args.muhurthamDates ?? []).map(m => m.mdate));
  }

  get blockedSet() {
    return new Set((this.args.blockedDates ?? []).map(b => b.blockedDate));
  }

  get weeks() {
    const y      = this.viewYear;
    const m      = this.viewMonth;
    const today  = todayIso();
    const byDate = this.byDate;
    const mSet   = this.muhurthamSet;
    const bSet   = this.blockedSet;
    const selIso = this.selectedIso;

    const firstDow    = new Date(y, m, 1).getDay();
    const daysInMonth = new Date(y, m + 1, 0).getDate();
    const daysInPrev  = new Date(y, m, 0).getDate();

    const cells = [];

    for (let i = firstDow - 1; i >= 0; i--) {
      cells.push({ outside: true, label: daysInPrev - i, key: `p${i}` });
    }

    for (let d = 1; d <= daysInMonth; d++) {
      const iso         = isoOf(y, m, d);
      const isMuhurtham = mSet.has(iso);
      const isBlocked   = bSet.has(iso);
      const isToday     = iso === today;
      const isSelected  = iso === selIso;

      const rawBookings = byDate[iso] ?? [];
      const bookings = rawBookings.map(b => ({
        ...b,
        pill:        STATUS_PILL[b.status]  ?? 'bg-stone-100 text-stone-600',
        statusLabel: STATUS_LABELS[b.status] ?? b.status,
        rentalLabel: RENTAL_LABELS[b.rentalType] ?? b.rentalType,
        startFmt:    fmtDt(b.startDatetime),
        endFmt:      fmtDt(b.endDatetime),
      }));

      // Pick highest-priority booking for cell colour
      const top = rawBookings.reduce((best, b) =>
        (STATUS_PRIORITY[b.status] ?? 0) > (STATUS_PRIORITY[best?.status] ?? -1) ? b : best
      , null);

      let cls = 'relative flex flex-col items-center justify-center h-10 w-full rounded-xl text-sm transition-all duration-100 ';

      if (top) {
        const s = top.status;
        if (s === 'CONFIRMED')
          cls += 'bg-green-100 text-green-800 font-semibold cursor-pointer hover:bg-green-200';
        else if (s === 'AWAITING_PAYMENT')
          cls += 'bg-yellow-100 text-yellow-800 font-semibold cursor-pointer hover:bg-yellow-200';
        else if (s === 'UNDER_ENQUIRY' || s === 'NEW')
          cls += 'bg-amber-100 text-amber-800 font-medium cursor-pointer hover:bg-amber-200';
        else if (s === 'COMPLETED')
          cls += 'bg-blue-50 text-blue-700 font-medium cursor-pointer hover:bg-blue-100';
        else
          cls += 'bg-stone-100 text-stone-500 font-medium cursor-pointer hover:bg-stone-200';
      } else if (isBlocked) {
        cls += 'bg-red-50 text-red-500 font-medium cursor-pointer';
      } else if (isMuhurtham && isToday) {
        cls += 'bg-amber-100 text-amber-900 font-semibold ring-2 ring-rose-400 cursor-pointer hover:bg-amber-200';
      } else if (isMuhurtham) {
        cls += 'bg-amber-100 text-amber-900 font-semibold cursor-pointer hover:bg-amber-200';
      } else if (isToday) {
        cls += 'ring-2 ring-rose-400 text-rose-700 font-semibold cursor-pointer hover:bg-rose-50';
      } else {
        cls += 'text-stone-700 font-medium cursor-pointer hover:bg-stone-100';
      }

      if (isSelected) cls += ' ring-2 ring-rose-500';

      cells.push({
        key: iso, outside: false, day: d, iso,
        isToday, isMuhurtham, isBlocked, isSelected,
        bookingCount: bookings.length,
        bookings, cls,
      });
    }

    let next = 1;
    while (cells.length % 7 !== 0) {
      cells.push({ outside: true, label: next++, key: `n${next}` });
    }

    const ws = [];
    for (let i = 0; i < cells.length; i += 7) ws.push(cells.slice(i, i + 7));
    return ws;
  }

  get selectedBookings() {
    if (!this.selectedIso) return [];
    return (this.byDate[this.selectedIso] ?? []).map(b => ({
      ...b,
      pill:        STATUS_PILL[b.status] ?? 'bg-stone-100 text-stone-600',
      statusLabel: STATUS_LABELS[b.status] ?? b.status,
      rentalLabel: RENTAL_LABELS[b.rentalType] ?? b.rentalType,
      startFmt:    fmtDt(b.startDatetime),
      endFmt:      fmtDt(b.endDatetime),
      waUrl: `https://wa.me/91${b.mobile}?text=Dear%20${encodeURIComponent(b.customerName)}%2C%20regarding%20your%20enquiry%20${b.reference}%20at%204S%20Malini%20Mahal%3A%20`,
    }));
  }

  get selectedDateLabel()   { return fmtDateLong(this.selectedIso); }
  get selectedIsMuhurtham() { return this.selectedIso ? this.muhurthamSet.has(this.selectedIso) : false; }
  get selectedIsBlocked()   { return this.selectedIso ? this.blockedSet.has(this.selectedIso)   : false; }

  @action prevMonth() {
    if (this.viewMonth === 0) { this.viewMonth = 11; this.viewYear -= 1; }
    else this.viewMonth -= 1;
    this.selectedIso = null;
  }

  @action nextMonth() {
    if (this.viewMonth === 11) { this.viewMonth = 0; this.viewYear += 1; }
    else this.viewMonth += 1;
    this.selectedIso = null;
  }

  @action selectDay(cell) {
    if (cell.outside) return;
    this.selectedIso = this.selectedIso === cell.iso ? null : cell.iso;
  }

  @action closeDetail() { this.selectedIso = null; }

  <template>
    <div class="rounded-xl border border-stone-200 bg-white shadow-sm overflow-hidden">

      {{! Month navigation }}
      <div class="flex items-center justify-between px-4 py-3 border-b border-stone-100 bg-stone-50">
        <button type="button"
          class="flex h-8 w-8 items-center justify-center rounded-lg text-stone-500 transition-colors hover:bg-stone-200"
          {{on "click" this.prevMonth}}>
          <svg class="h-4 w-4" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5"/>
          </svg>
        </button>
        <span class="text-sm font-semibold text-stone-800 tracking-wide select-none">{{this.headerLabel}}</span>
        <button type="button"
          class="flex h-8 w-8 items-center justify-center rounded-lg text-stone-500 transition-colors hover:bg-stone-200"
          {{on "click" this.nextMonth}}>
          <svg class="h-4 w-4" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5"/>
          </svg>
        </button>
      </div>

      {{! Day-of-week headers }}
      <div class="grid grid-cols-7 px-3 pt-3 pb-1">
        {{#each this.dayLabels as |dl|}}
          <div class="text-center text-xs font-semibold text-stone-400 py-1 select-none">{{dl}}</div>
        {{/each}}
      </div>

      {{! Calendar grid }}
      <div class="px-3 pb-3 space-y-1">
        {{#each this.weeks as |week|}}
          <div class="grid grid-cols-7 gap-1">
            {{#each week as |cell|}}
              {{#if cell.outside}}
                <div class="h-10"></div>
              {{else}}
                <button type="button" class={{cell.cls}} {{on "click" (fn this.selectDay cell)}}>
                  <span class="leading-none text-sm">{{cell.day}}</span>
                  {{#if cell.isMuhurtham}}
                    <span class="absolute bottom-1 left-1/2 -translate-x-1/2 h-1 w-1 rounded-full bg-amber-500" aria-hidden="true"></span>
                  {{/if}}
                  {{#if cell.isBlocked}}
                    <span class="absolute top-0.5 right-1 text-[9px] font-bold text-red-400 leading-none" aria-hidden="true">✕</span>
                  {{/if}}
                  {{#if cell.bookingCount}}
                    <span class="absolute top-0.5 right-1 text-[9px] font-bold leading-none opacity-70">{{cell.bookingCount}}</span>
                  {{/if}}
                </button>
              {{/if}}
            {{/each}}
          </div>
        {{/each}}
      </div>

      {{! Legend }}
      <div class="flex flex-wrap items-center gap-x-4 gap-y-1.5 border-t border-stone-100 px-4 py-2.5 bg-stone-50 text-xs text-stone-500 select-none">
        <span class="flex items-center gap-1.5"><span class="h-3 w-3 rounded bg-green-100 border border-green-200"></span>Confirmed</span>
        <span class="flex items-center gap-1.5"><span class="h-3 w-3 rounded bg-yellow-100 border border-yellow-200"></span>Awaiting payment</span>
        <span class="flex items-center gap-1.5"><span class="h-3 w-3 rounded bg-amber-100 border border-amber-200"></span>Under enquiry / Received</span>
        <span class="flex items-center gap-1.5"><span class="h-3 w-3 rounded bg-blue-50 border border-blue-200"></span>Completed</span>
        <span class="flex items-center gap-1.5">
          <span class="relative h-3 w-3 rounded bg-stone-50 border border-stone-200 flex items-center justify-center">
            <span class="h-1 w-1 rounded-full bg-amber-500"></span>
          </span>Muhurtham
        </span>
        <span class="flex items-center gap-1.5"><span class="h-3 w-3 rounded bg-red-50 border border-red-200 text-[8px] text-red-400 flex items-center justify-center font-bold">✕</span>Blocked</span>
      </div>
    </div>

    {{! Selected-day detail panel }}
    {{#if this.selectedIso}}
      <div class="mt-3 rounded-xl border border-stone-200 bg-white shadow-sm p-5">
        <div class="flex items-start justify-between mb-4 gap-2">
          <div>
            <h3 class="text-sm font-semibold text-stone-900">{{this.selectedDateLabel}}</h3>
            <div class="flex items-center gap-3 mt-0.5">
              {{#if this.selectedIsMuhurtham}}
                <span class="text-xs text-amber-600 font-medium">★ Muhurtham date</span>
              {{/if}}
              {{#if this.selectedIsBlocked}}
                <span class="text-xs text-red-500 font-medium">✕ Blocked</span>
              {{/if}}
            </div>
          </div>
          <button type="button"
            class="shrink-0 text-xs text-stone-400 hover:text-stone-600 transition-colors px-2 py-1 rounded"
            {{on "click" this.closeDetail}}>Close ✕</button>
        </div>

        {{#if this.selectedBookings.length}}
          <div class="space-y-3">
            {{#each this.selectedBookings as |b|}}
              <div class="rounded-lg border border-stone-100 bg-stone-50 px-4 py-3">
                <div class="flex items-start justify-between flex-wrap gap-2">
                  <div>
                    <p class="font-semibold text-stone-900 text-sm">{{b.customerName}}</p>
                    <p class="font-mono text-xs text-stone-400 mt-0.5">{{b.reference}}</p>
                  </div>
                  <div class="flex items-center gap-2">
                    <span class="rounded-full border px-2.5 py-0.5 text-xs font-semibold {{b.pill}}">{{b.statusLabel}}</span>
                    <a href={{b.waUrl}} target="_blank" rel="noopener noreferrer"
                      class="text-green-600 hover:text-green-700 transition-colors" title="WhatsApp">
                      <svg class="h-4 w-4" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                        <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
                      </svg>
                    </a>
                  </div>
                </div>
                <div class="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-stone-500">
                  <span>{{b.rentalLabel}}</span>
                  {{#if b.startFmt}}<span>{{b.startFmt}} – {{b.endFmt}}</span>{{/if}}
                  {{#if b.muhurtham}}<span class="text-amber-600 font-medium">★ Muhurtham</span>{{/if}}
                  <span>{{b.mobile}}</span>
                </div>
              </div>
            {{/each}}
          </div>
        {{else}}
          <p class="text-sm text-stone-400 text-center py-6">No bookings on this date.</p>
        {{/if}}
      </div>
    {{/if}}
  </template>
}
