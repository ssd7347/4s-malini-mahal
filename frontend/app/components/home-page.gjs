import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { LinkTo } from '@ember/routing';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import MyBookings from 'frontend/components/my-bookings';
import { apiUrl } from 'frontend/utils/api';

const T = {
  en: {
    badge:         'Thiruthangal, Sivakasi',
    heroTitle:     '4S Malini Mahal',
    heroSub:       'A Premier Kalyana Mandapam in Thiruthangal',
    bookNow:       'Book Now',
    checkAvail:    'Check Availability',

    welcomeTitle:  'Welcome to 4S Malini Mahal',
    welcomeBody:   'Located in the heart of Thiruthangal, 4S Malini Mahal is a fully air-conditioned banquet hall designed for weddings, receptions, and all kinds of family celebrations. With space for up to 200 guests across two floors, modern facilities, and transparent pricing — we make your special day truly memorable.',
    capacity:      'Up to 200 Guests',
    capacityNote:  'Floor 1 · 120 guests · Floor 2 · 80 guests',

    eventsTitle:   'Events We Host',
    ev1: 'Marriages',     ev2: 'Receptions',   ev3: 'Engagements',
    ev4: 'Birthdays',     ev5: 'Conferences',  ev6: 'Gatherings',

    amenitiesTitle:'Our Amenities',
    am1: 'AC Hall',           am1d: 'Fully air-conditioned across both floors',
    am2: 'Bride & Groom Rooms', am2d: 'Private, well-furnished AC rooms',
    am3: 'Dining Hall',       am3d: 'Spacious dining area with modern setup',
    am4: 'Stage',             am4d: 'Stage for all occasions — decoration charged separately',
    am5: 'Kitchen',           am5d: 'Full kitchen with gas connection',
    am6: 'Parking',           am6d: 'Ample vehicle parking for all guests',

    pricingTitle:  'Clear, Transparent Pricing',
    pricingNote:   'No hidden charges. What you see is what you pay.',
    p1label: 'Full Day',   p1price: '₹32,000', p1note: 'Day before 3 PM → Next day 2 PM',
    p2label: 'Half Day',   p2price: '₹23,000', p2note: 'Morning or Evening slot',
    p3label: 'Hourly',     p3price: '₹3,000',  p3note: 'Min 2 hrs · Max 4 hrs',

    galleryTitle:  'Gallery',
    viewAll:       'View Full Gallery',

    whyTitle:      'Why Choose Us',
    why1: 'Transparent pricing — no hidden charges or surprises',
    why2: 'Online booking with instant confirmation and Razorpay payment',
    why3: 'Trusted by families across Thiruthangal and Sivakasi',
    why4: 'Flexible slots — full day, half day, or hourly bookings',

    contactTitle:  'Get in Touch',
    whatsappUs:    'WhatsApp us',
    locationShort: 'Virudhunagar Main Rd, Thiruthangal',
    viewContact:   'View full contact page',

    stat1n: '200+',   stat1l: 'Guests Capacity',
    stat2n: '2',      stat2l: 'Floors',
    stat3n: '22',     stat3l: 'Months of Service',
    stat4n: '6',      stat4l: 'Amenities',

    aboutLabel: 'The Venue',
    aboutTitle: 'Your Perfect Celebration Space',
    aboutP1: '4S Malini Mahal is a premier kalyana mandapam in Thiruthangal, thoughtfully designed to make every celebration truly memorable. With a spacious hall spread across two floors and fully air-conditioned throughout, our venue comfortably accommodates up to 200 guests — perfect for weddings, receptions, engagements, and all family celebrations.',
    aboutP2: 'We take pride in providing everything a family needs under one roof — a beautifully decorated stage, private air-conditioned rooms for the bride and groom, a fully equipped kitchen with gas connections, a spacious dining area, and ample vehicle parking. Every detail is thoughtfully managed so you can focus entirely on your celebration.',
    aboutH1: '100% Air Conditioned',
    aboutH2: 'Dedicated Stage Available',
    aboutH3: 'Online Booking Available',
    aboutH4: 'Transparent, Fixed Pricing',

    capTitle: 'Comfortable Space for Every Gathering',
    capSub:   'Two floors, one complete celebration experience',
    cap1n: '200', cap1l: 'Total Capacity', cap1d: 'Combined across both floors',
    cap2n: '120', cap2l: 'Floor 1',        cap2d: 'Ground floor main hall',
    cap3n: '80',  cap3l: 'Floor 2',        cap3d: 'Upper floor seating',
    cap4n: '2+',  cap4l: 'Private Rooms',  cap4d: 'Bride and groom AC rooms',

    testimonialsTitle: 'Trusted by Families',
    t1q: 'A beautiful, well-maintained hall that made our wedding truly special. The AC halls are excellent and the stage was wonderfully decorated.',
    t1i: 'KF', t1n: 'Kumar Family',    t1l: 'Thiruthangal',
    t2q: 'Booking online was so easy. Clear pricing with no hidden charges at all. Highly recommend to anyone planning a function.',
    t2i: 'PS', t2n: 'Priya S.',        t2l: 'Sivakasi',
    t3q: 'The bride and groom rooms are well-furnished and spacious. The staff was very helpful and cooperative throughout our event.',
    t3i: 'AF', t3n: 'Anandan Family',  t3l: 'Virudhunagar',

    locationLabel:  'Location',
    locationTitle:  'Find Us in Thiruthangal',
    locationAddr1:  '4S Malini Mahal',
    locationAddr2:  'Virudhunagar Main Road',
    locationAddr3:  'Thiruthangal — 626 130',
    locationNearby: 'Near Thiruthangal Bus Stand, Virudhunagar District',
    locationGetDir: 'Get Directions',
  },
  ta: {
    badge:         'திருத்தங்கல், சிவகாசி',
    heroTitle:     '4S மாலினி மகால்',
    heroSub:       'திருத்தங்கலில் சிறந்த கல்யாண மண்டபம்',
    bookNow:       'இப்போது பதிவிடுங்கள்',
    checkAvail:    'தேதி கிடைப்பை சரிபார்க்கவும்',

    welcomeTitle:  '4S மாலினி மகால்க்கு வரவேற்கிறோம்',
    welcomeBody:   'திருத்தங்கல் மையத்தில் அமைந்த 4S மாலினி மகால், திருமணங்கள், வரவேற்புகள் மற்றும் குடும்ப விழாக்களுக்காக முழுவதும் ஏர்கண்டிஷன் வசதியுடன் அமைக்கப்பட்ட விழா மண்டபம். இரண்டு தளங்களில் 200 விருந்தினர்கள் வரை அமரலாம்.',
    capacity:      '200 விருந்தினர்கள் வரை',
    capacityNote:  'தளம் 1 · 120 பேர் · தளம் 2 · 80 பேர்',

    eventsTitle:   'நாங்கள் நடத்தும் நிகழ்வுகள்',
    ev1: 'திருமணம்',   ev2: 'வரவேற்பு',    ev3: 'நிச்சயதார்த்தம்',
    ev4: 'பிறந்தநாள்', ev5: 'மாநாடு',     ev6: 'சிறு கூட்டங்கள்',

    amenitiesTitle:'எங்கள் வசதிகள்',
    am1: 'AC மண்டபம்',         am1d: 'இரண்டு தளங்களிலும் முழு ஏர்கண்டிஷன்',
    am2: 'மணமகள் & மணமகன் அறை', am2d: 'தனியான, நவீன AC அறைகள்',
    am3: 'சாப்பாட்டு மண்டபம்',  am3d: 'நவீன வசதியுடன் கூடிய பரந்த சாப்பாட்டு அறை',
    am4: 'மேடை',               am4d: 'அனைத்து நிகழ்வுகளுக்கும் மேடை — அலங்காரம் தனியாக கட்டணம்',
    am5: 'சமையலறை',            am5d: 'கேஸ் இணைப்புடன் கூடிய முழு சமையலறை',
    am6: 'வாகன நிறுத்துமிடம்',  am6d: 'விருந்தினர்களுக்கு போதுமான இடவசதி',

    pricingTitle:  'தெளிவான, வெளிப்படையான கட்டணம்',
    pricingNote:   'மறைமுக கட்டணங்கள் இல்லை. நீங்கள் பார்ப்பதே நீங்கள் செலுத்துவது.',
    p1label: 'முழு நாள்',  p1price: '₹32,000', p1note: 'முந்தைய நாள் 3 மணி → மறுநாள் 2 மணி',
    p2label: 'அரை நாள்',  p2price: '₹23,000', p2note: 'காலை அல்லது மாலை நேரம்',
    p3label: 'மணிநேரம்',  p3price: '₹3,000',  p3note: 'குறைந்தது 2 மணி · அதிகபட்சம் 4 மணி',

    galleryTitle:  'படங்கள்',
    viewAll:       'முழு கேலரி பார்க்கவும்',

    whyTitle:      'எங்களை ஏன் தேர்வு செய்ய வேண்டும்',
    why1: 'வெளிப்படையான கட்டணம் — மறைமுக கட்டணங்களோ அதிர்ச்சிகளோ இல்லை',
    why2: 'ஆன்லைன் பதிவு, உடனடி உறுதிப்படுத்தல் மற்றும் Razorpay கட்டணம்',
    why3: 'திருத்தங்கல் மற்றும் சிவகாசி குடும்பங்களால் நம்பப்படுகிறது',
    why4: 'நெகிழ்வான நேர இடைவெளிகள் — முழு நாள், அரை நாள் அல்லது மணிநேரம்',

    contactTitle:  'தொடர்பு கொள்ளுங்கள்',
    whatsappUs:    'WhatsApp-ல் தொடர்பு கொள்ளுங்கள்',
    locationShort: 'விருதுநகர் பிரதான சாலை, திருத்தங்கல்',
    viewContact:   'தொடர்பு பக்கம்',

    stat1n: '200+',   stat1l: 'விருந்தினர்கள் கொள்ளளவு',
    stat2n: '2',      stat2l: 'தளங்கள்',
    stat3n: '22',     stat3l: 'மாதங்கள் சேவை',
    stat4n: '6',      stat4l: 'வசதிகள்',

    aboutLabel: 'விழா மண்டபம்',
    aboutTitle: 'உங்கள் சிறந்த விழா இடம்',
    aboutP1: '4S மாலினி மகால் ஒரு சாதாரண மண்டபம் மட்டுமல்ல — தமிழ் குடும்பங்களுக்காக சிந்தனையுடன் வடிவமைக்கப்பட்ட முழுமையான விழா இடம். இரண்டு தளங்களில் 200 விருந்தினர்களை அமர்த்தும் வசதியுடன், முழுவதும் ஏர்கண்டிஷன், அழகிய மேடை மற்றும் மணமகள் மணமகன் அறைகளுடன் திருமணங்கள், நிச்சயதார்த்தங்கள் மற்றும் குடும்ப விழாக்களுக்கு மிகவும் ஏற்றது.',
    aboutP2: 'ஒரே கூரையின் கீழ் குடும்பத்திற்கு தேவையான அனைத்தையும் வழங்குவதில் நாங்கள் பெருமிதப்படுகிறோம் — அழகிய மேடை, கேஸ் இணைப்புடன் கூடிய முழு சமையலறை, பரந்த சாப்பாட்டு மண்டபம் மற்றும் வாகன நிறுத்துமிடம். நீங்கள் உங்கள் விழாவில் மட்டும் கவனம் செலுத்துவதற்காக ஒவ்வொரு விவரமும் கவனமாக திட்டமிடப்பட்டுள்ளது.',
    aboutH1: '100% ஏர்கண்டிஷன்',
    aboutH2: 'மேடை வசதி உள்ளது',
    aboutH3: 'ஆன்லைன் பதிவு',
    aboutH4: 'வெளிப்படையான கட்டணம்',

    capTitle: 'உங்கள் கூட்டத்திற்கு ஏற்ற இடவசதி',
    capSub:   'இரண்டு தளங்கள், ஒரு முழுமையான விழா அனுபவம்',
    cap1n: '200', cap1l: 'மொத்த கொள்ளளவு', cap1d: 'இரண்டு தளங்களிலும் சேர்த்து',
    cap2n: '120', cap2l: 'தளம் 1 (கீழ்)',   cap2d: 'கீழ் தள மண்டபம்',
    cap3n: '80',  cap3l: 'தளம் 2 (மேல்)',   cap3d: 'மேல் தள கூடுதல் இடம்',
    cap4n: '2+',  cap4l: 'தனி அறைகள்',      cap4d: 'மணமகள் & மணமகன் AC அறைகள்',

    testimonialsTitle: 'விருந்தினர்கள் கருத்துகள்',
    t1q: 'அழகான, நன்றாக பராமரிக்கப்படும் மண்டபம். எங்கள் திருமணத்தை மிகவும் சிறப்பாக ஆக்கியது. AC மண்டபம் மற்றும் மேடை அலங்காரம் மிகவும் சிறந்தது.',
    t1i: 'KF', t1n: 'குமார் குடும்பம்',    t1l: 'திருத்தங்கல்',
    t2q: 'ஆன்லைன் பதிவு மிகவும் எளிதாக இருந்தது. தெளிவான கட்டணம், மறைமுக கட்டணங்கள் இல்லை. விழா திட்டமிடுவோருக்கு மிகவும் பரிந்துரைக்கிறோம்.',
    t2i: 'PS', t2n: 'பிரியா. ச',           t2l: 'சிவகாசி',
    t3q: 'மணமகள் மணமகன் அறைகள் மிகவும் அழகாக இருந்தன. ஊழியர்கள் மிகவும் உதவிகரமாக இருந்தனர். சமையலறை வசதிகளும் சிறந்தவை.',
    t3i: 'AF', t3n: 'ஆனந்தன் குடும்பம்',  t3l: 'விருதுநகர்',

    locationLabel:  'இருப்பிடம்',
    locationTitle:  'எங்களை கண்டறியுங்கள்',
    locationAddr1:  '4S மாலினி மகால்',
    locationAddr2:  'விருதுநகர் பிரதான சாலை',
    locationAddr3:  'திருத்தங்கல் — 626 130',
    locationNearby: 'திருத்தங்கல் பேருந்து நிலையம் அருகில்',
    locationGetDir: 'வழி காட்டுங்கள்',
  },
};

