import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';

const CX = 120, CY = 120, NR = 82, HR = 72, DR = 16;

function pt(frac, r) {
  const a = frac * 2 * Math.PI - Math.PI / 2;
  return { x: +(CX + r * Math.cos(a)).toFixed(1), y: +(CY + r * Math.sin(a)).toFixed(1) };
}

const HOURS = [12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
const MINS  = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];

export default class ClockTimePicker extends Component {
  @tracked step   = 'hour';
  @tracked hour   = 9;
  @tracked minute = 0;
  @tracked isAm   = true;
  @tracked isSet  = false;
  @tracked isOpen = false;

  // saved state for cancel
  _sh = 9; _sm = 0; _sa = true; _ss = false;

  get isHourStep() { return this.step === 'hour'; }

  get hour24() {
    if (this.isAm) return this.hour === 12 ? 0 : this.hour;
    return this.hour === 12 ? 12 : this.hour + 12;
  }

  get timeValue() {
    if (!this.isSet) return '';
    return `${String(this.hour24).padStart(2, '0')}:${String(this.minute).padStart(2, '0')}`;
  }

  get dH() { return String(this.hour).padStart(2, '0'); }
  get dM() { return String(this.minute).padStart(2, '0'); }
  get meridiem() { return this.isAm ? 'AM' : 'PM'; }

  get label() {
    return this.isSet
      ? `${this.dH}:${this.dM} ${this.meridiem}`
      : 'Select time';
  }

  get labelCls() {
    return this.isSet ? 'font-semibold text-stone-900' : 'text-stone-400';
  }

  get hand() {
    const frac = this.isHourStep ? HOURS.indexOf(this.hour) / 12 : this.minute / 60;
    return pt(frac, HR);
  }

  get markers() {
    return this.isHourStep
      ? HOURS.map((h, i) => ({ label: h,                ...pt(i / 12, NR), sel: h === this.hour }))
      : MINS.map( (m, i) => ({ label: m === 0 ? '00' : m, ...pt(i / 12, NR), sel: m === this.minute }));
  }

  @action
  openClock() {
    this._sh = this.hour; this._sm = this.minute;
    this._sa = this.isAm; this._ss = this.isSet;
    this.step = 'hour';
    this.isOpen = true;
  }

  @action
  cancelClock() {
    this.hour = this._sh; this.minute = this._sm;
    this.isAm = this._sa; this.isSet  = this._ss;
    this.isOpen = false;
  }

  @action doneClock()  { this.isSet = true;  this.isOpen = false; }
  @action goHour()     { this.step = 'hour'; }
  @action goMinute()   { this.step = 'minute'; }
  @action setAm()      { this.isAm = true; }
  @action setPm()      { this.isAm = false; }

  @action
  handleClock(event) {
    event.preventDefault();
    const svg = event.currentTarget;
    const svgPt = svg.createSVGPoint();
    svgPt.x = event.clientX;
    svgPt.y = event.clientY;
    const { x, y } = svgPt.matrixTransform(svg.getScreenCTM().inverse());
    const deg = ((Math.atan2(x - CX, -(y - CY)) * 180 / Math.PI) + 360) % 360;

    if (this.isHourStep) {
      const raw = Math.round(deg / 30) % 12;
      this.hour = raw === 0 ? 12 : raw;
      this.step = 'minute';
    } else {
      this.minute = Math.round(deg / 6) % 60;
      this.isSet  = true;
      this.isOpen = false;
    }
  }

  <template>
    {{! Hidden input carries the 24-hour HH:MM value for FormData }}
    <input type="hidden" name={{@name}} value={{this.timeValue}} />

    {{! Trigger button }}
    <button
      type="button"
      class="mt-1 w-full rounded-lg border border-stone-200 bg-white px-3 py-2.5 text-left text-sm flex items-center gap-2 transition-[border-color,box-shadow] duration-150 hover:border-rose-300 focus:border-rose-500 focus:ring-4 focus:ring-rose-500/10 focus:outline-none"
      {{on "click" this.openClock}}
    >
      <svg class="h-4 w-4 text-rose-400 shrink-0" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
        <circle cx="12" cy="12" r="10"/>
        <path stroke-linecap="round" d="M12 6v6l4 2"/>
      </svg>
      <span class={{this.labelCls}}>{{this.label}}</span>
    </button>

