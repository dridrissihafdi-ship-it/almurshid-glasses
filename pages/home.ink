<script def>
{
  "navigationBarTitleText": "المرشد"
}
</script>

<script setup>
import wx from 'wx';
import { nextPrayer, leftText, adhkarNow } from '../pt.js';
import { savedLoc, refreshLoc } from '../store.js';

export default {
  data: {
    prayerName: '',
    prayerAt: '',
    prayerLeft: '',
    suggest: '',
    locNote: '',
  },
  timer: null,
  loc: null,

  onLoad() {
    this.loc = savedLoc();
    this.update();
    refreshLoc((loc) => { this.loc = loc; this.update(); });
  },
  onShow() {
    this.update();
    if (!this.timer) this.timer = setInterval(() => this.update(), 30000);
  },
  onHide() { this.stopTimer(); },
  onUnload() { this.stopTimer(); },
  stopTimer() { if (this.timer) { clearInterval(this.timer); this.timer = null; } },

  update() {
    const loc = this.loc || savedLoc(), now = new Date();
    const n = nextPrayer(now, loc.lat, loc.lng), a = adhkarNow(now, loc.lat, loc.lng);
    this.setData({
      prayerName: n.name,
      prayerAt: n.at,
      prayerLeft: leftText(n.left),
      suggest: a === 'sabah' ? 'وقت أذكار الصباح' : a === 'masa' ? 'وقت أذكار المساء' : '',
      locNote: loc.guess ? 'المواقيت حسب فاس حتى يُعرف موقعك' : '',
    });
  },

  go(url) { wx.navigateTo({ url, fail() {} }); },
  openSabah() { this.go('/pages/adhkar?k=sabah'); },
  openMasa() { this.go('/pages/adhkar?k=masa'); },
  openSubha() { this.go('/pages/subha'); },
  openTimes() { this.go('/pages/times'); },
};
</script>

<page>
  <view class="page">
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
      <button class="item" bindtap="openSabah">أذكار الصباح</button>
      <button class="item" bindtap="openMasa">أذكار المساء</button>
      <button class="item" bindtap="openSubha">السبحة</button>
      <button class="item" bindtap="openTimes">مواقيت اليوم</button>
    </view>
    <text class="note" ink:if="{{locNote}}">{{locNote}}</text>
  </view>
</page>

<style>
.page {
  width: 100%;
  min-height: 100%;
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 12px 16px;
  background: #000000;
  font-family: 'Murshid Arabic', sans-serif;
}
.next {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  padding-bottom: 8px;
  border-bottom: 1px solid rgba(64,255,94,0.24);
}
.next-label { font-size: 12px; color: rgba(64,255,94,0.48); text-align: right; }
.next-row { display: flex; flex-direction: row-reverse; align-items: baseline; gap: 12px; }
.next-name { font-size: 26px; color: #40ff5e; }
.next-at { font-size: 22px; color: rgba(64,255,94,0.72); font-family: monospace; }
.next-left { font-size: 14px; color: rgba(64,255,94,0.72); text-align: right; }
.suggest { font-size: 14px; color: #40ff5e; text-align: right; }
.menu {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.item {
  padding: 6px 12px;
  text-align: right;
  font-size: 17px;
  color: rgba(64,255,94,0.72);
  background: #000000;
  border: 1px solid rgba(64,255,94,0.48);
  border-radius: 6px;
}
.item:focus {
  color: #40ff5e;
  border: 2px solid #40ff5e;
  background: rgba(64,255,94,0.12);
}
.note { font-size: 11px; color: rgba(64,255,94,0.48); text-align: right; }
</style>