const DIVIDER = `<svg viewBox="0 0 1440 40" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="none" class="w-full h-8 -mb-1"><path d="M0,20 C360,40 1080,0 1440,20 L1440,40 L0,40 Z" fill="currentColor"/></svg>`;

export default class HomePage extends Component {
  @service auth;
  @service language;

  @tracked _galleryItems = [];
  @tracked lightboxIndex = null;

  constructor(owner, args) {
    super(owner, args);
    this._handleKey = (e) => {
      if (this.lightboxIndex === null) return;
      if (e.key === 'ArrowLeft')  this.prevImage();
      else if (e.key === 'ArrowRight') this.nextImage();
      else if (e.key === 'Escape') this.closeLightbox();
    };
    this.loadGallery();
  }

  get lightboxCount() { return Math.min(this._galleryItems.length, 6); }
  get lightboxSrc()   { return this.lightboxIndex !== null ? this._imgSrc(this.lightboxIndex) : null; }
  get lightboxPos()   { return this.lightboxIndex !== null ? this.lightboxIndex + 1 : 0; }

  @action openLightbox(index) {
    this.lightboxIndex = index;
    document.removeEventListener('keydown', this._handleKey);
    document.addEventListener('keydown', this._handleKey);
  }
  @action closeLightbox() {
    this.lightboxIndex = null;
    document.removeEventListener('keydown', this._handleKey);
  }
  @action prevImage() {
    this.lightboxIndex = (this.lightboxIndex - 1 + this.lightboxCount) % this.lightboxCount;
  }
  @action nextImage() {
    this.lightboxIndex = (this.lightboxIndex + 1) % this.lightboxCount;
  }
  @action preventClose(e) { e.stopPropagation(); }

