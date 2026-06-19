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

const STATUS_DOT = {
  NEW:              'bg-stone-400',
  UNDER_ENQUIRY:    'bg-amber-500',
  AWAITING_PAYMENT: 'bg-yellow-400',
  CONFIRMED:        'bg-green-500',
  COMPLETED:        'bg-blue-500',
  DECLINED:         'bg-red-400',
  REJECTED:         'bg-orange-500',
  CANCELLED:        'bg-stone-200',
};

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
  get dayLabels() { return ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']; }

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
    const y = this.viewYear, m = this.viewMonth;
    const firstDow    = new Date(y, m, 1).getDay();
    const daysInMonth = new Date(y, m + 1, 0).getDate();
    const daysInPrev  = new Date(y, m, 0).getDate();
    const today  = todayIso();
    const byDate = this.byDate;
    const mSet   = this.muhurthamSet;
    const bSet   = this.blockedSet;
    const selIso = this.selectedIso;

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

      const bookings = (byDate[iso] ?? []).map(b => ({
        ...b,
        dot:         STATUS_DOT[b.status]  ?? 'bg-stone-300',
        pill:        STATUS_PILL[b.status] ?? 'bg-stone-100 text-stone-600',
        statusLabel: STATUS_LABELS[b.status] ?? b.status,
        rentalLabel: RENTAL_LABELS[b.rentalType] ?? b.rentalType,
        startFmt:    fmtDt(b.startDatetime),
        endFmt:      fmtDt(b.endDatetime),
      }));

      let cellCls = 'w-full min-h-16 sm:min-h-20 p-1.5 text-left align-top transition-colors duration-100 ';
      if (isSelected)       cellCls += 'ring-2 ring-inset ring-rose-500 ';
      if (isMuhurtham)      cellCls += 'bg-amber-50 hover:bg-amber-100/80 ';
      else if (isBlocked)   cellCls += 'bg-red-50 ';
      else                  cellCls += 'hover:bg-stone-50 ';

      let dayNumCls = 'text-xs font-semibold select-none ';
      if (isToday) dayNumCls += 'flex h-5 w-5 items-center justify-center rounded-full bg-rose-700 text-white -mt-0.5 -ml-0.5';
      else         dayNumCls += 'text-stone-700';

      cells.push({ key: iso, outside: false, day: d, iso,
        isToday, isMuhurtham, isBlocked, isSelected, bookings, cellCls, dayNumCls });
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
      <div class="flex items-center justify-between px-5 py-4 border-b border-stone-100 bg-stone-50">
        <button type="button"
          class="flex h-8 w-8 items-center justify-center rounded-lg text-stone-500 hover:bg-stone-200 transition-colors"
          {{on "click" this.prevMonth}}>
          <svg class="h-4 w-4" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5"/>
          </svg>
        </button>
        <span class="text-sm font-semibold text-stone-800 tracking-wide select-none">{{this.headerLabel}}</span>
        <button type="button"
          class="flex h-8 w-8 items-center justify-center rounded-lg text-stone-500 hover:bg-stone-200 transition-colors"
          {{on "click" this.nextMonth}}>
          <svg class="h-4 w-4" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5"/>
          </svg>
        </button>
      </div>

      {{! Day-of-week headers }}
      <div class="grid grid-cols-7 border-b border-stone-100">
        {{#each this.dayLabels as |dl|}}
          <div class="py-2 text-center text-xs font-semibold text-stone-400 select-none">{{dl}}</div>
        {{/each}}
      </div>

      {{! Calendar grid }}
      <div class="grid grid-cols-7 divide-x divide-y divide-stone-100 border-b border-stone-100">
        {{#each this.weeks as |week|}}
          {{#each week as |cell|}}
            {{#if cell.outside}}
              <div class="min-h-16 sm:min-h-20 bg-stone-50/50 p-1.5">
                <span class="text-xs text-stone-200 select-none">{{cell.label}}</span>
              </div>
            {{else}}
              <button type="button" class={{cell.cellCls}} {{on "click" (fn this.selectDay cell)}}>
                <div class="flex items-start justify-between">
                  <span class={{cell.dayNumCls}}>{{cell.day}}</span>
                  <div class="flex items-center gap-0.5">
                    {{#if cell.isMuhurtham}}
                      <span class="text-amber-400 text-xs leading-none select-none" title="Muhurtham">★</span>
                    {{/if}}
                    {{#if cell.isBlocked}}
                      <span class="text-red-400 text-xs font-bold leading-none select-none" title="Blocked">✕</span>
                    {{/if}}
                  </div>
                </div>
                {{! Desktop: name pills }}
                <div class="mt-1 hidden sm:block space-y-0.5">
                  {{#each cell.bookings as |b|}}
                    <div class="rounded px-1 py-0.5 text-xs truncate leading-tight {{b.pill}}">{{b.customerName}}</div>
                  {{/each}}
                </div>
                {{! Mobile: colored dots }}
                <div class="mt-1 flex flex-wrap gap-0.5 sm:hidden">
                  {{#each cell.bookings as |b|}}
                    <span class="inline-block h-1.5 w-1.5 rounded-full {{b.dot}}"></span>
                  {{/each}}
                </div>
              </button>
            {{/if}}
          {{/each}}
        {{/each}}
      </div>

      {{! Legend }}
      <div class="flex flex-wrap gap-x-5 gap-y-1.5 px-5 py-3 bg-stone-50 text-xs text-stone-500 select-none">
        <span class="flex items-center gap-1.5"><span class="h-2 w-2 rounded-full bg-green-500"></span>Confirmed</span>
        <span class="flex items-center gap-1.5"><span class="h-2 w-2 rounded-full bg-amber-500"></span>Under enquiry</span>
        <span class="flex items-center gap-1.5"><span class="h-2 w-2 rounded-full bg-yellow-400"></span>Awaiting payment</span>
        <span class="flex items-center gap-1.5"><span class="h-2 w-2 rounded-full bg-stone-400"></span>Received</span>
        <span class="flex items-center gap-1.5"><span class="h-2 w-2 rounded-full bg-blue-500"></span>Completed</span>
        <span class="flex items-center gap-1.5"><span class="text-amber-400">★</span>Muhurtham</span>
        <span class="flex items-center gap-1.5"><span class="text-red-400 font-bold">✕</span>Blocked</span>
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
