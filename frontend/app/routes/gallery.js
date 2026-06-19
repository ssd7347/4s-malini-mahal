import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class GalleryRoute extends Route {
  @service auth;
  @service router;

  async beforeModel() {
    await this.auth.checkAuth();
    if (!this.auth.isLoggedIn) {
      this.auth.returnTo = 'gallery';
      this.router.transitionTo('login', { queryParams: { next: '/gallery' } });
    }
  }
}
