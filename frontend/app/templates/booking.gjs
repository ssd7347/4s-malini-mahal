import Component from '@glimmer/component';
import { service } from '@ember/service';
import EnquiryForm from 'frontend/components/enquiry-form';

const T = {
  en: { title: 'Book a Slot',                    subtitle: 'Fill in your event details to request a booking at 4S Malini Mahal.' },
  ta: { title: 'ஒரு நேரத்தை பதிவு செய்யுங்கள்', subtitle: '4S மலினி மஹாலில் பதிவு கோர உங்கள் நிகழ்வு விவரங்களை நிரப்புங்கள்.' },
};

export default class BookingTemplate extends Component {
  @service language;
  get t() { return T[this.language.lang]; }

  <template>
    <div class="max-w-xl mx-auto animate-slide-up">
      <div class="mb-6">
        <h1 class="text-2xl font-bold text-stone-900 tracking-tight">{{this.t.title}}</h1>
        <p class="mt-1.5 text-stone-500">{{this.t.subtitle}}</p>
      </div>
      <EnquiryForm />
    </div>
  </template>
}