  async loadGallery() {
    try {
      const res = await fetch(apiUrl('/api/gallery'));
      if (res.ok) {
        const data = await res.json();
        this._galleryItems = data.filter(i => i.mediaType === 'IMAGE' && i.filename);
      }
    } catch (_) {}
  }

  get t()         { return T[this.language.lang]; }
  _imgSrc(idx)    { const it = this._galleryItems[idx]; return it ? apiUrl('/api/media/' + it.filename) : null; }
  get heroImage() { return this._imgSrc(0); }
  get gi0()       { return this._imgSrc(0); }
  get gi1()       { return this._imgSrc(1); }
  get gi2()       { return this._imgSrc(2); }
  get gi3()       { return this._imgSrc(3); }
  get gi4()       { return this._imgSrc(4); }
  get gi5()       { return this._imgSrc(5); }
  get hasGallery(){ return this._galleryItems.length >= 3; }

  <template>
    <div class="animate-slide-up">

      {{! ── HERO ── }}
      <div class="relative rounded-2xl overflow-hidden mb-8" style="min-height: 360px;">
        {{#if this.heroImage}}
          <img src={{this.heroImage}} alt="4S Malini Mahal" class="absolute inset-0 w-full h-full object-cover" />
          <div class="absolute inset-0 bg-gradient-to-b from-black/50 via-black/40 to-black/60"></div>
        {{else}}
          <div class="absolute inset-0 bg-gradient-to-br from-rose-900 via-rose-800 to-stone-900"></div>
        {{/if}}

        <div class="relative flex flex-col items-center justify-center text-center px-6 py-20 sm:py-28">
          <div class="inline-flex items-center gap-2 rounded-full border border-white/30 bg-white/10 backdrop-blur-sm px-4 py-1.5 text-sm font-medium text-white/90 mb-4">
            <span class="h-2 w-2 rounded-full bg-rose-400 shrink-0"></span>
            {{this.t.badge}}
          </div>
          <h1 class="text-4xl sm:text-6xl font-bold text-white leading-tight tracking-tight drop-shadow-lg">
            {{this.t.heroTitle}}
          </h1>
          <p class="mt-3 text-white/80 text-base sm:text-lg font-medium drop-shadow">
            {{this.t.heroSub}}
          </p>
          <div class="mt-8 flex flex-wrap items-center justify-center gap-3">
            <LinkTo @route="booking"
              class="inline-flex items-center gap-2 rounded-xl bg-rose-600 hover:bg-rose-700 px-7 py-3 text-sm font-bold text-white shadow-lg transition-colors active:scale-[0.97]">
              {{this.t.bookNow}}
              <svg class="h-4 w-4" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3"/></svg>
            </LinkTo>
            <LinkTo @route="availability"
              class="inline-flex items-center gap-2 rounded-xl border border-white/40 bg-white/10 backdrop-blur-sm hover:bg-white/20 px-6 py-3 text-sm font-semibold text-white transition-colors">
              {{this.t.checkAvail}}
            </LinkTo>
          </div>
        </div>
      </div>

      {{! ── STATS BANNER ── }}
      <section class="mb-10 grid grid-cols-2 sm:grid-cols-4 gap-4">
        <div class="rounded-2xl bg-rose-50 border border-rose-100 p-5 text-center shadow-sm">
          <p class="text-3xl sm:text-4xl font-extrabold text-rose-700">{{this.t.stat1n}}</p>
          <p class="mt-1 text-xs font-semibold text-rose-500 uppercase tracking-wide">{{this.t.stat1l}}</p>
        </div>
        <div class="rounded-2xl bg-amber-50 border border-amber-100 p-5 text-center shadow-sm">
          <p class="text-3xl sm:text-4xl font-extrabold text-amber-700">{{this.t.stat2n}}</p>
          <p class="mt-1 text-xs font-semibold text-amber-500 uppercase tracking-wide">{{this.t.stat2l}}</p>
        </div>
        <div class="rounded-2xl bg-green-50 border border-green-100 p-5 text-center shadow-sm">
          <p class="text-3xl sm:text-4xl font-extrabold text-green-700">{{this.t.stat3n}}</p>
          <p class="mt-1 text-xs font-semibold text-green-500 uppercase tracking-wide">{{this.t.stat3l}}</p>
        </div>
        <div class="rounded-2xl bg-purple-50 border border-purple-100 p-5 text-center shadow-sm">
          <p class="text-3xl sm:text-4xl font-extrabold text-purple-700">{{this.t.stat4n}}</p>
          <p class="mt-1 text-xs font-semibold text-purple-500 uppercase tracking-wide">{{this.t.stat4l}}</p>
        </div>
      </section>

      {{! Your Bookings — shown only when logged in }}
      {{#if this.auth.isLoggedIn}}
        <div class="mb-8">
          <MyBookings />
        </div>
      {{/if}}

      {{! ── WELCOME ── }}
      <section class="mb-12 grid md:grid-cols-2 gap-8 items-center">
        <div>
          <p class="text-xs font-bold uppercase tracking-widest text-rose-600 mb-2">About Us</p>
          <h2 class="text-2xl sm:text-3xl font-bold text-stone-900 leading-snug mb-4">{{this.t.welcomeTitle}}</h2>
          <p class="text-stone-500 leading-relaxed mb-6">{{this.t.welcomeBody}}</p>
          <div class="flex items-center gap-4 p-4 rounded-xl bg-rose-50 border border-rose-100">
            <div class="h-12 w-12 rounded-full bg-rose-100 flex items-center justify-center shrink-0">
              <svg class="h-6 w-6 text-rose-700" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z"/>
              </svg>
            </div>
            <div>
              <p class="font-bold text-rose-800 text-lg">{{this.t.capacity}}</p>
              <p class="text-sm text-rose-600">{{this.t.capacityNote}}</p>
            </div>
          </div>
        </div>
        <div class="rounded-2xl overflow-hidden shadow-lg aspect-video bg-stone-200">
          {{#if this.heroImage}}
            <img src={{this.heroImage}} alt="Malini Mahal Hall" class="w-full h-full object-cover" />
          {{else}}
            <div class="w-full h-full bg-gradient-to-br from-rose-100 to-stone-200 flex items-center justify-center">
              <svg class="h-16 w-16 text-stone-300" fill="none" stroke="currentColor" stroke-width="1" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159 5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 001.5-1.5V6a1.5 1.5 0 00-1.5-1.5H3.75A1.5 1.5 0 002.25 6v12a1.5 1.5 0 001.5 1.5zm10.5-11.25h.008v.008h-.008V8.25zm.375 0a.375.375 0 11-.75 0 .375.375 0 01.75 0z"/>
              </svg>
            </div>
          {{/if}}
        </div>
      </section>

      {{! ── ABOUT THE VENUE ── }}
      <section class="mb-12">
        <div class="rounded-2xl overflow-hidden border border-stone-200 shadow-sm">
          <div class="grid md:grid-cols-2">

            <div class="p-8 flex flex-col justify-center">
              <p class="text-xs font-bold uppercase tracking-widest text-rose-600 mb-2">{{this.t.aboutLabel}}</p>
              <h2 class="text-2xl sm:text-3xl font-bold text-stone-900 leading-snug mb-4">{{this.t.aboutTitle}}</h2>
              <p class="text-stone-500 leading-relaxed mb-4">{{this.t.aboutP1}}</p>
              <p class="text-stone-500 leading-relaxed mb-6">{{this.t.aboutP2}}</p>
              <div class="grid grid-cols-2 gap-3">
                <div class="flex items-center gap-2 text-sm text-stone-700">
                  <svg class="h-4 w-4 text-rose-500 shrink-0" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                  {{this.t.aboutH1}}
                </div>
                <div class="flex items-center gap-2 text-sm text-stone-700">
                  <svg class="h-4 w-4 text-rose-500 shrink-0" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                  {{this.t.aboutH2}}
                </div>
                <div class="flex items-center gap-2 text-sm text-stone-700">
                  <svg class="h-4 w-4 text-rose-500 shrink-0" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                  {{this.t.aboutH3}}
                </div>
                <div class="flex items-center gap-2 text-sm text-stone-700">
                  <svg class="h-4 w-4 text-rose-500 shrink-0" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                  {{this.t.aboutH4}}
                </div>
              </div>
            </div>

            <div class="bg-rose-100 min-h-64 relative">
              {{#if this.gi1}}
                <img src={{this.gi1}} alt="Malini Mahal Interior" class="w-full h-full object-cover absolute inset-0" />
              {{else}}
                <div class="absolute inset-0 flex flex-col items-center justify-center p-8 text-center">
                  <svg class="h-20 w-20 text-rose-300 mb-4" fill="none" stroke="currentColor" stroke-width="0.8" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159 5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 001.5-1.5V6a1.5 1.5 0 00-1.5-1.5H3.75A1.5 1.5 0 002.25 6v12a1.5 1.5 0 001.5 1.5zm10.5-11.25h.008v.008h-.008V8.25zm.375 0a.375.375 0 11-.75 0 .375.375 0 01.75 0z"/>
                  </svg>
                  <p class="text-rose-400 font-semibold">4S Malini Mahal</p>
                </div>
              {{/if}}
            </div>

          </div>
        </div>
      </section>

      {{! ── EVENTS WE HOST ── }}
      <section class="mb-12">
        <div class="text-center mb-6">
          <p class="text-xs font-bold uppercase tracking-widest text-rose-600 mb-1">Occasions</p>
          <h2 class="text-2xl sm:text-3xl font-bold text-stone-900">{{this.t.eventsTitle}}</h2>
        </div>
        <div class="grid grid-cols-2 sm:grid-cols-3 gap-4">

          <div class="rounded-xl border border-stone-200 bg-white p-5 text-center shadow-sm hover:shadow-md hover:border-rose-200 transition-all">
            <div class="h-12 w-12 rounded-full bg-rose-50 flex items-center justify-center mx-auto mb-3">
              <svg class="h-6 w-6 text-rose-600" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z"/>
              </svg>
            </div>
            <p class="font-semibold text-stone-800">{{this.t.ev1}}</p>
          </div>

          <div class="rounded-xl border border-stone-200 bg-white p-5 text-center shadow-sm hover:shadow-md hover:border-rose-200 transition-all">
            <div class="h-12 w-12 rounded-full bg-amber-50 flex items-center justify-center mx-auto mb-3">
              <svg class="h-6 w-6 text-amber-600" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09z"/>
              </svg>
            </div>
            <p class="font-semibold text-stone-800">{{this.t.ev2}}</p>
          </div>

          <div class="rounded-xl border border-stone-200 bg-white p-5 text-center shadow-sm hover:shadow-md hover:border-rose-200 transition-all">
            <div class="h-12 w-12 rounded-full bg-pink-50 flex items-center justify-center mx-auto mb-3">
              <svg class="h-6 w-6 text-pink-600" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z"/>
              </svg>
            </div>
            <p class="font-semibold text-stone-800">{{this.t.ev3}}</p>
          </div>

          <div class="rounded-xl border border-stone-200 bg-white p-5 text-center shadow-sm hover:shadow-md hover:border-rose-200 transition-all">
            <div class="h-12 w-12 rounded-full bg-yellow-50 flex items-center justify-center mx-auto mb-3">
              <svg class="h-6 w-6 text-yellow-600" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z"/>
              </svg>
            </div>
            <p class="font-semibold text-stone-800">{{this.t.ev4}}</p>
          </div>

          <div class="rounded-xl border border-stone-200 bg-white p-5 text-center shadow-sm hover:shadow-md hover:border-rose-200 transition-all">
            <div class="h-12 w-12 rounded-full bg-blue-50 flex items-center justify-center mx-auto mb-3">
              <svg class="h-6 w-6 text-blue-600" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 3v11.25A2.25 2.25 0 006 16.5h2.25M3.75 3h-1.5m1.5 0h16.5m0 0h1.5m-1.5 0v11.25A2.25 2.25 0 0118 16.5h-2.25m-7.5 0h7.5m-7.5 0l-1 3m8.5-3l1 3m0 0l.5 1.5m-.5-1.5h-9.5m0 0l-.5 1.5M9 11.25v1.5M12 9v3.75m3-6v6"/>
              </svg>
            </div>
            <p class="font-semibold text-stone-800">{{this.t.ev5}}</p>
          </div>

          <div class="rounded-xl border border-stone-200 bg-white p-5 text-center shadow-sm hover:shadow-md hover:border-rose-200 transition-all">
            <div class="h-12 w-12 rounded-full bg-green-50 flex items-center justify-center mx-auto mb-3">
              <svg class="h-6 w-6 text-green-600" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M18 18.72a9.094 9.094 0 003.741-.479 3 3 0 00-4.682-2.72m.94 3.198l.001.031c0 .225-.012.447-.037.666A11.944 11.944 0 0112 21c-2.17 0-4.207-.576-5.963-1.584A6.062 6.062 0 016 18.719m12 0a5.971 5.971 0 00-.941-3.197m0 0A5.995 5.995 0 0012 12.75a5.995 5.995 0 00-5.058 2.772m0 0a3 3 0 00-4.681 2.72 8.986 8.986 0 003.74.477m.94-3.197a5.971 5.971 0 00-.94 3.197M15 6.75a3 3 0 11-6 0 3 3 0 016 0zm6 3a2.25 2.25 0 11-4.5 0 2.25 2.25 0 014.5 0zm-13.5 0a2.25 2.25 0 11-4.5 0 2.25 2.25 0 014.5 0z"/>
              </svg>
            </div>
            <p class="font-semibold text-stone-800">{{this.t.ev6}}</p>
          </div>

        </div>
      </section>

      {{! ── CAPACITY & SPACE ── }}
      <section class="mb-12">
        <div class="text-center mb-6">
          <p class="text-xs font-bold uppercase tracking-widest text-rose-600 mb-1">Space</p>
          <h2 class="text-2xl sm:text-3xl font-bold text-stone-900">{{this.t.capTitle}}</h2>
          <p class="mt-1 text-sm text-stone-400">{{this.t.capSub}}</p>
        </div>
        <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
          <div class="rounded-2xl border-2 border-rose-200 bg-rose-50 p-6 text-center shadow-sm">
            <p class="text-4xl font-extrabold text-rose-700 mb-1">{{this.t.cap1n}}</p>
            <p class="font-semibold text-stone-800 text-sm">{{this.t.cap1l}}</p>
            <p class="text-xs text-stone-400 mt-1">{{this.t.cap1d}}</p>
          </div>
          <div class="rounded-2xl border border-stone-200 bg-white p-6 text-center shadow-sm">
            <p class="text-4xl font-extrabold text-stone-700 mb-1">{{this.t.cap2n}}</p>
            <p class="font-semibold text-stone-700 text-sm">{{this.t.cap2l}}</p>
            <p class="text-xs text-stone-400 mt-1">{{this.t.cap2d}}</p>
          </div>
          <div class="rounded-2xl border border-stone-200 bg-white p-6 text-center shadow-sm">
            <p class="text-4xl font-extrabold text-stone-700 mb-1">{{this.t.cap3n}}</p>
            <p class="font-semibold text-stone-700 text-sm">{{this.t.cap3l}}</p>
            <p class="text-xs text-stone-400 mt-1">{{this.t.cap3d}}</p>
          </div>
          <div class="rounded-2xl border border-stone-200 bg-white p-6 text-center shadow-sm">
            <p class="text-4xl font-extrabold text-stone-700 mb-1">{{this.t.cap4n}}</p>
            <p class="font-semibold text-stone-700 text-sm">{{this.t.cap4l}}</p>
            <p class="text-xs text-stone-400 mt-1">{{this.t.cap4d}}</p>
          </div>
        </div>
      </section>

      {{! ── AMENITIES ── }}
      <section class="mb-12">
        <div class="text-center mb-6">
          <p class="text-xs font-bold uppercase tracking-widest text-rose-600 mb-1">Facilities</p>
          <h2 class="text-2xl sm:text-3xl font-bold text-stone-900">{{this.t.amenitiesTitle}}</h2>
        </div>
        <div class="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">

          <div class="flex items-center gap-4 rounded-2xl border border-stone-200 bg-white p-5 shadow-sm hover:shadow-md hover:border-rose-200 transition-all">
            <div class="h-12 w-12 rounded-xl bg-rose-100 flex items-center justify-center shrink-0">
              <svg class="h-6 w-6 text-rose-700" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 3v2.25m6.364.386l-1.591 1.591M21 12h-2.25m-.386 6.364l-1.591-1.591M12 18.75V21m-4.773-4.227l-1.591 1.591M5.25 12H3m4.227-4.773L5.636 5.636M15.75 12a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0z"/>
              </svg>
            </div>
            <div><p class="font-semibold text-stone-800">{{this.t.am1}}</p><p class="text-sm text-stone-500 mt-0.5">{{this.t.am1d}}</p></div>
          </div>

          <div class="flex items-center gap-4 rounded-2xl border border-stone-200 bg-white p-5 shadow-sm hover:shadow-md hover:border-rose-200 transition-all">
            <div class="h-12 w-12 rounded-xl bg-pink-100 flex items-center justify-center shrink-0">
              <svg class="h-6 w-6 text-pink-700" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25"/>
              </svg>
            </div>
            <div><p class="font-semibold text-stone-800">{{this.t.am2}}</p><p class="text-sm text-stone-500 mt-0.5">{{this.t.am2d}}</p></div>
          </div>

          <div class="flex items-center gap-4 rounded-2xl border border-stone-200 bg-white p-5 shadow-sm hover:shadow-md hover:border-rose-200 transition-all">
            <div class="h-12 w-12 rounded-xl bg-amber-100 flex items-center justify-center shrink-0">
              <svg class="h-6 w-6 text-amber-700" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 3v11.25A2.25 2.25 0 006 16.5h2.25M3.75 3h-1.5m1.5 0h16.5m0 0h1.5m-1.5 0v11.25A2.25 2.25 0 0118 16.5h-2.25m-7.5 0h7.5"/>
              </svg>
            </div>
            <div><p class="font-semibold text-stone-800">{{this.t.am3}}</p><p class="text-sm text-stone-500 mt-0.5">{{this.t.am3d}}</p></div>
          </div>

          <div class="flex items-center gap-4 rounded-2xl border border-stone-200 bg-white p-5 shadow-sm hover:shadow-md hover:border-rose-200 transition-all">
            <div class="h-12 w-12 rounded-xl bg-purple-100 flex items-center justify-center shrink-0">
              <svg class="h-6 w-6 text-purple-700" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09z"/>
              </svg>
            </div>
            <div><p class="font-semibold text-stone-800">{{this.t.am4}}</p><p class="text-sm text-stone-500 mt-0.5">{{this.t.am4d}}</p></div>
          </div>

          <div class="flex items-center gap-4 rounded-2xl border border-stone-200 bg-white p-5 shadow-sm hover:shadow-md hover:border-rose-200 transition-all">
            <div class="h-12 w-12 rounded-xl bg-orange-100 flex items-center justify-center shrink-0">
              <svg class="h-6 w-6 text-orange-700" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15.362 5.214A8.252 8.252 0 0112 21 8.25 8.25 0 016.038 7.048 8.287 8.287 0 009 9.6a8.983 8.983 0 013.361-6.867 8.21 8.21 0 003 2.48z"/>
              </svg>
            </div>
            <div><p class="font-semibold text-stone-800">{{this.t.am5}}</p><p class="text-sm text-stone-500 mt-0.5">{{this.t.am5d}}</p></div>
          </div>

          <div class="flex items-center gap-4 rounded-2xl border border-stone-200 bg-white p-5 shadow-sm hover:shadow-md hover:border-rose-200 transition-all">
            <div class="h-12 w-12 rounded-xl bg-blue-100 flex items-center justify-center shrink-0">
              <svg class="h-6 w-6 text-blue-700" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 18.75a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m3 0h6m-9 0H3.375a1.125 1.125 0 01-1.125-1.125V14.25m17.25 4.5a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m3 0h1.125c.621 0 1.129-.504 1.09-1.124a17.902 17.902 0 00-3.213-9.193 2.056 2.056 0 00-1.58-.86H14.25M16.5 18.75h-2.25m0-11.177v-.958c0-.568-.422-1.048-.987-1.106a48.554 48.554 0 00-10.026 0 1.106 1.106 0 00-.987 1.106v7.635m12-6.677v6.677m0 4.5v-4.5m0 0h-12"/>
              </svg>
            </div>
            <div><p class="font-semibold text-stone-800">{{this.t.am6}}</p><p class="text-sm text-stone-500 mt-0.5">{{this.t.am6d}}</p></div>
          </div>

        </div>
      </section>

      {{! ── PRICING ── }}
      <section class="mb-12">
        <div class="text-center mb-6">
          <p class="text-xs font-bold uppercase tracking-widest text-rose-600 mb-1">Pricing</p>
          <h2 class="text-2xl sm:text-3xl font-bold text-stone-900">{{this.t.pricingTitle}}</h2>
          <p class="mt-1 text-sm text-stone-400">{{this.t.pricingNote}}</p>
        </div>
        <div class="grid sm:grid-cols-3 gap-4">

          <div class="rounded-2xl border-2 border-rose-200 bg-rose-50 p-6 text-center shadow-sm">
            <p class="text-xs font-bold uppercase tracking-widest text-rose-500 mb-2">{{this.t.p1label}}</p>
            <p class="text-4xl font-extrabold text-rose-700 mb-1">{{this.t.p1price}}</p>
            <p class="text-xs text-rose-500">{{this.t.p1note}}</p>
            <LinkTo @route="booking" class="mt-4 block rounded-lg bg-rose-700 py-2 text-sm font-bold text-white hover:bg-rose-800 transition-colors">
              {{this.t.bookNow}}
            </LinkTo>
          </div>

          <div class="rounded-2xl border-2 border-stone-200 bg-white p-6 text-center shadow-sm">
            <p class="text-xs font-bold uppercase tracking-widest text-stone-500 mb-2">{{this.t.p2label}}</p>
            <p class="text-4xl font-extrabold text-stone-800 mb-1">{{this.t.p2price}}</p>
            <p class="text-xs text-stone-400">{{this.t.p2note}}</p>
            <LinkTo @route="booking" class="mt-4 block rounded-lg border border-stone-200 py-2 text-sm font-bold text-stone-700 hover:bg-stone-50 transition-colors">
              {{this.t.bookNow}}
            </LinkTo>
          </div>

          <div class="rounded-2xl border-2 border-stone-200 bg-white p-6 text-center shadow-sm">
            <p class="text-xs font-bold uppercase tracking-widest text-stone-500 mb-2">{{this.t.p3label}}</p>
            <p class="text-4xl font-extrabold text-stone-800 mb-1">{{this.t.p3price}}</p>
            <p class="text-xs text-stone-400">{{this.t.p3note}}</p>
            <LinkTo @route="booking" class="mt-4 block rounded-lg border border-stone-200 py-2 text-sm font-bold text-stone-700 hover:bg-stone-50 transition-colors">
              {{this.t.bookNow}}
            </LinkTo>
          </div>

        </div>
      </section>

      {{! ── TESTIMONIALS ── }}
      <section class="mb-12">
        <div class="text-center mb-6">
          <p class="text-xs font-bold uppercase tracking-widest text-rose-600 mb-1">Reviews</p>
          <h2 class="text-2xl sm:text-3xl font-bold text-stone-900">{{this.t.testimonialsTitle}}</h2>
        </div>
        <div class="grid sm:grid-cols-3 gap-4">

          <div class="rounded-2xl border border-stone-200 bg-white p-6 shadow-sm flex flex-col">
            <div class="flex gap-0.5 mb-3">
              <svg class="h-4 w-4 text-amber-400" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
              <svg class="h-4 w-4 text-amber-400" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
              <svg class="h-4 w-4 text-amber-400" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
              <svg class="h-4 w-4 text-amber-400" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
              <svg class="h-4 w-4 text-amber-400" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
            </div>
            <p class="text-stone-600 text-sm leading-relaxed mb-4 grow">{{this.t.t1q}}</p>
            <div class="flex items-center gap-3 mt-auto pt-3 border-t border-stone-100">
              <div class="h-9 w-9 rounded-full bg-rose-100 flex items-center justify-center shrink-0">
                <span class="text-xs font-bold text-rose-700">{{this.t.t1i}}</span>
              </div>
              <div>
                <p class="font-semibold text-stone-800 text-sm">{{this.t.t1n}}</p>
                <p class="text-xs text-stone-400">{{this.t.t1l}}</p>
              </div>
            </div>
          </div>

          <div class="rounded-2xl border border-stone-200 bg-white p-6 shadow-sm flex flex-col">
            <div class="flex gap-0.5 mb-3">
              <svg class="h-4 w-4 text-amber-400" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
              <svg class="h-4 w-4 text-amber-400" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
              <svg class="h-4 w-4 text-amber-400" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
              <svg class="h-4 w-4 text-amber-400" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
              <svg class="h-4 w-4 text-amber-400" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
            </div>
            <p class="text-stone-600 text-sm leading-relaxed mb-4 grow">{{this.t.t2q}}</p>
            <div class="flex items-center gap-3 mt-auto pt-3 border-t border-stone-100">
              <div class="h-9 w-9 rounded-full bg-amber-100 flex items-center justify-center shrink-0">
                <span class="text-xs font-bold text-amber-700">{{this.t.t2i}}</span>
              </div>
              <div>
                <p class="font-semibold text-stone-800 text-sm">{{this.t.t2n}}</p>
                <p class="text-xs text-stone-400">{{this.t.t2l}}</p>
              </div>
            </div>
          </div>

          <div class="rounded-2xl border border-stone-200 bg-white p-6 shadow-sm flex flex-col">
            <div class="flex gap-0.5 mb-3">
              <svg class="h-4 w-4 text-amber-400" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
              <svg class="h-4 w-4 text-amber-400" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
              <svg class="h-4 w-4 text-amber-400" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
              <svg class="h-4 w-4 text-amber-400" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
              <svg class="h-4 w-4 text-amber-400" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
            </div>
            <p class="text-stone-600 text-sm leading-relaxed mb-4 grow">{{this.t.t3q}}</p>
            <div class="flex items-center gap-3 mt-auto pt-3 border-t border-stone-100">
              <div class="h-9 w-9 rounded-full bg-green-100 flex items-center justify-center shrink-0">
                <span class="text-xs font-bold text-green-700">{{this.t.t3i}}</span>
              </div>
              <div>
                <p class="font-semibold text-stone-800 text-sm">{{this.t.t3n}}</p>
                <p class="text-xs text-stone-400">{{this.t.t3l}}</p>
              </div>
            </div>
          </div>

        </div>
      </section>

      {{! ── GALLERY PREVIEW ── }}
      {{#if this.hasGallery}}
        <section class="mb-12">
          <div class="flex items-baseline justify-between mb-4">
            <div>
              <p class="text-xs font-bold uppercase tracking-widest text-rose-600 mb-1">Photos</p>
              <h2 class="text-2xl font-bold text-stone-900">{{this.t.galleryTitle}}</h2>
            </div>
            <LinkTo @route="gallery" class="text-sm font-semibold text-rose-700 hover:text-rose-900 transition-colors">
              {{this.t.viewAll}} →
            </LinkTo>
          </div>
          <div class="grid grid-cols-2 sm:grid-cols-3 gap-3">
            {{#if this.gi0}}<button type="button" {{on "click" (fn this.openLightbox 0)}} class="rounded-xl overflow-hidden aspect-video bg-stone-100 shadow-sm cursor-zoom-in block w-full group"><img src={{this.gi0}} class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" /></button>{{/if}}
            {{#if this.gi1}}<button type="button" {{on "click" (fn this.openLightbox 1)}} class="rounded-xl overflow-hidden aspect-video bg-stone-100 shadow-sm cursor-zoom-in block w-full group"><img src={{this.gi1}} class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" /></button>{{/if}}
            {{#if this.gi2}}<button type="button" {{on "click" (fn this.openLightbox 2)}} class="rounded-xl overflow-hidden aspect-video bg-stone-100 shadow-sm cursor-zoom-in block w-full group"><img src={{this.gi2}} class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" /></button>{{/if}}
            {{#if this.gi3}}<button type="button" {{on "click" (fn this.openLightbox 3)}} class="rounded-xl overflow-hidden aspect-video bg-stone-100 shadow-sm cursor-zoom-in block w-full group"><img src={{this.gi3}} class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" /></button>{{/if}}
            {{#if this.gi4}}<button type="button" {{on "click" (fn this.openLightbox 4)}} class="rounded-xl overflow-hidden aspect-video bg-stone-100 shadow-sm cursor-zoom-in block w-full group"><img src={{this.gi4}} class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" /></button>{{/if}}
            {{#if this.gi5}}<button type="button" {{on "click" (fn this.openLightbox 5)}} class="rounded-xl overflow-hidden aspect-video bg-stone-100 shadow-sm cursor-zoom-in block w-full group"><img src={{this.gi5}} class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" /></button>{{/if}}
          </div>
        </section>
      {{/if}}

      {{! ── LOCATION ── }}
      <section class="mb-12">
        <div class="text-center mb-6">
          <p class="text-xs font-bold uppercase tracking-widest text-rose-600 mb-1">{{this.t.locationLabel}}</p>
          <h2 class="text-2xl sm:text-3xl font-bold text-stone-900">{{this.t.locationTitle}}</h2>
        </div>
        <div class="rounded-2xl border border-stone-200 bg-white shadow-sm overflow-hidden">
          <div class="grid md:grid-cols-2">

            <div class="p-8 border-b md:border-b-0 md:border-r border-stone-100">
              <div class="space-y-5">
                <div class="flex items-start gap-4">
                  <div class="h-10 w-10 rounded-xl bg-rose-100 flex items-center justify-center shrink-0 mt-0.5">
                    <svg class="h-5 w-5 text-rose-700" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z"/>
                      <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z"/>
                    </svg>
                  </div>
                  <div>
                    <p class="font-bold text-stone-800">{{this.t.locationAddr1}}</p>
                    <p class="text-stone-500 text-sm">{{this.t.locationAddr2}}</p>
                    <p class="text-stone-500 text-sm">{{this.t.locationAddr3}}</p>
                    <p class="text-stone-400 text-xs mt-1">{{this.t.locationNearby}}</p>
                  </div>
                </div>
                <div class="flex items-center gap-4">
                  <div class="h-10 w-10 rounded-xl bg-green-100 flex items-center justify-center shrink-0">
                    <svg class="h-5 w-5 text-green-700" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 6.75c0 8.284 6.716 15 15 15h2.25a2.25 2.25 0 002.25-2.25v-1.372c0-.516-.351-.966-.852-1.091l-4.423-1.106c-.44-.11-.902.055-1.173.417l-.97 1.293c-.282.376-.769.542-1.21.38a12.035 12.035 0 01-7.143-7.143c-.162-.441.004-.928.38-1.21l1.293-.97c.363-.271.527-.734.417-1.173L6.963 3.102a1.125 1.125 0 00-1.091-.852H4.5A2.25 2.25 0 002.25 4.5v2.25z"/>
                    </svg>
                  </div>
                  <a href="tel:+919443380023" class="font-semibold text-stone-700 hover:text-rose-700 transition-colors">+91 94433 80023</a>
                </div>
              </div>
              <div class="mt-6 flex flex-col sm:flex-row gap-3">
                <a href="https://maps.app.goo.gl/JeJpq91QKdKQLGHb9" target="_blank" rel="noopener noreferrer"
                  class="inline-flex items-center justify-center gap-2 rounded-xl bg-rose-700 hover:bg-rose-800 px-5 py-2.5 text-sm font-bold text-white transition-colors">
                  <svg class="h-4 w-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z"/></svg>
                  {{this.t.locationGetDir}}
                </a>
                <a href="https://wa.me/919443380023" target="_blank" rel="noopener noreferrer"
                  class="inline-flex items-center justify-center gap-2 rounded-xl border border-green-300 bg-green-50 hover:bg-green-100 px-5 py-2.5 text-sm font-bold text-green-700 transition-colors">
                  <svg class="h-4 w-4" fill="currentColor" viewBox="0 0 24 24"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/></svg>
                  {{this.t.whatsappUs}}
                </a>
              </div>
            </div>

            <div class="bg-rose-50 flex flex-col items-center justify-center p-10 text-center">
              <div class="h-20 w-20 rounded-full bg-white border-4 border-rose-200 shadow-sm flex items-center justify-center mb-5">
                <svg class="h-10 w-10 text-rose-600" fill="none" stroke="currentColor" stroke-width="1.2" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25"/>
                </svg>
              </div>
              <p class="font-bold text-stone-800 text-lg">4S Malini Mahal</p>
              <p class="text-stone-500 text-sm mt-1">{{this.t.locationNearby}}</p>
              <div class="mt-4 pt-4 border-t border-rose-100 w-full">
                <p class="text-xs text-stone-400">Thiruthangal — 626 130, Tamil Nadu</p>
              </div>
            </div>

          </div>
        </div>
      </section>

      {{! ── WHY US + CONTACT ── }}
      <div class="grid sm:grid-cols-2 gap-6 mb-8">

        <div class="rounded-2xl border border-stone-200 bg-white p-6 shadow-sm">
          <p class="text-xs font-bold uppercase tracking-widest text-rose-600 mb-1">Trust</p>
          <h3 class="font-bold text-stone-900 text-lg mb-4">{{this.t.whyTitle}}</h3>
          <ul class="space-y-3 text-sm text-stone-600">
            <li class="flex items-start gap-2.5">
              <svg class="h-4 w-4 text-green-500 mt-0.5 shrink-0" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
              </svg>{{this.t.why1}}
            </li>
            <li class="flex items-start gap-2.5">
              <svg class="h-4 w-4 text-green-500 mt-0.5 shrink-0" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
              </svg>{{this.t.why2}}
            </li>
            <li class="flex items-start gap-2.5">
              <svg class="h-4 w-4 text-green-500 mt-0.5 shrink-0" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
              </svg>{{this.t.why3}}
            </li>
            <li class="flex items-start gap-2.5">
              <svg class="h-4 w-4 text-green-500 mt-0.5 shrink-0" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
              </svg>{{this.t.why4}}
            </li>
          </ul>
        </div>

        <div class="rounded-2xl border border-stone-200 bg-white p-6 shadow-sm">
          <p class="text-xs font-bold uppercase tracking-widest text-rose-600 mb-1">Contact</p>
          <h3 class="font-bold text-stone-900 text-lg mb-4">{{this.t.contactTitle}}</h3>
          <div class="space-y-3">
            <a href="tel:+919443380023" class="flex items-center gap-3 text-sm text-stone-700 hover:text-rose-700 transition-colors">
              <svg class="h-4 w-4 text-rose-500 shrink-0" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 6.75c0 8.284 6.716 15 15 15h2.25a2.25 2.25 0 002.25-2.25v-1.372c0-.516-.351-.966-.852-1.091l-4.423-1.106c-.44-.11-.902.055-1.173.417l-.97 1.293c-.282.376-.769.542-1.21.38a12.035 12.035 0 01-7.143-7.143c-.162-.441.004-.928.38-1.21l1.293-.97c.363-.271.527-.734.417-1.173L6.963 3.102a1.125 1.125 0 00-1.091-.852H4.5A2.25 2.25 0 002.25 4.5v2.25z"/>
              </svg>
              +91 94433 80023
            </a>
            <a href="https://wa.me/919443380023" target="_blank" rel="noopener noreferrer" class="flex items-center gap-3 text-sm text-stone-700 hover:text-green-700 transition-colors">
              <svg class="h-4 w-4 text-green-500 shrink-0" fill="currentColor" viewBox="0 0 24 24">
                <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
              </svg>
              {{this.t.whatsappUs}}
            </a>
            <a href="https://maps.app.goo.gl/JeJpq91QKdKQLGHb9" target="_blank" rel="noopener noreferrer" class="flex items-center gap-3 text-sm text-stone-700 hover:text-blue-700 transition-colors">
              <svg class="h-4 w-4 text-blue-500 shrink-0" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z"/>
                <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z"/>
              </svg>
              {{this.t.locationShort}}
            </a>
          </div>
          <LinkTo @route="contact"
            class="mt-4 inline-flex items-center gap-1 text-xs font-medium text-rose-700 hover:text-rose-900 transition-colors">
            {{this.t.viewContact}}
            <svg class="h-3 w-3" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3"/>
            </svg>
          </LinkTo>
        </div>

      </div>

    </div>

    {{! ── LIGHTBOX ── }}
    {{#if this.lightboxSrc}}
      <div class="fixed inset-0 z-50 bg-black/90 flex items-center justify-center" role="dialog" aria-modal="true" {{on "click" this.closeLightbox}}>

        <div class="relative flex items-center gap-3 sm:gap-5 px-3 sm:px-5 max-w-5xl w-full" {{on "click" this.preventClose}}>

          <button type="button" {{on "click" this.prevImage}}
            class="shrink-0 h-11 w-11 rounded-full bg-white/10 hover:bg-white/30 flex items-center justify-center text-white transition-colors">
            <svg class="h-6 w-6" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5"/>
            </svg>
          </button>

          <div class="relative flex-1 min-w-0 flex items-center justify-center">
            <img src={{this.lightboxSrc}} alt="Gallery image" class="max-w-full max-h-[85vh] object-contain rounded-xl shadow-2xl" />
            <button type="button" {{on "click" this.closeLightbox}}
              class="absolute -top-3 -right-3 h-9 w-9 rounded-full bg-white/20 hover:bg-white/40 flex items-center justify-center text-white transition-colors">
              <svg class="h-5 w-5" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
              </svg>
            </button>
          </div>

          <button type="button" {{on "click" this.nextImage}}
            class="shrink-0 h-11 w-11 rounded-full bg-white/10 hover:bg-white/30 flex items-center justify-center text-white transition-colors">
            <svg class="h-6 w-6" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5"/>
            </svg>
          </button>

        </div>

        <p class="absolute bottom-4 left-0 right-0 text-center text-white/30 text-xs pointer-events-none">
          {{this.lightboxPos}} / {{this.lightboxCount}} · Arrow keys to navigate · Esc to close
        </p>

      </div>
    {{/if}}

  </template>
}
