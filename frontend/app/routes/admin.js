import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class AdminRoute extends Route {
  @service auth;
  @service router;

  async beforeModel() {
    await this.auth.checkAuth();
    if (!this.auth.isLoggedIn) {
      this.auth.returnTo = 'admin';
      this.router.transitionTo('login', { queryParams: { next: '/admin' } });
    } else if (!this.auth.isAdmin) {
      this.router.transitionTo('index');
    }
  }
}
