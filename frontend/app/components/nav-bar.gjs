import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { LinkTo } from '@ember/routing';
import { on } from '@ember/modifier';

const NAV_LINK = 'block px-3 py-1.5 rounded-md text-stone-600 transition-colors duration-150 hover:text-rose-700 hover:bg-rose-50 [&.active]:text-rose-700 [&.active]:bg-rose-50 whitespace-nowrap';
const MOBILE_LINK = 'block w-full rounded-lg px-4 py-2.5 text-sm font-medium text-stone-700 transition-colors duration-150 hover:bg-rose-50 hover:text-rose-700 [&.active]:bg-rose-50 [&.active]:text-rose-700';

const T = {
  en: {
    home: 'Home', gallery: 'Gallery', bookNow: 'Book Now',
    trackBooking: 'Track Booking', contact: 'Contact',
    admin: 'Admin', logIn: 'Log in', logOut: 'Log out',
  },
  ta: {
    home: 'முகப்பு', gallery: 'கேலரி', bookNow: 'பதிவு செய்',
    trackBooking: 'கண்காணி', contact: 'தொடர்பு',
    admin: 'நிர்வாகம்', logIn: 'உள்நுழைய', logOut: 'வெளியேறு',
  },
};

export default class NavBar extends Component {
  @service auth;
  @service router;
  @service language;
  @tracked mobileMenuOpen = false;

  get t() { return T[this.language.lang]; }

  get displayMobile() {
    const m = this.auth.user?.mobile;
    if (!m) return '';
    return m.slice(0, 3) + '•••••' + m.slice(-2);
  }

  @action toggleMenu()  { this.mobileMenuOpen = !this.mobileMenuOpen; }
  @action closeMenu()   { this.mobileMenuOpen = false; }

  @action
  async logout() {
    this.mobileMenuOpen = false;
    await this.auth.logout();
    this.router.transitionTo('index');
  }

  <template>
    <header class="sticky top-0 z-30 bg-white/95 backdrop-blur-sm border-b border-stone-200/80 shadow-sm">
      <nav class="max-w-5xl mx-auto px-4 h-16 flex items-center justify-between">

        {{! Logo }}
        <LinkTo @route="index" class="flex shrink-0 items-center gap-2.5 group" {{on "click" this.closeMenu}}>
          <img
            src="/logo.jpg"
            alt="4S Malini Mahal"
            class="h-9 w-9 rounded-lg object-cover shadow-sm transition-transform duration-150 group-hover:scale-105"
          />
          <span class="font-semibold text-stone-900 hidden sm:block tracking-tight">Malini&nbsp;Mahal</span>
        </LinkTo>

