import Route from '@ember/routing/route';
import { service } from '@ember/service';

const PAGE_TITLES = {
  'index':        '4S Malini Mahal — Marriage Hall in Sivakasi, Thiruthangal | Book Online',
  'gallery':      'Photo Gallery | 4S Malini Mahal — Sivakasi',
  'amenities':    'Amenities & Facilities | 4S Malini Mahal — Sivakasi',
  'booking':      'Book the Hall Online | 4S Malini Mahal — Sivakasi',
  'availability': 'Check Availability | 4S Malini Mahal — Sivakasi',
  'contact':      'Contact Us | 4S Malini Mahal — Thiruthangal, Sivakasi',
  'login':        'Login | 4S Malini Mahal',
  'track':        'Track Booking | 4S Malini Mahal',
};

const DEFAULT_TITLE = '4S Malini Mahal — Marriage Hall in Sivakasi';

export default class ApplicationRoute extends Route {
  @service auth;
  @service router;

  async beforeModel() {
    await this.auth.checkAuth();
    this.router.on('routeDidChange', () => {
      const name = this.router.currentRouteName ?? '';
      document.title = PAGE_TITLES[name] ?? DEFAULT_TITLE;
    });
  }
}
