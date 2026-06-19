import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class BookingRoute extends Route {
  @service auth;
  @service router;

  async beforeModel() {
    await this.auth.checkAuth();
    if (!this.auth.isLoggedIn) {
      this.auth.returnTo = 'booking';
      this.router.transitionTo('login', { queryParams: { next: '/booking' } });
    }
  }
}
