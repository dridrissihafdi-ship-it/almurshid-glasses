<script def>
{
  "navigationBarTitleText": "السبحة"
}
</script>

<script setup>
import { load, store, today } from '../store.js';

/* the same phrases and targets as the subha in Al-Murshid */
const PHRASES = [
  ['سبحان الله', 33],
  ['الحمد لله', 33],
  ['الله أكبر', 34],
  ['أستغفر الله', 100],
  ['اللهم صلِّ على سيدنا محمد', 100],
  ['لا إله إلا الله', 100],
];

/* Tap (Enter): +1. Swipe forward / back (ArrowDown / ArrowUp): next / previous phrase. */
export default {
  data: {
    phrase: '',
    count: 0,
    target: 33,
    pos: '',
    total: 0,
    complete: false,
    barStyle: 'width: 0%;',
  },
  st: null,
  k: 0,

  onLoad() {
    const s = load('murshid-subha', null);
    this.st = s && s.day === today() ? s : { day: today(), c: PHRASES.map(() => 0), k: 0 };
    this.k = this.st.k || 0;
    this.show();
  },

  show() {
    const [t, n] = PHRASES[this.k], c = this.st.c[this.k] || 0, total = this.st.c.reduce((a, b) => a + b, 0);
    this.setData({
      phrase: t,
      count: c,
      target: n,
      pos: (this.k + 1) + ' / ' + PHRASES.length,
      total,
      complete: c >= n,
      barStyle: 'width: ' + Math.min(100, Math.round((c / n) * 100)) + '%;',
    });
    this.st.k = this.k;
    store('murshid-subha', this.st);
  },

  add() {
    if (this.st.day !== today()) this.st = { day: today(), c: PHRASES.map(() => 0), k: this.k };
    this.st.c[this.k] = (this.st.c[this.k] || 0) + 1;
    /* move to the next phrase once its count is reached, as after the prayer */
    if (this.st.c[this.k] === PHRASES[this.k][1] && this.k < 2) this.k++;
    this.show();
  },
  move(step) { this.k = (this.k + step + PHRASES.length) % PHRASES.length; this.show(); },

  onKeyDown(event) {
    if (!event) return;
    if (event.code === 'Enter') this.add();
    else if (event.code === 'ArrowDown') this.move(1);
    else if (event.code === 'ArrowUp') this.move(-1);
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
    <text class="pos">{{pos}}</text>
    <text class="phrase">{{phrase}}</text>
    <view class="num">
      <text class="count">{{count}}</text>
      <text class="target">/ {{target}}</text>
    </view>
    <view class="bar"><view class="fill" style="{{barStyle}}"></view></view>
    <text class="done" ink:if="{{complete}}">تمّ ✓</text>
    <text class="hint">اضغط للعدّ · اسحب لتغيير الذكر · اليوم: {{total}}</text>
  </view>
</page>

<style>
.page {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 12px 16px;
  background: #000000;
  font-family: 'Murshid Arabic', sans-serif;
}
.pos { font-size: 12px; color: rgba(64,255,94,0.48); font-family: monospace; }
.phrase { font-size: 26px; color: #40ff5e; text-align: center; }
.num { display: flex; flex-direction: row; align-items: baseline; gap: 6px; }
.count { font-size: 54px; color: #40ff5e; font-family: monospace; }
.target { font-size: 18px; color: rgba(64,255,94,0.48); font-family: monospace; }
.bar { width: 70%; height: 4px; background: rgba(64,255,94,0.12); border-radius: 2px; overflow: hidden; }
.fill { height: 100%; background: #40ff5e; }
.done { font-size: 14px; color: #40ff5e; }
.hint { font-size: 11px; color: rgba(64,255,94,0.48); text-align: center; }
</style>
