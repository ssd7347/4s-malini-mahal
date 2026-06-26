import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { apiUrl } from 'frontend/utils/api';
import AdminCalendar from 'frontend/components/admin-calendar';
import DatePickerCalendar from 'frontend/components/date-picker-calendar';

const STATUSES = ['NEW', 'UNDER_ENQUIRY', 'AWAITING_PAYMENT', 'CONFIRMED', 'COMPLETED', 'DECLINED', 'REJECTED', 'CANCELLED'];

const STATUS_LABELS = {
  NEW:              'Received',
  UNDER_ENQUIRY:    'Under enquiry',
  AWAITING_PAYMENT: 'Awaiting Payment',
  CONFIRMED:        'Confirmed',
  COMPLETED:        'Completed',
  DECLINED:         'Declined',
  REJECTED:         'Rejected',
  CANCELLED:        'Cancelled',
};

// Literal strings so Tailwind's scanner picks up every class.
const STATUS_STYLES = {
  NEW:              'bg-stone-100 text-stone-600 border-stone-300',
  UNDER_ENQUIRY:    'bg-amber-50 text-amber-700 border-amber-300',
  AWAITING_PAYMENT: 'bg-yellow-50 text-yellow-700 border-yellow-300',
  CONFIRMED:        'bg-green-50 text-green-700 border-green-300',
  COMPLETED:        'bg-blue-50 text-blue-700 border-blue-300',
  DECLINED:         'bg-red-50 text-red-600 border-red-300',
  REJECTED:         'bg-orange-50 text-orange-700 border-orange-300',
  CANCELLED:        'bg-stone-50 text-stone-400 border-stone-200',
};

const RENTAL_LABELS = { HOURLY: 'Hourly', HALF_DAY: 'Half day', FULL_DAY: 'Full day' };

const FUNCTION_TYPE_LABELS = {
  MARRIAGE:         'Marriage',
  RECEPTION:        'Reception',
  ENGAGEMENT:       'Engagement',
  BIRTHDAY_FUNCTION:'Birthday Function',
  OTHER:            'Other',
  MEETING:          'Meeting',
  CONFERENCE:       'Conference',
  TRAINING_SESSION: 'Training Session',
  SEMINAR:          'Seminar',
  WORKSHOP:         'Workshop',
  SMALL_GATHERING:  'Small Gathering',
  OTHER_HOURLY:     'Other Hourly Events',
};

const STATUS_FILTER_OPTS = [
  { value: '', label: 'All statuses' },
  ...STATUSES.map(s => ({ value: s, label: STATUS_LABELS[s] ?? s })),
];

function todayIso() {
  const n = new Date();
  return `${n.getFullYear()}-${String(n.getMonth() + 1).padStart(2, '0')}-${String(n.getDate()).padStart(2, '0')}`;
}

function fmtDate(iso) {
  if (!iso) return '—';
  const [y, m, d] = iso.split('-').map(Number);
  return new Date(y, m - 1, d).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
}

function fmtTime(isoStr) {
  if (!isoStr) return null;
  return new Date(isoStr).toLocaleString('en-IN', {
    day: 'numeric', month: 'short',
    hour: '2-digit', minute: '2-digit',
    hour12: true, timeZone: 'Asia/Kolkata',
  });
}

function ytId(url) {
  if (!url) return null;
  const m = url.match(/(?:v=|youtu\.be\/|embed\/)([A-Za-z0-9_-]{11})/);
  return m ? m[1] : null;
}

const INPUT_CLS = 'rounded-lg border border-stone-200 bg-white px-3 py-2 text-stone-900 placeholder:text-stone-400 transition-[border-color,box-shadow] duration-150 focus:border-rose-500 focus:ring-4 focus:ring-rose-500/10 focus:outline-none text-sm';

export default class AdminPortal extends Component {
  @service auth;
  @service router;

  @tracked enquiries = [];
  @tracked blockedDates = [];
  @tracked _blockDate = null;
  @tracked galleryItems = [];
  @tracked muhurthamDates = [];
  @tracked termsVersions = [];
  @tracked refunds = [];
  @tracked notificationLog = [];
  @tracked notifConfig = null;
  @tracked notice = null;
  @tracked openBillingRef = null;
  @tracked statsMonth = new Date().toISOString().slice(0, 7);
  @tracked monthStats = null;
  @tracked broadcastMonth = new Date().toISOString().slice(0, 7);
  @tracked broadcastMessage = '';
  @tracked searchQuery = '';
  @tracked filterStatus = '';
  @tracked filterMonth = '';

  _flashTimer = null;

  constructor() {
    super(...arguments);
    this.loadData().catch(() => {});
    this.loadMonthStats().catch(() => {});
  }

  // ── Derived rows ────────────────────────────────────────────────────────────

  get galleryRows() {
    const HOME_LABELS = { 1: 'Welcome', 2: 'About', 3: 'Hospitality', 4: 'Book Online' };
    return this.galleryItems.map((item) => {
      const isLocalVideo = item.mediaType === 'VIDEO' && !!item.filename;
      return {
        ...item,
        isImage: item.mediaType === 'IMAGE',
        isLocalVideo,
        thumbSrc: item.mediaType === 'IMAGE'
          ? (item.mediaUrl || apiUrl('/api/media/' + item.filename))
          : isLocalVideo
            ? null
            : (ytId(item.youtubeUrl) ? `https://img.youtube.com/vi/${ytId(item.youtubeUrl)}/hqdefault.jpg` : ''),
        videoSrc: isLocalVideo ? (item.mediaUrl || apiUrl('/api/media/' + item.filename)) : null,
        homeSlotLabel: item.homeSlot ? HOME_LABELS[item.homeSlot] : null,
        pinSlots: [1, 2, 3, 4].map(s => ({ slot: s, label: HOME_LABELS[s], active: item.homeSlot === s })),
      };
    });
  }

  get stats() {
    const total     = this.enquiries.length;
    const confirmed = this.enquiries.filter(e => e.status === 'CONFIRMED').length;
    const pending   = this.enquiries.filter(e => e.status === 'NEW' || e.status === 'UNDER_ENQUIRY').length;
    const now       = new Date();
    const thisMonth = this.enquiries.filter(e => {
      const d = new Date(e.createdAt);
      return d.getMonth() === now.getMonth() && d.getFullYear() === now.getFullYear();
    }).length;
    return { total, confirmed, pending, thisMonth };
  }

  get refundRows() {
    return this.refunds.map((r) => ({
      ...r,
      advanceRupees: r.advancePaise ? (r.advancePaise / 100).toLocaleString('en-IN') : '—',
      refundRupees:  r.refundPaise  ? (r.refundPaise  / 100).toLocaleString('en-IN') : '—',
      isPending:   r.status === 'PENDING',
      statusCls: r.status === 'PENDING'
        ? 'bg-amber-50 text-amber-700 border-amber-300'
        : r.status === 'PROCESSED'
          ? 'bg-green-50 text-green-700 border-green-300'
          : 'bg-red-50 text-red-600 border-red-300',
    }));
  }

  get notificationRows() {
    return (this.notificationLog ?? []).map(n => ({
      ...n,
      channelCls: n.channel === 'whatsapp' ? 'bg-green-50 text-green-700'
                : n.channel === 'email'    ? 'bg-blue-50 text-blue-700'
                :                           'bg-stone-100 text-stone-600',
      statusCls:  n.status === 'sent'     ? 'bg-green-50 text-green-700'
                : n.status === 'pending'   ? 'bg-yellow-50 text-yellow-700'
                : n.status === 'retrying'  ? 'bg-amber-50 text-amber-700'
                :                           'bg-red-50 text-red-600',
      sentAtFmt: n.sentAt ? new Date(n.sentAt).toLocaleString('en-IN', {
        day: 'numeric', month: 'short',
        hour: '2-digit', minute: '2-digit', hour12: true, timeZone: 'Asia/Kolkata',
      }) : null,
    }));
  }

  _mapEnquiryRow(e) {
    return {
      ...e,
      statusOptions: STATUSES.map((s) => ({ value: s, label: STATUS_LABELS[s] ?? s, selected: s === e.status })),
      statusStyle: STATUS_STYLES[e.status] || 'bg-stone-100 text-stone-600 border-stone-300',
      rentalLabel: RENTAL_LABELS[e.rentalType] ?? e.rentalType,
      functionTypeLabel: FUNCTION_TYPE_LABELS[e.functionType] ?? e.functionType ?? '—',
      eventDateFormatted: fmtDate(e.eventDate),
      timeSlot: e.startDatetime
        ? `${fmtTime(e.startDatetime)} → ${fmtTime(e.endDatetime)}`
        : '—',
      waUrl: `https://wa.me/91${e.mobile}?text=Dear%20${encodeURIComponent(e.customerName)}%2C%20regarding%20your%20enquiry%20${e.reference}%20at%204S%20Malini%20Mahal%3A%20`,
      showBillingBtn: e.status === 'CONFIRMED',
      showPaymentLink: e.status === 'AWAITING_PAYMENT',
      showInvoiceLink: ['AWAITING_PAYMENT', 'CONFIRMED', 'COMPLETED'].includes(e.status),
      billingOpen: this.openBillingRef === e.reference,
      decorationChargeRupees: e.decorationChargePaise ? e.decorationChargePaise / 100 : '',
      earlyEntryChargeRupees: e.earlyEntryChargePaise ? e.earlyEntryChargePaise / 100 : '',
      keyLossChargeRupees:    e.keyLossChargePaise    ? e.keyLossChargePaise    / 100 : '',
    };
  }

