<script def>
{
  "navigationBarTitleText": "المرشد"
}
</script>

<script setup>
import { nextPrayer, leftText, adhkarNow, prayerTimes, hm, NAMES } from '../pt.js';
import { savedLoc, refreshLoc, load, store, today } from '../store.js';
import { ADHKAR } from '../adhkar.js';

/* One page, four modes: menu, adhkar, subha, times.
   The page reads the temple keys itself, so nothing depends on focus or page navigation:
   tap (Enter, or the temple button "GlobalHook") = confirm / count,
   swipe (ArrowDown / ArrowUp) = next / previous,
   back (Backspace) = return to the menu. */
const MENU = [
  ['adhkar-sabah', 'أذكار الصباح'],
  ['adhkar-masa', 'أذكار المساء'],
  ['subha', 'السبحة'],
  ['times', 'مواقيت اليوم'],
];
const PHRASES = [
  ['سبحان الله', 33], ['الحمد لله', 33], ['الله أكبر', 34],
  ['أستغفر الله', 100], ['اللهم صلِّ على سيدنا محمد', 100], ['لا إله إلا الله', 100],
];
const TAP = ['Enter', 'GlobalHook', 'NumpadEnter', 'Space'];
const NEXT = ['ArrowDown', 'ArrowRight', 'PageDown'];
const PREV = ['ArrowUp', 'ArrowLeft', 'PageUp'];
const BACK = ['Backspace', 'Escape', 'GoBack', 'BrowserBack'];
const ORDER = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];

