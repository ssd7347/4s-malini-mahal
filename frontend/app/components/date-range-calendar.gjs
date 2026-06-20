import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { apiUrl } from 'frontend/utils/api';

function pad(n) { return String(n).padStart(2, '0'); }
function isoOf(y, m, d) { return `${y}-${pad(m + 1)}-${pad(d)}`; }
function todayStr() {
  const n = new Date();
  return isoOf(n.getFullYear(), n.getMonth(), n.getDate());
}

const MONTH_NAMES = [
  'January','February','March','April','May','June',
  'July','August','September','October','November','December',
];

function fmtDate(iso) {
  if (!iso) return null;
  const [y, m, d] = iso.split('-').map(Number);
  return `${d} ${MONTH_NAMES[m - 1].slice(0, 3)} '${String(y).slice(2)}`;
}

export default class DateRangeCalendar extends Component {
  @service language;
  @tracked viewYear;
  @tracked viewMonth;
  @tracked muhurthamSet = new Set();

  constructor(owner, args) {
    super(owner, args);
    const start = args.checkIn;
    const d = start ? new Date(start + 'T00:00:00') : new Date();
    this.viewYear  = d.getFullYear();
    this.viewMonth = d.getMonth();
    this._load();
  }

  async _load() {
    try {
      const res = await fetch(apiUrl('/api/muhurtham'));
      if (res.ok) {
        const list = await res.json();
        this.muhurthamSet = new Set(list.map(i => i.mdate));
      }
    } catch (_) {}
  }

  get today()    { return todayStr(); }
  get min()      { return this.args.min || this.today; }
  get checkIn()  { return this.args.checkIn  || ''; }
  get checkOut() { return this.args.checkOut || ''; }