    {{#if this.isOpen}}
      <div class="mt-2 rounded-2xl border border-stone-100 bg-white shadow-xl overflow-hidden">

        {{! Rose header — digital display }}
        <div class="bg-rose-700 px-5 py-4 select-none">
          <p class="text-xs font-semibold uppercase tracking-wider text-rose-300 mb-2">
            {{if this.isHourStep "Select hour" "Select minute"}}
          </p>
          <div class="flex items-center gap-1">
            <button
              type="button"
              class="text-4xl font-bold font-mono rounded-xl px-2 py-0.5 transition-colors leading-tight
                {{if this.isHourStep 'bg-white/20 text-white' 'text-rose-300 hover:bg-white/10 hover:text-white'}}"
              {{on "click" this.goHour}}
            >{{this.dH}}</button>
            <span class="text-3xl font-bold text-rose-300 px-0.5">:</span>
            <button
              type="button"
              class="text-4xl font-bold font-mono rounded-xl px-2 py-0.5 transition-colors leading-tight
                {{if this.isHourStep 'text-rose-300 hover:bg-white/10 hover:text-white' 'bg-white/20 text-white'}}"
              {{on "click" this.goMinute}}
            >{{this.dM}}</button>
            <div class="ml-auto flex flex-col gap-1">
              <button
                type="button"
                class="text-xs font-bold w-10 py-1 rounded-lg border transition-colors
                  {{if this.isAm 'bg-white text-rose-700 border-transparent' 'text-rose-200 border-rose-400 hover:bg-white/10 hover:text-white'}}"
                {{on "click" this.setAm}}
              >AM</button>
              <button
                type="button"
                class="text-xs font-bold w-10 py-1 rounded-lg border transition-colors
                  {{if this.isAm 'text-rose-200 border-rose-400 hover:bg-white/10 hover:text-white' 'bg-white text-rose-700 border-transparent'}}"
                {{on "click" this.setPm}}
              >PM</button>
            </div>
          </div>
        </div>

        {{! Clock face }}
        <div class="px-4 pt-4 pb-2 select-none">
          <svg
            viewBox="0 0 240 240"
            class="w-full max-w-[240px] mx-auto block touch-none cursor-pointer"
            {{on "pointerup" this.handleClock}}
          >
            {{! Background }}
            <circle cx="120" cy="120" r="108" fill="#fef2f2"/>
            <circle cx="120" cy="120" r="108" fill="none" stroke="#fecaca" stroke-width="1.5"/>

            {{! Hand from center to tip }}
            <line x1="120" y1="120" x2={{this.hand.x}} y2={{this.hand.y}} stroke="#be123c" stroke-width="2.5" stroke-linecap="round"/>

            {{! Center dot }}
            <circle cx="120" cy="120" r="4" fill="#be123c"/>

            {{! Selection dot at hand tip }}
            <circle cx={{this.hand.x}} cy={{this.hand.y}} r={{DR}} fill="#be123c"/>

            {{! Hour or minute numbers }}
            {{#each this.markers as |m|}}
              <text
                x={{m.x}}
                y={{m.y}}
                text-anchor="middle"
                dominant-baseline="central"
                font-size="13"
                font-weight={{if m.sel "700" "400"}}
                fill={{if m.sel "white" "#78716c"}}
                pointer-events="none"
              >{{m.label}}</text>
            {{/each}}
          </svg>

          <p class="mt-1.5 text-center text-xs text-stone-400">
            {{if this.isHourStep "Tap to pick hour → then minute" "Tap minute — done!"}}
          </p>
        </div>

        {{! Cancel / Done }}
        <div class="px-4 pb-4 flex gap-2">
          <button
            type="button"
            class="flex-1 rounded-xl border border-stone-200 px-4 py-2 text-sm font-medium text-stone-600 hover:bg-stone-50 transition-colors"
            {{on "click" this.cancelClock}}
          >Cancel</button>
          <button
            type="button"
            class="flex-1 rounded-xl bg-rose-700 px-4 py-2 text-sm font-semibold text-white hover:bg-rose-800 transition-colors"
            {{on "click" this.doneClock}}
          >Done</button>
        </div>

      </div>
    {{/if}}
  </template>
}
