import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class EnquiryRoute extends Route {
  @service auth;
  @service router;

  async beforeModel() {
    await this.auth.checkAuth();
    if (!this.auth.isLoggedIn) {
      this.auth.returnTo = 'enquiry';
      this.router.transitionTo('login', { queryParams: { next: '/enquiry' } });
    }
  }
}
