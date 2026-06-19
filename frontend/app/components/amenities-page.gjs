import Component from '@glimmer/component';
import { service } from '@ember/service';
import { LinkTo } from '@ember/routing';

const T = {
  en: {
    hallTitle:     'Air-Conditioned Hall',
    hallDesc:      'Spacious fully air-conditioned hall for maximum comfort during events.',
    elevatorTitle: 'Elevator Facility',
    elevatorDesc:  'Convenient elevator access for elderly guests, children, and differently-abled visitors.',
    parkingTitle:  'Ample Parking Space',
    parkingDesc:   'Safe and spacious parking area for all guests\' vehicles.',
    roomsTitle:    'Bride & Groom Rooms',
    roomsDesc:     'Dedicated, well-furnished rooms for the bride, groom, and guests.',
    serviceTitle:  '24-Hour Room Service',
    serviceDesc:   'Round-the-clock room service and assistance for guests staying at the venue.',
    fireTitle:     'Fire Safety',
    fireDesc:      'Modern fire safety systems and emergency equipment installed throughout the premises.',
    audioTitle:    'Professional Audio',
    audioDesc:     'High-quality sound systems suitable for weddings, receptions, and other functions.',
    serviceStdsTitle: 'Service',
    serviceStdsDesc:  'Unmatched service standards for every guest at the venue.',
    ctaTitle:      'Ready to experience these amenities?',
    ctaDesc:       'Book a slot today and make your event unforgettable at 4S Malini Mahal.',
    bookNow:       'Book Now',
    contactUs:     'Contact Us',
  },
  ta: {
    hallTitle:     'குளிர்சாதன மண்டபம்',
    hallDesc:      'நிகழ்வுகளின் போது அதிகபட்ச வசதிக்காக முழுவதும் குளிர்சாதன வசதியுடன் கூடிய மண்டபம்.',
    elevatorTitle: 'மின்தூக்கி வசதி',
    elevatorDesc:  'வயதானவர்கள், குழந்தைகள் மற்றும் மாற்றுத்திறனாளிகளுக்கு எளிதான மின்தூக்கி வசதி.',
    parkingTitle:  'வாகன நிறுத்துமிடம்',
    parkingDesc:   'விருந்தினர்களின் வாகனங்களுக்கு பாதுகாப்பான மற்றும் விரிவான வாகன நிறுத்துமிடம்.',
    roomsTitle:    'மணமகள் & மணமகன் அறைகள்',
    roomsDesc:     'மணமகள், மணமகன் மற்றும் விருந்தினர்களுக்கான தனி, நன்கு அமைக்கப்பட்ட அறைகள்.',
    serviceTitle:  '24 மணி நேர சேவை',
    serviceDesc:   'விருந்தினர்களுக்கு 24 மணி நேரமும் அறை சேவை மற்றும் உதவி.',
    fireTitle:     'தீ பாதுகாப்பு',
    fireDesc:      'வளாகம் முழுவதும் நவீன தீ பாதுகாப்பு அமைப்புகள் மற்றும் அவசரகால உபகரணங்கள்.',
    audioTitle:    'தொழில்முறை ஒலி',
    audioDesc:     'திருமணங்கள் மற்றும் விழாக்களுக்கு ஏற்ற உயர்தர ஒலி அமைப்புகள்.',
    serviceStdsTitle: 'சேவை',
    serviceStdsDesc:  'விழாவில் உள்ள ஒவ்வொரு விருந்தினருக்கும் தரமற்ற சேவை தரம்.',
    ctaTitle:      'இந்த வசதிகளை அனுபவிக்க தயாரா?',
    ctaDesc:       'இன்றே ஒரு நேர இடைவெளியை பதிவு செய்து 4S மலினி மஹாலில் உங்கள் நிகழ்வை மறக்கமுடியாததாக மாற்றுங்கள்.',
    bookNow:       'இப்போது பதிவு செய்',
    contactUs:     'தொடர்பு கொள்ளுங்கள்',
  },
};

export default class AmenitiesPage extends Component {
  @service language;
  get t() { return T[this.language.lang]; }

  <template>
    <div class="grid grid-cols-2 sm:grid-cols-2 lg:grid-cols-4 gap-4">

