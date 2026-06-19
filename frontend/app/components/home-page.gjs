import Component from '@glimmer/component';
import { service } from '@ember/service';
import { LinkTo } from '@ember/routing';

const T = {
  en: {
    badge:        'Thiruthangal, Sivakasi',
    tagline:      'A banquet hall for weddings, receptions and family functions — with AC facilities for up to 200 guests.',
    submitBooking:'Submit a Booking',
    submitEnquiry:'Submit an Enquiry',
    trackEnquiry: 'Track Enquiry',
    capacity:     'Capacity',
    capacityDesc: 'Floor 1 · 120 guests · Floor 2 · 80 guests · Combined up to 200',
    facilities:   'Facilities',
    facilitiesDesc:'AC bride & groom rooms · Dining hall & stage · Kitchen with gas · Ample parking',
    pricing:      'Clear Pricing',
    pricingDesc:  '₹32,000 full day · ₹23,000 half day · ₹3,000/hr — no hidden charges',
    location:     'Location',
    locationDesc: 'Virudhunagar Main Rd, Thiruthangal — easy access for all guests',
    whyUs:        'Why Choose Us',
    why1: 'Transparent, fixed pricing — no last-minute surprises',
    why2: 'Online booking with instant reference number and Razorpay payment',
    why3: 'Trusted by families across Thiruthangal and Sivakasi',
    why4: 'Flexible slots — full day, half day, or hourly bookings available',
    getInTouch:   'Get in Touch',
    whatsappUs:   'WhatsApp us',
    locationShort:'Virudhunagar Main Rd, Thiruthangal',
    viewContact:  'View full contact page',
  },
  ta: {
    badge:        'திருத்தங்கல், சிவகாசி',
    tagline:      'திருமணங்கள், வரவேற்புகள் மற்றும் குடும்ப விழாக்களுக்கான விழா மண்டபம் — 200 விருந்தினர்கள் வரை ஏர்கண்டிஷன் வசதியுடன்.',
    submitBooking:'பதிவு செய்யுங்கள்',
    submitEnquiry:'விசாரணை செய்யுங்கள்',
    trackEnquiry: 'விசாரணையை கண்காணிக்க',
    capacity:     'அமர்வு திறன்',
    capacityDesc: 'தளம் 1 · 120 பேர் · தளம் 2 · 80 பேர் · மொத்தம் 200 வரை',
    facilities:   'வசதிகள்',
    facilitiesDesc:'AC மணமகள் & மணமகன் அறைகள் · சாப்பாட்டு மண்டபம் & மேடை · சமையலறை · நிறைந்த வாகன நிறுத்துமிடம்',
    pricing:      'தெளிவான கட்டணம்',
    pricingDesc:  '₹32,000 முழு நாள் · ₹23,000 அரை நாள் · ₹3,000/மணி — மறைமுக கட்டணங்கள் இல்லை',
    location:     'இடம்',
    locationDesc: 'விருதுநகர் பிரதான சாலை, திருத்தங்கல் — அனைவருக்கும் எளிதான வழி',
    whyUs:        'எங்களை ஏன் தேர்வு செய்ய வேண்டும்',
    why1: 'வெளிப்படையான, நிலையான கட்டணம் — கடைசி நிமிட அதிர்ச்சிகள் இல்லை',
    why2: 'ஆன்லைன் பதிவு, உடனடி குறிப்பு எண் மற்றும் Razorpay கட்டணம்',
    why3: 'திருத்தங்கல் மற்றும் சிவகாசியின் குடும்பங்களால் நம்பப்படுகிறது',
    why4: 'நெகிழ்வான நேர இடைவெளிகள் — முழு நாள், அரை நாள் அல்லது மணிநேர பதிவுகள்',
    getInTouch:   'தொடர்பு கொள்ளுங்கள்',
    whatsappUs:   'WhatsApp-ல் தொடர்பு கொள்ளுங்கள்',
    locationShort:'விருதுநகர் பிரதான சாலை, திருத்தங்கல்',
    viewContact:  'தொடர்பு பக்கம்',
  },
};

