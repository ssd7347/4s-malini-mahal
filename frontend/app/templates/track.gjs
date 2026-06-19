import Component from '@glimmer/component';
import { service } from '@ember/service';
import EnquiryTracker from 'frontend/components/enquiry-tracker';

const T = {
  en: { title: 'Track your Booking',          subtitle: 'Enter the reference number from your booking confirmation (e.g. MM-7K4QPX).' },
  ta: { title: 'உங்கள் பதிவை கண்காணிக்கவும்', subtitle: 'உங்கள் பதிவு உறுதிப்படுத்தலில் உள்ள குறிப்பு எண்ணை உள்ளிடுங்கள் (உ.தா. MM-7K4QPX).' },
};

export default class TrackTemplate extends Component {
  @service language;
  get t() { return T[this.language.lang]; }

  <template>
    <div class="max-w-xl mx-auto animate-slide-up">
      <div class="mb-6">
        <h1 class="text-2xl font-bold text-stone-900 tracking-tight">{{this.t.title}}</h1>
        <p class="mt-1.5 text-stone-500">{{this.t.subtitle}}</p>
      </div>
      <EnquiryTracker />
    </div>
  </template>
}
