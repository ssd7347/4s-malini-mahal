import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { apiUrl } from 'frontend/utils/api';

const SKELETON = [1, 2, 3, 4, 5, 6];

function timeAgo(dateStr) {
  if (!dateStr) return '';
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.floor(hrs / 24);
  if (days < 30) return `${days} day${days === 1 ? '' : 's'} ago`;
  const months = Math.floor(days / 30);
  if (months < 12) return `${months} month${months === 1 ? '' : 's'} ago`;
  const years = Math.floor(months / 12);
  return `${years} year${years === 1 ? '' : 's'} ago`;
}

function ytId(url) {
  if (!url) return null;
  const m = url.match(/(?:v=|youtu\.be\/|embed\/)([A-Za-z0-9_-]{11})/);
  return m ? m[1] : null;
}

export default class GalleryGrid extends Component {
  @tracked loading = true;
  @tracked items = [];
  @tracked filter = 'ALL';

  _lightboxIndex = null;
  _lightboxEl = null;
  _keyHandler = null;

  constructor() {
    super(...arguments);
    this.load();
  }

  willDestroy() {
    super.willDestroy();
    this._closeLightbox();
  }

  async load() {
    try {
      const res = await fetch(apiUrl('/api/gallery'));
      if (res.ok) this.items = await res.json();
    } catch (_) {}
    this.loading = false;
  }

  get gridItems() {
    const src = this.filter === 'ALL' ? this.items : this.items.filter(i => i.mediaType === this.filter);
    return src.map(item => {
      const isLocalVideo = item.mediaType === 'VIDEO' && !!item.filename && !item.mediaUrl;
      const fileSrc = item.mediaUrl || (item.filename ? apiUrl('/api/media/' + item.filename) : null);
      return {
        ...item,
        isImage: item.mediaType === 'IMAGE',
        isLocalVideo: isLocalVideo || (item.mediaType === 'VIDEO' && !!item.mediaUrl),
        thumbSrc: item.mediaType === 'IMAGE'
          ? fileSrc
          : (isLocalVideo || item.mediaUrl)
            ? null
            : (ytId(item.youtubeUrl) ? `https://img.youtube.com/vi/${ytId(item.youtubeUrl)}/hqdefault.jpg` : ''),
        videoSrc: (isLocalVideo || (item.mediaType === 'VIDEO' && !!item.mediaUrl)) ? fileSrc : null,
        timeAgo: timeAgo(item.createdAt),
      };
    });
  }

  get photoCount()    { return this.items.filter(i => i.mediaType === 'IMAGE').length; }
  get videoCount()    { return this.items.filter(i => i.mediaType === 'VIDEO').length; }
  get filterIsAll()   { return this.filter === 'ALL'; }
  get filterIsPhoto() { return this.filter === 'IMAGE'; }
  get filterIsVideo() { return this.filter === 'VIDEO'; }

  @action setFilter(f) {
    this.filter = f;
    this._closeLightbox();
  }

  @action open(item) {
    const idx = this.gridItems.findIndex(i => i.id === item.id);
    this._lightboxIndex = idx >= 0 ? idx : 0;
    this._openLightbox();
  }

  @action prev() {
    if (this._lightboxIndex === null) return;
    this._lightboxIndex = (this._lightboxIndex - 1 + this.gridItems.length) % this.gridItems.length;
    this._openLightbox();
  }

  @action next() {
    if (this._lightboxIndex === null) return;
    this._lightboxIndex = (this._lightboxIndex + 1) % this.gridItems.length;
    this._openLightbox();
  }

  @action close() {
    this._closeLightbox();
  }

