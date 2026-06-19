import Service from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { apiUrl } from 'frontend/utils/api';

export default class AuthService extends Service {
  @tracked user = null;

  _checked = false;

  get isLoggedIn() { return this.user !== null; }
  get isAdmin()    { return this.user?.role === 'ADMIN'; }

  returnTo = null; // route name to go to after login

  async checkAuth() {
    if (this._checked) return;
    this._checked = true; // set before await to prevent concurrent calls
    try {
      const res = await fetch(apiUrl('/api/auth/me'), { credentials: 'include' });
      if (res.ok) this.user = await res.json();
    } catch (_) {}
  }

  async logout() {
    try {
      await fetch(apiUrl('/api/auth/logout'), { method: 'POST', credentials: 'include' });
    } catch (_) {}
    this.user = null;
    this._checked = false;
  }
}
