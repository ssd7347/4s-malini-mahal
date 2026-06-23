import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';

export default class OfflineOverlay extends Component {
  @tracked isOffline = !navigator.onLine;

  _setOffline = () => { this.isOffline = true; };
  _setOnline  = () => { this.isOffline = false; };

  constructor() {
    super(...arguments);
    window.addEventListener('offline', this._setOffline);
    window.addEventListener('online',  this._setOnline);
  }

  willDestroy() {
    super.willDestroy(...arguments);
    window.removeEventListener('offline', this._setOffline);
    window.removeEventListener('online',  this._setOnline);
  }

  @action retry() { window.location.reload(); }

  <template>
    {{#if this.isOffline}}
      <div class="fixed inset-0 z-50 bg-white flex flex-col items-center justify-center p-8 text-center">
        <img src="/logo.jpg" alt="4S Malini Mahal" class="h-20 w-20 rounded-2xl object-cover shadow-md mb-6" />
        <h2 class="text-xl font-bold text-rose-700 mb-2">No Internet Connection</h2>
        <p class="text-stone-500 mb-1">4S Malini Mahal requires an internet connection.</p>
        <p class="text-stone-400 text-sm mb-6">Please check your Wi-Fi or mobile data and try again.</p>
        <button
          type="button"
          class="rounded-lg bg-rose-700 px-6 py-2.5 text-sm font-semibold text-white hover:bg-rose-800 active:scale-95 transition-all"
          {{on "click" this.retry}}
        >
          Try Again
        </button>
      </div>
    {{/if}}
  </template>
}
