import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class GalleryRoute extends Route {
  @service auth;

  async beforeModel() {
    await this.auth.checkAuth();
    // Gallery is public — no login required
  }
}
