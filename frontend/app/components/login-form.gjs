import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { apiUrl } from 'frontend/utils/api';

const INPUT_CLS = 'w-full rounded-lg border border-stone-200 bg-white px-3 py-2.5 text-stone-900 placeholder:text-stone-400 transition-[border-color,box-shadow] duration-150 focus:border-rose-500 focus:ring-4 focus:ring-rose-500/10 focus:outline-none';

const T = {
  en: {
    mobileLabel:       'Mobile number',
    mobilePlaceholder: '10-digit mobile number',
    mobileHint:        "We'll send a one-time code to this number via WhatsApp",
    sending:           'Sending…',
    sendOtp:           'Send OTP via WhatsApp',
    otpSentPrefix:     'OTP sent to',
    otpSentSuffix:     'via WhatsApp',
    otpLabel:          'Enter OTP',
    otpPlaceholder:    '6-digit code',
    verifying:         'Verifying…',
    verifyOtp:         'Verify OTP',
    changeMobile:      '← Change mobile number',
    errSend:           'Could not send OTP. Please try again.',
    errVerify:         'Invalid OTP. Please try again.',
    errServer:         'Could not reach the server. Please try again.',
  },
  ta: {
    mobileLabel:       'கைபேசி எண்',
    mobilePlaceholder: '10 இலக்க கைபேசி எண்',
    mobileHint:        'இந்த எண்ணுக்கு WhatsApp மூலம் ஒரு முறை குறியீடு அனுப்புவோம்',
    sending:           'அனுப்புகிறது…',
    sendOtp:           'WhatsApp மூலம் OTP அனுப்பு',
    otpSentPrefix:     '',
    otpSentSuffix:     '-க்கு WhatsApp மூலம் OTP அனுப்பப்பட்டது',
    otpLabel:          'OTP உள்ளிடவும்',
    otpPlaceholder:    '6 இலக்க குறியீடு',
    verifying:         'சரிபார்க்கிறது…',
    verifyOtp:         'OTP சரிபார்க்கவும்',
    changeMobile:      '← கைபேசி எண்ணை மாற்றவும்',
    errSend:           'OTP அனுப்ப முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
    errVerify:         'தவறான OTP. மீண்டும் முயற்சிக்கவும்.',
    errServer:         'சேவையகத்தை அடைய முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
  },
};

export default class LoginForm extends Component {
  @service auth;
  @service router;
  @service language;

  @tracked step    = 'mobile';
  @tracked mobile  = '';
  @tracked otp     = '';
  @tracked loading = false;
  @tracked error   = null;
  @tracked devOtp  = null;

  get t()           { return T[this.language.lang]; }
  get stepIsMobile(){ return this.step === 'mobile'; }
  get stepIsOtp()   { return this.step === 'otp'; }

  get maskedMobile() {
    if (!this.mobile) return '';
    return this.mobile.slice(0, 2) + '••••••' + this.mobile.slice(-2);
  }

  get returnToRoute() {
    if (this.auth.returnTo) return this.auth.returnTo;
    const next = new URLSearchParams(window.location.search).get('next');
    const map = { '/gallery': 'gallery', '/enquiry': 'enquiry', '/admin': 'admin', '/booking': 'booking' };
    return map[next] || 'index';
  }

  @action updateMobile(e) { this.mobile = e.target.value; }
  @action updateOtp(e)    { this.otp    = e.target.value; }

  @action goBack() {
    this.step   = 'mobile';
    this.otp    = '';
    this.error  = null;
    this.devOtp = null;
  }