  get enquiryRows() {
    return this.enquiries.map(e => this._mapEnquiryRow(e));
  }

  get filteredEnquiries() {
    let rows = this.enquiries;
    if (this.filterStatus) rows = rows.filter(e => e.status === this.filterStatus);
    if (this.filterMonth)  rows = rows.filter(e => e.eventDate && e.eventDate.startsWith(this.filterMonth));
    if (this.searchQuery) {
      const q = this.searchQuery.toLowerCase();
      rows = rows.filter(e =>
        (e.customerName && e.customerName.toLowerCase().includes(q)) ||
        (e.mobile && e.mobile.includes(q)) ||
        (e.reference && e.reference.toLowerCase().includes(q))
      );
    }
    return rows;
  }

  get filteredEnquiryRows() {
    return this.filteredEnquiries.map(e => this._mapEnquiryRow(e));
  }

  get hasActiveFilters() {
    return !!(this.searchQuery || this.filterStatus || this.filterMonth);
  }

  get filterStatusOptions() {
    return STATUS_FILTER_OPTS.map(o => ({ ...o, selected: o.value === this.filterStatus }));
  }

  // ── Today's schedule ────────────────────────────────────────────────────────

  get todaySchedule() {
    const iso = todayIso();
    return this.enquiries
      .filter(e => e.eventDate === iso && ['NEW', 'UNDER_ENQUIRY', 'AWAITING_PAYMENT', 'CONFIRMED'].includes(e.status))
      .map(e => ({
        ...e,
        statusStyle: STATUS_STYLES[e.status] || 'bg-stone-100 text-stone-600 border-stone-300',
        statusLabel: STATUS_LABELS[e.status] || e.status,
        functionTypeLabel: FUNCTION_TYPE_LABELS[e.functionType] ?? e.functionType ?? '—',
        rentalLabel: RENTAL_LABELS[e.rentalType] ?? e.rentalType,
      }));
  }

  // ── Upcoming events (tomorrow) ───────────────────────────────────────────────

  get upcomingEvents() {
    const t = new Date();
    t.setDate(t.getDate() + 1);
    const iso = `${t.getFullYear()}-${String(t.getMonth() + 1).padStart(2, '0')}-${String(t.getDate()).padStart(2, '0')}`;
    return this.enquiries
      .filter(e => e.eventDate === iso && e.status === 'CONFIRMED')
      .map(e => ({
        ...e,
        functionTypeLabel: FUNCTION_TYPE_LABELS[e.functionType] ?? e.functionType ?? '—',
        rentalLabel: RENTAL_LABELS[e.rentalType] ?? e.rentalType,
      }));
  }

  // ── Revenue chart ────────────────────────────────────────────────────────────

  get revenueChartData() {
    const now = new Date();
    const months = [];
    for (let i = 11; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
      months.push({
        key,
        label: d.toLocaleDateString('en-IN', { month: 'short', year: '2-digit' }),
        count: 0,
      });
    }
    for (const e of this.enquiries) {
      if (!['CONFIRMED', 'COMPLETED'].includes(e.status) || !e.eventDate) continue;
      const key = e.eventDate.slice(0, 7);
      const slot = months.find(m => m.key === key);
      if (slot) slot.count++;
    }
    const maxCount = Math.max(...months.map(m => m.count), 1);
    const CHART_H = 90;
    const N = months.length;
    const SVG_W = 600;
    const slotW = SVG_W / N;
    const barW = Math.floor(slotW - 5);
    return months.map((m, i) => {
      const barH = Math.max(2, Math.round((m.count / maxCount) * CHART_H));
      const x = Math.round(i * slotW + 2);
      const y = CHART_H - barH;
      const textX = Math.round(x + barW / 2);
      return { ...m, rectX: x, rectY: y, rectH: barH, rectW: barW, textX, labelY: 108, countY: y - 3 };
    });
  }

  // ── Monthly billing ──────────────────────────────────────────────────────────

  get billingCollectedRupees() {
    if (!this.monthStats) return '0';
    return (this.monthStats.billingCollectedPaise / 100).toLocaleString('en-IN');
  }

  get broadcastRows() {
    const [year, month] = this.broadcastMonth.split('-').map(Number);
    const msg = encodeURIComponent(this.broadcastMessage || '');
    return this.enquiries
      .filter(e => {
        if (!['CONFIRMED', 'COMPLETED'].includes(e.status)) return false;
        if (!e.eventDate) return false;
        const [y, m] = e.eventDate.split('-').map(Number);
        return y === year && m === month;
      })
      .map(e => ({
        ...e,
        waUrl: `https://wa.me/91${e.mobile}?text=${msg}`,
        eventDateFmt: fmtDate(e.eventDate),
      }));
  }

  // ── Data loading ─────────────────────────────────────────────────────────────

  async api(path, opts = {}) {
    return fetch(apiUrl(path), {
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      ...opts,
    });
  }

