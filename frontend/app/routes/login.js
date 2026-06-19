import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class LoginRoute extends Route {
  @service auth;
  @service router;

  queryParams = { next: { refreshModel: false } };

  async beforeModel() {
    await this.auth.checkAuth();
    if (this.auth.isLoggedIn) {
      this.router.transitionTo('index');
    }
  }
}