export default {
  data: {
    mode: 'menu',
    lastKey: '',
    /* menu */
    prayerName: '', prayerAt: '', prayerLeft: '', suggest: '', locNote: '',
    items: [],
    /* adhkar */
    aTitle: '', aText: '', aPos: '', aCount: '', aHint: '',
    /* subha */
    sPhrase: '', sCount: 0, sTarget: 33, sPos: '', sTotal: 0, sDone: false, sBar: 'width: 0%;',
    /* times */
    rows: [],
  },
  sel: 0,
  loc: null,
  timer: null,
  lastAt: 0,
  lastCode: '',
  /* adhkar state */
  kind: 'sabah', list: [], i: 0, part: 0, reps: 0,
  /* subha state */
  st: null, k: 0,

  onLoad() {
    this.loc = savedLoc();
    this.renderMenu();
    refreshLoc((loc) => { this.loc = loc; if (this.data.mode === 'menu') this.renderMenu(); if (this.data.mode === 'times') this.renderTimes(); });
  },
  onShow() {
    if (this.data.mode === 'menu') this.renderMenu();
    if (!this.timer) this.timer = setInterval(() => { if (this.data.mode === 'menu') this.renderMenu(); }, 30000);
  },
  onHide() { this.stopTimer(); },
  onUnload() { this.stopTimer(); },
  stopTimer() { if (this.timer) { clearInterval(this.timer); this.timer = null; } },

  /* ---------- keys ---------- */
  handleKey(event) {
    if (!event) return false;
    const code = event.code || event.key || '';
    /* the same press can reach both the page and the root view */
    const now = Date.now();
    if (now - this.lastAt < 120 && code === this.lastCode) return true;
    this.lastAt = now; this.lastCode = code;
    this.setData({ lastKey: code });
    const m = this.data.mode;
    if (TAP.includes(code)) { this.tap(); return true; }
    if (NEXT.includes(code)) { this.step(1); return true; }
    if (PREV.includes(code)) { this.step(-1); return true; }
    if (BACK.includes(code) && m !== 'menu') { this.toMenu(); return true; }
    return false;
  },
  onKeyDown(event) { this.handleKey(event); },
  onRootKey(event) { this.handleKey(event); },
  onKeyUp(event) {
    if (!event) return;
    const code = event.code || event.key || '';
    const ours = TAP.includes(code) || NEXT.includes(code) || PREV.includes(code) || (BACK.includes(code) && this.data.mode !== 'menu');
    if (ours && typeof event.preventDefault === 'function') event.preventDefault();
  },

  tap() {
    const m = this.data.mode;
    if (m === 'menu') this.open(this.sel);
    else if (m === 'adhkar') this.adhTap();
    else if (m === 'subha') this.subAdd();
    else this.toMenu();
  },
  step(d) {
    const m = this.data.mode;
    if (m === 'menu') { this.sel = (this.sel + d + MENU.length) % MENU.length; this.renderMenu(); }
    else if (m === 'adhkar') { if (d > 0) this.adhForward(); else this.adhBack(); }
    else if (m === 'subha') { this.k = (this.k + d + PHRASES.length) % PHRASES.length; this.renderSubha(); }
  },
  toMenu() { this.setData({ mode: 'menu' }); this.renderMenu(); },

  /* touch / mouse in the simulator */
  pick0() { this.sel = 0; this.open(0); },
  pick1() { this.sel = 1; this.open(1); },
  pick2() { this.sel = 2; this.open(2); },
  pick3() { this.sel = 3; this.open(3); },
  tapArea() { this.tap(); },

  open(n) {
    const id = MENU[n][0];
    if (id === 'adhkar-sabah' || id === 'adhkar-masa') this.startAdhkar(id === 'adhkar-sabah' ? 'sabah' : 'masa');
    else if (id === 'subha') this.startSubha();
    else { this.setData({ mode: 'times' }); this.renderTimes(); }
  },

  /* ---------- menu ---------- */
  renderMenu() {
    const loc = this.loc || savedLoc(), now = new Date();
    const n = nextPrayer(now, loc.lat, loc.lng), a = adhkarNow(now, loc.lat, loc.lng);
    this.setData({
      prayerName: n.name, prayerAt: n.at, prayerLeft: leftText(n.left),
      suggest: a === 'sabah' ? 'وقت أذكار الصباح' : a === 'masa' ? 'وقت أذكار المساء' : '',
      locNote: loc.guess ? 'المواقيت حسب فاس حتى يُعرف موقعك' : '',
      items: MENU.map(([id, t], i) => ({ id, t, cls: i === this.sel ? 'item on' : 'item' })),
    });
  },

  /* ---------- adhkar ---------- */
  startAdhkar(kind) {
    this.kind = kind; this.list = ADHKAR[kind] || [];
    const saved = load('murshid-adh-' + kind, null);
    this.i = saved && saved.day === today() && saved.i < this.list.length ? saved.i : 0;
    this.part = 0; this.reps = 0;
    this.setData({ mode: 'adhkar' });
    this.renderAdhkar();
  },
  renderAdhkar() {
    const title = this.kind === 'sabah' ? 'أذكار الصباح' : 'أذكار المساء';
    store('murshid-adh-' + this.kind, { day: today(), i: this.i });
    if (this.i >= this.list.length) {
      this.setData({ aTitle: title, aText: 'أتممت الأذكار، تقبّل الله منك.', aPos: '', aCount: '', aHint: 'اضغط للعودة' });
      return;
    }
    const d = this.list[this.i], last = this.part === d.p.length - 1;
    this.setData({
      aTitle: title,
      aText: d.p[this.part],
      aPos: (this.i + 1) + ' / ' + this.list.length + (d.p.length > 1 ? '  ·  ' + (this.part + 1) + '/' + d.p.length : ''),
      aCount: d.n > 1 ? this.reps + ' / ' + d.n : '',
      aHint: !last ? 'اضغط للتتمة' : d.n > 1 ? 'اضغط بعد كل مرة' : 'اضغط للذكر التالي',
    });
  },
  adhNext() { this.i++; this.part = 0; this.reps = 0; this.renderAdhkar(); },
  adhTap() {
    if (this.i >= this.list.length) { this.store0(); this.toMenu(); return; }
    const d = this.list[this.i];
    if (this.part < d.p.length - 1) { this.part++; this.renderAdhkar(); return; }
    this.reps++;
    if (this.reps >= d.n) { this.adhNext(); return; }
    this.part = 0; this.renderAdhkar();
  },
  store0() { store('murshid-adh-' + this.kind, { day: today(), i: 0 }); },
  adhForward() {
    if (this.i >= this.list.length) return;
    const d = this.list[this.i];
    if (this.part < d.p.length - 1) { this.part++; this.renderAdhkar(); } else this.adhNext();
  },
  adhBack() {
    if (this.part > 0) { this.part--; this.renderAdhkar(); return; }
    if (this.i > 0) { this.i = Math.min(this.i, this.list.length) - 1; this.part = this.list[this.i].p.length - 1; this.reps = 0; this.renderAdhkar(); }
  },

  /* ---------- subha ---------- */
  startSubha() {
    const s = load('murshid-subha', null);
    this.st = s && s.day === today() ? s : { day: today(), c: PHRASES.map(() => 0), k: 0 };
    this.k = this.st.k || 0;
    this.setData({ mode: 'subha' });
    this.renderSubha();
  },
  renderSubha() {
    const [t, n] = PHRASES[this.k], c = this.st.c[this.k] || 0;
    this.st.k = this.k; store('murshid-subha', this.st);
    this.setData({
      sPhrase: t, sCount: c, sTarget: n, sPos: (this.k + 1) + ' / ' + PHRASES.length,
      sTotal: this.st.c.reduce((a, b) => a + b, 0), sDone: c >= n,
      sBar: 'width: ' + Math.min(100, Math.round((c / n) * 100)) + '%;',
    });
  },
  subAdd() {
    if (this.st.day !== today()) this.st = { day: today(), c: PHRASES.map(() => 0), k: this.k };
    this.st.c[this.k] = (this.st.c[this.k] || 0) + 1;
    if (this.st.c[this.k] === PHRASES[this.k][1] && this.k < 2) this.k++;
    this.renderSubha();
  },

  /* ---------- times ---------- */
  renderTimes() {
    const loc = this.loc || savedLoc(), now = new Date();
    const pt = prayerTimes(now, loc.lat, loc.lng), nx = nextPrayer(now, loc.lat, loc.lng);
    this.setData({
      rows: ORDER.map((k) => ({ k, name: NAMES[k], at: hm(pt[k]), mark: k === nx.k ? '◂ القادمة' : '', cls: k === nx.k ? 'row cur' : k === 'sunrise' ? 'row dim' : 'row' })),
    });
  },
};
</script>

