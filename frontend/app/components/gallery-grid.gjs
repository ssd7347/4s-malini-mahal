import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { apiUrl } from 'frontend/utils/api';

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
  @tracked lightboxIndex = null;

  constructor() {
    super(...arguments);
    this.load();
    this._onKey = (e) => {
      if (!this.lightbox) return;
      if (e.key === 'Escape')     { this.close(); }
      if (e.key === 'ArrowLeft')  { this.prev(); }
      if (e.key === 'ArrowRight') { this.next(); }
    };
    document.addEventListener('keydown', this._onKey);
  }

  willDestroy() {
    super.willDestroy();
    document.removeEventListener('keydown', this._onKey);
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
      const isLocalVideo = item.mediaType === 'VIDEO' && !!item.filename;
      return {
        ...item,
        isImage: item.mediaType === 'IMAGE',
        isLocalVideo,
        thumbSrc: item.mediaType === 'IMAGE'
          ? apiUrl('/api/media/' + item.filename)
          : isLocalVideo
            ? null
            : (ytId(item.youtubeUrl) ? `https://img.youtube.com/vi/${ytId(item.youtubeUrl)}/hqdefault.jpg` : ''),
        videoSrc: isLocalVideo ? apiUrl('/api/media/' + item.filename) : null,
        timeAgo: timeAgo(item.createdAt),
      };
    });
  }

  get lightbox() {
    if (this.lightboxIndex === null) return null;
    const item = this.gridItems[this.lightboxIndex];
    if (!item) return null;
    const videoId = ytId(item.youtubeUrl);
    const type = item.isImage ? 'IMAGE' : item.isLocalVideo ? 'LOCAL_VIDEO' : 'YOUTUBE';
    const src = item.isImage
      ? item.thumbSrc
      : item.isLocalVideo
        ? item.videoSrc
        : (videoId ? `https://www.youtube.com/embed/${videoId}?autoplay=1&rel=0` : '');
    return { type, src, title: item.title };
  }

  get lightboxCounter() {
    if (this.lightboxIndex === null) return '';
    return (this.lightboxIndex + 1) + ' / ' + this.gridItems.length;
  }

  get hasMultiple()        { return this.gridItems.length > 1; }
  get photoCount()         { return this.items.filter(i => i.mediaType === 'IMAGE').length; }
  get videoCount()         { return this.items.filter(i => i.mediaType === 'VIDEO').length; }
  get filterIsAll()        { return this.filter === 'ALL'; }
  get filterIsPhoto()      { return this.filter === 'IMAGE'; }
  get filterIsVideo()      { return this.filter === 'VIDEO'; }
  get lightboxIsImage()    { return this.lightbox?.type === 'IMAGE'; }
  get lightboxIsLocalVideo() { return this.lightbox?.type === 'LOCAL_VIDEO'; }

  @action setFilter(f) {
    this.filter = f;
    this.lightboxIndex = null;
  }

  @action
  open(item) {
    const idx = this.gridItems.findIndex(i => i.id === item.id);
    this.lightboxIndex = idx >= 0 ? idx : 0;
  }

  @action
  prev(e) {
    e?.stopPropagation();
    if (this.lightboxIndex === null) return;
    this.lightboxIndex = (this.lightboxIndex - 1 + this.gridItems.length) % this.gridItems.length;
  }

  @action
  next(e) {
    e?.stopPropagation();
    if (this.lightboxIndex === null) return;
    this.lightboxIndex = (this.lightboxIndex + 1) % this.gridItems.length;
  }

  @action stopProp(e) { e.stopPropagation(); }
  @action close()     { this.lightboxIndex = null; }

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
      <div class="flex items-center justify-center gap-3 py-20 text-stone-400">
        <svg class="animate-spin h-5 w-5" viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
        </svg>
        <span class="text-sm">Loading gallery…</span>
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

            {{! Overlay }}
            {{#if item.isImage}}
              {{! zoom icon on hover }}
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

    {{! Lightbox }}
    <div
      class="fixed inset-0 bg-black flex items-center justify-center {{if this.lightbox '' 'hidden'}}"
      style="z-index:9999"
      role="dialog"
      aria-modal="true"
      {{on "click" this.close}}
    >
      {{#if this.lightbox}}

        {{! Close }}
        <button
          type="button"
          style="position:absolute;top:1rem;right:1rem;color:#fff;font-size:2rem;line-height:1;width:2.5rem;height:2.5rem;display:flex;align-items:center;justify-content:center;background:none;border:none;cursor:pointer"
          {{on "click" this.close}}
          aria-label="Close"
        >&times;</button>

        {{! Prev }}
        {{#if this.hasMultiple}}
          <button
            type="button"
            style="position:absolute;left:0.75rem;top:50%;transform:translateY(-50%);color:#fff;font-size:3rem;line-height:1;width:3rem;height:3rem;display:flex;align-items:center;justify-content:center;background:none;border:none;cursor:pointer"
            {{on "click" this.prev}}
            aria-label="Previous"
          >&#8249;</button>
        {{/if}}

        {{! Next }}
        {{#if this.hasMultiple}}
          <button
            type="button"
            style="position:absolute;right:0.75rem;top:50%;transform:translateY(-50%);color:#fff;font-size:3rem;line-height:1;width:3rem;height:3rem;display:flex;align-items:center;justify-content:center;background:none;border:none;cursor:pointer"
            {{on "click" this.next}}
            aria-label="Next"
          >&#8250;</button>
        {{/if}}

        {{! Image / Video }}
        {{#if this.lightboxIsImage}}
          <img
            src={{this.lightbox.src}}
            alt={{this.lightbox.title}}
            style="max-height:calc(100vh - 2rem);max-width:calc(100vw - 8rem);object-fit:contain;display:block"
            {{on "click" this.stopProp}}
          />
        {{else if this.lightboxIsLocalVideo}}
          <video
            src={{this.lightbox.src}}
            controls
            autoplay
            style="max-height:calc(100vh - 2rem);max-width:calc(100vw - 8rem);outline:none;display:block"
            {{on "click" this.stopProp}}
          ></video>
        {{else}}
          <div
            style="width:min(90vw,56rem);aspect-ratio:16/9"
            {{on "click" this.stopProp}}
          >
            <iframe
              src={{this.lightbox.src}}
              style="width:100%;height:100%;border:none"
              allowfullscreen
              allow="autoplay; encrypted-media; picture-in-picture"
              title={{this.lightbox.title}}
            ></iframe>
          </div>
        {{/if}}

      {{/if}}
    </div>
  </template>
}
