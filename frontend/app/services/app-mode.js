import Service from '@ember/service';
import { tracked } from '@glimmer/tracking';

export default class AppModeService extends Service {
  @tracked _value = 'browser';

  constructor() {
    super(...arguments);
    this._sync();
    window.addEventListener('mmAppModeChanged', () => this._sync());
    // Poll for 3s after startup to catch Capacitor's post-load injection
    let n = 0;
    const t = setInterval(() => {
      this._sync();
      if (++n >= 10) clearInterval(t);
    }, 300);
  }

  _sync() {
    try {
      const v = localStorage.getItem('mmAppMode') || 'browser';
      if (v !== this._value) this._value = v;
    } catch (_) {}
  }

  get isAdminApp()    { return this._value === 'admin'; }
  get isCustomerApp() { return this._value === 'customer'; }
}