<page>
  <view class="page" bindkeydown="onRootKey">

    <view class="menu-w" ink:if="{{mode === 'menu'}}">
      <view class="next">
        <text class="next-label">الصلاة القادمة</text>
        <view class="next-row">
          <text class="next-name">{{prayerName}}</text>
          <text class="next-at">{{prayerAt}}</text>
        </view>
        <text class="next-left">{{prayerLeft}}</text>
      </view>
      <text class="suggest" ink:if="{{suggest}}">{{suggest}}</text>
      <view class="menu">
        <view class="{{items[0].cls}}" bindtap="pick0"><text class="item-t">{{items[0].t}}</text></view>
        <view class="{{items[1].cls}}" bindtap="pick1"><text class="item-t">{{items[1].t}}</text></view>
        <view class="{{items[2].cls}}" bindtap="pick2"><text class="item-t">{{items[2].t}}</text></view>
        <view class="{{items[3].cls}}" bindtap="pick3"><text class="item-t">{{items[3].t}}</text></view>
      </view>
      <text class="note">اسحب للاختيار · اضغط للفتح{{locNote ? ' · ' + locNote : ''}}</text>
      <text class="key" ink:if="{{lastKey}}">{{lastKey}}</text>
    </view>

    <view class="adh" ink:elif="{{mode === 'adhkar'}}" bindtap="tapArea">
      <view class="bar-top">
        <text class="t-title">{{aTitle}}</text>
        <text class="t-pos">{{aPos}}</text>
      </view>
      <text class="dhikr">{{aText}}</text>
      <view class="bar-bottom">
        <text class="count" ink:if="{{aCount}}">{{aCount}}</text>
        <text class="hint">{{aHint}}</text>
      </view>
    </view>

    <view class="sub" ink:elif="{{mode === 'subha'}}" bindtap="tapArea">
      <text class="t-pos">{{sPos}}</text>
      <text class="phrase">{{sPhrase}}</text>
      <view class="num">
        <text class="s-count">{{sCount}}</text>
        <text class="s-target">/ {{sTarget}}</text>
      </view>
      <view class="s-bar"><view class="s-fill" style="{{sBar}}"></view></view>
      <text class="s-done" ink:if="{{sDone}}">تمّ ✓</text>
      <text class="hint">اضغط للعدّ · اسحب لتغيير الذكر · اليوم: {{sTotal}}</text>
    </view>

    <view class="times" ink:else bindtap="tapArea">
      <view class="{{r.cls}}" ink:for="{{rows}}" ink:for-item="r" ink:key="k">
        <text class="name">{{r.name}}</text>
        <text class="mark">{{r.mark}}</text>
        <text class="at">{{r.at}}</text>
      </view>
      <text class="hint">اضغط للرجوع</text>
    </view>

  </view>
