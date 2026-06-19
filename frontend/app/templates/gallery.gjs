import Component from '@glimmer/component';
import { service } from '@ember/service';
import GalleryGrid from 'frontend/components/gallery-grid';

const T = {
  en: { title: 'Gallery',          subtitle: 'Photos and videos from events at 4S Malini Mahal.' },
  ta: { title: 'படத்தொகுப்பு',    subtitle: '4S மலினி மஹாலில் நடைபெற்ற நிகழ்வுகளின் புகைப்படங்கள் மற்றும் காணொலிகள்.' },
};

export default class GalleryTemplate extends Component {
  @service language;
  get t() { return T[this.language.lang]; }

  <template>
    <div class="animate-slide-up mb-6">
      <h1 class="text-2xl font-bold text-stone-900 tracking-tight">{{this.t.title}}</h1>
      <p class="mt-1.5 text-stone-500">{{this.t.subtitle}}</p>
    </div>
    <GalleryGrid />
  </template>
}
