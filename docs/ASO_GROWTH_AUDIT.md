# AudioPeel — ASO, Ranking & Growth Audit

**App:** Video to MP3 – AudioPeel (`com.mcore.audiopeel`)
**Listing:** https://play.google.com/store/apps/details?id=com.mcore.audiopeel
**Audit date:** 30 Sep 2026
**Build audited:** v1.1.0 (build 2), the version live on Play. Its source is on the **unmerged** branch `origin/inh/ntification`, not on `main` (see §7.1).

---

## 0. Summary

**In one sentence:** AudioPeel is a clean, well-built MP3 extractor, but on Google Play it is close to invisible. It ranks for no generic keyword and has zero ratings. It shows a large download size, sits in a weak category, offers fewer features than every competitor, and has not been updated in 6.5 months. The few people who do install it can't find their MP3s, because files are saved to a hidden folder. So Play's ranking signals (install velocity, retention, ratings, engagement) never start moving.

| Metric | Value |
|---|---|
| Lifetime installs | **138** (Play's exact counter) in ~200 days, about **0.7 installs/day** |
| Ratings / reviews | **0** (no star rating is shown on the listing) |
| Rank for "video to mp3", "video to audio converter", "mp3 converter", "extract audio from video" (US, top 30) | **Not ranked on any of them.** It appears only when searching the brand "audiopeel". |
| Last update | Mar 14/15 2026 (v1.1.0). No release since. |
| Category | Tools |

Apps that launched in the **same window** did far better, so the niche is not closed:

| App | Launched | Installs today |
|---|---|---|
| Golden Mango "MP3 Converter : Video To Mp3" | 6 Apr 2026 | **169,546** |
| ss media "Video to MP3 Converter・2Audio" | 31 Mar 2026 | **10,880** (476 ratings) |
| HyperMind "Video to MP3 & Audio Converter" | 23 Jun 2026 | **10,294** |
| Decibel Labs "Video to MP3 Converter" | 24 Mar 2026 | **4,894** |
| **AudioPeel** | **14 Mar 2026** | **138** |

### The 10 root causes, ranked by impact

| # | Root cause | Area | Severity |
|---|---|---|---|
| 1 | **Converted MP3s are saved to a hidden app-private folder** (`Android/data/com.mcore.audiopeel/files/AudioPeel`). Music players, WhatsApp's audio picker and most file managers can't see them, so users think the app failed and uninstall it. | Product | 🔴 Critical |
| 2 | **Zero ratings, and no in-app review prompt.** With 0★ the listing converts poorly, and Play has no quality signal to rank it on. | ASO / product | 🔴 Critical |
| 3 | **Fewer features than every competitor:** MP3 only, no trim/cut, no batch, no M4A/WAV/AAC, no "Share to AudioPeel". Competitors rank on keywords like *cutter*, *ringtone maker*, *trim*, *merge* and *M4A* that AudioPeel can't honestly claim. | Product / ASO | 🔴 Critical |
| 4 | **Large download size** (your own docs estimate 80–90 MB) for a single-purpose utility. Heavy apps convert worse, especially in price-sensitive and low-storage markets like India, which is the main market for this category. | Product | 🟠 High |
| 5 | **Weak store creatives:** an icon that doesn't say "video → audio", screenshots that show a UI bug ("Time Remaining: 00:00 remaining"), a broken icon, the hidden `Android/data/...` save path and personal filenames, and a misleading "Download" caption. | ASO | 🟠 High |
| 6 | **Keyword coverage is thin.** The title and short description target only "video to mp3". The description is fine but short, and there is no localization at all (English/US only). | ASO | 🟠 High |
| 7 | **Wrong category (Tools).** The leaders sit in *Video Players & Editors* or *Music & Audio*. | ASO | 🟡 Medium |
| 8 | **No updates for 6.5 months.** Competitors ship monthly, and freshness plus the "What's new" text feed ranking and conversion. | Ops | 🟡 Medium |
| 9 | **Policy exposure:** the Data safety form says "No data collected" although AdMob collects data; there is no GDPR/UMP consent flow; READ_MEDIA_VIDEO and storage permissions are still declared even though they're unused; WRITE_SETTINGS is shown at install. Any of these can cause a rejected update or limited ad serving. | Compliance | 🟡 Medium (can become 🔴 overnight) |
| 10 | **No analytics or crash reporting.** You can't see where users drop off, which conversions fail or why people uninstall. | Engineering | 🟡 Medium |

**The fix, in order:** (1) save files where users can find them, (2) add a review prompt plus a "Share to AudioPeel" entry point, (3) add trim + M4A output + batch, (4) cut the app size, (5) rebuild the listing (title, short description, screenshots, icon test, category, localization), (6) fix compliance, (7) ship an update every 2–4 weeks. The detailed plan is in §10.

---

## 1. How Play decides who gets installs

The rest of this report explains why AudioPeel fails at each stage of this funnel. Every stage feeds the next one.

```
 Keyword relevance ──► IMPRESSIONS ──► STORE VISITS ──► INSTALLS ──► RETENTION / ENGAGEMENT ──► RATINGS
 (title, short desc,   (search rank,   (icon, title,    (screenshots,   (does it work? can I find   (review prompt,
  description,          browse, similar  rating, size)    rating, size,   my file? too many ads?)     happy moments)
  category, locale)     apps)                             description)          │
        ▲                                                                       │
        └────────────── Play re-ranks using install velocity, uninstall rate, ◄─┘
                        retention, ratings, Android vitals (crash/ANR)
```

| Stage | AudioPeel today | Why |
|---|---|---|
| Keyword relevance | Weak | 2 keyword phrases total; no *converter*, *audio extractor*, *cutter*, *ringtone* or *M4A* in the title or short description; no localized listings |
| Impressions | ~0 from search | Not in the top 30 for any head term; a new app with no velocity can't break in on head terms |
| Store visit → install | Likely poor | No rating, a large size, an icon that reads as a fruit/food app, screenshots with visible bugs |
| Retention | Likely poor | Files can't be found, interstitial ads fire right on the result screen, the feature set is narrow |
| Ratings | 0 | No in-app review API; nothing asks happy users to rate |
| Re-rank | Stuck | With no velocity and no ratings, the flywheel never starts |

---

## 2. Current listing, as live on Play

| Field | Current value | Assessment |
|---|---|---|
| Title (30 max) | `Video to MP3 – AudioPeel` (24) | Good that the keyword comes first. 6 characters are unused, and "AudioPeel" has no search volume. |
| Short description (80 max) | `Fast Video to MP3 Converter. Extract audio from video offline.` (62) | 18 characters unused. It repeats "video" 3×, and "Fast" is a claim everyone makes. |
| Full description | ~1,500 characters, well structured, keywords present | OK, but it uses less than 40% of the 4,000 limit and misses many long-tail terms (§5.3) |
| Category | Tools | See §5.4 |
| Icon | Orange-slice character with headphones on a beige background | See §5.5 |
| Feature graphic | Orange gradient, 3 phones, "Video → MP3 Converter / Extract Audio Instantly" | Decent. The brand mark is small and the phones show "100%" and personal filenames. |
| Phone screenshots | 5 | Competitors use 8–25. There are content problems too (§5.6). |
| Tablet screenshots | 5 (the same image repeated for 7" and 10") | The tablet image is a rotated phone mock-up |
| Promo video | None | None of the top 13 competitors has one either, so a video would help it stand out |
| Rating | None | — |
| Contains ads / IAP | Ads: yes. IAP: none. | The README advertises a "$1.99 Remove Ads" purchase that doesn't exist in the shipped build. |
| What's new | "v1.1.0 … Removed unnecessary storage permission" | Inaccurate: the listing's permissions still show "read/modify USB storage". |
| Data safety | "No data shared", "No data collected" | **Incorrect** while AdMob is in the app (§8.1) |
| Developer | Name **ShahLabs**, website **crushco.de**, support email **dev.mcore@gmail.com**, contact **shahlabs.dev@gmail.com**; the privacy policy says **"MCore Studios"** | 4 different identities. That weakens trust and looks unprofessional (§8.5). |
| Permissions shown at install | Storage read/modify, **modify system settings**, network, vibration, wake lock, license check | "Modify system settings" is alarming to see in a converter app |

---

## 3. Competitive landscape

Data scraped from the US Play Store (logged out) on 30 Sep 2026.

| App | Dev | Category | Installs | Rating (count) | Screenshots | Last update | Key features |
|---|---|---|---|---|---|---|---|
| Video to MP3 - Video to Audio | InShot | Video Players & Editors | 86.4M | 4.75 (734k) | 8 | Apr 2026 | Trimmer, converter |
| MP3 Converter - Video to MP3 | Bizcraft | Music & Audio | 4.27M | 4.73 (82k) | 25 | Feb 2026 | Convert, **cut** |
| Extract Audio from Video | Inglesdivino | Music & Audio | 2.67M | 4.69 (11.5k) | 8 | Nov 2025 | Extract |
| Video to Mp3 - Audio Converter | Easyelife | Video Players & Editors | 2.73M | 4.3 (8.5k) | 18 | Sep 2026 | **Trim**, extract (launched Sep 2025) |
| Video to MP3 Converter | Convenient & Easy | Video Players & Editors | 2.17M | 4.54 (13.5k) | **21** | Sep 2026 | (launched Dec 2024) |
| Audio Converter - MP4 to MP3 | TAPUNIVERSE | Music & Audio | 772k | 4.72 (46k) | 15 | Jul 2026 | Convert |
| MP3 Converter : Video To Mp3 | Golden Mango | Music & Audio | 170k | 4.56 (1.2k) | **24** | Sep 2026 | MP3/WAV/AAC/FLAC/OGG, **trim, batch, merge** |
| Video to MP3 Converter・2Audio | ss media | Music & Audio | 10.9k | 4.18 (476) | 21 | — | **Batch, MP3/WAV/M4A, trim, ringtone, "no ads"** |
| Video to MP3 & Audio Converter | HyperMind | Music & Audio | 10.3k | 4.33 (264) | 12 | Sep 2026 | Trim, **denoise**, ringtone |
| Video to MP3 Converter | Decibel Labs | Tools | 4.9k | — | 8 | — | Cutter, merger, tag editor, volume boost, compressor… |
| **AudioPeel** | ShahLabs | **Tools** | **138** | **—** | **5** | **Mar 2026** | MP3 only |

### What the winners have in common

1. **Trim/cut is standard.** Every app above 10k installs mentions trim, cut or cutter. Users want part of a video (a song, a dialogue clip, a ringtone), not the whole soundtrack.
2. **Multiple output formats.** MP3 + M4A/AAC + WAV at minimum. AAC-to-M4A can be a **stream copy**, which is instant and lossless.
3. **Batch conversion** shows up in 3 of the 4 fastest-growing 2026 entrants.
4. **Music & Audio or Video Players & Editors, not Tools.** Only 3 of 13 are in Tools, and those are the smaller ones.
5. **Many screenshots with feature captions** (15–25 on the growing apps).
6. **Frequent updates.** Most competitors updated in Jul–Sep 2026.
7. **Keyword-dense titles:** "Video to MP3 - Video to Audio", "MP3 Converter - Video to MP3", "Video to MP3 & Audio Converter", "Audio Converter - MP4 to MP3". None of them spends title characters on a brand.

### What AudioPeel can own

- **Genuinely offline and private, with nothing uploaded.** Several competitors say this; few make it their identity.
- **Clean, modern UI.** The screenshots look better than most of the category.
- **Lightweight**, once the minimal FFmpeg build ships (§6.4). Being 10–15 MB versus 30–90 MB is a real differentiator you can put in the description and screenshots.
- **"Saved straight to your Music folder / shows up in WhatsApp and your music player"**, once §6.1 is fixed. That targets the exact complaint users of other apps have.

---

## 4. Why search ranking is zero

1. **Keyword competition vs authority.** "video to mp3" is dominated by apps with 700k+ ratings. A new app can't rank on a head term until it has install velocity and ratings. The way in is **long-tail terms** ("extract audio from mp4 offline", "video to m4a", "mp4 to mp3 converter no upload", "video to ringtone") plus **localized listings**, where competition is thinner.
2. **Only one keyword theme in the heaviest-weighted fields.** Play weights the title more than the short description, which counts more than the long description. AudioPeel's title and short description say only "video to mp3 … converter … extract audio … offline".
3. **No ratings and no velocity.** Play's search ranking weighs install velocity, conversion rate, retention and ratings heavily. 0.7 installs/day and 0 ratings keep it out of the results even where it's keyword-relevant.
4. **No localization.** Each localized listing is indexed separately for that language. Right now nothing exists for Hindi, Indonesian, Portuguese (BR), Spanish, Arabic, Vietnamese, Turkish or Russian, which are the biggest markets for this category.
5. **Category signal.** Tools is a large, generic category. Music & Audio or Video Players & Editors puts the app in "Similar apps" and browse surfaces next to the leaders.

---

## 5. ASO audit, element by element

### 5.1 Title (30 characters)

Current: `Video to MP3 – AudioPeel` (24).

The brand gets no search traffic, and the developer name already appears under the title. Spend the characters on keywords. Only claim features the app actually has.

| Option | Characters | When to use it |
|---|---|---|
| `Video to MP3 Converter Offline` | 30 | **Now.** Every word is true today, and it adds *converter* and *offline*. |
| `Video to MP3 & Audio Extractor` | 30 | Alternative for now; adds *audio* and *extractor*. |
| `Video to MP3 Converter, Cutter` | 30 | **After trim ships.** *Cutter* is a high-volume modifier. |

Keep "AudioPeel" in the icon, feature graphic, first line of the description and the developer page.

### 5.2 Short description (80 characters)

Current (62): `Fast Video to MP3 Converter. Extract audio from video offline.`

| Option | Characters | Notes |
|---|---|---|
| `Video to MP3 converter: extract audio from any video offline. No upload. 320kbps` | 80 | True today |
| `Convert video to MP3 & extract audio offline. MP4 to MP3, 320kbps, ringtones` | 76 | True today (ringtone exists) |
| `Video to MP3 converter: extract audio from video offline. Trim & make ringtones` | 79 | After trim ships |

### 5.3 Full description

The current text is well structured. Keep that format, but:

- **Use ~3,000–3,800 of the 4,000 characters.** Right now it's ~1,500.
- Put the **main keyword in the first 167 characters**. Play shows that part above "About this app" and weights it more.
- Add long-tail terms naturally, **2–4 times each**, without stuffing. Terms missing today:
  `video to audio converter`, `mp3 extractor`, `audio extractor`, `mp4 to mp3 converter`, `convert video to audio`, `extract music from video`, `save audio from video`, `video to m4a` / `aac` / `wav` (once added), `mp3 cutter` / `trim audio` (once added), `ringtone maker`, `whatsapp video to mp3`, `screen recording to audio`, `lecture / podcast audio`, `batch convert` (once added), `no upload`, `no watermark`, `lightweight`.
- Add a **"Where are my files?"** line ("Saved to Music/AudioPeel, visible in any music player and in WhatsApp") once §6.1 is fixed.
- Remove "Save music in seconds" and anything that suggests downloading from the internet (see §5.6 on the "Download & Share" caption). It attracts YouTube-downloader seekers, who uninstall when they find the app works on local files only.
- A full draft is in **Appendix A**.

### 5.4 Category

**Move from Tools to Music & Audio.** Most of the direct competitors are there (Bizcraft, Inglesdivino, TAPUNIVERSE, Golden Mango, 2Audio, HyperMind), and it matches the output (audio). *Video Players & Editors* is the alternative once trim/cut ships. Changing category is instant in Play Console and reversible; watch the Store listing acquisition report for 2–3 weeks after the change.

### 5.5 Icon

The current icon is an orange-slice/shrimp-like character wearing headphones on a beige background.

- At grid size (48dp) it reads as a food or fruit app, not "video → audio". Competitor icons use a **play triangle + music note** or **film strip + waveform** metaphor, which people recognize in about 50 ms.
- Beige on Play's white background is low-contrast, and a dark-mode Play grid flattens it.
- The in-app brand is **navy and electric blue** while the icon is **orange and beige**. That mismatch makes the screenshots look like a different app.

**Recommendation:** run a **Store Listing Experiment** (Play Console → Grow → Store listing experiments) with 2 variants:
A. The current mascot, simplified onto a saturated orange background with a small ▶→♪ badge.
B. A blue gradient tile with a bold ▶ morphing into ♪ (matching the in-app hero button).
Run each for at least 7 days or 1,000 visitors. The experiment needs traffic, so do this after §10 Phase 1 has lifted visits.

### 5.6 Screenshots

| # | Caption | Problems |
|---|---|---|
| 1 | "Convert Video to MP3 Instantly" | Real personal filenames ("Cute Panthu 5746 🦄🦄", "VID_20260212_…"). A cluttered status bar (LinkedIn icon, etc.). |
| 2 | "Choose Audio Quality 128kbps • 320kbps" | "SaipuddinMishta T_ba902f9713c…" filename. A blurry thumbnail. |
| 3 | "Fast Conversion" | **Shows a UI bug: "Time Remaining: 00:00 remaining"** (see §6.8), plus "CONVERTING… 100%" contradicting itself. The layout is inverted (caption at the bottom, phone cut off at the top), unlike the others. |
| 4 | "Download & Share Audio" | **Broken audio icon, rendered as a solid blue square**, in 2 places. The **"SAVED TO /storage/emulated/0/Android/data/co…"** path advertises the hidden-folder problem. "Download" is the wrong intent. |
| 5 | "Conversion History" | Fine, but low value as a selling point. |
| Tablet | Rotated copy of #1 | Low effort, and Play knows it. |

**New screenshot set** (8 phone screenshots; build the tablet set properly or drop it). Captions should be benefits rather than feature names, with 3–5 large words each:

1. **"Video to MP3 in 1 Tap"**: home screen, clean demo filenames ("Summer Vibes.mp4").
2. **"100% Offline · Nothing Uploaded"**: an airplane-mode badge over the converting screen.
3. **"Cut Just the Part You Want"**: trim UI (after trim ships).
4. **"MP3 · M4A · WAV up to 320kbps"**: the format and quality picker.
5. **"Saved to Your Music Folder"**: the success screen showing `Music/AudioPeel`, with WhatsApp and music-player logos.
6. **"Make Any Clip Your Ringtone"**: the ringtone action.
7. **"Convert Many Videos at Once"**: batch (after it ships).
8. **"Light: Only XX MB"**: after the size fix.

Use a consistent layout (caption on top, device below), the brand color from the icon, a clean status bar (use `adb shell settings put global sysui_demo_allowed 1` and demo mode) and localized captions for the top 5 locales.

### 5.7 Localization

There are no localized listings today. Each localized listing is indexed separately and faces much less competition than en-US.

**Priority locales for this category:** Hindi (hi-IN), Indonesian (id), Portuguese-BR (pt-BR), Spanish (es-419 and es-ES), Arabic (ar), Vietnamese (vi), Turkish (tr), Russian (ru), Bengali (bn), Filipino (fil).

- Phase 1: translate the title, short description, full description and screenshot captions (professional translation, or a careful LLM translation reviewed by a native speaker).
- Phase 2: translate the in-app strings too. They are already centralised in `lib/constants/app_strings.dart`, so moving to `flutter_localizations` + ARB files is a moderate job. Play boosts apps whose UI matches the user's language.
- Also create **custom store listings per country** (India first) with locally relevant screenshots (WhatsApp status, reels, lecture recordings).

### 5.8 Ratings & reviews

There are 0 ratings and no review prompt in the code (`in_app_review` isn't a dependency).

- Add `in_app_review` and call `requestReview()` **after the 2nd successful conversion**, when the user taps **Play** or **Share** on the success screen (a happy moment), **not** in the same session as an interstitial ad. Google throttles the dialog, so a well-placed call matters more than calling often.
- Add a light pre-prompt ("Enjoying AudioPeel? 👍 / 👎"). Send 👎 to a feedback email and 👍 to `requestReview()`. Keep it policy-safe: don't gate or incentivise the rating itself.
- Reply to every review within 24 hours. Play shows replies, and they affect conversion.

### 5.9 Update cadence & "What's new"

The app has been silent since March. Ship **every 2–4 weeks**, with a specific, benefit-led "What's new" (for example: "✂️ NEW: Trim video before converting · 🎵 M4A & WAV output · 📁 Files now saved to Music/AudioPeel"). Update freshness helps both ranking and the conversion of returning visitors.

### 5.10 Promo video

None of the top competitors has one. A 20–30 s screen recording (pick video → trim → convert → play in WhatsApp) shown in the first slot would be a cheap way to stand out.

---

## 6. Product & codebase audit: issues that hurt retention and ranking

Line numbers refer to the shipped branch `origin/inh/ntification`, unless marked (main). Most files are identical on `main`.

### 6.1 🔴 Output files are saved to a hidden folder

[storage_service.dart:50](../lib/services/storage_service.dart#L50) uses `getExternalStorageDirectory()`, which resolves to `/storage/emulated/0/Android/data/com.mcore.audiopeel/files/AudioPeel/`.

On Android 11+:
- Music players (Samsung Music, Google Files audio tab, VLC's library, Spotify local files) **won't index it**, because nothing inserts the file into MediaStore.
- WhatsApp's and Telegram's "Audio" attachment pickers **won't list it**.
- Google Files and most file managers **can't open `Android/data`** at all.
- **Uninstalling the app deletes every converted MP3.**
- Your own screenshot #4 shows the path.

Users who leave the app and look for their MP3 won't find it. That makes this the most likely cause of 1★ reviews and uninstalls once volume picks up.

**Fix:** after a successful conversion, **insert the file into MediaStore** under `Music/AudioPeel` (`MediaStore.Audio.Media.EXTERNAL_CONTENT_URI`, `RELATIVE_PATH = "Music/AudioPeel"`, `IS_PENDING` flow). On API 29+ this needs **no permission**. Convert to a temp/cache path, then copy into MediaStore, or write straight to the MediaStore output stream. On API 26–28, use `WRITE_EXTERNAL_STORAGE` and `Environment.DIRECTORY_MUSIC`. You already have a Kotlin method channel in `MainActivity.kt` that does almost exactly this for ringtones and can be reused. Then:
- Show "Saved to **Music/AudioPeel**" on the success screen, with an **"Open folder"** button.
- Remove or rework the "Output Path" picker in Settings ([settings_screen.dart:240](../lib/screens/settings_screen.dart#L240) (main)). `getDirectoryPath()` returns a SAF tree, and writing to it with `dart:io` `File` is unreliable on Android 11+.

### 6.2 🔴 Every selected video is copied into cache and never deleted

`FilePicker.platform.pickFiles(type: FileType.video)` ([conversion_provider.dart:98](../lib/providers/conversion_provider.dart#L98)) **copies the chosen file into the app's cache** on Android so it can return a `path`. For a 1 GB video, that means:
- a long, silent wait before the Options screen appears (the home screen is blanked meanwhile);
- **1 GB of extra storage used**, which piles up with every conversion.

`StorageService.clearCache()` exists ([storage_service.dart:161](../lib/services/storage_service.dart#L161)) but **nothing calls it**, and `FilePicker.platform.clearTemporaryFiles()` is never called either. Android's "App info → Storage" will show AudioPeel growing by gigabytes, which is a classic uninstall trigger and a source of "phone full" reviews.

**Fix (short term):** after conversion (success, failure or cancel), delete the cached copy and call `FilePicker.platform.clearTemporaryFiles()`; also clean up on app start.
**Fix (proper):** pass the `content://` URI straight to FFmpeg. FFmpegKit supports SAF URIs via `FFmpegKitConfig.getSafParameterForRead()`, so there's no copy at all. This also makes selection instant.

### 6.3 🔴 No "Share to AudioPeel" / "Open with" entry point

The manifest has only the launcher intent filter ([AndroidManifest.xml:28-31](../android/app/src/main/AndroidManifest.xml#L28-L31)). Users who are looking at a video in Gallery, Google Photos, WhatsApp or Files can't send it to AudioPeel.

**Fix:** add `ACTION_SEND` / `ACTION_SEND_MULTIPLE` / `ACTION_VIEW` intent filters for `video/*` and route them to the Options screen. This is a big engagement boost, and it puts AudioPeel's icon in the system share sheet every time someone shares a video, which works as free re-engagement.

### 6.4 🟠 App size: full FFmpeg for an audio-only job

`ffmpeg_kit_flutter_new ^4.1.0` bundles the full FFmpeg (video encoders, filters, protocols). Your own [README_SIZE_REDUCTION.md](README_SIZE_REDUCTION.md) estimates an **80–90 MB user download**. Check the real figure in Play Console → App bundle explorer → Download size.

- The minimal build plan in `scripts/build-ffmpeg-minimal.sh` is the right idea but **has not shipped**.
- The plan keeps **video decoders, which aren't needed**. With `-vn`, FFmpeg never decodes the video stream. You need only **demuxers + audio decoders (AAC, MP3, Opus, Vorbis, AC3, FLAC, PCM) + the LAME encoder + an MP4/IPOD muxer for M4A**. That should come in under ~5 MB per ABI.
- Alternative: drop FFmpeg entirely. Use Android's `MediaExtractor` + `MediaMuxer` for M4A (a stream copy, which is instant) and a small LAME binding for MP3.
- Ship an **AAB** (not a universal APK) so each device downloads only its ABI.

**Target:** under 15 MB download. Then say "Only X MB" in the listing.

### 6.5 🟠 No instant M4A mode

Most phone videos have AAC audio. `-vn -c:a copy out.m4a` extracts it **in seconds and losslessly**, with no re-encode. Offer "Original quality (M4A) — fastest" next to MP3 128/192/320. It's a genuine differentiator ("10× faster") and adds M4A/AAC keywords.

### 6.6 🟠 Ads: placement and frequency

- Banner ads on 6 screens, including the converting and error screens ([home_screen.dart:324](../lib/screens/home_screen.dart#L324) etc.).
- An interstitial is shown **the moment the success screen appears** ([conversion_success_screen.dart:39](../lib/screens/conversion_success_screen.dart#L39)), every 2nd conversion on the shipped branch ([app_constants.dart:8](../lib/constants/app_constants.dart#L8)) and **every** conversion on `main`. This hides the payoff moment, which is exactly when you want the user to feel satisfied or be asked for a review.
- There's no way to pay to remove ads (the README's $1.99 IAP isn't in the build).

**Recommendation:**
- Show **no interstitial on the first 2–3 conversions or in the first session**. Early retention matters far more than roughly $0.01 of eCPM at 138 users.
- Move the interstitial to when the user taps **"Convert another"** or leaves the success screen, not when it appears.
- Drop the banner from the converting screen, or swap it for a **native ad** that looks like part of the UI. Consider an **App Open** ad on warm resume only (frequency-capped).
- Add a **"Remove ads" IAP** ($1.99–2.99, one-time). It's revenue, and it lets you say "ads are optional" in reviews.
- Rewarded option: "Watch an ad to unlock batch/320kbps for today" can work once batch exists.

### 6.7 🟠 Cold start and first-run friction

- `main()` **awaits `MobileAds.instance.initialize()` before `runApp`** ([main.dart:36](../lib/main.dart#L36)). On slow networks this adds hundreds of milliseconds to seconds to cold start. Initialize without awaiting, after the first frame.
- There's an artificial **1.5 s splash** ([splash_screen.dart:50](../lib/screens/splash_screen.dart#L50)) on top of the native splash. Remove it, or show it only on first launch.
- The first-launch coach-mark over a single obvious button adds friction for no gain. Consider removing it.
- Slow cold starts count against Android vitals, which affects ranking.

### 6.8 🟡 Visible UI bugs (both appear in the store screenshots)

- **"Time Remaining: 00:00 remaining"**: the label says "Time Remaining:" and the value appends " remaining" ([converting_screen.dart:289](../lib/screens/converting_screen.dart#L289)). The estimate itself ([converting_screen.dart:303](../lib/screens/converting_screen.dart#L303)) is based on a guessed conversion speed rather than elapsed time. `ConversionProvider._calculateEstimatedTime` already computes a real ETA; use it.
- **Broken audio icon (solid blue square)** on the success screen in screenshot #4. The custom `AudioIcon` / `audio_icon.png` asset isn't rendering on some devices. Check the asset path after the rename on the shipped branch (`assets/icon/audiopeel-nobg.png`).

### 6.9 🟡 Long videos fail silently after 10 minutes

`conversionTimeout = 10 minutes` ([app_constants.dart:72](../lib/constants/app_constants.dart#L72)). A 2-hour movie at 320 kbps with `loudnorm` on a budget phone can exceed that, and the user gets a generic failure. Scale the timeout with duration, or remove it and rely on progress stalls.

### 6.10 🟡 Background conversion isn't protected

Progress notifications are posted, but there's **no foreground service**. When the user leaves the app during a long conversion, Android (especially Xiaomi, Oppo, Vivo and Samsung, which are popular in the target markets) may kill the process, and the conversion is lost. Use a foreground service of type `dataSync` or `mediaProcessing` (API 35+) for conversions longer than about 30 s.

### 6.11 🟡 Missing features that competitors rank on

| Feature | Effort | Keyword/ranking value | Retention value |
|---|---|---|---|
| **Trim / cut** (start–end slider before convert, using `-ss`/`-to`) | M | ★★★ (*cutter, trim, cut*) | ★★★ |
| **M4A / AAC / WAV output** (+ instant copy mode) | S | ★★ | ★★ |
| **Batch conversion** (multi-select + queue) | M | ★★ | ★★ |
| **Share-to intent** (§6.3) | S | — | ★★★ |
| **Ringtone / notification / alarm** (exists; make it visible on the success screen) | S | ★★ (*ringtone maker*) | ★★ |
| **ID3 tag + cover art** (title/artist, thumbnail as cover) | S | ★ | ★★ |
| **Volume boost / fade in-out** | S | ★ | ★ |
| **Built-in player** in History (instead of an external intent) | S | — | ★★ |

### 6.12 🟡 No analytics or crash reporting

You have no data on the funnel (open → pick → convert → success → share), failure rates by codec/device, or crashes. Add **Firebase Analytics + Crashlytics**, and update the Data safety form and privacy policy to match. Minimum events to log: `video_picked`, `conversion_started`, `conversion_succeeded` (duration, size, quality), `conversion_failed` (error class), `file_shared`, `file_played`, `ringtone_set`, `review_prompt_shown`.

---

## 7. Engineering hygiene (affects shipping speed)

### 7.1 The shipped code isn't on `main`

Play serves **v1.1.0 (build 2)**. `main` is still at **1.0.0+1** with the interstitial on every conversion, the startup notification-permission prompt, and a stale version string. The released source lives only on `origin/inh/ntification` (last commit 28 Feb). There's also an older `origin/v2` branch with an IAP service and redesigned screens that was never merged.

**Fix:** merge `inh/ntification` into `main`, tag it `v1.1.0`, and delete or archive `v2` after taking anything useful from it (`iap_service.dart`, `cache_service.dart`). Release from tagged commits from now on.

### 7.2 Dead or misleading code

- `PermissionService._androidSdkVersion()` always returns **29** ([permission_service.dart:87-89](../lib/services/permission_service.dart#L87-L89)), so the whole version-branching logic is dead. Delete the service once the storage permissions are removed (§8.3).
- `AppStrings.versionValue` is hard-coded ([app_strings.dart:130](../lib/constants/app_strings.dart#L130)). Use `package_info_plus` so it can't drift.
- README says "Remove Ads — $1.99 IAP", "in_app_purchase" and "Target SDK 34"; none of these match the build. Play has required **targetSdk 35** for updates since 31 Aug 2025. If Google followed its yearly schedule, that became **36** on 31 Aug 2026; check the current requirement in Play Console → Policy status. Confirm what `flutter.targetSdkVersion` resolves to with your Flutter version, or your next update may be blocked.
- The notification permission is requested every time a conversion starts ([conversion_provider.dart:192](../lib/providers/conversion_provider.dart#L192)). That's harmless but noisy. Ask once, with context.

---

## 8. Policy & compliance risks

### 8.1 🔴 Data safety form is inaccurate

The listing says **"No data collected"** and **"No data shared"**. The Google Mobile Ads SDK collects and shares, at minimum: **Device or other IDs** (advertising ID), **approximate location** (IP), **app interactions**, and **diagnostics / crash logs**. Google's AdMob guidance requires apps to declare this. Your own privacy policy also says "AdMob may collect device identifiers, usage data, and location data" and "Crash reports may be collected". So the policy and the form contradict each other.

**Risk:** policy enforcement (update rejection or listing removal), especially since Play cross-checks SDKs in the bundle.
**Fix:** declare the AdMob data types as collected + shared for *Advertising or marketing* and *Analytics*, and do the same for Firebase if you add it (§6.12).

### 8.2 🔴 No GDPR consent (UMP)

The code has no `ConsentInformation` / `ConsentForm`. Since January 2024 Google requires a **Google-certified CMP** (UMP counts) for serving ads in the EEA, UK and Switzerland. Without it, ads in those regions are limited or not served, and the AdMob account can be flagged.
**Fix:** implement the UMP flow (`ConsentInformation.instance.requestConsentInfoUpdate` → `ConsentForm.loadAndShowConsentFormIfRequired`) before loading ads, and add a "Privacy options" entry in Settings.

### 8.3 🟠 Permissions declared but not used

The manifest ([AndroidManifest.xml:47](../android/app/src/main/AndroidManifest.xml#L47)) declares `READ_MEDIA_VIDEO`, `READ_MEDIA_AUDIO`, `READ_EXTERNAL_STORAGE` and `WRITE_EXTERNAL_STORAGE`, yet the app **never requests them**, because the permission check was deleted and file picking goes through the system picker.

- Under Play's **Photo and Video Permissions policy**, apps that need only one-time or infrequent access must use the system photo picker and **must not declare `READ_MEDIA_VIDEO`**. Every update needs a justification declaration, and a rejection is possible.
- The listing shows "read/modify the contents of your USB storage", which scares off privacy-minded users. It also contradicts your "What's new" ("Removed unnecessary storage permission") and your "private & offline" pitch.

**Fix:** remove `READ_MEDIA_VIDEO`, `READ_MEDIA_AUDIO` and `READ_EXTERNAL_STORAGE`. Keep `WRITE_EXTERNAL_STORAGE` with `maxSdkVersion="28"` only for the API 26–28 MediaStore fallback (§6.1). Remove `requestLegacyExternalStorage`.

### 8.4 🟡 `WRITE_SETTINGS` ("modify system settings")

This permission is shown on the listing. It's only needed to set the *default* ringtone ([AndroidManifest.xml:55](../android/app/src/main/AndroidManifest.xml#L55)). It's legitimate, but it makes a simple converter look invasive. Alternative: save the clip into `Ringtones/` via MediaStore (no permission needed) and open the system sound picker (`RingtoneManager.ACTION_RINGTONE_PICKER` or `Settings.ACTION_SOUND_SETTINGS`) so the user picks it with one tap. If you keep it, request it only from the ringtone action, which you already do.

### 8.5 🟡 Inconsistent developer identity

| Place | Identity |
|---|---|
| Developer name | ShahLabs |
| Package | com.**mcore**.audiopeel |
| Website | crushco.de |
| Support email | dev.mcore@gmail.com |
| Developer contact | shahlabs.dev@gmail.com |
| Privacy policy organization | **MCore Studios** |
| Privacy policy host | mahendra-shah.github.io |

Pick **one** brand (ShahLabs seems current). Use one support email, and host the privacy policy and app-ads.txt on the same domain as the listed website. Right now app-ads.txt on crushco.de is correct: `google.com, pub-5583038215571668, DIRECT, f08c47fec0942fa0`. Add a simple AudioPeel page on the website. Consistent identity is a trust signal for users and for Google's review systems.

### 8.6 Privacy policy accuracy

- It says READ_MEDIA_AUDIO is used "to save converted audio files". Read permissions don't save anything, and the app doesn't use it.
- It mentions crash reports that aren't collected (no Crashlytics).
- It doesn't mention UMP consent, the Firebase processors (if added), or where files are stored.

Rewrite it after the fixes above so that the policy, the Data safety form and the manifest all match.

---

## 9. Keyword strategy

The US search pages are dominated by apps with 100k–700k ratings, so **don't expect head terms for 3–6 months**. Attack in this order:

| Tier | Keywords | Where to use them |
|---|---|---|
| Head (long term) | video to mp3, mp3 converter, video to audio converter | Title, short description, description (2–3×) |
| Mid | mp4 to mp3, extract audio from video, audio extractor, mp3 extractor, convert video to audio | Short description, description (2–4×), screenshot captions |
| Long-tail (winnable now) | video to mp3 offline, mp4 to mp3 converter offline, extract audio from video without internet, video to m4a, video to wav, video to ringtone, whatsapp video to mp3, screen recording to mp3, lecture video to audio, save song from video | Description, "What's new", localized listings |
| After features ship | mp3 cutter, video cutter to mp3, trim video audio, batch video to mp3, audio merger | Title (cutter), description |

**Localized equivalents** (translate properly; these are the high-intent phrases): Hindi *वीडियो से MP3*, Indonesian *video ke mp3*, Portuguese *converter vídeo em mp3*, Spanish *convertir video a mp3*, Arabic *تحويل الفيديو إلى MP3*, Vietnamese *chuyển video sang mp3*, Turkish *videoyu mp3'e çevir*.

**Measure:** Play Console → Grow → Store performance → *Search terms*. Check it weekly and move terms that convert well into the title or short description.

---

## 10. Prioritized action plan

### Phase 0: Hygiene (1–2 days)
| # | Action | Ref |
|---|---|---|
| 0.1 | Merge `inh/ntification` → `main`, tag v1.1.0, archive `v2` | §7.1 |
| 0.2 | Correct the **Data safety** form for AdMob | §8.1 |
| 0.3 | Unify developer identity, support email and privacy-policy organization | §8.5 |
| 0.4 | Confirm targetSdk meets Play's current requirement (35 or 36) | §7.2 |

### Phase 1: Stop losing the users you get (v1.2, ~1–2 weeks)
| # | Action | Impact | Effort | Ref |
|---|---|---|---|---|
| 1.1 | **Save outputs to `Music/AudioPeel` via MediaStore** + an "Open folder" button | 🔴 | M | §6.1 |
| 1.2 | **Delete picker cache copies**, or read via SAF URI | 🔴 | S | §6.2 |
| 1.3 | **Share-to / Open-with intent filters** for `video/*` | 🔴 | S | §6.3 |
| 1.4 | **In-app review** after the 2nd successful conversion, at play/share | 🔴 | S | §5.8 |
| 1.5 | No interstitial for the first 2–3 conversions; show it on "Convert another", not when the success screen appears | 🟠 | S | §6.6 |
| 1.6 | Remove unused storage permissions and `requestLegacyExternalStorage` | 🟠 | S | §8.3 |
| 1.7 | UMP consent flow | 🟠 | S | §8.2 |
| 1.8 | Fix the "Time Remaining … remaining" text and the broken audio icon | 🟡 | XS | §6.8 |
| 1.9 | Don't await the Ads SDK before `runApp`; remove the 1.5 s splash | 🟡 | XS | §6.7 |
| 1.10 | Firebase Analytics + Crashlytics (and update Data safety) | 🟡 | S | §6.12 |

### Phase 1b: Listing refresh (same week as v1.2)
| # | Action | Ref |
|---|---|---|
| 1b.1 | Title → `Video to MP3 Converter Offline` | §5.1 |
| 1b.2 | Short description → `Video to MP3 converter: extract audio from any video offline. No upload. 320kbps` | §5.2 |
| 1b.3 | Full description → Appendix A (about 3,500 characters) | §5.3 |
| 1b.4 | Category → **Music & Audio** | §5.4 |
| 1b.5 | Reshoot 8 screenshots with clean demo data and benefit captions | §5.6 |
| 1b.6 | Localized listings: hi, id, pt-BR, es-419, ar (text + captions) | §5.7 |

### Phase 2: Match the category (v1.3–1.4, ~3–5 weeks)
| # | Action | Ref |
|---|---|---|
| 2.1 | **Trim/cut** before converting | §6.11 |
| 2.2 | **M4A instant (stream-copy) + AAC/WAV** output | §6.5 |
| 2.3 | **Batch** conversion queue | §6.11 |
| 2.4 | Show "Set as ringtone" on the success screen; MediaStore-based ringtone without WRITE_SETTINGS | §8.4 |
| 2.5 | Foreground service for long conversions; scale the timeout | §6.9, §6.10 |
| 2.6 | Update the title to `Video to MP3 Converter, Cutter` and the screenshots to show trim/batch | §5.1 |
| 2.7 | "Remove ads" IAP | §6.6 |

### Phase 3: Differentiate & scale (month 2–3)
| # | Action | Ref |
|---|---|---|
| 3.1 | **Minimal FFmpeg or MediaCodec pipeline → under 15 MB download**, then advertise it | §6.4 |
| 3.2 | In-app localization (ARB) for the top 5 locales | §5.7 |
| 3.3 | Icon Store Listing Experiment (2 variants) | §5.5 |
| 3.4 | Promo video (20–30 s) | §5.10 |
| 3.5 | Custom store listing for India | §5.7 |
| 3.6 | Small paid push to seed velocity, if wanted: Google App Campaigns at $5–10/day, geo-targeted to India/Indonesia/Brazil, only **after** Phase 1 fixes retention | — |
| 3.7 | Organic seeding: Reddit (r/androidapps), XDA thread, Product Hunt, short YouTube/Instagram reels showing "WhatsApp video → MP3 in 5 s" | — |

---

## 11. KPIs to track (Play Console + Firebase)

| KPI | Where | Today (est.) | 30-day target | 90-day target |
|---|---|---|---|---|
| Daily installs | Statistics | ~0.7 | 15+ | 100+ |
| Store listing conversion rate (visitor → install) | Store performance | unknown (pull it) | ≥ 25% | ≥ 35% |
| Search impressions for "video to mp3 offline" / long-tail | Search terms | ~0 | appearing | top 10 in ≥ 1 locale |
| Ratings count / average | Ratings | 0 / — | 20 / ≥ 4.4 | 150 / ≥ 4.5 |
| D1 / D7 retention | Firebase / Play | unknown | 30% / 12% | 35% / 15% |
| Conversion success rate | Firebase (`conversion_succeeded` / `started`) | unknown | ≥ 97% | ≥ 98% |
| Uninstall rate (30-day) | Statistics | unknown | < 40% | < 30% |
| Crash / ANR rate | Android vitals | unknown | < 0.5% / < 0.3% | same |
| Download size | App bundle explorer | ~80–90 MB (per docs) | — | < 15 MB |

---

## 12. What this audit could not see

To go further, pull these from Play Console and I can extend the analysis:

- **Store listing acquisition** (visitors, installers, conversion rate by country and source)
- **Search terms** report (which queries show AudioPeel and which convert)
- **Android vitals** (crash/ANR rate, slow cold start)
- **Uninstall** and **retention** curves
- **Download size** per device class
- **Country breakdown** of the 138 installs

Method notes: competitor data and search ranks were scraped from the logged-out US Play Store (en-US) on 30 Sep 2026. Rankings differ by country, language and personalisation. Install counts use Play's internal exact counters, which the page embeds.

---

## Appendix A: Draft full description (≈3,500 characters)

> Features marked ⏳ should go into the description only once they ship.

```
Video to MP3 Converter – extract audio from any video in seconds, 100% offline. AudioPeel turns MP4, MKV, MOV and more into high-quality MP3 right on your phone. Nothing is uploaded.

AudioPeel is a fast, lightweight video to audio converter and MP3 extractor. Pick a video, choose the quality, tap Convert, and your MP3 is saved to your Music folder, ready for any music player, WhatsApp, Telegram or your ringtone.

🎵 VIDEO TO MP3 & AUDIO EXTRACTOR
• Convert video to MP3 in one tap
• MP4 to MP3, MKV to MP3, MOV to MP3, AVI, WEBM, 3GP, FLV, TS, M4V
• Choose 128, 192 or 320 kbps MP3
• ⏳ Save as M4A (original quality, instant), AAC or WAV
• Extract music, dialogue, lectures or podcasts from any video

✂️ ⏳ TRIM & CUT
• Cut just the part you want before converting
• Make a short audio clip or ringtone from any video
• Precise start and end sliders with preview

⚡ FAST, LIGHT & OFFLINE
• Works without internet: convert on a plane, on the train, anywhere
• Powered by FFmpeg for fast, reliable audio extraction
• ⏳ Instant M4A mode copies the original audio with no re-encoding
• ⏳ Batch convert many videos at once
• ⏳ Lightweight app: only XX MB

🔒 PRIVATE BY DESIGN
• Your videos never leave your phone
• No account, no sign-up, no login
• No cloud upload and no watermark

📁 FIND YOUR FILES EASILY
• MP3s are saved to Music/AudioPeel
• They show up in your music player, file manager, WhatsApp and Telegram
• Conversion history with search and filters
• Share, play, rename or delete in one tap

🔔 RINGTONE MAKER
• Set any converted audio as your ringtone
• ⏳ Or as your notification or alarm sound

💡 GREAT FOR
• Saving a song from a video you recorded
• Turning WhatsApp videos or reels into MP3
• Extracting lecture, class or meeting audio to listen on the go
• Converting screen recordings into audio
• Making custom ringtones from video clips
• Freeing up storage by keeping only the audio

📱 HOW TO CONVERT VIDEO TO MP3
1. Tap Select Video, or share a video to AudioPeel from your gallery
2. ⏳ Trim the part you want (optional)
3. Pick MP3 quality or format
4. Tap Convert. Done!

Works on Android 8.0 and above. Supports audio tracks in AAC, MP3, Opus, Vorbis, AC3, FLAC and PCM.

AudioPeel is free and supported by ads. Please convert only videos you own or have permission to use.

Questions or ideas? Email us at <one support email>. We read every message.
```

## Appendix B: Evidence index

| Claim | Evidence |
|---|---|
| 138 installs, 0 ratings, Tools, released 14 Mar 2026 | Embedded Play listing data (`ds:5`) |
| Not in top 30 for 4 head terms (US) | Scraped Play search result pages |
| Competitor stats | Scraped competitor listing pages |
| Hidden output folder | [storage_service.dart:50](../lib/services/storage_service.dart#L50); screenshot #4 on the listing |
| Picker cache never cleared | [conversion_provider.dart:98](../lib/providers/conversion_provider.dart#L98), [storage_service.dart:161](../lib/services/storage_service.dart#L161) (no callers) |
| No share intent | [AndroidManifest.xml:28-31](../android/app/src/main/AndroidManifest.xml#L28-L31) |
| Interstitial on success screen appearance | [conversion_success_screen.dart:39](../lib/screens/conversion_success_screen.dart#L39) |
| Time-remaining text bug | [converting_screen.dart:289](../lib/screens/converting_screen.dart#L289); screenshot #3 on the listing |
| Unused media permissions | [AndroidManifest.xml:47](../android/app/src/main/AndroidManifest.xml#L47); no `ensureStoragePermission()` callers on the shipped branch |
| App size estimate | [README_SIZE_REDUCTION.md](README_SIZE_REDUCTION.md) |
| No UMP / analytics / in-app review | `grep` across `lib/` and `pubspec.yaml` |
| Shipped code on an unmerged branch | `git log origin/inh/ntification` (version `1.1.0+2`) vs `main` (`1.0.0+1`) |