  @action
  async sendOtp(event) {
    event.preventDefault();
    this.error   = null;
    this.devOtp  = null;
    this.loading = true;
    try {
      const res = await fetch(apiUrl('/api/auth/otp/send'), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({ mobile: this.mobile }),
      });
      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        this.error = data.error || this.t.errSend;
      } else {
        const data = await res.json();
        this.step = 'otp';
        if (data.devOtp) this.devOtp = data.devOtp;
      }
    } catch (_) {
      this.error = this.t.errServer;
    } finally {
      this.loading = false;
    }
  }

  @action
  async verifyOtp(event) {
    event.preventDefault();
    this.error   = null;
    this.loading = true;
    try {
      const res = await fetch(apiUrl('/api/auth/otp/verify'), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({ mobile: this.mobile, code: this.otp }),
      });
      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        this.error = data.error || this.t.errVerify;
      } else {
        const data = await res.json();
        const route = this.returnToRoute; // capture before clearing returnTo
        this.auth.user     = data;
        this.auth._checked = true;
        this.auth.returnTo = null;
        this.router.transitionTo(route);
      }
    } catch (_) {
      this.error = this.t.errServer;
    } finally {
      this.loading = false;
    }
  }

  <template>
    {{#if this.stepIsMobile}}
      <form class="space-y-4" {{on "submit" this.sendOtp}}>
        {{#if this.error}}
          <p class="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 animate-fade-in">
            {{this.error}}
          </p>
        {{/if}}

        <div>
          <label class="block text-sm font-medium text-stone-700 mb-1">{{this.t.mobileLabel}}</label>
          <input
            type="tel"
            inputmode="numeric"
            required
            pattern="[6-9][0-9]{9}"
            maxlength="10"
            placeholder={{this.t.mobilePlaceholder}}
            value={{this.mobile}}
            class={{INPUT_CLS}}
            {{on "input" this.updateMobile}}
          />
          <p class="mt-1.5 text-xs text-stone-400">{{this.t.mobileHint}}</p>
        </div>

        <button
          type="submit"
          disabled={{this.loading}}
          class="inline-flex w-full items-center justify-center gap-2 rounded-lg bg-rose-700 px-4 py-2.5 text-sm font-semibold text-white shadow-sm transition-all duration-150 hover:bg-rose-800 active:scale-[0.98] disabled:opacity-60 disabled:cursor-not-allowed"
        >
          {{#if this.loading}}
            <svg class="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none" aria-hidden="true">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
            </svg>
            {{this.t.sending}}
          {{else}}
            <svg class="h-4 w-4" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
              <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
            </svg>
            {{this.t.sendOtp}}
          {{/if}}
        </button>
      </form>

    {{else}}
      <form class="space-y-4" {{on "submit" this.verifyOtp}}>
        <div class="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
          {{this.t.otpSentPrefix}}
          <span class="font-mono font-semibold">{{this.maskedMobile}}</span>
          {{this.t.otpSentSuffix}}
          {{#if this.devOtp}}
            <span class="ml-1 font-mono font-bold text-rose-700">(Dev: {{this.devOtp}})</span>
          {{/if}}
        </div>

        {{#if this.error}}
          <p class="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 animate-fade-in">
            {{this.error}}
          </p>
        {{/if}}

        <div>
          <label class="block text-sm font-medium text-stone-700 mb-1">{{this.t.otpLabel}}</label>
          <input
            type="tel"
            required
            inputmode="numeric"
            autocomplete="one-time-code"
            pattern="[0-9]{6}"
            maxlength="6"
            placeholder={{this.t.otpPlaceholder}}
            value={{this.otp}}
            class="w-full rounded-lg border border-stone-200 bg-white px-3 py-2.5 font-mono tracking-[0.4em] text-stone-900 placeholder:text-stone-400 placeholder:tracking-normal transition-[border-color,box-shadow] duration-150 focus:border-rose-500 focus:ring-4 focus:ring-rose-500/10 focus:outline-none text-center text-lg"
            {{on "input" this.updateOtp}}
          />
        </div>

        <button
          type="submit"
          disabled={{this.loading}}
          class="inline-flex w-full items-center justify-center gap-2 rounded-lg bg-rose-700 px-4 py-2.5 text-sm font-semibold text-white shadow-sm transition-all duration-150 hover:bg-rose-800 active:scale-[0.98] disabled:opacity-60 disabled:cursor-not-allowed"
        >
          {{#if this.loading}}
            <svg class="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none" aria-hidden="true">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
            </svg>
            {{this.t.verifying}}
          {{else}}
            {{this.t.verifyOtp}}
          {{/if}}
        </button>

        <button
          type="button"
          class="w-full text-sm text-stone-400 hover:text-stone-600 transition-colors duration-150"
          {{on "click" this.goBack}}
        >
          {{this.t.changeMobile}}
        </button>
      </form>
    {{/if}}
  </template>
}