  async loadData() {
    const [eRes, bRes, mRes, tRes, rRes, nRes, cfgRes] = await Promise.all([
      this.api('/api/admin/enquiries'),
      this.api('/api/admin/blocked-dates'),
      this.api('/api/admin/muhurtham'),
      this.api('/api/admin/terms/versions'),
      this.api('/api/admin/refunds'),
      this.api('/api/admin/notification-log'),
      this.api('/api/admin/notification-config'),
    ]);
    if (eRes.ok)   this.enquiries       = await eRes.json();
    if (bRes.ok)   this.blockedDates    = await bRes.json();
    if (mRes.ok)   this.muhurthamDates  = await mRes.json();
    if (tRes.ok)   this.termsVersions   = await tRes.json();
    if (rRes.ok)   this.refunds         = await rRes.json();
    if (nRes.ok)   this.notificationLog = await nRes.json();
    if (cfgRes.ok) this.notifConfig     = await cfgRes.json();
    const gRes = await this.api('/api/gallery');
    if (gRes.ok) this.galleryItems = await gRes.json();
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  @action
  async logout() {
    await this.auth.logout();
    this.router.transitionTo('index');
  }

  @action
  async changeStatus(reference, event) {
    const newStatus = event.target.value;
    const res = await this.api(`/api/admin/enquiries/${reference}/status`, {
      method: 'POST',
      body: JSON.stringify({ status: newStatus }),
    });
    if (res.ok) {
      this.flash(`${reference} → ${STATUS_LABELS[newStatus] ?? newStatus}`);
    } else {
      const data = await res.json().catch(() => ({}));
      this.flash(`Cannot confirm: ${data.error || 'Could not change status'}`);
    }
    const eRes = await this.api('/api/admin/enquiries');
    if (eRes.ok) this.enquiries = await eRes.json();
  }

  @action setBlockDate(iso) { this._blockDate = iso; }

  @action
  async addBlock(event) {
    event.preventDefault();
    if (!this._blockDate) { this.flash('Please select a date'); return; }
    const form = event.currentTarget;
    const fd = new FormData(form);
    const res = await this.api('/api/admin/blocked-dates', {
      method: 'POST',
      body: JSON.stringify({ date: this._blockDate, reason: fd.get('reason') }),
    });
    if (res.ok) {
      form.reset();
      this._blockDate = null;
      await this.loadData();
      this.flash('Date blocked');
    } else {
      const data = await res.json().catch(() => ({}));
      this.flash(data.error || 'Could not block date');
    }
  }

  @action
  async removeBlock(date) {
    const res = await this.api(`/api/admin/blocked-dates/${date}`, { method: 'DELETE' });
    if (res.ok) {
      this.blockedDates = this.blockedDates.filter((b) => b.blockedDate !== date);
      this.flash('Date unblocked');
    }
  }

  @action
  async addPhoto(event) {
    event.preventDefault();
    const form = event.currentTarget;
    const fd = new FormData(form);
    const res = await fetch(apiUrl('/api/admin/gallery'), {
      method: 'POST',
      credentials: 'include',
      body: fd,
    });
    if (res.ok) {
      form.reset();
      const gRes = await this.api('/api/gallery');
      if (gRes.ok) this.galleryItems = await gRes.json();
      this.flash('Photo added to gallery');
    } else {
      const data = await res.json().catch(() => ({}));
      this.flash(data.error || 'Upload failed');
    }
  }

  @action
  async addVideoFile(event) {
    event.preventDefault();
    const form = event.currentTarget;
    const fd = new FormData(form);
    const res = await fetch(apiUrl('/api/admin/gallery'), {
      method: 'POST',
      credentials: 'include',
      body: fd,
    });
    if (res.ok) {
      form.reset();
      const gRes = await this.api('/api/gallery');
      if (gRes.ok) this.galleryItems = await gRes.json();
      this.flash('Video uploaded to gallery');
    } else {
      const data = await res.json().catch(() => ({}));
      this.flash(data.error || 'Upload failed');
    }
  }

  @action
  async addVideo(event) {
    event.preventDefault();
    const form = event.currentTarget;
    const fd = new FormData(form);
    const res = await this.api('/api/admin/gallery', {
      method: 'POST',
      body: JSON.stringify({ youtubeUrl: fd.get('youtubeUrl'), title: fd.get('title') }),
    });
    if (res.ok) {
      form.reset();
      const gRes = await this.api('/api/gallery');
      if (gRes.ok) this.galleryItems = await gRes.json();
      this.flash('Video added to gallery');
    } else {
      const data = await res.json().catch(() => ({}));
      this.flash(data.error || 'Could not add video');
    }
  }

  @action
  async removeGalleryItem(id) {
    const res = await this.api(`/api/admin/gallery/${id}`, { method: 'DELETE' });
    if (res.ok) {
      this.galleryItems = this.galleryItems.filter((i) => i.id !== id);
      this.flash('Item removed from gallery');
    }
  }

  @action
  async pinToHome(id, slot) {
    const res = await this.api(`/api/admin/gallery/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ homeSlot: slot }),
    });
    if (res.ok) {
      const updated = await res.json();
      this.galleryItems = this.galleryItems.map(i =>
        i.id === id ? { ...i, homeSlot: updated.homeSlot } :
        (updated.homeSlot && i.homeSlot === updated.homeSlot ? { ...i, homeSlot: null } : i)
      );
      this.flash(slot ? `Pinned to Home section ${slot}` : 'Unpinned from home page');
    }
  }

  @action
  toggleBilling(reference) {
    this.openBillingRef = this.openBillingRef === reference ? null : reference;
  }

  @action
  async saveBilling(reference, event) {
    event.preventDefault();
    const fd = new FormData(event.currentTarget);
    const elecUnits = fd.get('elecUnits') ? Number(fd.get('elecUnits')) : null;
    const gasKg     = fd.get('gasKg')     ? Number(fd.get('gasKg'))     : null;
    const decorRaw  = fd.get('decorationCharge');
    const decorationChargePaise = decorRaw ? Math.round(Number(decorRaw) * 100) : null;
    const earlyEntryRaw = fd.get('earlyEntryCharge');
    const earlyEntryChargePaise = earlyEntryRaw ? Math.round(Number(earlyEntryRaw) * 100) : null;
    const keyLossRaw = fd.get('keyLossCharge');
    const keyLossChargePaise = keyLossRaw ? Math.round(Number(keyLossRaw) * 100) : null;
    const res = await this.api(`/api/admin/enquiries/${reference}/billing`, {
      method: 'POST',
      body: JSON.stringify({ elecUnits, gasKg, decorationChargePaise, earlyEntryChargePaise, keyLossChargePaise }),
    });
    if (res.ok) {
      this.openBillingRef = null;
      this.flash(`Billing saved — ${reference}`);
      const eRes = await this.api('/api/admin/enquiries');
      if (eRes.ok) this.enquiries = await eRes.json();
    } else {
      const data = await res.json().catch(() => ({}));
      this.flash(data.error || 'Could not save billing');
    }
  }

  @action
  async addMuhurtham(event) {
    event.preventDefault();
    const form = event.currentTarget;
    const fd = new FormData(form);
    const res = await this.api('/api/admin/muhurtham', {
      method: 'POST',
      body: JSON.stringify({ date: fd.get('date'), note: fd.get('note') }),
    });
    if (res.ok) {
      form.reset();
      const r = await this.api('/api/admin/muhurtham');
      if (r.ok) this.muhurthamDates = await r.json();
      this.flash('Muhurtham date added');
    } else {
      const d = await res.json().catch(() => ({}));
      this.flash(d.error || 'Could not add muhurtham date');
    }
  }

  @action
  async removeMuhurtham(date) {
    const res = await this.api(`/api/admin/muhurtham/${date}`, { method: 'DELETE' });
    if (res.ok) {
      this.muhurthamDates = this.muhurthamDates.filter((m) => m.mdate !== date);
      this.flash('Muhurtham date removed');
    }
  }

  @action
  async createTerms(event) {
    event.preventDefault();
    const form = event.currentTarget;
    const fd = new FormData(form);
    const res = await this.api('/api/admin/terms/versions', {
      method: 'POST',
      body: JSON.stringify({ tamilText: fd.get('tamilText'), englishText: fd.get('englishText') }),
    });
    if (res.ok) {
      form.reset();
      const r = await this.api('/api/admin/terms/versions');
      if (r.ok) this.termsVersions = await r.json();
      this.flash('T&C version created');
    } else {
      const d = await res.json().catch(() => ({}));
      this.flash(d.error || 'Could not create T&C version');
    }
  }

  @action
  async translateTerms(id) {
    const res = await this.api(`/api/admin/terms/versions/${id}/translate`, { method: 'POST' });
    if (res.ok) {
      const r = await this.api('/api/admin/terms/versions');
      if (r.ok) this.termsVersions = await r.json();
      this.flash('Translation completed');
    } else {
      const d = await res.json().catch(() => ({}));
      this.flash(d.error || 'Translation failed');
    }
  }

  @action
  async activateTerms(id) {
    const res = await this.api(`/api/admin/terms/versions/${id}/activate`, { method: 'POST' });
    if (res.ok) {
      const r = await this.api('/api/admin/terms/versions');
      if (r.ok) this.termsVersions = await r.json();
      this.flash('T&C version activated');
    } else {
      const d = await res.json().catch(() => ({}));
      this.flash(d.error || 'Could not activate version');
    }
  }

  @action
  async processRefund(id) {
    const res = await this.api(`/api/admin/refunds/${id}/process`, { method: 'POST' });
    if (res.ok) {
      const r = await this.api('/api/admin/refunds');
      if (r.ok) this.refunds = await r.json();
      this.flash('Refund marked as processed');
    }
  }

  @action
  async denyRefund(id) {
    const res = await this.api(`/api/admin/refunds/${id}/deny`, { method: 'POST' });
    if (res.ok) {
      const r = await this.api('/api/admin/refunds');
      if (r.ok) this.refunds = await r.json();
      this.flash('Refund denied');
    }
  }

  @action setStatsMonth(event) {
    this.statsMonth = event.target.value;
    this.loadMonthStats().catch(() => {});
  }

  async loadMonthStats() {
    const res = await this.api(`/api/admin/stats?month=${this.statsMonth}`);
    if (res.ok) this.monthStats = await res.json();
  }

  @action async downloadCsv() {
    const res = await this.api('/api/admin/enquiries/export');
    if (!res.ok) { this.flash('Export failed'); return; }
    const blob = await res.blob();
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'bookings.csv';
    a.click();
    URL.revokeObjectURL(url);
  }

  @action setBroadcastMonth(event) { this.broadcastMonth = event.target.value; }
  @action setBroadcastMessage(event) { this.broadcastMessage = event.target.value; }

  @action setSearch(event) { this.searchQuery = event.target.value; }
  @action setFilterStatus(event) { this.filterStatus = event.target.value; }
  @action setFilterMonth(event) { this.filterMonth = event.target.value; }
  @action clearFilters() { this.searchQuery = ''; this.filterStatus = ''; this.filterMonth = ''; }

  @action printInvoice(ref) {
    window.open(`/invoice/${ref}?print=1`, '_blank');
  }

  @action
  dismissNotice() {
    this.notice = null;
    clearTimeout(this._flashTimer);
  }

  flash(msg) {
    this.notice = msg;
    clearTimeout(this._flashTimer);
    this._flashTimer = setTimeout(() => { this.notice = null; }, 3500);
  }

  <template>
    <div class="animate-slide-up">
      <div class="flex items-center justify-between mb-2">
        <h1 class="text-2xl font-bold text-stone-900 tracking-tight">Admin Portal</h1>
      </div>

      {{! Flash notice }}
      {{#if this.notice}}
        <div class="mt-3 flex items-center justify-between gap-3 rounded-lg border border-sky-200 bg-sky-50 px-4 py-2.5 text-sm text-sky-800 animate-fade-in">
          <div class="flex items-center gap-2">
            <svg class="h-4 w-4 text-sky-500 shrink-0" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
              <path stroke-linecap="round" stroke-linejoin="round" d="M11.25 11.25l.041-.02a.75.75 0 011.063.852l-.708 2.836a.75.75 0 001.063.853l.041-.021M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-9-3.75h.008v.008H12V8.25z"/>
            </svg>
            {{this.notice}}
          </div>
          <button type="button" class="text-sky-500 hover:text-sky-700 transition-colors" {{on "click" this.dismissNotice}} aria-label="Dismiss">
            <svg class="h-4 w-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
            </svg>
          </button>
        </div>
      {{/if}}

      {{! Upcoming events reminder (tomorrow) }}
      {{#if this.upcomingEvents.length}}
        <div class="mt-3 rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 animate-fade-in">
          <div class="flex items-center gap-2 mb-1.5">
            <svg class="h-4 w-4 text-amber-500 shrink-0" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
              <path stroke-linecap="round" stroke-linejoin="round" d="M14.857 17.082a23.848 23.848 0 005.454-1.31A8.967 8.967 0 0118 9.75v-.7V9A6 6 0 006 9v.75a8.967 8.967 0 01-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 01-5.714 0m5.714 0a3 3 0 11-5.714 0"/>
            </svg>
            <p class="text-sm font-semibold text-amber-800">Reminder — {{this.upcomingEvents.length}} confirmed event(s) tomorrow</p>
          </div>
          <div class="space-y-0.5 pl-6">
            {{#each this.upcomingEvents as |e|}}
              <p class="text-xs text-amber-700">
                <span class="font-semibold">{{e.customerName}}</span>
                <span class="text-amber-500"> &middot; {{e.functionTypeLabel}} &middot; {{e.rentalLabel}} &middot; {{e.mobile}}</span>
              </p>
            {{/each}}
          </div>
        </div>
      {{/if}}

      {{! Today's schedule }}
      {{#if this.todaySchedule.length}}
        <div class="mt-3 rounded-xl border border-green-200 bg-green-50 px-5 py-4 animate-fade-in">
          <div class="flex items-center gap-2 mb-3">
            <div class="h-2 w-2 rounded-full bg-green-500 animate-pulse"></div>
            <h2 class="text-sm font-semibold text-green-800">Today's Schedule — {{this.todaySchedule.length}} event(s)</h2>
          </div>
          <div class="space-y-2">
            {{#each this.todaySchedule as |e|}}
              <div class="flex items-center justify-between rounded-lg bg-white border border-green-100 px-4 py-2.5 shadow-sm">
                <div>
                  <p class="text-sm font-semibold text-stone-800">{{e.customerName}}</p>
                  <p class="text-xs text-stone-500">{{e.functionTypeLabel}} &middot; {{e.rentalLabel}} &middot; {{e.mobile}}</p>
                </div>
                <span class="rounded-full border px-2 py-0.5 text-xs font-semibold {{e.statusStyle}}">{{e.statusLabel}}</span>
              </div>
            {{/each}}
          </div>
        </div>
      {{/if}}

      {{! Stats }}
      <div class="mt-6 grid grid-cols-2 sm:grid-cols-4 gap-3">
        <div class="rounded-xl border border-stone-200 bg-white px-5 py-4 shadow-sm">
          <p class="text-xs font-semibold text-stone-400 uppercase tracking-wide">Total</p>
          <p class="mt-1 text-2xl font-bold text-stone-900 tabular-nums">{{this.stats.total}}</p>
        </div>
        <div class="rounded-xl border border-stone-200 bg-white px-5 py-4 shadow-sm">
          <p class="text-xs font-semibold text-stone-400 uppercase tracking-wide">Pending</p>
          <p class="mt-1 text-2xl font-bold text-amber-600 tabular-nums">{{this.stats.pending}}</p>
        </div>
        <div class="rounded-xl border border-stone-200 bg-white px-5 py-4 shadow-sm">
          <p class="text-xs font-semibold text-stone-400 uppercase tracking-wide">Confirmed</p>
          <p class="mt-1 text-2xl font-bold text-green-600 tabular-nums">{{this.stats.confirmed}}</p>
        </div>
        <div class="rounded-xl border border-stone-200 bg-white px-5 py-4 shadow-sm">
          <p class="text-xs font-semibold text-stone-400 uppercase tracking-wide">This month</p>
          <p class="mt-1 text-2xl font-bold text-rose-700 tabular-nums">{{this.stats.thisMonth}}</p>
        </div>
      </div>

      {{! Monthly stats dashboard }}
      <section class="mt-6">
        <div class="flex items-center justify-between mb-3">
          <h2 class="text-base font-semibold text-stone-900">Monthly Stats</h2>
          <input type="month" value={{this.statsMonth}}
            class="rounded-lg border border-stone-200 bg-white px-3 py-1.5 text-sm text-stone-700 focus:border-rose-500 focus:outline-none"
            {{on "change" this.setStatsMonth}} />
        </div>
        {{#if this.monthStats}}
          <div class="grid grid-cols-3 gap-3">
            <div class="rounded-xl border border-stone-200 bg-white px-5 py-4 shadow-sm">
              <p class="text-xs font-semibold text-stone-400 uppercase tracking-wide">Bookings</p>
              <p class="mt-1 text-2xl font-bold text-stone-900 tabular-nums">{{this.monthStats.bookingsCount}}</p>
              <p class="text-xs text-stone-400 mt-0.5">confirmed + completed</p>
            </div>
            <div class="rounded-xl border border-stone-200 bg-white px-5 py-4 shadow-sm">
              <p class="text-xs font-semibold text-stone-400 uppercase tracking-wide">Billing Collected</p>
              <p class="mt-1 text-xl font-bold text-green-700 tabular-nums">₹{{this.billingCollectedRupees}}</p>
              <p class="text-xs text-stone-400 mt-0.5">from completed events</p>
            </div>
            <div class="rounded-xl border border-stone-200 bg-white px-5 py-4 shadow-sm">
              <p class="text-xs font-semibold text-stone-400 uppercase tracking-wide">Occupancy</p>
              <p class="mt-1 text-2xl font-bold text-rose-600 tabular-nums">{{this.monthStats.occupancyRate}}%</p>
              <p class="text-xs text-stone-400 mt-0.5">{{this.monthStats.occupiedDays}} / {{this.monthStats.daysInMonth}} days</p>
            </div>
          </div>
        {{/if}}
      </section>

      {{! Revenue chart — confirmed + completed bookings by event month }}
      <section class="mt-6">
        <h2 class="text-base font-semibold text-stone-900 mb-3">Bookings by Month (last 12)</h2>
        <div class="rounded-xl border border-stone-200 bg-white shadow-sm px-5 pt-5 pb-3">
          <svg viewBox="0 0 600 120" class="w-full h-auto" aria-label="Monthly bookings bar chart">
            {{#each this.revenueChartData as |m|}}
              <rect x={{m.rectX}} y={{m.rectY}} width={{m.rectW}} height={{m.rectH}} rx="2" fill="#be123c" opacity="0.85"/>
              <text x={{m.textX}} y={{m.labelY}} text-anchor="middle" font-size="9" fill="#a8a29e">{{m.label}}</text>
              {{#if m.count}}
                <text x={{m.textX}} y={{m.countY}} text-anchor="middle" font-size="9" fill="#44403c" font-weight="600">{{m.count}}</text>
              {{/if}}
            {{/each}}
          </svg>
        </div>
      </section>

      {{! Booking calendar }}
      <section class="mt-6">
        <h2 class="text-base font-semibold text-stone-900 mb-3">Booking Calendar</h2>
        <AdminCalendar
          @enquiries={{this.enquiries}}
          @muhurthamDates={{this.muhurthamDates}}
          @blockedDates={{this.blockedDates}}
        />
      </section>

      {{! Enquiries table }}
      <section class="mt-8">
        <div class="flex items-center justify-between mb-3">
          <h2 class="text-base font-semibold text-stone-900">Enquiries</h2>
          <div class="flex items-center gap-3">
            <span class="text-sm text-stone-400">
              {{#if this.hasActiveFilters}}
                {{this.filteredEnquiries.length}} of {{this.enquiries.length}}
              {{else}}
                {{this.enquiries.length}} total
              {{/if}}
            </span>
            <button type="button"
              class="flex items-center gap-1.5 rounded-lg border border-stone-200 bg-white px-3 py-1.5 text-xs font-medium text-stone-600 hover:bg-stone-50 hover:text-stone-800 transition-colors shadow-sm"
              {{on "click" this.downloadCsv}}>
              <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3"/>
              </svg>
              Export CSV
            </button>
          </div>
        </div>

        {{! Search & filter controls }}
        <div class="flex flex-wrap items-center gap-2 mb-3">
          <div class="relative flex-1 min-w-44">
            <svg class="absolute left-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-stone-400 pointer-events-none" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
              <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z"/>
            </svg>
            <input
              type="search"
              placeholder="Search name, mobile, reference…"
              value={{this.searchQuery}}
              class="w-full rounded-lg border border-stone-200 bg-white pl-8 pr-3 py-1.5 text-sm text-stone-900 placeholder:text-stone-400 focus:border-rose-500 focus:ring-4 focus:ring-rose-500/10 focus:outline-none"
              {{on "input" this.setSearch}}
            />
          </div>
          <select
            class="rounded-lg border border-stone-200 bg-white px-3 py-1.5 text-sm text-stone-700 focus:border-rose-500 focus:outline-none"
            {{on "change" this.setFilterStatus}}>
            {{#each this.filterStatusOptions as |opt|}}
              <option value={{opt.value}} selected={{opt.selected}}>{{opt.label}}</option>
            {{/each}}
          </select>
          <input type="month"
            value={{this.filterMonth}}
            class="rounded-lg border border-stone-200 bg-white px-3 py-1.5 text-sm text-stone-700 focus:border-rose-500 focus:outline-none"
            title="Filter by event month"
            {{on "change" this.setFilterMonth}} />
          {{#if this.hasActiveFilters}}
            <button type="button"
              class="text-xs font-medium text-rose-600 hover:text-rose-800 transition-colors"
              {{on "click" this.clearFilters}}>
              Clear filters ×
            </button>
          {{/if}}
        </div>

        <div class="rounded-xl border border-stone-200 bg-white shadow-sm overflow-hidden">
          {{#if this.filteredEnquiryRows.length}}
            <div class="overflow-x-auto">
              <table class="w-full text-sm">
                <thead>
                  <tr class="bg-stone-50 border-b border-stone-200 text-left">
                    <th class="px-4 py-3 text-xs font-semibold text-stone-500 uppercase tracking-wide">Reference</th>
                    <th class="px-4 py-3 text-xs font-semibold text-stone-500 uppercase tracking-wide">Name</th>
                    <th class="px-4 py-3 text-xs font-semibold text-stone-500 uppercase tracking-wide">Mobile</th>
                    <th class="px-4 py-3 text-xs font-semibold text-stone-500 uppercase tracking-wide">Date</th>
                    <th class="px-4 py-3 text-xs font-semibold text-stone-500 uppercase tracking-wide">Time Slot</th>
                    <th class="px-4 py-3 text-xs font-semibold text-stone-500 uppercase tracking-wide">Rental</th>
                    <th class="px-4 py-3 text-xs font-semibold text-stone-500 uppercase tracking-wide">Function</th>
                    <th class="px-4 py-3 text-xs font-semibold text-stone-500 uppercase tracking-wide">Status</th>
                    <th class="px-4 py-3 text-xs font-semibold text-stone-500 uppercase tracking-wide">Actions</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-stone-100">
                  {{#each this.filteredEnquiryRows as |e|}}
                    <tr class="transition-colors duration-100 hover:bg-stone-50/70 {{if e.message '' 'border-b border-stone-100'}}">
                      <td class="px-4 py-3 font-mono text-xs font-medium text-stone-700">{{e.reference}}</td>
                      <td class="px-4 py-3 text-stone-800">{{e.customerName}}</td>
                      <td class="px-4 py-3 text-stone-600">
                        <div class="flex items-center gap-2">
                          <span>{{e.mobile}}</span>
                          <a
                            href={{e.waUrl}}
                            target="_blank"
                            rel="noopener noreferrer"
                            class="text-green-600 hover:text-green-700 transition-colors"
                            title="WhatsApp"
                          >
                            <svg class="h-4 w-4" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                              <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
                            </svg>
                          </a>
                        </div>
                      </td>
                      <td class="px-4 py-3 text-stone-800 tabular-nums">{{e.eventDateFormatted}}</td>
                      <td class="px-4 py-3 text-stone-500 text-xs whitespace-nowrap">{{e.timeSlot}}</td>
                      <td class="px-4 py-3 text-stone-600">{{e.rentalLabel}}</td>
                      <td class="px-4 py-3 text-stone-600">{{e.functionTypeLabel}}</td>
                      <td class="px-4 py-3">
                        <select
                          class="rounded-full border px-3 py-1 text-xs font-semibold transition-colors duration-150 focus:outline-none focus:ring-2 focus:ring-rose-500/20 cursor-pointer {{e.statusStyle}}"
                          {{on "change" (fn this.changeStatus e.reference)}}
                        >
                          {{#each e.statusOptions as |o|}}
                            <option value={{o.value}} selected={{o.selected}}>{{o.label}}</option>
                          {{/each}}
                        </select>
                      </td>
                      <td class="px-4 py-3">
                        <div class="flex items-center gap-2 flex-wrap">
                          {{#if e.showPaymentLink}}
                            <a href="/payment/{{e.reference}}" target="_blank"
                              class="text-xs font-medium text-yellow-600 hover:text-yellow-800 transition-colors whitespace-nowrap">
                              Pay Link
                            </a>
                          {{/if}}
                          {{#if e.showBillingBtn}}
                            <button type="button"
                              class="text-xs font-medium text-indigo-600 hover:text-indigo-800 transition-colors whitespace-nowrap"
                              {{on "click" (fn this.toggleBilling e.reference)}}
                            >{{if e.billingOpen "Close" "Billing"}}</button>
                          {{/if}}
                          {{#if e.showInvoiceLink}}
                            <a href="/invoice/{{e.reference}}" target="_blank"
                              class="text-xs font-medium text-emerald-600 hover:text-emerald-800 transition-colors whitespace-nowrap">
                              Invoice
                            </a>
                            <button type="button"
                              class="text-xs font-medium text-stone-500 hover:text-stone-700 transition-colors whitespace-nowrap"
                              title="Print invoice"
                              {{on "click" (fn this.printInvoice e.reference)}}>
                              <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M6.72 13.829c-.24.03-.48.062-.72.096m.72-.096a42.415 42.415 0 0110.56 0m-10.56 0L6.34 18m10.94-4.171c.24.03.48.062.72.096m-.72-.096L17.66 18m0 0l.229 2.523a1.125 1.125 0 01-1.12 1.227H7.231c-.662 0-1.18-.568-1.12-1.227L6.34 18m11.318 0h1.091A2.25 2.25 0 0021 15.75V9.456c0-1.081-.768-2.015-1.837-2.175a48.055 48.055 0 00-1.913-.247M6.34 18H5.25A2.25 2.25 0 013 15.75V9.456c0-1.081.768-2.015 1.837-2.175a48.041 48.041 0 011.913-.247m10.5 0a48.536 48.536 0 00-10.5 0m10.5 0V3.375c0-.621-.504-1.125-1.125-1.125h-8.25c-.621 0-1.125.504-1.125 1.125v3.659M18 10.5h.008v.008H18V10.5zm-3 0h.008v.008H15V10.5z"/>
                              </svg>
                            </button>
                          {{/if}}
                        </div>
                      </td>
                    </tr>
                    {{#if e.billingOpen}}
                      <tr class="border-b border-stone-100 bg-indigo-50/40">
                        <td colspan="9" class="px-6 py-4">
                          <form class="flex flex-wrap items-end gap-3" {{on "submit" (fn this.saveBilling e.reference)}}>
                            <div>
                              <label class="block text-xs font-medium text-stone-500 mb-1">Electricity (units)</label>
                              <input name="elecUnits" type="number" step="0.1" min="0" placeholder="e.g. 120"
                                value={{if e.elecUnits e.elecUnits ""}}
                                class="w-32 rounded-lg border border-stone-200 bg-white px-3 py-1.5 text-sm text-stone-900 focus:border-indigo-500 focus:ring-2 focus:ring-indigo-500/10 focus:outline-none" />
                              <p class="text-xs text-stone-400 mt-0.5">₹40/unit</p>
                            </div>
                            <div>
                              <label class="block text-xs font-medium text-stone-500 mb-1">Gas (kg)</label>
                              <input name="gasKg" type="number" step="0.1" min="0" placeholder="e.g. 50"
                                value={{if e.gasKg e.gasKg ""}}
                                class="w-28 rounded-lg border border-stone-200 bg-white px-3 py-1.5 text-sm text-stone-900 focus:border-indigo-500 focus:ring-2 focus:ring-indigo-500/10 focus:outline-none" />
                              <p class="text-xs text-stone-400 mt-0.5">₹180/kg</p>
                            </div>
                            <div>
                              <label class="block text-xs font-medium text-stone-500 mb-1">Decoration (₹)</label>
                              <input name="decorationCharge" type="number" step="1" min="0" placeholder="e.g. 5000"
                                value={{e.decorationChargeRupees}}
                                class="w-32 rounded-lg border border-stone-200 bg-white px-3 py-1.5 text-sm text-stone-900 focus:border-indigo-500 focus:ring-2 focus:ring-indigo-500/10 focus:outline-none" />
                              <p class="text-xs text-stone-400 mt-0.5">Flat charge</p>
                            </div>
                            <div>
                              <label class="block text-xs font-medium text-stone-500 mb-1">Early Entry (₹)</label>
                              <input name="earlyEntryCharge" type="number" step="1" min="0" placeholder="5000 or 0"
                                value={{e.earlyEntryChargeRupees}}
                                class="w-28 rounded-lg border border-stone-200 bg-white px-3 py-1.5 text-sm text-stone-900 focus:border-indigo-500 focus:ring-2 focus:ring-indigo-500/10 focus:outline-none" />
                              <p class="text-xs text-stone-400 mt-0.5">Rule 2: key before 3 PM</p>
                            </div>
                            <div>
                              <label class="block text-xs font-medium text-stone-500 mb-1">Key Loss (₹)</label>
                              <input name="keyLossCharge" type="number" step="1" min="0" placeholder="900 or 0"
                                value={{e.keyLossChargeRupees}}
                                class="w-28 rounded-lg border border-stone-200 bg-white px-3 py-1.5 text-sm text-stone-900 focus:border-indigo-500 focus:ring-2 focus:ring-indigo-500/10 focus:outline-none" />
                              <p class="text-xs text-stone-400 mt-0.5">Rule 10: ₹900/lost key</p>
                            </div>
                            <button type="submit"
                              class="rounded-lg bg-indigo-600 px-4 py-1.5 text-sm font-semibold text-white shadow-sm hover:bg-indigo-700 active:scale-[0.98] transition-all duration-150">
                              Save Billing
                            </button>
                          </form>
                        </td>
                      </tr>
                    {{/if}}
                    {{#if e.message}}
                      <tr class="border-b border-stone-100">
                        <td class="px-4 pb-2.5 text-stone-300">
                          <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M7.5 8.25h9m-9 3H12m-9.75 1.51c0 1.6 1.123 2.994 2.707 3.227 1.129.166 2.27.293 3.423.379.35.026.67.21.865.501L12 21l2.755-4.133a1.14 1.14 0 01.865-.501 48.172 48.172 0 003.423-.379c1.584-.233 2.707-1.626 2.707-3.228V6.741c0-1.602-1.123-2.995-2.707-3.228A48.394 48.394 0 0012 3c-2.392 0-4.744.175-7.043.513C3.373 3.746 2.25 5.14 2.25 6.741v6.018z"/>
                          </svg>
                        </td>
                        <td colspan="8" class="px-2 pb-2.5 text-xs text-stone-500 italic">{{e.message}}</td>
                      </tr>
                    {{/if}}
                  {{/each}}
                </tbody>
              </table>
            </div>
          {{else if this.hasActiveFilters}}
            <div class="py-12 text-center text-sm text-stone-400">
              No bookings match your filters.
              <button type="button" class="ml-2 text-rose-600 hover:text-rose-800 transition-colors" {{on "click" this.clearFilters}}>Clear filters</button>
            </div>
          {{else}}
            <div class="py-12 text-center text-sm text-stone-400">
              No enquiries yet.
            </div>
          {{/if}}
        </div>
      </section>

      {{! Blocked dates }}
      <section class="mt-10">
        <h2 class="text-base font-semibold text-stone-900 mb-3">Blocked Dates</h2>

        <div class="mb-4 grid sm:grid-cols-2 gap-4 items-start">
          <DatePickerCalendar
            @value={{this._blockDate}}
            @onChange={{this.setBlockDate}}
            @min="2000-01-01"
          />
          <form class="flex flex-col gap-3" {{on "submit" this.addBlock}}>
            {{#if this._blockDate}}
              <p class="text-sm font-semibold text-stone-800">
                Selected: <span class="text-rose-700">{{this._blockDate}}</span>
              </p>
            {{else}}
              <p class="text-sm text-stone-400">← Pick a date from the calendar</p>
            {{/if}}
            <input name="reason" type="text" placeholder="Reason (optional)" class={{INPUT_CLS}} />
            <button type="submit"
              class="inline-flex items-center justify-center gap-1.5 rounded-lg bg-rose-700 px-4 py-2 text-sm font-semibold text-white shadow-sm transition-all duration-150 hover:bg-rose-800 hover:shadow-md active:scale-[0.98]">
              <svg class="h-4 w-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15"/>
              </svg>
              Block date
            </button>
          </form>
        </div>

        <div class="rounded-xl border border-stone-200 bg-white shadow-sm overflow-hidden">
          {{#if this.blockedDates.length}}
            <ul class="divide-y divide-stone-100">
              {{#each this.blockedDates as |b|}}
                <li class="flex items-center justify-between px-5 py-3 text-sm transition-colors duration-100 hover:bg-stone-50/70">
                  <div class="flex items-center gap-3">
                    <svg class="h-4 w-4 text-stone-300 shrink-0" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v11.25m-18 0A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75m-18 0v-7.5A2.25 2.25 0 015.25 9h13.5A2.25 2.25 0 0121 11.25v7.5"/>
                    </svg>
                    <span>
                      <span class="font-medium tabular-nums text-stone-800">{{b.blockedDate}}</span>
                      {{#if b.reason}}
                        <span class="ml-2 text-stone-400">{{b.reason}}</span>
                      {{/if}}
                    </span>
                  </div>
                  <button
                    type="button"
                    class="text-xs font-medium text-rose-600 hover:text-rose-800 transition-colors duration-150"
                    {{on "click" (fn this.removeBlock b.blockedDate)}}
                  >Remove</button>
                </li>
              {{/each}}
            </ul>
          {{else}}
            <div class="py-10 text-center text-sm text-stone-400">
              No blocked dates.
            </div>
          {{/if}}
        </div>
      </section>

      {{! Gallery management }}
      <section class="mt-10">
        <div class="flex items-baseline justify-between mb-3">
          <h2 class="text-base font-semibold text-stone-900">Gallery</h2>
          <span class="text-sm text-stone-400">{{this.galleryItems.length}} items</span>
        </div>

        <div class="grid sm:grid-cols-2 lg:grid-cols-3 gap-4 mb-4">
          {{! Photo upload }}
          <form class="rounded-xl border border-stone-200 bg-white p-4 space-y-2" {{on "submit" this.addPhoto}}>
            <h3 class="text-sm font-semibold text-stone-700">Upload photo</h3>
            <input
              name="file"
              type="file"
              accept="image/jpeg,image/png,image/webp"
              required
              class="block w-full text-sm text-stone-500 file:mr-3 file:rounded-lg file:border-0 file:bg-rose-50 file:px-3 file:py-1.5 file:text-sm file:font-medium file:text-rose-700 hover:file:bg-rose-100 transition-colors cursor-pointer"
            />
            <input name="title" type="text" placeholder="Caption (optional)" class="w-full {{INPUT_CLS}}" />
            <button type="submit"
              class="w-full rounded-lg bg-rose-700 px-4 py-2 text-sm font-semibold text-white shadow-sm transition-all duration-150 hover:bg-rose-800 active:scale-[0.98]">
              Upload photo
            </button>
          </form>

          {{! Local video upload }}
          <form class="rounded-xl border border-stone-200 bg-white p-4 space-y-2" {{on "submit" this.addVideoFile}}>
            <h3 class="text-sm font-semibold text-stone-700">Upload video</h3>
            <input
              name="file"
              type="file"
              accept="video/mp4,video/webm,video/quicktime"
              required
              class="block w-full text-sm text-stone-500 file:mr-3 file:rounded-lg file:border-0 file:bg-rose-50 file:px-3 file:py-1.5 file:text-sm file:font-medium file:text-rose-700 hover:file:bg-rose-100 transition-colors cursor-pointer"
            />
            <p class="text-xs text-stone-400">MP4, WebM, MOV · max 200 MB</p>
            <input name="title" type="text" placeholder="Caption (optional)" class="w-full {{INPUT_CLS}}" />
            <button type="submit"
              class="w-full rounded-lg bg-rose-700 px-4 py-2 text-sm font-semibold text-white shadow-sm transition-all duration-150 hover:bg-rose-800 active:scale-[0.98]">
              Upload video
            </button>
          </form>

          {{! YouTube video }}
          <form class="rounded-xl border border-stone-200 bg-white p-4 space-y-2" {{on "submit" this.addVideo}}>
            <h3 class="text-sm font-semibold text-stone-700">Add YouTube video</h3>
            <input name="youtubeUrl" type="url" required placeholder="https://youtube.com/watch?v=…" class="w-full {{INPUT_CLS}}" />
            <input name="title" type="text" placeholder="Caption (optional)" class="w-full {{INPUT_CLS}}" />
            <button type="submit"
              class="w-full rounded-lg bg-rose-700 px-4 py-2 text-sm font-semibold text-white shadow-sm transition-all duration-150 hover:bg-rose-800 active:scale-[0.98]">
              Add YouTube video
            </button>
          </form>
        </div>

        {{! Gallery grid }}
        <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
          {{#each this.galleryRows as |item|}}
            <div class="group relative rounded-xl overflow-hidden border border-stone-100 bg-stone-100 aspect-video shadow-sm">
              {{#if item.isLocalVideo}}
                <video src={{item.videoSrc}} preload="metadata" muted playsinline
                  class="h-full w-full object-cover"></video>
              {{else}}
                <img src={{item.thumbSrc}} alt={{if item.title item.title ""}} loading="lazy"
                  class="h-full w-full object-cover" />
              {{/if}}

              {{#if item.isImage}}
                {{! no extra overlay needed }}
              {{else}}
                <div class="absolute inset-0 flex items-center justify-center bg-black/20">
                  <div class="h-10 w-10 rounded-full bg-black/50 flex items-center justify-center">
                    <svg class="h-5 w-5 text-white ml-0.5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                      <path d="M8 5v14l11-7z"/>
                    </svg>
                  </div>
                </div>
              {{/if}}

              {{! Pin badge (always visible when pinned) }}
              {{#if item.homeSlotLabel}}
                <div class="absolute top-1.5 left-1.5 flex items-center gap-1 rounded-full bg-rose-600 px-2 py-0.5 text-white z-10 pointer-events-none">
                  <svg class="h-3 w-3" fill="currentColor" viewBox="0 0 24 24"><path d="M16 3a1 1 0 011 1v1h1a1 1 0 010 2h-.268l.537 5.372A3 3 0 0121 15v1a1 1 0 01-1 1h-6v4a1 1 0 01-2 0v-4H6a1 1 0 01-1-1v-1a3 3 0 012.731-2.628L8.268 7H8a1 1 0 010-2h1V4a1 1 0 011-1h6z"/></svg>
                  <span class="text-xs font-semibold leading-none">{{item.homeSlotLabel}}</span>
                </div>
              {{/if}}

              {{! Hover overlay with remove + pin buttons }}
              <div class="absolute inset-0 bg-black/0 group-hover:bg-black/50 transition-colors duration-150 flex flex-col items-end justify-between p-2">
                <button
                  type="button"
                  class="opacity-0 group-hover:opacity-100 transition-opacity duration-150 rounded-full bg-red-600 hover:bg-red-700 h-7 w-7 flex items-center justify-center shadow-sm"
                  {{on "click" (fn this.removeGalleryItem item.id)}}
                  aria-label="Remove"
                >
                  <svg class="h-3.5 w-3.5 text-white" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24" aria-hidden="true">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
                  </svg>
                </button>
                {{#if item.isImage}}
                  <div class="opacity-0 group-hover:opacity-100 transition-opacity duration-150 w-full">
                    <p class="text-white text-xs font-semibold mb-1 text-center drop-shadow">Pin to Home</p>
                    <div class="flex gap-1 justify-center flex-wrap">
                      {{#each item.pinSlots as |ps|}}
                        <button type="button"
                          class="rounded px-1.5 py-0.5 text-xs font-bold shadow transition-colors {{if ps.active 'bg-rose-500 text-white' 'bg-white/80 text-stone-800 hover:bg-white'}}"
                          {{on "click" (fn this.pinToHome item.id (if ps.active null ps.slot))}}
                        >{{ps.label}}</button>
                      {{/each}}
                    </div>
                  </div>
                {{/if}}
              </div>

              {{#if item.title}}
                <div class="absolute bottom-0 inset-x-0 bg-gradient-to-t from-black/60 to-transparent px-2 py-1.5 opacity-0 group-hover:opacity-100 transition-opacity duration-150">
                  <p class="text-xs text-white truncate">{{item.title}}</p>
                </div>
              {{/if}}
            </div>
          {{else}}
            <div class="col-span-full py-8 text-center text-sm text-stone-400">
              No gallery items yet. Upload a photo, upload a video, or add a YouTube link above.
            </div>
          {{/each}}
        </div>
      </section>

      {{! Muhurtham Dates }}
      <section class="mt-10">
        <h2 class="text-base font-semibold text-stone-900 mb-3">Muhurtham Dates</h2>

        <form class="flex flex-wrap gap-2 mb-4" {{on "submit" this.addMuhurtham}}>
          <input name="date" type="date" required class={{INPUT_CLS}} />
          <input name="note" type="text" placeholder="Note (optional, e.g. Tamil New Year)" class="flex-1 min-w-40 {{INPUT_CLS}}" />
          <button type="submit"
            class="inline-flex items-center gap-1.5 rounded-lg bg-yellow-600 px-4 py-2 text-sm font-semibold text-white shadow-sm transition-all duration-150 hover:bg-yellow-700 active:scale-[0.98]">
            ★ Add Muhurtham
          </button>
        </form>

        <div class="rounded-xl border border-stone-200 bg-white shadow-sm overflow-hidden">
          {{#if this.muhurthamDates.length}}
            <ul class="divide-y divide-stone-100">
              {{#each this.muhurthamDates as |m|}}
                <li class="flex items-center justify-between px-5 py-3 text-sm hover:bg-stone-50/70 transition-colors">
                  <div class="flex items-center gap-3">
                    <span class="text-yellow-500">★</span>
                    <span>
                      <span class="font-medium tabular-nums text-stone-800">{{m.mdate}}</span>
                      {{#if m.note}}
                        <span class="ml-2 text-stone-400">{{m.note}}</span>
                      {{/if}}
                    </span>
                  </div>
                  <button type="button"
                    class="text-xs font-medium text-rose-600 hover:text-rose-800 transition-colors"
                    {{on "click" (fn this.removeMuhurtham m.mdate)}}>Remove</button>
                </li>
              {{/each}}
            </ul>
          {{else}}
            <div class="py-10 text-center text-sm text-stone-400">No muhurtham dates added yet.</div>
          {{/if}}
        </div>
      </section>

      {{! Terms & Conditions }}
      <section class="mt-10">
        <h2 class="text-base font-semibold text-stone-900 mb-3">Terms & Conditions</h2>

        <form class="rounded-xl border border-stone-200 bg-white p-4 space-y-3 mb-4" {{on "submit" this.createTerms}}>
          <h3 class="text-sm font-semibold text-stone-700">Create new version</h3>
          <div>
            <label class="block text-xs font-medium text-stone-500 mb-1">Tamil text <span class="text-rose-500">*</span></label>
            <textarea name="tamilText" rows="4" required placeholder="Enter Tamil T&C text…"
              class="w-full {{INPUT_CLS}}"></textarea>
          </div>
          <div>
            <label class="block text-xs font-medium text-stone-500 mb-1">English translation <span class="text-stone-400">(optional — or use Translate button)</span></label>
            <textarea name="englishText" rows="4" placeholder="English translation will appear here…"
              class="w-full {{INPUT_CLS}}"></textarea>
          </div>
          <button type="submit"
            class="rounded-lg bg-rose-700 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-rose-800 active:scale-[0.98] transition-all duration-150">
            Create Version
          </button>
        </form>

        <div class="rounded-xl border border-stone-200 bg-white shadow-sm overflow-hidden">
          {{#if this.termsVersions.length}}
            <div class="divide-y divide-stone-100">
              {{#each this.termsVersions as |v|}}
                <div class="px-5 py-4">
                  <div class="flex items-center justify-between gap-3 mb-2">
                    <div class="flex items-center gap-2">
                      <span class="font-semibold text-stone-800">Version {{v.version}}</span>
                      {{#if v.isActive}}
                        <span class="rounded-full border border-green-300 bg-green-50 px-2 py-0.5 text-xs font-semibold text-green-700">Active</span>
                      {{/if}}
                    </div>
                    <div class="flex items-center gap-2">
                      {{#if v.tamilText}}
                        <button type="button"
                          class="text-xs font-medium text-indigo-600 hover:text-indigo-800 transition-colors"
                          {{on "click" (fn this.translateTerms v.id)}}>Translate</button>
                      {{/if}}
                      {{#unless v.isActive}}
                        <button type="button"
                          class="text-xs font-medium text-green-600 hover:text-green-800 transition-colors"
                          {{on "click" (fn this.activateTerms v.id)}}>Activate</button>
                      {{/unless}}
                    </div>
                  </div>
                  {{#if v.englishText}}
                    <p class="text-xs text-stone-500 truncate">{{v.englishText}}</p>
                  {{else}}
                    <p class="text-xs text-stone-400 italic">No English translation yet — click Translate</p>
                  {{/if}}
                </div>
              {{/each}}
            </div>
          {{else}}
            <div class="py-10 text-center text-sm text-stone-400">No T&C versions yet. Create one above.</div>
          {{/if}}
        </div>
      </section>

      {{! Refunds }}
      <section class="mt-10 mb-10">
        <div class="flex items-baseline justify-between mb-3">
          <h2 class="text-base font-semibold text-stone-900">Refunds</h2>
          <span class="text-sm text-stone-400">{{this.refunds.length}} total</span>
        </div>

        <div class="rounded-xl border border-stone-200 bg-white shadow-sm overflow-hidden">
          {{#if this.refunds.length}}
            <div class="overflow-x-auto">
              <table class="w-full text-sm">
                <thead>
                  <tr class="bg-stone-50 border-b border-stone-200 text-left">
                    <th class="px-4 py-3 text-xs font-semibold text-stone-500 uppercase tracking-wide">Reference</th>
                    <th class="px-4 py-3 text-xs font-semibold text-stone-500 uppercase tracking-wide">Type</th>
                    <th class="px-4 py-3 text-xs font-semibold text-stone-500 uppercase tracking-wide">Advance</th>
                    <th class="px-4 py-3 text-xs font-semibold text-stone-500 uppercase tracking-wide">Refund %</th>
                    <th class="px-4 py-3 text-xs font-semibold text-stone-500 uppercase tracking-wide">Refund Amt</th>
                    <th class="px-4 py-3 text-xs font-semibold text-stone-500 uppercase tracking-wide">Replaced by</th>
                    <th class="px-4 py-3 text-xs font-semibold text-stone-500 uppercase tracking-wide">Status</th>
                    <th class="px-4 py-3 text-xs font-semibold text-stone-500 uppercase tracking-wide">Actions</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-stone-100">
                  {{#each this.refundRows as |r|}}
                    <tr class="hover:bg-stone-50/70 transition-colors">
                      <td class="px-4 py-3 font-mono text-xs font-medium text-stone-700">{{r.enquiryRef}}</td>
                      <td class="px-4 py-3 text-stone-600 text-xs">
                        {{#if r.isMuhurtham}}
                          <span class="text-yellow-700 font-semibold">★ Muhurtham</span>
                        {{else}}
                          Non-muhurtham
                        {{/if}}
                      </td>
                      <td class="px-4 py-3 text-stone-800 tabular-nums text-xs">₹{{r.advanceRupees}}</td>
                      <td class="px-4 py-3 text-stone-800 tabular-nums text-xs">
                        {{#if r.refundPct}}{{r.refundPct}}%{{else}}—{{/if}}
                      </td>
                      <td class="px-4 py-3 text-stone-800 tabular-nums text-xs">
                        {{#if r.refundPaise}}₹{{r.refundRupees}}{{else}}—{{/if}}
                      </td>
                      <td class="px-4 py-3 font-mono text-xs text-stone-500">{{if r.replacedByRef r.replacedByRef "—"}}</td>
                      <td class="px-4 py-3 text-xs">
                        <span class="rounded-full border px-2 py-0.5 font-semibold {{r.statusCls}}">
                          {{r.status}}
                        </span>
                      </td>
                      <td class="px-4 py-3">
                        {{#if r.isPending}}
                          <div class="flex items-center gap-2">
                            <button type="button"
                              class="text-xs font-medium text-green-600 hover:text-green-800 transition-colors"
                              {{on "click" (fn this.processRefund r.id)}}>Processed</button>
                            <button type="button"
                              class="text-xs font-medium text-red-600 hover:text-red-800 transition-colors"
                              {{on "click" (fn this.denyRefund r.id)}}>Deny</button>
                          </div>
                        {{/if}}
                      </td>
                    </tr>
                  {{/each}}
                </tbody>
              </table>
            </div>
          {{else}}
            <div class="py-10 text-center text-sm text-stone-400">No refund records yet.</div>
          {{/if}}
        </div>
      </section>

      {{! Notifications }}
      <section class="mt-10 mb-10">
        <div class="flex items-baseline justify-between mb-3">
          <h2 class="text-base font-semibold text-stone-900">Notifications</h2>
          <span class="text-sm text-stone-400">{{this.notificationLog.length}} recent</span>
        </div>

        {{! Channel config status }}
        {{#if this.notifConfig}}
          <div class="rounded-xl border border-stone-200 bg-white shadow-sm p-4 mb-4">
            <p class="text-xs font-semibold text-stone-500 uppercase tracking-wide mb-3">Channel Status</p>
            <div class="flex flex-wrap gap-3">

              <div class="flex items-center gap-2 rounded-lg border px-3 py-2 {{if this.notifConfig.whatsappActive 'border-green-200 bg-green-50' 'border-stone-200 bg-stone-50'}}">
                <svg class="h-4 w-4 shrink-0 {{if this.notifConfig.whatsappActive 'text-green-500' 'text-stone-400'}}" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                  <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
                </svg>
                <div>
                  <p class="text-xs font-semibold {{if this.notifConfig.whatsappActive 'text-green-700' 'text-stone-600'}}">WhatsApp</p>
                  <p class="text-xs {{if this.notifConfig.whatsappActive 'text-green-500' 'text-stone-400'}}">{{if this.notifConfig.whatsappActive 'Active' 'Not configured'}}</p>
                </div>
              </div>

              <div class="flex items-center gap-2 rounded-lg border px-3 py-2 {{if this.notifConfig.ownerEmailSet 'border-blue-200 bg-blue-50' 'border-stone-200 bg-stone-50'}}">
                <svg class="h-4 w-4 shrink-0 {{if this.notifConfig.ownerEmailSet 'text-blue-500' 'text-stone-400'}}" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75"/>
                </svg>
                <div>
                  <p class="text-xs font-semibold {{if this.notifConfig.ownerEmailSet 'text-blue-700' 'text-stone-600'}}">Email</p>
                  <p class="text-xs {{if this.notifConfig.ownerEmailSet 'text-blue-500' 'text-stone-400'}}">{{if this.notifConfig.ownerEmailSet 'Configured' 'OWNER_EMAIL not set'}}</p>
                </div>
              </div>

              <div class="flex items-center gap-2 rounded-lg border px-3 py-2 {{if this.notifConfig.ownerMobileSet 'border-emerald-200 bg-emerald-50' 'border-stone-200 bg-stone-50'}}">
                <svg class="h-4 w-4 shrink-0 {{if this.notifConfig.ownerMobileSet 'text-emerald-500' 'text-stone-400'}}" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 1.5H8.25A2.25 2.25 0 006 3.75v16.5a2.25 2.25 0 002.25 2.25h7.5A2.25 2.25 0 0018 20.25V3.75a2.25 2.25 0 00-2.25-2.25H13.5m-3 0V3h3V1.5m-3 0h3m-3 8.25h3"/>
                </svg>
                <div>
                  <p class="text-xs font-semibold {{if this.notifConfig.ownerMobileSet 'text-emerald-700' 'text-stone-600'}}">Owner mobile</p>
                  <p class="text-xs {{if this.notifConfig.ownerMobileSet 'text-emerald-500' 'text-stone-400'}}">{{if this.notifConfig.ownerMobileSet 'Set' 'OWNER_MOBILE not set'}}</p>
                </div>
              </div>
            </div>

            {{#unless this.notifConfig.whatsappActive}}
              <details class="mt-4">
                <summary class="text-xs text-stone-500 cursor-pointer hover:text-stone-700 transition-colors select-none">Setup guide — enable WhatsApp notifications ▸</summary>
                <pre class="mt-2 rounded-lg bg-stone-900 text-green-300 text-xs p-3 overflow-x-auto leading-relaxed whitespace-pre-wrap">Add these to Tomcat's setenv.bat (or your startup command):

set WA_ENABLED=true
set WA_META_TOKEN=&lt;token from Meta Business Suite&gt;
set WA_META_PHONE_ID=&lt;Phone Number ID from Meta&gt;
set OWNER_MOBILE=&lt;10-digit mobile, no +91&gt;
set OWNER_EMAIL=&lt;owner@example.com&gt;

Then restart Tomcat. Notifications send automatically on each new booking.</pre>
              </details>
            {{/unless}}
          </div>
        {{/if}}

        {{! Notification log table }}
        <div class="rounded-xl border border-stone-200 bg-white shadow-sm overflow-hidden">
          {{#if this.notificationRows.length}}
            <div class="overflow-x-auto">
              <table class="w-full text-sm">
                <thead>
                  <tr class="bg-stone-50 border-b border-stone-200 text-left">
                    <th class="px-4 py-3 text-xs font-semibold text-stone-500 uppercase tracking-wide">Reference</th>
                    <th class="px-4 py-3 text-xs font-semibold text-stone-500 uppercase tracking-wide">Channel</th>
                    <th class="px-4 py-3 text-xs font-semibold text-stone-500 uppercase tracking-wide">Status</th>
                    <th class="px-4 py-3 text-xs font-semibold text-stone-500 uppercase tracking-wide">Attempts</th>
                    <th class="px-4 py-3 text-xs font-semibold text-stone-500 uppercase tracking-wide">Sent at</th>
                    <th class="px-4 py-3 text-xs font-semibold text-stone-500 uppercase tracking-wide">Error</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-stone-100">
                  {{#each this.notificationRows as |n|}}
                    <tr class="hover:bg-stone-50/70 transition-colors">
                      <td class="px-4 py-3 font-mono text-xs text-stone-600">{{n.enquiryRef}}</td>
                      <td class="px-4 py-3">
                        <span class="rounded-full px-2 py-0.5 text-xs font-semibold {{n.channelCls}}">{{n.channel}}</span>
                      </td>
                      <td class="px-4 py-3">
                        <span class="rounded-full px-2 py-0.5 text-xs font-semibold {{n.statusCls}}">{{n.status}}</span>
                      </td>
                      <td class="px-4 py-3 text-xs text-stone-500 tabular-nums">{{n.attempts}}</td>
                      <td class="px-4 py-3 text-xs text-stone-500 whitespace-nowrap">{{if n.sentAtFmt n.sentAtFmt "—"}}</td>
                      <td class="px-4 py-3 text-xs text-red-500 max-w-xs truncate" title={{n.lastError}}>{{if n.lastError n.lastError "—"}}</td>
                    </tr>
                  {{/each}}
                </tbody>
              </table>
            </div>
          {{else}}
            <div class="py-10 text-center text-sm text-stone-400">No notification records yet. Notifications are sent automatically when a new booking arrives.</div>
          {{/if}}
        </div>
      </section>

      {{! WhatsApp Broadcast }}
      <section class="mt-8">
        <h2 class="text-base font-semibold text-stone-900 mb-3">WhatsApp Broadcast</h2>
        <div class="rounded-xl border border-stone-200 bg-white shadow-sm p-5 space-y-4">
          <div class="flex flex-wrap items-center gap-3">
            <label class="text-sm font-medium text-stone-600">Month:</label>
            <input type="month" value={{this.broadcastMonth}}
              class="rounded-lg border border-stone-200 bg-white px-3 py-1.5 text-sm text-stone-700 focus:border-rose-500 focus:outline-none"
              {{on "change" this.setBroadcastMonth}} />
            <span class="text-sm text-stone-400">{{this.broadcastRows.length}} confirmed / completed bookings</span>
          </div>
          <div>
            <label class="block text-sm font-medium text-stone-600 mb-1">Message</label>
            <textarea rows="3"
              placeholder="Type your broadcast message here..."
              class="w-full rounded-lg border border-stone-200 bg-white px-3 py-2 text-sm text-stone-900 placeholder:text-stone-400 focus:border-rose-500 focus:ring-4 focus:ring-rose-500/10 focus:outline-none resize-none"
              {{on "input" this.setBroadcastMessage}}></textarea>
          </div>
          {{#if this.broadcastRows.length}}
            <div class="divide-y divide-stone-100">
              {{#each this.broadcastRows as |e|}}
                <div class="flex items-center justify-between py-2.5">
                  <div>
                    <p class="text-sm font-medium text-stone-800">{{e.customerName}}</p>
                    <p class="text-xs text-stone-400">{{e.mobile}} &middot; {{e.eventDateFmt}}</p>
                  </div>
                  <a href={{e.waUrl}} target="_blank" rel="noopener noreferrer"
                    class="flex items-center gap-1.5 rounded-full bg-[#25D366] px-3 py-1.5 text-xs font-semibold text-white hover:bg-[#1ebe5d] transition-colors">
                    <svg class="h-3.5 w-3.5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                      <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
                    </svg>
                    Send
                  </a>
                </div>
              {{/each}}
            </div>
          {{else}}
            <p class="text-sm text-stone-400 text-center py-4">No confirmed or completed bookings for this month.</p>
          {{/if}}
        </div>
      </section>

    </div>
  </template>
}
