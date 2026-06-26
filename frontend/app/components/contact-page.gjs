import Component from '@glimmer/component';
import { service } from '@ember/service';

const T = {
  en: {
    title:       'Contact Us',
    subtitle:    'Reach us by phone, WhatsApp, or visit us in Thiruthangal.',
    callUs:      'Call us',
    tapToCall:   'Tap to call',
    chatWithUs:  'Chat with us',
    followUs:    'Follow us',
    ourLocation: 'Our Location',
    address1:    'Virudhunagar Main Rd, Thiruthangal',
    address2:    'Sivakasi, Tamil Nadu 626 130',
    directions:  'Get Directions',
  },
  ta: {
    title:       'எங்களை தொடர்பு கொள்ளுங்கள்',
    subtitle:    'தொலைபேசி, WhatsApp மூலம் அல்லது திருத்தங்கலில் எங்களை சந்தியுங்கள்.',
    callUs:      'எங்களை அழைக்கவும்',
    tapToCall:   'அழைக்க தட்டவும்',
    chatWithUs:  'எங்களுடன் அரட்டை',
    followUs:    'எங்களை பின்தொடருங்கள்',
    ourLocation: 'எங்கள் இடம்',
    address1:    'விருதுநகர் பிரதான சாலை, திருத்தங்கல்',
    address2:    'சிவகாசி, தமிழ்நாடு 626 130',
    directions:  'வழி பெறுங்கள்',
  },
};

export default class ContactPage extends Component {
  @service language;
  get t() { return T[this.language.lang]; }

  <template>
    <div class="animate-slide-up">
      <div class="mb-6">
        <h1 class="text-2xl font-bold text-stone-900 tracking-tight">{{this.t.title}}</h1>
        <p class="mt-1.5 text-stone-500">{{this.t.subtitle}}</p>
      </div>

      {{! Contact cards }}
      <div class="grid sm:grid-cols-3 gap-4 mb-8">

        {{! Phone }}
        <a
          href="tel:+919443380023"
          class="flex items-start gap-4 rounded-xl border border-stone-200 bg-white p-5 shadow-sm transition-all duration-200 hover:shadow-md hover:-translate-y-0.5 group"
        >
          <div class="h-10 w-10 shrink-0 rounded-lg bg-rose-50 flex items-center justify-center">
            <svg class="h-5 w-5 text-rose-700" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true">
              <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 6.75c0 8.284 6.716 15 15 15h2.25a2.25 2.25 0 002.25-2.25v-1.372c0-.516-.351-.966-.852-1.091l-4.423-1.106c-.44-.11-.902.055-1.173.417l-.97 1.293c-.282.376-.769.542-1.21.38a12.035 12.035 0 01-7.143-7.143c-.162-.441.004-.928.38-1.21l1.293-.97c.363-.271.527-.734.417-1.173L6.963 3.102a1.125 1.125 0 00-1.091-.852H4.5A2.25 2.25 0 002.25 4.5v2.25z"/>
            </svg>
          </div>
          <div>
            <p class="text-xs font-semibold text-stone-400 uppercase tracking-wide mb-1">{{this.t.callUs}}</p>
            <p class="text-sm font-semibold text-stone-900 group-hover:text-rose-700 transition-colors">+91 94433 80023</p>
            <p class="text-xs text-stone-400 mt-0.5">{{this.t.tapToCall}}</p>
          </div>
        </a>

        {{! WhatsApp }}
        <a
          href="https://wa.me/919443380023?text=Hi%2C%20I%20would%20like%20to%20enquire%20about%204S%20Malini%20Mahal."
          target="_blank"
          rel="noopener noreferrer"
          class="flex items-start gap-4 rounded-xl border border-stone-200 bg-white p-5 shadow-sm transition-all duration-200 hover:shadow-md hover:-translate-y-0.5 group"
        >
          <div class="h-10 w-10 shrink-0 rounded-lg bg-green-50 flex items-center justify-center">
            <svg class="h-5 w-5 text-green-600" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
              <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
            </svg>
          </div>
          <div>
            <p class="text-xs font-semibold text-stone-400 uppercase tracking-wide mb-1">WhatsApp</p>
            <p class="text-sm font-semibold text-stone-900 group-hover:text-green-700 transition-colors">+91 94433 80023</p>
            <p class="text-xs text-stone-400 mt-0.5">{{this.t.chatWithUs}}</p>
          </div>
        </a>

        {{! Instagram }}
        <a
          href="https://www.instagram.com/4s_malini_mahal?igsh=MXd2NmhtdXB4OXh6bQ=="
          target="_blank"
          rel="noopener noreferrer"
          class="flex items-start gap-4 rounded-xl border border-stone-200 bg-white p-5 shadow-sm transition-all duration-200 hover:shadow-md hover:-translate-y-0.5 group"
        >
          <div class="h-10 w-10 shrink-0 rounded-lg bg-pink-50 flex items-center justify-center">
            <svg class="h-5 w-5 text-pink-600" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
              <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/>
            </svg>
          </div>
          <div>
            <p class="text-xs font-semibold text-stone-400 uppercase tracking-wide mb-1">Instagram</p>
            <p class="text-sm font-semibold text-stone-900 group-hover:text-pink-700 transition-colors">@4s_malini_mahal</p>
            <p class="text-xs text-stone-400 mt-0.5">{{this.t.followUs}}</p>
          </div>
        </a>
      </div>

      {{! Location }}
      <div class="bg-white rounded-2xl border border-stone-200 overflow-hidden">
        <div class="p-6 pb-4 flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4">
          <div>
            <h2 class="text-lg font-semibold text-stone-900">{{this.t.ourLocation}}</h2>
            <p class="mt-1 text-sm text-stone-500 leading-relaxed">
              {{this.t.address1}}<br/>
              {{this.t.address2}}
            </p>
          </div>
          <a
            href="https://maps.app.goo.gl/JeJpq91QKdKQLGHb9"
            target="_blank"
            rel="noopener noreferrer"
            class="inline-flex items-center gap-2 self-start rounded-lg border border-stone-300 bg-white px-4 py-2 text-sm font-semibold text-stone-700 shadow-sm transition-all duration-150 hover:bg-stone-50 hover:border-stone-400 active:scale-[0.97] whitespace-nowrap"
          >
            <svg class="h-4 w-4 text-rose-600" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
              <path stroke-linecap="round" stroke-linejoin="round" d="M9 6.75V15m6-6v8.25m.503 3.498l4.875-2.437c.381-.19.622-.58.622-1.006V4.82c0-.836-.88-1.38-1.628-1.006l-3.869 1.934c-.317.159-.69.159-1.006 0L9.503 3.252a1.125 1.125 0 00-1.006 0L3.622 5.689C3.24 5.88 3 6.695V19.18c0 .836.88 1.38 1.628 1.006l3.869-1.934c.317-.159.69-.159 1.006 0l4.994 2.497c.317.158.69.158 1.006 0z"/>
            </svg>
            {{this.t.directions}}
          </a>
        </div>
        <div class="h-72 w-full">
          <iframe
            src="https://maps.google.com/maps?q=4S+Malini+Mahal+Thiruthangal+Sivakasi+Tamil+Nadu&output=embed"
            class="h-full w-full border-0"
            loading="lazy"
            allowfullscreen
            title="4S Malini Mahal on Google Maps"
          ></iframe>
        </div>
      </div>
    </div>
  </template>
}
