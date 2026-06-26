import Component from '@glimmer/component';
import { service } from '@ember/service';

const TIMEOUT_MS = 5 * 60 * 1000; // 5 minutes
const EVENTS = ['mousemove', 'mousedown', 'keydown', 'touchstart', 'scroll', 'click'];

export default class InactivityWatcher extends Component {
  @service auth;
  @service router;

  _timer = null;

  constructor(owner, args) {
    super(owner, args);
    this._onActivity = this._onActivity.bind(this);
    EVENTS.forEach(ev => document.addEventListener(ev, this._onActivity, { passive: true }));
  }

  willDestroy() {
    super.willDestroy();
    clearTimeout(this._timer);
    EVENTS.forEach(ev => document.removeEventListener(ev, this._onActivity));
  }

  _onActivity() {
    if (!this.auth.isLoggedIn) {
      clearTimeout(this._timer);
      this._timer = null;
      return;
    }
    clearTimeout(this._timer);
    this._timer = setTimeout(() => this._handleTimeout(), TIMEOUT_MS);
  }

  async _handleTimeout() {
    if (!this.auth.isLoggedIn) return;
    await this.auth.logout();
    this.router.transitionTo('login');
  }

  <template></template>
}
