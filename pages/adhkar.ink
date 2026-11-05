<script def>
{
  "navigationBarTitleText": "الأذكار"
}
</script>

<script setup>
import { ADHKAR } from '../adhkar.js';
import { load, store, today } from '../store.js';

/* One dhikr at a time, one screen-sized part at a time.
   Tap (Enter): next part, or one repetition on the last part; the next dhikr opens by itself when the count is complete.
   Swipe forward / back (ArrowDown / ArrowUp): next / previous part or dhikr. */
export default {
  data: {
    title: '',
    text: '',
    pos: '',
    count: '',
    hint: '',
    done: false,
  },
  kind: 'sabah',
  list: [],
  i: 0,
  part: 0,
  reps: 0,

  onLoad(query) {
    this.kind = query && query.k === 'masa' ? 'masa' : 'sabah';
    this.list = ADHKAR[this.kind] || [];
    const saved = load('murshid-adh-' + this.kind, null);
    if (saved && saved.day === today() && saved.i < this.list.length) { this.i = saved.i; }
    this.show();
  },

  save() { store('murshid-adh-' + this.kind, { day: today(), i: this.i, done: this.data.done }); },

  show() {
    if (!this.list.length) { this.setData({ text: 'تعذّر تحميل الأذكار.', pos: '', count: '' }); return; }
    if (this.i >= this.list.length) {
      this.setData({
        title: this.kind === 'sabah' ? 'أذكار الصباح' : 'أذكار المساء',
        text: 'أتممت الأذكار، تقبّل الله منك.',
        pos: '', count: '', hint: 'اضغط للعودة إلى أولها', done: true,
      });
      this.save();
      return;
    }
    const d = this.list[this.i], last = this.part === d.p.length - 1;
    this.setData({
      title: this.kind === 'sabah' ? 'أذكار الصباح' : 'أذكار المساء',
      text: d.p[this.part],
      pos: (this.i + 1) + ' / ' + this.list.length + (d.p.length > 1 ? '  ·  ' + (this.part + 1) + '/' + d.p.length : ''),
      count: d.n > 1 ? this.reps + ' / ' + d.n : '',
      hint: !last ? 'اضغط للتتمة' : d.n > 1 ? 'اضغط بعد كل مرة' : 'اضغط للذكر التالي',
      done: false,
    });
    this.save();
  },

  nextDhikr() { this.i++; this.part = 0; this.reps = 0; this.show(); },

  tap() {
    if (this.i >= this.list.length) { this.i = 0; this.part = 0; this.reps = 0; this.show(); return; }
    const d = this.list[this.i];
    if (this.part < d.p.length - 1) { this.part++; this.show(); return; }
    this.reps++;
    if (this.reps >= d.n) { this.nextDhikr(); return; }
    /* a repeated dhikr starts again from its first part */
    this.part = 0;
    this.show();
  },

  forward() {
    if (this.i >= this.list.length) return;
    const d = this.list[this.i];
    if (this.part < d.p.length - 1) { this.part++; this.show(); } else this.nextDhikr();
  },

  back() {
    if (this.part > 0) { this.part--; this.show(); return; }
    if (this.i > 0) {
      this.i = Math.min(this.i, this.list.length) - 1;
      this.part = this.list[this.i].p.length - 1;
      this.reps = 0;
      this.show();
    }
  },

  onKeyDown(event) {
    if (!event) return;
    if (event.code === 'Enter') this.tap();
    else if (event.code === 'ArrowDown') this.forward();
    else if (event.code === 'ArrowUp') this.back();
  },
  onKeyUp(event) {
    if (!event) return;
    if ((event.code === 'Enter' || event.code === 'ArrowDown' || event.code === 'ArrowUp') && typeof event.preventDefault === 'function') {
      event.preventDefault();
    }
  },
};
</script>

<page>
  <view class="page">
    <view class="top">
      <text class="title">{{title}}</text>
      <text class="pos">{{pos}}</text>
    </view>
    <text class="dhikr">{{text}}</text>
    <view class="bottom">
      <text class="count" ink:if="{{count}}">{{count}}</text>
      <text class="hint">{{hint}}</text>
    </view>
  </view>
</page>

<style>
.page {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  padding: 10px 16px;
  background: #000000;
  font-family: 'Murshid Arabic', sans-serif;
}
.top {
  display: flex;
  flex-direction: row-reverse;
  justify-content: space-between;
  align-items: center;
  padding-bottom: 6px;
  border-bottom: 1px solid rgba(64,255,94,0.24);
}
.title { font-size: 13px; color: rgba(64,255,94,0.72); }
.pos { font-size: 12px; color: rgba(64,255,94,0.48); font-family: monospace; }
.dhikr {
  flex-grow: 1;
  padding-top: 10px;
  font-size: 22px;
  line-height: 1.85;
  color: #40ff5e;
  text-align: right;
}
.bottom {
  display: flex;
  flex-direction: row-reverse;
  justify-content: space-between;
  align-items: center;
  padding-top: 6px;
  border-top: 1px solid rgba(64,255,94,0.24);
}
.count { font-size: 18px; color: #40ff5e; font-family: monospace; }
.hint { font-size: 12px; color: rgba(64,255,94,0.48); }
</style>
