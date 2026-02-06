# Launch Checklist — MP3 Extract

Complete every item before submitting to the Play Store.

---

## QA Testing

### Device Coverage
- [ ] Android 8.0 (API 26) — legacy storage permissions
- [ ] Android 10 (API 29) — Scoped Storage transition
- [ ] Android 13 (API 33) — granular media permissions
- [ ] Android 14 (API 34) — latest, predictive back

### Screen Sizes
- [ ] Small phone (5″, 720 × 1280)
- [ ] Medium phone (6″, 1080 × 2340)
- [ ] Large phone / phablet (7″+, 1440 × 3200)

### Conversion Scenarios
- [ ] Short video (30 sec, MP4) — completes < 10 sec
- [ ] Medium video (5 min, various: MP4, AVI, MKV, MOV) — all succeed
- [ ] Long video (30 min) — progress bar is accurate
- [ ] Very long video (1 hour) — no timeout (limit is 10 min; may need bump)
- [ ] Corrupt / empty file — friendly error shown
- [ ] Audio-only file (MP3 renamed to MP4) — graceful failure
- [ ] Unsupported codec — clear error message

### Quality & Output
- [ ] 128 kbps — file size is ≈ 1 MB/min
- [ ] 192 kbps — file size is ≈ 1.5 MB/min
- [ ] 320 kbps — file size is ≈ 2.5 MB/min
- [ ] Output plays in default music player
- [ ] Output plays in third-party player (VLC, Spotify local)

### Features
- [ ] File picker opens correctly
- [ ] Video preview thumbnail shown
- [ ] Custom file name input works (validation, max 50 chars)
- [ ] Quality pills select/deselect correctly
- [ ] Conversion progress ring animates smoothly (60 FPS)
- [ ] Cancel conversion mid-way — partial file cleaned up
- [ ] Success screen — play preview works
- [ ] Success screen — share to WhatsApp, Gmail, Telegram
- [ ] Success screen — delete output file
- [ ] History — all conversions listed with date grouping
- [ ] History — search by file name
- [ ] History — filter: Today, This Week, High Quality
- [ ] History — delete single entry
- [ ] History — clear all entries
- [ ] Settings — dark mode toggle persists across restart
- [ ] Settings — default quality persists across restart
- [ ] Settings — normalize volume toggle
- [ ] Settings — auto-delete original toggle
- [ ] Settings — storage info shows correct values

### Ads & Monetization
- [ ] Banner ad loads on home screen (not blocking content)
- [ ] Interstitial ad shows after configured frequency
- [ ] "Remove Ads" button visible in settings
- [ ] IAP purchase flow completes (sandbox account)
- [ ] After purchase: banner and interstitial no longer appear
- [ ] Restore purchases after reinstall works
- [ ] Ad-free state persists across app restarts

### Edge Cases
- [ ] Airplane mode — conversion works offline, ads fail gracefully
- [ ] Low storage (< 100 MB) — disk space warning shown
- [ ] App killed during conversion — no crash on reopen
- [ ] Rapid tap on CONVERT — no double conversion
- [ ] Back button during conversion — confirm dialog or cancel
- [ ] Orientation lock — portrait only, no rotation bugs

### Accessibility
- [ ] TalkBack reads all interactive elements
- [ ] Sufficient contrast ratios (WCAG AA)
- [ ] Touch targets ≥ 48 dp
- [ ] No content cut off at largest font size

### Performance
- [ ] UI renders at 60 FPS (check with `flutter run --profile`)
- [ ] No memory leaks (check DevTools memory tab)
- [ ] APK size < 30 MB
- [ ] Cold start < 2 seconds on mid-range device

---

## Play Store Assets

### Required
- [ ] **App Icon**: 512 × 512 PNG, high-res, transparent background
- [ ] **Feature Graphic**: 1024 × 500 PNG (hero banner for store listing)
- [ ] **Screenshots**: 5–8 phone screenshots (1080 × 1920 or higher)
  - Home screen (show recent conversions)
  - Quality selection (highlight options)
  - Conversion progress (show speed)
  - Success screen (show share)
  - Settings (highlight Remove Ads)
  - History (show filters)
- [ ] **Short Description** (80 chars max):
  > Convert videos to MP3 offline. Fast, free, no account needed.
- [ ] **Full Description** (4000 chars max): ASO-optimised, with keywords

### Optional but Recommended
- [ ] Tablet screenshots (2–4, 7″ and 10″)
- [ ] Promo video (30 sec YouTube link)

---

## Store Listing

- [ ] **App Name**: MP3 Extract — Video to MP3
- [ ] **Category**: Music & Audio
- [ ] **Tags**: converter, audio, mp3, video, offline, utility
- [ ] **Content Rating**: Complete IARC questionnaire → Expected: Everyone
- [ ] **Privacy Policy**: Hosted on public URL (GitHub Pages or website)
  - Covers: no personal data collection, permissions used, AdMob, Play Billing
- [ ] **Pricing**: Free
- [ ] **Countries**: All (or target regions)
- [ ] **Contact email**: Listed in store

---

## Release Tracks

| Track | Testers | Purpose |
|-------|---------|---------|
| Internal Testing | 10–20 | Quick smoke testing |
| Closed Testing (Alpha) | 50–100 | Detailed QA, crash reports |
| Open Testing (Beta) | Public opt-in | Real-world validation |
| Production | Everyone | Full launch |

### Rollout Strategy
1. **Internal** → Fix critical bugs (1–2 days)
2. **Closed Alpha** → Collect feedback (3–5 days)
3. **Open Beta** → Monitor crash rate, target < 0.5% (5–7 days)
4. **Production** → Staged rollout: 10% → 25% → 50% → 100%

---

## Post-Launch Monitoring (Week 1)

- [ ] Crash rate < 0.5% (Firebase Crashlytics or Play Console)
- [ ] Conversion success rate > 95%
- [ ] Daily active users trending up
- [ ] Ad fill rate > 80%
- [ ] IAP conversion rate > 2%
- [ ] Respond to all reviews within 24 hours
- [ ] Average rating > 4.5 ★

### Key Metrics Targets

| Metric | Day 1 | Day 7 | Day 30 |
|--------|-------|-------|--------|
| Retention | > 25% | > 12% | > 6% |
| Conversions/User | > 1 | > 3 | > 5 |
| Ad Revenue/DAU | — | $0.05 | $0.08 |

---

## Privacy Policy Template

Host at `https://yourdomain.com/mp3extract/privacy` and include:

1. **Data Collection**: MP3 Extract does not collect, store, or transmit any personal data.
2. **Permissions**: Storage access is used solely to read video files and write converted MP3 files on-device.
3. **Third-Party Services**:
   - Google AdMob: Serves ads; see [Google's Privacy Policy](https://policies.google.com/privacy).
   - Google Play Billing: Processes in-app purchases; see [Google Play Terms](https://play.google.com/intl/en_us/about/play-terms/).
4. **Children**: This app is not directed at children under 13.
5. **Contact**: [your-email@example.com]

---

✅ **Ready to launch when all boxes are checked!**
