<script def>
{ "widget": { "family": "1x2" } }
</script>

<script setup>
import { nextPrayer, leftText } from '../pt.js';
import { savedLoc } from '../store.js';

/* the next prayer at a glance; the main page saves the position this widget uses */
export default {
  data: { name: '', at: '', left: '' },
  timer: null,

  onCreate() { this.update(); },
  onAttach() {
    this.update();
    if (!this.timer) this.timer = setInterval(() => this.update(), 30000);
  },
  onDetach() { this.stop(); },
  onDestroy() { this.stop(); },
  stop() { if (this.timer) { clearInterval(this.timer); this.timer = null; } },

  update() {
    const loc = savedLoc(), n = nextPrayer(new Date(), loc.lat, loc.lng);
    this.setData({ name: n.name, at: n.at, left: leftText(n.left) });
  },
};
</script>

<widget>
  <view class="w">
    <view class="main">
      <text class="name">{{name}}</text>
      <text class="at">{{at}}</text>
    </view>
    <text class="left">{{left}}</text>
  </view>
</widget>

<style>
.w {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: flex-end;
  gap: 4px;
  padding: 8px 14px;
  box-sizing: border-box;
  font-family: 'Murshid Arabic', sans-serif;
}
.main { display: flex; flex-direction: row-reverse; align-items: baseline; gap: 10px; }
.name { font-size: 24px; color: #40ff5e; }
.at { font-size: 22px; color: rgba(64,255,94,0.72); font-family: monospace; }
.left { font-size: 13px; color: rgba(64,255,94,0.48); }
</style>