  get headerLabel() { return `${MONTH_NAMES[this.viewMonth]} ${this.viewYear}`; }
  get cantGoPrev() {
    const [my, mm] = this.min.split('-').map(Number);
    return !(this.viewYear > my || (this.viewYear === my && this.viewMonth + 1 > mm));
  }
  get dayLabels() { return ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']; }

  get weeks() {
    const y   = this.viewYear;
    const m   = this.viewMonth;
    const min = this.min;
    const ci  = this.checkIn;
    const co  = this.checkOut;

    const firstDow    = new Date(y, m, 1).getDay();
    const daysInMonth = new Date(y, m + 1, 0).getDate();
    const daysInPrev  = new Date(y, m, 0).getDate();

    const cells = [];

    for (let i = firstDow - 1; i >= 0; i--) {
      cells.push({ key: `p${i}`, label: daysInPrev - i, outside: true });
    }

    for (let d = 1; d <= daysInMonth; d++) {
      const iso         = isoOf(y, m, d);
      const isPast      = iso < min;
      const isMuhurtham = this.muhurthamSet.has(iso);
      const isToday     = iso === this.today;
      const isCheckIn   = iso === ci;
      const isCheckOut  = !!(ci && co && iso === co);
      const isInRange   = !!(ci && co && iso > ci && iso < co);
      const isEndpoint  = isCheckIn || isCheckOut;

      // Replicates DatePickerCalendar cls pattern exactly, with range additions
      let cls = 'relative flex flex-col items-center justify-center h-10 w-full rounded-xl text-sm transition-all duration-100 ';

      if (isCheckIn || isCheckOut) {
        cls += 'bg-rose-700 text-white font-bold shadow-md cursor-pointer';
      } else if (isInRange) {
        cls += isMuhurtham
          ? 'bg-amber-200 text-amber-900 font-semibold cursor-pointer hover:bg-amber-300'
          : 'bg-rose-100 text-rose-800 font-medium cursor-pointer hover:bg-rose-200';
      } else if (isPast) {
        cls += 'text-stone-300 cursor-not-allowed font-normal';
      } else if (isMuhurtham && isToday) {
        cls += 'bg-amber-100 text-amber-900 font-semibold ring-2 ring-rose-400 cursor-pointer hover:bg-amber-200';
      } else if (isMuhurtham) {
        cls += 'bg-amber-100 text-amber-900 font-semibold cursor-pointer hover:bg-amber-200';
      } else if (isToday) {
        cls += 'ring-2 ring-rose-400 text-rose-700 font-semibold cursor-pointer hover:bg-rose-50';
      } else {
        cls += 'text-stone-700 font-medium cursor-pointer hover:bg-stone-100';
      }

      cells.push({ key: iso, label: d, outside: false, iso, isPast,
                   isMuhurtham, isEndpoint, cls });
    }

    let next = 1;
    while (cells.length % 7 !== 0) {
      cells.push({ key: `n${next}`, label: next++, outside: true });
    }

    const ws = [];
    for (let i = 0; i < cells.length; i += 7) ws.push(cells.slice(i, i + 7));
    return ws;
  }

  get lang()           { return this.language.lang; }
  get pickingCheckIn() { return !this.checkIn || !!(this.checkIn && this.checkOut); }
  get pickingCheckOut(){ return !!(this.checkIn && !this.checkOut); }

  get checkInLabel()  { return this.lang === 'ta' ? 'நுழைவு தேதி'   : 'Check-in'; }
  get checkOutLabel() { return this.lang === 'ta' ? 'வெளியேறு தேதி' : 'Check-out'; }
  get selectHint()    { return this.lang === 'ta' ? 'தேர்வு செய்யவும்' : 'Select date'; }
  get checkInDisplay()  { return fmtDate(this.checkIn)  || this.selectHint; }
  get checkOutDisplay() { return fmtDate(this.checkOut) || this.selectHint; }
  get legendMuhurtham() { return this.lang === 'ta' ? 'முஹூர்த்தம் நாள்' : 'Muhurtham date'; }
  get legendToday()     { return this.lang === 'ta' ? 'இன்று' : 'Today'; }

  @action prevMonth() {
    if (this.cantGoPrev) return;
    if (this.viewMonth === 0) { this.viewMonth = 11; this.viewYear -= 1; }
    else this.viewMonth -= 1;
  }

  @action nextMonth() {
    if (this.viewMonth === 11) { this.viewMonth = 0; this.viewYear += 1; }
    else this.viewMonth += 1;
  }

  // Exactly mirrors DatePickerCalendar's pick action
  @action pick(cell) {
    if (cell.outside || cell.isPast) return;
    const ci = this.checkIn;
    const co = this.checkOut;

    if (!ci || (ci && co)) {
      // No check-in yet, or both set — start fresh with new check-in
      this.args.onChange?.({ checkIn: cell.iso, checkOut: '' });
    } else if (cell.iso <= ci) {
      // Clicked on or before check-in — reset check-in
      this.args.onChange?.({ checkIn: cell.iso, checkOut: '' });
    } else {
      // Have check-in, clicked after it — set check-out
      this.args.onChange?.({ checkIn: ci, checkOut: cell.iso });
    }
  }

  <template>
    <div class="rounded-xl border border-stone-200 bg-white shadow-sm overflow-hidden">

      {{! Check-in / Check-out header }}
      <div class="grid grid-cols-2 border-b border-stone-200">
        <div class="px-4 py-3 border-r border-stone-200 {{if this.pickingCheckIn 'bg-rose-50'}}">
          <p class="text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-0.5">
            {{this.checkInLabel}}
            {{#if this.pickingCheckIn}}<span class="ml-1 text-rose-500">←</span>{{/if}}
          </p>
          <p class="text-base font-bold {{if this.checkIn 'text-rose-700' 'text-stone-400'}}">
            {{this.checkInDisplay}}
          </p>
        </div>
        <div class="px-4 py-3 {{if this.pickingCheckOut 'bg-rose-50'}}">
          <p class="text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-0.5">
            {{this.checkOutLabel}}
            {{#if this.pickingCheckOut}}<span class="ml-1 text-rose-500">←</span>{{/if}}
          </p>
          <p class="text-base font-bold {{if this.checkOut 'text-rose-700' 'text-stone-400'}}">
            {{this.checkOutDisplay}}
          </p>
        </div>
      </div>

      {{! Month navigation }}
      <div class="flex items-center justify-between px-4 py-3 border-b border-stone-100 bg-stone-50">
        <button type="button"
          disabled={{this.cantGoPrev}}
          class="flex h-8 w-8 items-center justify-center rounded-lg text-stone-500 transition-colors hover:bg-stone-200 disabled:opacity-25 disabled:cursor-not-allowed"
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
        {{#each this.dayLabels as |d|}}
          <div class="text-center text-xs font-semibold text-stone-400 py-1 select-none">{{d}}</div>
        {{/each}}
      </div>

      {{! Calendar grid — identical structure to DatePickerCalendar }}
      <div class="px-3 pb-3 space-y-1">
        {{#each this.weeks as |week|}}
          <div class="grid grid-cols-7 gap-1">
            {{#each week as |cell|}}
              {{#if cell.outside}}
                <div class="h-10"></div>
              {{else}}
                <button
                  type="button"
                  class={{cell.cls}}
                  {{on "click" (fn this.pick cell)}}
                >
                  <span class="leading-none">{{cell.label}}</span>
                  {{#if cell.isMuhurtham}}
                    <span
                      class="absolute bottom-1 left-1/2 -translate-x-1/2 h-1 w-1 rounded-full {{if cell.isEndpoint 'bg-amber-300' 'bg-amber-500'}}"
                      aria-hidden="true"
                    ></span>
                  {{/if}}
                </button>
              {{/if}}
            {{/each}}
          </div>
        {{/each}}
      </div>

      {{! Legend }}
      <div class="flex flex-wrap items-center gap-x-5 gap-y-1 border-t border-stone-100 px-4 py-2.5 text-xs text-stone-500 bg-stone-50 select-none">
        <span class="flex items-center gap-1.5">
          <span class="inline-flex h-4 w-4 items-center justify-center rounded-lg bg-amber-100 border border-amber-300">
            <span class="h-1 w-1 rounded-full bg-amber-500"></span>
          </span>
          {{this.legendMuhurtham}}
        </span>
        <span class="flex items-center gap-1.5">
          <span class="inline-block h-4 w-4 rounded-lg ring-2 ring-rose-400 bg-white"></span>
          {{this.legendToday}}
        </span>
        <span class="flex items-center gap-1.5">
          <span class="inline-flex h-4 w-4 rounded-lg bg-rose-700 items-center justify-center">
            <span class="h-1.5 w-1.5 rounded-full bg-rose-100"></span>
          </span>
          {{this.checkInLabel}} / {{this.checkOutLabel}}
        </span>
        <span class="flex items-center gap-1.5">
          <span class="inline-block h-4 w-4 rounded-lg bg-rose-100 border border-rose-200"></span>
          Range
        </span>
      </div>
    </div>
  </template>
}
