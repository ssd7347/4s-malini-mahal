import Component from '@glimmer/component';
import { service } from '@ember/service';
import LoginForm from 'frontend/components/login-form';

const T = {
  en: { title: 'Log in to continue',   subtitle: "We'll send a one-time code to your WhatsApp" },
  ta: { title: 'தொடர உள்நுழைவு',      subtitle: 'உங்கள் WhatsApp-க்கு ஒரு முறை குறியீடு அனுப்புவோம்' },
};

export default class LoginTemplate extends Component {
  @service language;
  get t() { return T[this.language.lang]; }

  <template>
    <div class="max-w-sm mx-auto animate-slide-up">
      <div class="mb-8 text-center">
        <img
          src="/logo.jpg"
          alt="4S Malini Mahal"
          class="mx-auto mb-4 h-14 w-14 rounded-2xl object-cover shadow-sm"
        />
        <h1 class="text-xl font-bold text-stone-900 tracking-tight">{{this.t.title}}</h1>
        <p class="mt-1.5 text-sm text-stone-400">{{this.t.subtitle}}</p>
      </div>
      <div class="rounded-2xl border border-stone-200 bg-white p-6 shadow-sm">
        <LoginForm />
      </div>
    </div>
  </template>
}
