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
  @tracked hoverIso = null;

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

  get rangeEnd() {
    const ci  = this.checkIn;
    const co  = this.checkOut;
    const hov = this.hoverIso;
    if (!ci) return '';
    if (co)  return co;
    if (hov && hov > ci) return hov;
    return '';
  }

  get weeks() {
    const y   = this.viewYear;
    const m   = this.viewMonth;
    const min = this.min;
    const ci  = this.checkIn;
    const co  = this.checkOut;
    const re  = this.rangeEnd;

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
      const isInRange   = !!(ci && re && iso > ci && iso < re);
      const isHoverEnd  = !!(this.hoverIso === iso && !co && ci && iso > ci);
      const hasRange    = !!(ci && re && re > ci);
      const isEndpoint  = isCheckIn || isCheckOut;

      let wrapCls = 'h-10 flex items-center justify-center';
      if (isCheckIn && hasRange && !isCheckOut) {
        wrapCls += ' range-start-bg';
      } else if (isCheckOut) {
        wrapCls += ' range-end-bg';
      } else if (isHoverEnd) {
        wrapCls += ' hover-end-bg';
      } else if (isInRange) {
        wrapCls += ' bg-rose-100';
      }

      let cls = 'relative flex flex-col items-center justify-center h-9 w-9 text-sm rounded-full ';
      if (isCheckIn || isCheckOut) {
        cls += 'bg-rose-700 text-white font-bold shadow-md cursor-pointer';
      } else if (isHoverEnd) {
        cls += 'bg-rose-200 text-rose-800 font-semibold cursor-pointer';
      } else if (isInRange) {
        cls += isMuhurtham
          ? 'bg-amber-200 text-amber-900 font-semibold cursor-pointer hover:bg-amber-300'
          : 'text-rose-800 font-medium cursor-pointer hover:bg-rose-200';
      } else if (isPast) {
        cls += 'text-stone-300 cursor-not-allowed';
      } else if (isMuhurtham && isToday) {
        cls += 'bg-amber-100 text-amber-900 font-semibold ring-2 ring-rose-400 cursor-pointer hover:bg-amber-200';
      } else if (isMuhurtham) {
        cls += 'bg-amber-100 text-amber-900 font-semibold cursor-pointer hover:bg-amber-200';
      } else if (isToday) {
        cls += 'ring-2 ring-rose-400 text-rose-700 font-semibold cursor-pointer hover:bg-rose-50';
      } else {
        cls += 'text-stone-700 font-medium cursor-pointer hover:bg-stone-100';
      }

      cells.push({ key: iso, label: d, outside: false, iso,
                   isPast, isMuhurtham, isEndpoint, wrapCls, cls });
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

  // Read ISO from data-date attribute — avoids any fn/closure capture issues
  @action onCellClick(event) {
    const iso = event.currentTarget.getAttribute('data-date');
    if (!iso) return;
    const min = this.min;
    if (iso < min) return;

    const ci = this.checkIn;
    const co = this.checkOut;
    this.hoverIso = null;

    if (!ci || (ci && co)) {
      this.args.onChange?.({ checkIn: iso, checkOut: '' });
    } else if (iso <= ci) {
      this.args.onChange?.({ checkIn: iso, checkOut: '' });
    } else {
      this.args.onChange?.({ checkIn: ci, checkOut: iso });
    }
  }

  @action onCellHover(event) {
    const iso = event.currentTarget.getAttribute('data-date');
    if (!iso) return;
    const ci = this.checkIn;
    const co = this.checkOut;
    if (ci && !co && iso > ci) {
      this.hoverIso = iso;
    } else {
      this.hoverIso = null;
    }
  }

  @action clearHover() { this.hoverIso = null; }

  <template>
    <style>
      .range-start-bg { background: linear-gradient(to right, transparent 50%, rgb(255 228 230) 50%); }
      .range-end-bg   { background: linear-gradient(to right, rgb(255 228 230) 50%, transparent 50%); }
      .hover-end-bg   { background: linear-gradient(to right, rgb(255 241 242) 50%, transparent 50%); }
    </style>

    <div class="rounded-xl border border-stone-200 bg-white shadow-sm overflow-hidden">

      {{! Check-in / Check-out header }}
      <div class="grid grid-cols-2 border-b border-stone-200">
        <div class="px-4 py-3 border-r border-stone-200 {{if this.pickingCheckIn 'bg-rose-50' ''}}">
          <p class="text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-0.5">
            {{this.checkInLabel}}
            {{#if this.pickingCheckIn}}<span class="ml-1 text-rose-500">←</span>{{/if}}
          </p>
          <p class="text-base font-bold {{if this.checkIn 'text-rose-700' 'text-stone-400'}}">
            {{this.checkInDisplay}}
          </p>
        </div>
        <div class="px-4 py-3 {{if this.pickingCheckOut 'bg-rose-50' ''}}">
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
          class="flex h-8 w-8 items-center justify-center rounded-lg text-stone-500 hover:bg-stone-200 disabled:opacity-25 disabled:cursor-not-allowed"
          {{on "click" this.prevMonth}}>
          <svg class="h-4 w-4" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5"/>
          </svg>
        </button>
        <span class="text-sm font-semibold text-stone-800 select-none">{{this.headerLabel}}</span>
        <button type="button"
          class="flex h-8 w-8 items-center justify-center rounded-lg text-stone-500 hover:bg-stone-200"
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

      {{! Calendar grid }}
      <div class="px-3 pb-3 space-y-0.5" {{on "mouseleave" this.clearHover}}>
        {{#each this.weeks as |week|}}
          <div class="grid grid-cols-7">
            {{#each week as |cell|}}
              {{#if cell.outside}}
                <div class="h-10"></div>
              {{else}}
                <div class={{cell.wrapCls}}>
                  <button
                    type="button"
                    data-date={{cell.iso}}
                    class={{cell.cls}}
                    {{on "click" this.onCellClick}}
                    {{on "mouseenter" this.onCellHover}}
                  >
                    <span class="leading-none">{{cell.label}}</span>
                    {{#if cell.isMuhurtham}}
                      <span
                        class="absolute bottom-0.5 left-1/2 -translate-x-1/2 h-1 w-1 rounded-full {{if cell.isEndpoint 'bg-amber-300' 'bg-amber-500'}}"
                        aria-hidden="true"
                      ></span>
                    {{/if}}
                  </button>
                </div>
              {{/if}}
            {{/each}}
          </div>
        {{/each}}
      </div>

      {{! Legend }}
      <div class="flex flex-wrap items-center gap-x-5 gap-y-1 border-t border-stone-100 px-4 py-2.5 text-xs text-stone-500 bg-stone-50 select-none">
        <span class="flex items-center gap-1.5">
          <span class="inline-flex h-4 w-4 items-center justify-center rounded-full bg-amber-100 border border-amber-300">
            <span class="h-1 w-1 rounded-full bg-amber-500"></span>
          </span>
          {{this.legendMuhurtham}}
        </span>
        <span class="flex items-center gap-1.5">
          <span class="inline-block h-4 w-4 rounded-full ring-2 ring-rose-400 bg-white"></span>
          {{this.legendToday}}
        </span>
        <span class="flex items-center gap-1.5">
          <span class="flex h-4">
            <span class="w-3 h-4 bg-rose-700 rounded-l-full"></span>
            <span class="w-3 h-4 bg-rose-100"></span>
            <span class="w-3 h-4 bg-rose-100"></span>
            <span class="w-3 h-4 bg-rose-700 rounded-r-full"></span>
          </span>
          {{this.checkInLabel}} → {{this.checkOutLabel}}
        </span>
      </div>
    </div>
  </template>
}
