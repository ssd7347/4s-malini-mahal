import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class BookingRoute extends Route {
  @service auth;

  async beforeModel() {
    await this.auth.checkAuth();
    // Booking form is public — login is required only at submission time
  }
}