        {{! Desktop navigation }}
        <div class="hidden md:flex items-center gap-0.5 text-sm font-medium">
          <LinkTo @route="index"   class={{NAV_LINK}}>{{this.t.home}}</LinkTo>
          <LinkTo @route="gallery" class={{NAV_LINK}}>{{this.t.gallery}}</LinkTo>
          <LinkTo @route="booking" class={{NAV_LINK}}>{{this.t.bookNow}}</LinkTo>
          <LinkTo @route="track"   class={{NAV_LINK}}>{{this.t.trackBooking}}</LinkTo>
          <LinkTo @route="contact" class={{NAV_LINK}}>{{this.t.contact}}</LinkTo>
          {{#if this.auth.isAdmin}}
            <LinkTo @route="admin" class={{NAV_LINK}}>{{this.t.admin}}</LinkTo>
          {{/if}}
        </div>

        {{! Right side: lang toggle + login + hamburger }}
        <div class="flex shrink-0 items-center gap-2">

          {{! Language toggle pill }}
          <button
            type="button"
            aria-label="Switch language"
            class="flex items-center rounded-full border border-stone-200 text-xs font-semibold overflow-hidden shrink-0"
            {{on "click" this.language.toggle}}
          >
            <span class="px-2.5 py-1.5 transition-colors {{if this.language.isTamil 'text-stone-400 hover:bg-stone-50' 'bg-rose-700 text-white'}}">EN</span>
            <span class="px-2.5 py-1.5 transition-colors {{if this.language.isTamil 'bg-rose-700 text-white' 'text-stone-400 hover:bg-stone-50'}}">தமிழ்</span>
          </button>

          {{#if this.auth.isLoggedIn}}
            <span class="hidden sm:block text-xs text-stone-400 font-mono">{{this.displayMobile}}</span>
            <button
              type="button"
              class="hidden md:inline-flex items-center gap-1.5 rounded-lg border border-stone-200 px-3 py-1.5 text-sm font-medium text-stone-600 transition-colors duration-150 hover:bg-stone-100 hover:border-stone-300"
              {{on "click" this.logout}}
            >
              <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0013.5 3h-6a2.25 2.25 0 00-2.25 2.25v13.5A2.25 2.25 0 007.5 21h6a2.25 2.25 0 002.25-2.25V15m3 0l3-3m0 0l-3-3m3 3H9"/>
              </svg>
              {{this.t.logOut}}
            </button>
          {{else}}
            <LinkTo
              @route="login"
              class="hidden md:inline-flex items-center gap-1.5 rounded-lg bg-rose-700 px-3 py-1.5 text-sm font-semibold text-white shadow-sm transition-all duration-150 hover:bg-rose-800 active:scale-[0.97]"
            >
              {{this.t.logIn}}
            </LinkTo>
          {{/if}}

          {{! Hamburger (mobile only) }}
          <button
            type="button"
            aria-label="Toggle menu"
            class="md:hidden inline-flex items-center justify-center h-9 w-9 rounded-lg border border-stone-200 text-stone-600 hover:bg-stone-100 transition-colors"
            {{on "click" this.toggleMenu}}
          >
            {{#if this.mobileMenuOpen}}
              <svg class="h-5 w-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
              </svg>
            {{else}}
              <svg class="h-5 w-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"/>
              </svg>
            {{/if}}
          </button>
        </div>
      </nav>

      {{! Mobile dropdown }}
      {{#if this.mobileMenuOpen}}
        <div class="md:hidden border-t border-stone-100 bg-white px-3 py-3 space-y-1 shadow-lg">
          <LinkTo @route="index"   class={{MOBILE_LINK}} {{on "click" this.closeMenu}}>{{this.t.home}}</LinkTo>
          <LinkTo @route="gallery" class={{MOBILE_LINK}} {{on "click" this.closeMenu}}>{{this.t.gallery}}</LinkTo>
          <LinkTo @route="booking" class={{MOBILE_LINK}} {{on "click" this.closeMenu}}>{{this.t.bookNow}}</LinkTo>
          <LinkTo @route="track"   class={{MOBILE_LINK}} {{on "click" this.closeMenu}}>{{this.t.trackBooking}}</LinkTo>
          <LinkTo @route="contact" class={{MOBILE_LINK}} {{on "click" this.closeMenu}}>{{this.t.contact}}</LinkTo>
          {{#if this.auth.isAdmin}}
            <LinkTo @route="admin" class={{MOBILE_LINK}} {{on "click" this.closeMenu}}>{{this.t.admin}}</LinkTo>
          {{/if}}

          <div class="pt-2 border-t border-stone-100 mt-2">
            {{#if this.auth.isLoggedIn}}
              <div class="px-4 py-1 mb-1 text-xs text-stone-400 font-mono">{{this.displayMobile}}</div>
              <button
                type="button"
                class="w-full text-left rounded-lg px-4 py-2.5 text-sm font-medium text-stone-700 hover:bg-stone-100 transition-colors flex items-center gap-2"
                {{on "click" this.logout}}
              >
                <svg class="h-4 w-4 text-stone-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0013.5 3h-6a2.25 2.25 0 00-2.25 2.25v13.5A2.25 2.25 0 007.5 21h6a2.25 2.25 0 002.25-2.25V15m3 0l3-3m0 0l-3-3m3 3H9"/>
                </svg>
                {{this.t.logOut}}
              </button>
            {{else}}
              <LinkTo
                @route="login"
                class="block w-full rounded-lg bg-rose-700 px-4 py-2.5 text-sm font-bold text-white text-center hover:bg-rose-800 transition-colors"
                {{on "click" this.closeMenu}}
              >
                {{this.t.logIn}}
              </LinkTo>
            {{/if}}
          </div>
        </div>
      {{/if}}
    </header>
  </template>
}
