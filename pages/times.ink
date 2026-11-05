<script def>
{
  "navigationBarTitleText": "مواقيت اليوم"
}
</script>

<script setup>
import { prayerTimes, nextPrayer, hm, NAMES } from '../pt.js';
import { savedLoc, refreshLoc } from '../store.js';

const ORDER = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];

export default {
  data: { rows: [], note: '' },
  loc: null,

  onLoad() {
    this.loc = savedLoc();
    this.update();
    refreshLoc((loc) => { this.loc = loc; this.update(); });
  },
  onShow() { this.update(); },

  update() {
    const loc = this.loc || savedLoc(), now = new Date();
    const pt = prayerTimes(now, loc.lat, loc.lng), nx = nextPrayer(now, loc.lat, loc.lng);
    this.setData({
      rows: ORDER.map((k) => ({ k, name: NAMES[k], at: hm(pt[k]), mark: k === nx.k ? '◂ القادمة' : '', cls: k === nx.k ? 'row next' : k === 'sunrise' ? 'row dim' : 'row' })),
      note: loc.guess ? 'حسب فاس حتى يُعرف موقعك' : '',
    });
  },
};
</script>

<page>
  <view class="page">
    <view class="{{r.cls}}" ink:for="{{rows}}" ink:for-item="r" ink:key="k">
      <text class="name">{{r.name}}</text>
      <text class="mark">{{r.mark}}</text>
      <text class="at">{{r.at}}</text>
    </view>
    <text class="note" ink:if="{{note}}">{{note}}</text>
  </view>
</page>

<style>
.page {
  width: 100%;
  min-height: 100%;
  display: flex;
  flex-direction: column;
  gap: 2px;
  padding: 12px 20px;
  background: #000000;
  font-family: 'Murshid Arabic', sans-serif;
}
.row {
  display: flex;
  flex-direction: row-reverse;
  align-items: center;
  gap: 10px;
  padding: 5px 8px;
  border-bottom: 1px solid rgba(64,255,94,0.12);
}
.name { font-size: 19px; color: rgba(64,255,94,0.72); width: 90px; text-align: right; }
.mark { flex-grow: 1; font-size: 12px; color: #40ff5e; text-align: right; }
.at { font-size: 19px; color: rgba(64,255,94,0.72); font-family: monospace; }
.next { border: 1px solid #40ff5e; border-radius: 6px; background: rgba(64,255,94,0.12); }
.next .name, .next .at { color: #40ff5e; }
.dim .name, .dim .at { color: rgba(64,255,94,0.48); }
.note { font-size: 11px; color: rgba(64,255,94,0.48); text-align: right; padding-top: 6px; }
</style>