export default class HomePage extends Component {
  @service auth;
  @service language;

  get t() { return T[this.language.lang]; }

  <template>
    <div class="animate-slide-up space-y-8">

      {{! Hero card }}
      <div class="rounded-2xl bg-gradient-to-br from-rose-50 to-white border border-rose-100 px-6 py-10 sm:py-20 text-center shadow-sm">

        <div class="inline-flex items-center gap-2 rounded-full border border-rose-200 bg-white px-4 py-1.5 text-sm font-medium text-stone-600 mb-5 sm:mb-8 shadow-sm">
          <span class="h-2 w-2 rounded-full bg-rose-600 shrink-0"></span>
          {{this.t.badge}}
        </div>

        <h1 class="text-3xl sm:text-5xl font-bold text-stone-900 leading-tight tracking-tight">
          4S Malini Mahal
        </h1>

        <p class="mt-4 text-stone-500 text-base max-w-md mx-auto leading-relaxed">
          {{this.t.tagline}}
        </p>

        <div class="mt-8 flex flex-wrap items-center justify-center gap-3">
          <LinkTo
            @route="booking"
            class="inline-flex items-center gap-2 rounded-xl bg-rose-700 px-6 py-3 text-sm font-bold text-white shadow-sm hover:bg-rose-800 transition-colors active:scale-[0.97]"
          >
            {{this.t.submitBooking}}
            <svg class="h-4 w-4" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24" aria-hidden="true">
              <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3"/>
            </svg>
          </LinkTo>
          <LinkTo
            @route="track"
            class="inline-flex items-center gap-2 rounded-xl border border-stone-200 bg-white px-6 py-3 text-sm font-semibold text-stone-700 shadow-sm hover:bg-stone-50 transition-colors"
          >
            {{this.t.trackEnquiry}}
          </LinkTo>
        </div>
      </div>

      {{! Info cards }}
      <div id="about" class="grid sm:grid-cols-2 lg:grid-cols-4 gap-4">

        <div class="rounded-xl border border-stone-200 bg-white p-5 shadow-sm">
          <div class="h-10 w-10 rounded-lg bg-rose-50 flex items-center justify-center mb-3">
            <svg class="h-5 w-5 text-rose-700" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z"/>
            </svg>
          </div>
          <p class="font-semibold text-stone-900">{{this.t.capacity}}</p>
          <p class="mt-1 text-sm text-stone-500 leading-relaxed">{{this.t.capacityDesc}}</p>
        </div>

        <div class="rounded-xl border border-stone-200 bg-white p-5 shadow-sm">
          <div class="h-10 w-10 rounded-lg bg-amber-50 flex items-center justify-center mb-3">
            <svg class="h-5 w-5 text-amber-600" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true">
              <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25"/>
            </svg>
          </div>
          <p class="font-semibold text-stone-900">{{this.t.facilities}}</p>
          <p class="mt-1 text-sm text-stone-500 leading-relaxed">{{this.t.facilitiesDesc}}</p>
        </div>

        <div class="rounded-xl border border-stone-200 bg-white p-5 shadow-sm">
          <div class="h-10 w-10 rounded-lg bg-green-50 flex items-center justify-center mb-3">
            <svg class="h-5 w-5 text-green-600" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true">
              <path stroke-linecap="round" stroke-linejoin="round" d="M9 14.25l6-6m4.5-3.493V21.75l-3.75-1.5-3.75 1.5-3.75-1.5-3.75 1.5V4.757c0-1.108.806-2.057 1.907-2.185a48.507 48.507 0 0111.186 0c1.1.128 1.907 1.077 1.907 2.185zM9.75 9h.008v.008H9.75V9zm.375 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm4.125 4.5h.008v.008h-.008V13.5zm.375 0a.375.375 0 11-.75 0 .375.375 0 01.75 0z"/>
            </svg>
          </div>
          <p class="font-semibold text-stone-900">{{this.t.pricing}}</p>
          <p class="mt-1 text-sm text-stone-500 leading-relaxed">{{this.t.pricingDesc}}</p>
        </div>