      {{! 1 — Air-Conditioned Hall }}
      <div class="group flex flex-col items-center text-center gap-5 rounded-2xl bg-amber-50 border border-amber-100 p-6 shadow-sm hover:-translate-y-1 hover:shadow-md transition-all duration-300">
        <h3 class="font-bold text-amber-800 text-xs sm:text-sm uppercase tracking-wide leading-snug">
          {{this.t.hallTitle}}
        </h3>
        <div class="h-20 w-20 sm:h-24 sm:w-24 rounded-full bg-amber-600 flex items-center justify-center shadow group-hover:scale-105 transition-transform duration-300">
          <svg class="h-9 w-9 sm:h-11 sm:w-11 text-white" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" d="M17.7 7.7a2.5 2.5 0 1 1 1.8 4.3H2"/>
            <path stroke-linecap="round" stroke-linejoin="round" d="M9.6 4.6A2 2 0 0 1 11 8H2"/>
            <path stroke-linecap="round" stroke-linejoin="round" d="M12.6 19.4A2 2 0 0 0 14 16H2"/>
          </svg>
        </div>
        <p class="text-xs sm:text-sm text-stone-600 leading-relaxed">{{this.t.hallDesc}}</p>
      </div>

      {{! 2 — Elevator }}
      <div class="group flex flex-col items-center text-center gap-5 rounded-2xl bg-amber-50 border border-amber-100 p-6 shadow-sm hover:-translate-y-1 hover:shadow-md transition-all duration-300">
        <h3 class="font-bold text-amber-800 text-xs sm:text-sm uppercase tracking-wide leading-snug">
          {{this.t.elevatorTitle}}
        </h3>
        <div class="h-20 w-20 sm:h-24 sm:w-24 rounded-full bg-amber-600 flex items-center justify-center shadow group-hover:scale-105 transition-transform duration-300">
          <svg class="h-9 w-9 sm:h-11 sm:w-11 text-white" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" d="M3 7.5L7.5 3m0 0L12 7.5M7.5 3v13.5m13.5 0L16.5 21m0 0L12 16.5m4.5 4.5V7.5"/>
          </svg>
        </div>
        <p class="text-xs sm:text-sm text-stone-600 leading-relaxed">{{this.t.elevatorDesc}}</p>
      </div>

      {{! 3 — Parking }}
      <div class="group flex flex-col items-center text-center gap-5 rounded-2xl bg-amber-50 border border-amber-100 p-6 shadow-sm hover:-translate-y-1 hover:shadow-md transition-all duration-300">
        <h3 class="font-bold text-amber-800 text-xs sm:text-sm uppercase tracking-wide leading-snug">
          {{this.t.parkingTitle}}
        </h3>
        <div class="h-20 w-20 sm:h-24 sm:w-24 rounded-full bg-amber-600 flex items-center justify-center shadow group-hover:scale-105 transition-transform duration-300">
          <svg class="h-9 w-9 sm:h-11 sm:w-11 text-white" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 18.75a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m3 0h6m-9 0H3.375a1.125 1.125 0 01-1.125-1.125V14.25m17.25 4.5a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m3 0h1.125c.621 0 1.129-.504 1.09-1.124a17.902 17.902 0 00-3.213-9.193 2.056 2.056 0 00-1.58-.86H14.25M16.5 18.75h-2.25m0-11.177v-.958c0-.568-.422-1.048-.987-1.106a48.554 48.554 0 00-10.026 0 1.106 1.106 0 00-.987 1.106v7.635m12-6.677v6.677m0 4.5v-4.5m0 0h-12"/>
          </svg>
        </div>
        <p class="text-xs sm:text-sm text-stone-600 leading-relaxed">{{this.t.parkingDesc}}</p>
      </div>

      {{! 4 — Bride & Groom Rooms }}
      <div class="group flex flex-col items-center text-center gap-5 rounded-2xl bg-amber-50 border border-amber-100 p-6 shadow-sm hover:-translate-y-1 hover:shadow-md transition-all duration-300">
        <h3 class="font-bold text-amber-800 text-xs sm:text-sm uppercase tracking-wide leading-snug">
          {{this.t.roomsTitle}}
        </h3>
        <div class="h-20 w-20 sm:h-24 sm:w-24 rounded-full bg-amber-600 flex items-center justify-center shadow group-hover:scale-105 transition-transform duration-300">
          <svg class="h-9 w-9 sm:h-11 sm:w-11 text-white" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25"/>
          </svg>
        </div>
        <p class="text-xs sm:text-sm text-stone-600 leading-relaxed">{{this.t.roomsDesc}}</p>
      </div>

      {{! 5 — 24-Hour Service }}
      <div class="group flex flex-col items-center text-center gap-5 rounded-2xl bg-amber-50 border border-amber-100 p-6 shadow-sm hover:-translate-y-1 hover:shadow-md transition-all duration-300">
        <h3 class="font-bold text-amber-800 text-xs sm:text-sm uppercase tracking-wide leading-snug">
          {{this.t.serviceTitle}}
        </h3>
        <div class="h-20 w-20 sm:h-24 sm:w-24 rounded-full bg-amber-600 flex items-center justify-center shadow group-hover:scale-105 transition-transform duration-300">
          <svg class="h-9 w-9 sm:h-11 sm:w-11 text-white" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z"/>
          </svg>
        </div>
        <p class="text-xs sm:text-sm text-stone-600 leading-relaxed">{{this.t.serviceDesc}}</p>
      </div>