  _openLightbox() {
    // Read item BEFORE _closeLightbox() resets _lightboxIndex to null
    const idx = this._lightboxIndex;
    const item = this.gridItems[idx];
    if (!item) return;
    this._closeLightbox();
    this._lightboxIndex = idx; // restore after _closeLightbox() nulled it

    // Build overlay as a plain div appended to body.
    // After appending we measure getBoundingClientRect() and correct top/left
    // in case an ancestor CSS transform/filter creates a non-viewport containing block.
    const el = document.createElement('div');
    el.setAttribute('role', 'dialog');
    el.setAttribute('aria-modal', 'true');
    el.style.cssText = 'position:fixed;top:0;left:0;width:100vw;height:100vh;background:#000;z-index:2147483647;display:flex;align-items:center;justify-content:center;box-sizing:border-box';
    el.addEventListener('click', () => this._closeLightbox());

    // Close ×
    const closeBtn = document.createElement('button');
    closeBtn.type = 'button';
    closeBtn.setAttribute('aria-label', 'Close');
    closeBtn.style.cssText = 'position:absolute;top:1rem;right:1rem;color:#fff;font-size:2rem;line-height:1;width:2.5rem;height:2.5rem;display:flex;align-items:center;justify-content:center;background:none;border:none;cursor:pointer';
    closeBtn.textContent = '×';
    closeBtn.addEventListener('click', e => { e.stopPropagation(); this._closeLightbox(); });
    el.appendChild(closeBtn);

    // Prev / Next
    if (this.gridItems.length > 1) {
      const prevBtn = document.createElement('button');
      prevBtn.type = 'button';
      prevBtn.setAttribute('aria-label', 'Previous');
      prevBtn.style.cssText = 'position:absolute;left:0.75rem;top:50%;transform:translateY(-50%);color:#fff;font-size:3rem;line-height:1;width:3rem;height:3rem;display:flex;align-items:center;justify-content:center;background:none;border:none;cursor:pointer';
      prevBtn.innerHTML = '&#8249;';
      prevBtn.addEventListener('click', e => { e.stopPropagation(); this.prev(); });
      el.appendChild(prevBtn);

      const nextBtn = document.createElement('button');
      nextBtn.type = 'button';
      nextBtn.setAttribute('aria-label', 'Next');
      nextBtn.style.cssText = 'position:absolute;right:0.75rem;top:50%;transform:translateY(-50%);color:#fff;font-size:3rem;line-height:1;width:3rem;height:3rem;display:flex;align-items:center;justify-content:center;background:none;border:none;cursor:pointer';
      nextBtn.innerHTML = '&#8250;';
      nextBtn.addEventListener('click', e => { e.stopPropagation(); this.next(); });
      el.appendChild(nextBtn);
    }

    // Media
    if (item.isImage) {
      const img = document.createElement('img');
      img.src = item.thumbSrc;
      img.alt = item.title || '';
      img.style.cssText = 'max-height:90vh;max-width:90vw;object-fit:contain;display:block';
      img.addEventListener('click', e => e.stopPropagation());
      el.appendChild(img);
    } else if (item.isLocalVideo) {
      const vid = document.createElement('video');
      vid.src = item.videoSrc;
      vid.controls = true;
      vid.autoplay = true;
      vid.style.cssText = 'max-height:90vh;max-width:90vw;outline:none;display:block';
      vid.addEventListener('click', e => e.stopPropagation());
      el.appendChild(vid);
    } else {
      const id = ytId(item.youtubeUrl);
      if (id) {
        const wrap = document.createElement('div');
        wrap.style.cssText = 'width:min(90vw,56rem);aspect-ratio:16/9';
        wrap.addEventListener('click', e => e.stopPropagation());
        const iframe = document.createElement('iframe');
        iframe.src = `https://www.youtube.com/embed/${id}?autoplay=1&rel=0`;
        iframe.style.cssText = 'width:100%;height:100%;border:none';
        iframe.allowFullscreen = true;
        iframe.allow = 'autoplay; encrypted-media; picture-in-picture';
        iframe.title = item.title || 'Video';
        wrap.appendChild(iframe);
        el.appendChild(wrap);
      }
    }

    document.body.appendChild(el);

    // Self-correct position: if an ancestor CSS property (transform, backdrop-filter, etc.)
    // made it the containing block instead of the viewport, compensate.
    const rect = el.getBoundingClientRect();
    if (Math.abs(rect.top) > 1 || Math.abs(rect.left) > 1 ||
        Math.abs(rect.width - window.innerWidth) > 1 ||
        Math.abs(rect.height - window.innerHeight) > 1) {
      el.style.top    = (-rect.top) + 'px';
      el.style.left   = (-rect.left) + 'px';
      el.style.width  = window.innerWidth + 'px';
      el.style.height = window.innerHeight + 'px';
    }

    this._lightboxEl = el;

    this._keyHandler = e => {
      if (e.key === 'Escape')     this._closeLightbox();
      if (e.key === 'ArrowLeft')  this.prev();
      if (e.key === 'ArrowRight') this.next();
    };
    document.addEventListener('keydown', this._keyHandler);
  }

  _closeLightbox() {
    if (this._lightboxEl) {
      this._lightboxEl.remove();
      this._lightboxEl = null;
    }
    if (this._keyHandler) {
      document.removeEventListener('keydown', this._keyHandler);
      this._keyHandler = null;
    }
    this._lightboxIndex = null;
  }