        <div class="rounded-xl border border-stone-200 bg-white p-5 shadow-sm">
          <div class="h-10 w-10 rounded-lg bg-blue-50 flex items-center justify-center mb-3">
            <svg class="h-5 w-5 text-blue-600" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z"/>
              <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z"/>
            </svg>
          </div>
          <p class="font-semibold text-stone-900">{{this.t.location}}</p>
          <p class="mt-1 text-sm text-stone-500 leading-relaxed">{{this.t.locationDesc}}</p>
        </div>
      </div>

      {{! Why choose us + Contact }}
      <div class="grid sm:grid-cols-2 gap-6">
        <div class="rounded-xl border border-stone-200 bg-white p-6 shadow-sm">
          <h3 class="font-semibold text-stone-900 mb-4">{{this.t.whyUs}}</h3>
          <ul class="space-y-3 text-sm text-stone-600">
            <li class="flex items-start gap-2.5">
              <svg class="h-4 w-4 text-green-500 mt-0.5 shrink-0" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
              </svg>
              {{this.t.why1}}
            </li>
            <li class="flex items-start gap-2.5">
              <svg class="h-4 w-4 text-green-500 mt-0.5 shrink-0" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
              </svg>
              {{this.t.why2}}
            </li>
            <li class="flex items-start gap-2.5">
              <svg class="h-4 w-4 text-green-500 mt-0.5 shrink-0" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
              </svg>
              {{this.t.why3}}
            </li>
            <li class="flex items-start gap-2.5">
              <svg class="h-4 w-4 text-green-500 mt-0.5 shrink-0" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
              </svg>
              {{this.t.why4}}
            </li>
          </ul>
        </div>

        <div class="rounded-xl border border-stone-200 bg-white p-6 shadow-sm">
          <h3 class="font-semibold text-stone-900 mb-4">{{this.t.getInTouch}}</h3>
          <div class="space-y-3">
            <a href="tel:+919443380023" class="flex items-center gap-3 text-sm text-stone-700 hover:text-rose-700 transition-colors">
              <svg class="h-4 w-4 text-rose-500 shrink-0" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 6.75c0 8.284 6.716 15 15 15h2.25a2.25 2.25 0 002.25-2.25v-1.372c0-.516-.351-.966-.852-1.091l-4.423-1.106c-.44-.11-.902.055-1.173.417l-.97 1.293c-.282.376-.769.542-1.21.38a12.035 12.035 0 01-7.143-7.143c-.162-.441.004-.928.38-1.21l1.293-.97c.363-.271.527-.734.417-1.173L6.963 3.102a1.125 1.125 0 00-1.091-.852H4.5A2.25 2.25 0 002.25 4.5v2.25z"/>
              </svg>
              +91 94433 80023
            </a>
            <a href="https://wa.me/919443380023" target="_blank" rel="noopener noreferrer" class="flex items-center gap-3 text-sm text-stone-700 hover:text-green-700 transition-colors">
              <svg class="h-4 w-4 text-green-500 shrink-0" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
              </svg>
              {{this.t.whatsappUs}}
            </a>
            <a href="https://maps.app.goo.gl/JeJpq91QKdKQLGHb9" target="_blank" rel="noopener noreferrer" class="flex items-center gap-3 text-sm text-stone-700 hover:text-blue-700 transition-colors">
              <svg class="h-4 w-4 text-blue-500 shrink-0" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z"/>
                <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z"/>
              </svg>
              {{this.t.locationShort}}
            </a>
          </div>
          <LinkTo
            @route="contact"
            class="mt-4 inline-flex items-center gap-1 text-xs font-medium text-rose-700 hover:text-rose-900 transition-colors"
          >
            {{this.t.viewContact}}
            <svg class="h-3 w-3" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24" aria-hidden="true">
              <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3"/>
            </svg>
          </LinkTo>
        </div>
      </div>

    </div>
  </template>
}
