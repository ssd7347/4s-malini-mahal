import Component from '@glimmer/component';
import { service } from '@ember/service';
import AvailabilityPage from 'frontend/components/availability-page';

const T = {
  en: {
    title:    'Check Availability',
    subtitle: 'Select a date to see if the hall is available for your event.',
  },
  ta: {
    title:    'தேதி கிடைப்பை சரிபார்க்கவும்',
    subtitle: 'உங்கள் நிகழ்வுக்கு மண்டபம் கிடைக்கிறதா என்று தேதியை தேர்வு செய்து பாருங்கள்.',
  },
};

export default class AvailabilityTemplate extends Component {
  @service language;
  get t() { return T[this.language.lang]; }

  <template>
    <div class="max-w-xl mx-auto animate-slide-up">
      <div class="mb-6">
        <h1 class="text-2xl font-bold text-stone-900 tracking-tight">{{this.t.title}}</h1>
        <p class="mt-1.5 text-stone-500">{{this.t.subtitle}}</p>
      </div>
      <AvailabilityPage />
    </div>
  </template>
}
