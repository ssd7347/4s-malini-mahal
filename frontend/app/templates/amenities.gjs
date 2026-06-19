import Component from '@glimmer/component';
import { service } from '@ember/service';
import AmenitiesPage from 'frontend/components/amenities-page';

const T = {
  en: {
    title:    'Our Amenities',
    subtitle: 'Everything you need for a perfect event — comfort, convenience, and safety all under one roof.',
  },
  ta: {
    title:    'எங்கள் வசதிகள்',
    subtitle: 'உங்கள் நிகழ்வை சிறப்பாக்க தேவையான அனைத்தும் — வசதி, வழக்கம் மற்றும் பாதுகாப்பு ஒரே கூரையின் கீழ்.',
  },
};

export default class AmenitiesTemplate extends Component {
  @service language;
  get t() { return T[this.language.lang]; }

  <template>
    <div class="animate-slide-up mb-6">
      <h1 class="text-2xl font-bold text-stone-900 tracking-tight">{{this.t.title}}</h1>
      <p class="mt-1.5 text-stone-500">{{this.t.subtitle}}</p>
    </div>
    <AmenitiesPage />
  </template>
}