</page>

<style>
.page {
  width: 100%;
  height: 100%;
  padding: 10px 16px;
  box-sizing: border-box;
  background: #000000;
  font-family: 'Murshid Arabic', sans-serif;
}
.menu-w, .adh, .sub, .times { width: 100%; height: 100%; display: flex; flex-direction: column; }
.menu-w { gap: 6px; }

.next { display: flex; flex-direction: column; align-items: flex-end; padding-bottom: 6px; border-bottom: 1px solid rgba(64,255,94,0.24); }
.next-label { font-size: 12px; color: rgba(64,255,94,0.48); text-align: right; }
.next-row { display: flex; flex-direction: row-reverse; align-items: baseline; gap: 12px; }
.next-name { font-size: 24px; color: #40ff5e; }
.next-at { font-size: 21px; color: rgba(64,255,94,0.72); font-family: monospace; }
.next-left { font-size: 13px; color: rgba(64,255,94,0.72); text-align: right; }
.suggest { font-size: 13px; color: #40ff5e; text-align: right; }
.menu { display: flex; flex-direction: column; gap: 5px; }
.item { padding: 4px 12px; border: 1px solid rgba(64,255,94,0.36); border-radius: 6px; display: flex; flex-direction: row-reverse; }
.item-t { font-size: 17px; color: rgba(64,255,94,0.72); text-align: right; }
.on { border: 2px solid #40ff5e; background: rgba(64,255,94,0.14); }
.on .item-t { color: #40ff5e; }
.note { font-size: 11px; color: rgba(64,255,94,0.48); text-align: right; }
.key { font-size: 10px; color: rgba(64,255,94,0.36); font-family: monospace; }

.bar-top { display: flex; flex-direction: row-reverse; justify-content: space-between; align-items: center; padding-bottom: 6px; border-bottom: 1px solid rgba(64,255,94,0.24); }
.t-title { font-size: 13px; color: rgba(64,255,94,0.72); }
.t-pos { font-size: 12px; color: rgba(64,255,94,0.48); font-family: monospace; }
.dhikr { flex-grow: 1; padding-top: 10px; font-size: 22px; line-height: 1.85; color: #40ff5e; text-align: right; }
.bar-bottom { display: flex; flex-direction: row-reverse; justify-content: space-between; align-items: center; padding-top: 6px; border-top: 1px solid rgba(64,255,94,0.24); }
.count { font-size: 18px; color: #40ff5e; font-family: monospace; }
.hint { font-size: 12px; color: rgba(64,255,94,0.48); text-align: center; }

.sub { align-items: center; justify-content: center; gap: 8px; }
.phrase { font-size: 26px; color: #40ff5e; text-align: center; }
.num { display: flex; flex-direction: row; align-items: baseline; gap: 6px; }
.s-count { font-size: 54px; color: #40ff5e; font-family: monospace; }
.s-target { font-size: 18px; color: rgba(64,255,94,0.48); font-family: monospace; }
.s-bar { width: 70%; height: 4px; background: rgba(64,255,94,0.12); border-radius: 2px; overflow: hidden; }
.s-fill { height: 100%; background: #40ff5e; }
.s-done { font-size: 14px; color: #40ff5e; }

.times { gap: 2px; }
.row { display: flex; flex-direction: row-reverse; align-items: center; gap: 10px; padding: 4px 8px; border-bottom: 1px solid rgba(64,255,94,0.12); }
.name { font-size: 18px; color: rgba(64,255,94,0.72); width: 90px; text-align: right; }
.mark { flex-grow: 1; font-size: 12px; color: #40ff5e; text-align: right; }
.at { font-size: 18px; color: rgba(64,255,94,0.72); font-family: monospace; }
.cur { border: 1px solid #40ff5e; border-radius: 6px; background: rgba(64,255,94,0.12); }
.cur .name, .cur .at { color: #40ff5e; }
.dim .name, .dim .at { color: rgba(64,255,94,0.48); }
</style>