  <template>
    {{! Filter tabs }}
    <div class="flex items-center gap-2 mb-6 flex-wrap">
      <button type="button"
        class="rounded-full px-4 py-1.5 text-sm font-medium transition-colors duration-150 {{if this.filterIsAll 'bg-rose-700 text-white shadow-sm' 'bg-white border border-stone-200 text-stone-600 hover:border-rose-200 hover:text-rose-700'}}"
        {{on "click" (fn this.setFilter 'ALL')}}>
        All ({{this.items.length}})
      </button>
      <button type="button"
        class="rounded-full px-4 py-1.5 text-sm font-medium transition-colors duration-150 {{if this.filterIsPhoto 'bg-rose-700 text-white shadow-sm' 'bg-white border border-stone-200 text-stone-600 hover:border-rose-200 hover:text-rose-700'}}"
        {{on "click" (fn this.setFilter 'IMAGE')}}>
        Photos ({{this.photoCount}})
      </button>
      <button type="button"
        class="rounded-full px-4 py-1.5 text-sm font-medium transition-colors duration-150 {{if this.filterIsVideo 'bg-rose-700 text-white shadow-sm' 'bg-white border border-stone-200 text-stone-600 hover:border-rose-200 hover:text-rose-700'}}"
        {{on "click" (fn this.setFilter 'VIDEO')}}>
        Videos ({{this.videoCount}})
      </button>
    </div>

    {{#if this.loading}}
      <div class="grid grid-cols-2 sm:grid-cols-3 gap-3">
        {{#each SKELETON as |_|}}
          <div class="animate-pulse rounded-xl aspect-video bg-stone-200"></div>
        {{/each}}
      </div>

    {{else if this.gridItems.length}}
      <div class="grid grid-cols-2 sm:grid-cols-3 gap-3 animate-slide-up">
        {{#each this.gridItems as |item|}}
          <button
            type="button"
            class="group relative rounded-xl overflow-hidden bg-stone-100 aspect-video focus:outline-none focus:ring-2 focus:ring-rose-500/30 shadow-sm"
            {{on "click" (fn this.open item)}}
            aria-label={{if item.title item.title "View"}}
          >
            {{#if item.isLocalVideo}}
              <video
                src={{item.videoSrc}}
                preload="metadata"
                muted
                playsinline
                class="h-full w-full object-cover transition-transform duration-300 group-hover:scale-105"
              ></video>
            {{else}}
              <img
                src={{item.thumbSrc}}
                alt={{if item.title item.title ""}}
                loading="lazy"
                class="h-full w-full object-cover transition-transform duration-300 group-hover:scale-105"
              />
            {{/if}}

            {{! Hover overlay }}
            {{#if item.isImage}}
              <div class="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-colors duration-200 flex items-center justify-center">
                <div class="opacity-0 group-hover:opacity-100 transition-opacity duration-200 rounded-full bg-white/20 p-3 backdrop-blur-sm">
                  <svg class="h-5 w-5 text-white" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607zM10.5 7.5v6m3-3h-6"/>
                  </svg>
                </div>
              </div>
            {{else}}
              <div class="absolute inset-0 flex items-center justify-center bg-black/20 group-hover:bg-black/30 transition-colors duration-200">
                <div class="h-14 w-14 rounded-full bg-black/50 backdrop-blur-sm flex items-center justify-center transition-transform duration-200 group-hover:scale-110">
                  <svg class="h-7 w-7 text-white ml-1" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                    <path d="M8 5v14l11-7z"/>
                  </svg>
                </div>
              </div>
            {{/if}}

            {{! Caption on hover }}
            <div class="absolute bottom-0 inset-x-0 bg-gradient-to-t from-black/70 to-transparent px-3 py-2.5 translate-y-full group-hover:translate-y-0 transition-transform duration-200">
              {{#if item.title}}
                <p class="text-xs font-medium text-white truncate leading-tight">{{item.title}}</p>
              {{/if}}
              <p class="text-xs text-white/60 {{if item.title 'mt-0.5' ''}}">Added {{item.timeAgo}}</p>
            </div>
          </button>
        {{/each}}
      </div>

    {{else}}
      <div class="py-20 text-center">
        <svg class="mx-auto mb-4 h-12 w-12 text-stone-200" fill="none" stroke="currentColor" stroke-width="1" viewBox="0 0 24 24" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159 5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 001.5-1.5V6a1.5 1.5 0 00-1.5-1.5H3.75A1.5 1.5 0 002.25 6v12a1.5 1.5 0 001.5 1.5zm10.5-11.25h.008v.008h-.008V8.25zm.375 0a.375.375 0 11-.75 0 .375.375 0 01.75 0z"/>
        </svg>
        <p class="text-sm font-medium text-stone-400">No media yet.</p>
        <p class="text-xs text-stone-300 mt-1">Check back soon for photos and videos.</p>
      </div>
    {{/if}}
  </template>
}
