import Service from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class LanguageService extends Service {
  @tracked lang =
    (typeof localStorage !== 'undefined' && localStorage.getItem('mm-lang')) || 'en';

  @action toggle() {
    this.lang = this.lang === 'en' ? 'ta' : 'en';
    if (typeof localStorage !== 'undefined') {
      localStorage.setItem('mm-lang', this.lang);
    }
  }

  get isTamil() { return this.lang === 'ta'; }
}
