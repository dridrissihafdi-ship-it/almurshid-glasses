# Agent Manifest

## Identity
- **Name**: المرشد (Al-Murshid)
- **Version**: 0.1.0
- **Description**: A companion of the Al-Murshid tazkiya app for Rokid Glasses. It shows the next prayer, the morning and evening adhkar one at a time, a dhikr counter (subha), and today's prayer times. The interface is in Arabic.
- **Author**: Al-Murshid (almurshidapp.com)

## Behaviour
- Open with "Hi Rokid, open Al-Murshid" (افتح المرشد).
- Main page: next prayer with time left, then four entries: morning adhkar, evening adhkar, subha, today's times.
- Adhkar: tap the temple to read on or count one repetition; swipe forward or back to move between parts and adhkar. Progress is kept for the day.
- Subha: tap to count; swipe to change the phrase. Counts reset each day.
- Widget "الصلاة القادمة": the next prayer and the time left.

## Boundaries
- No account, no network calls, and no personal data leave the glasses.
- Location is used only to calculate prayer times and is stored on the glasses. Without it, times follow Fez, Morocco, and the screen says so.
- Religious texts are fixed and reproduced exactly from the Al-Murshid app; the agent never generates or paraphrases them.

## Capabilities
- **Permissions**:
  - GEOLOCATION (prayer times)