      {{! 6 — Fire Safety }}
      <div class="group flex flex-col items-center text-center gap-5 rounded-2xl bg-amber-50 border border-amber-100 p-6 shadow-sm hover:-translate-y-1 hover:shadow-md transition-all duration-300">
        <h3 class="font-bold text-amber-800 text-xs sm:text-sm uppercase tracking-wide leading-snug">
          {{this.t.fireTitle}}
        </h3>
        <div class="h-20 w-20 sm:h-24 sm:w-24 rounded-full bg-amber-600 flex items-center justify-center shadow group-hover:scale-105 transition-transform duration-300">
          <svg class="h-9 w-9 sm:h-11 sm:w-11 text-white" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z"/>
          </svg>
        </div>
        <p class="text-xs sm:text-sm text-stone-600 leading-relaxed">{{this.t.fireDesc}}</p>
      </div>

      {{! 7 — Audio Systems }}
      <div class="group flex flex-col items-center text-center gap-5 rounded-2xl bg-amber-50 border border-amber-100 p-6 shadow-sm hover:-translate-y-1 hover:shadow-md transition-all duration-300">
        <h3 class="font-bold text-amber-800 text-xs sm:text-sm uppercase tracking-wide leading-snug">
          {{this.t.audioTitle}}
        </h3>
        <div class="h-20 w-20 sm:h-24 sm:w-24 rounded-full bg-amber-600 flex items-center justify-center shadow group-hover:scale-105 transition-transform duration-300">
          <svg class="h-9 w-9 sm:h-11 sm:w-11 text-white" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" d="M19.114 5.636a9 9 0 010 12.728M16.463 8.288a5.25 5.25 0 010 7.424M6.75 8.25l4.72-4.72a.75.75 0 011.28.53v15.88a.75.75 0 01-1.28.53l-4.72-4.72H4.51c-.88 0-1.704-.507-1.938-1.354A9.01 9.01 0 012.25 12c0-.83.112-1.633.322-2.396C2.806 8.756 3.63 8.25 4.51 8.25H6.75z"/>
          </svg>
        </div>
        <p class="text-xs sm:text-sm text-stone-600 leading-relaxed max-w-xs">{{this.t.audioDesc}}</p>
      </div>

      {{! 8 — Service Standards }}
      <div class="group flex flex-col items-center text-center gap-5 rounded-2xl bg-amber-50 border border-amber-100 p-6 shadow-sm hover:-translate-y-1 hover:shadow-md transition-all duration-300">
        <h3 class="font-bold text-amber-800 text-xs sm:text-sm uppercase tracking-wide leading-snug">
          {{this.t.serviceStdsTitle}}
        </h3>
        <div class="h-20 w-20 sm:h-24 sm:w-24 rounded-full bg-amber-600 flex items-center justify-center shadow group-hover:scale-105 transition-transform duration-300">
          <svg class="h-9 w-9 sm:h-11 sm:w-11 text-white" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z"/>
          </svg>
        </div>
        <p class="text-xs sm:text-sm text-stone-600 leading-relaxed">{{this.t.serviceStdsDesc}}</p>
      </div>

    </div>

    {{! CTA banner }}
    <div class="mt-8 rounded-2xl bg-gradient-to-br from-rose-50 to-white border border-rose-100 px-6 py-8 text-center shadow-sm">
      <h3 class="text-lg font-bold text-stone-900">{{this.t.ctaTitle}}</h3>
      <p class="mt-2 text-sm text-stone-500 max-w-md mx-auto leading-relaxed">{{this.t.ctaDesc}}</p>
      <div class="mt-5 flex flex-wrap items-center justify-center gap-3">
        <LinkTo
          @route="booking"
          class="inline-flex items-center gap-2 rounded-xl bg-rose-700 px-6 py-3 text-sm font-bold text-white shadow-sm hover:bg-rose-800 transition-colors active:scale-[0.97]"
        >
          {{this.t.bookNow}}
          <svg class="h-4 w-4" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3"/>
          </svg>
        </LinkTo>
        <LinkTo
          @route="contact"
          class="inline-flex items-center gap-2 rounded-xl border border-stone-200 bg-white px-6 py-3 text-sm font-semibold text-stone-700 shadow-sm hover:bg-stone-50 transition-colors"
        >
          {{this.t.contactUs}}
        </LinkTo>
      </div>
    </div>
  </template>
}
