# AudioPeel 2.0: UX/UI Redesign Spec

**Status:** Implemented on branch `redesign/v2-studio` (based on the shipped v1.1.0 code)
**Companion doc:** [ASO_GROWTH_AUDIT.md](ASO_GROWTH_AUDIT.md), which is the "why". This doc is the "what" and "how".

---

## 1. The design problem

People install a video-to-MP3 app with **one job in mind**: "get the sound out of this video, and let me use it (send it, play it, make it my ringtone)." Today there are 3 kinds of friction in that job, and every competitor has at least 2 of them:

| Friction | AudioPeel 1.x | Competitors (InShot, Bizcraft, Golden Mango…) |
|---|---|---|
| **Getting the video in** | Picker copies the whole file into cache (slow for big videos, bloats storage). No share-to-app. | Mostly the same; some have an in-app gallery that needs a broad media permission |
| **Shaping the audio** | Quality only | Many tools, each on a **separate screen** (Video Cutter, Audio Cutter, Converter, Tag editor), shown as a grid of icons the user has to decode |
| **Using the result** | File hidden in `Android/data`; external player only | Saved to storage, but results live in a separate "Output" screen; sharing takes several taps |

On top of that, the whole category **feels the same**: saturated red/orange, a tool grid, dense forms, no sense of progress or reward.

### Design goal

> **One tap to start, zero dead ends, and every step physically connected to the next.**

The user should feel that the video *turns into* audio, rather than moving through five unrelated forms.

---

## 2. Principles

1. **One continuous surface.** Home → Studio → Job → Result is one journey, and elements travel between screens: the thumbnail flies from the pick into the Studio, the Convert button *expands* into the job, and the progress ring *becomes* the checkmark.
2. **Progressive disclosure, not a tool grid.** Trim, format and quality are always visible because they're used most. Enhancements (normalize, boost, fades, album art, tags) sit in one collapsible "Enhance" card. There's no separate cutter screen.
3. **Smart defaults.** If the source audio is AAC, the Studio offers **M4A · Instant**, a lossless stream copy that is about 10× faster. If the video has **no audio track**, we say so *before* converting.
4. **Motion with meaning.** Every animation explains a state change (where something came from, where it went, what's happening). Nothing moves just for decoration, and everything respects the system *Remove animations* setting.
5. **Instant feedback.** Every press gives a spring scale and a haptic tick. Progress is smoothed (critically damped) so it never jumps or stalls visually.
6. **Results are first-class.** Audio lands in **Music/AudioPeel**, where every player, WhatsApp and file manager can see it. It plays **inside the app** with a persistent mini-player, and Share / Ringtone / Open folder are one tap away.
7. **Respect the user.** No ads during a user's first conversions, no ad on top of the result, no permission prompts on launch, no broad media permissions.

---

## 3. Brand & visual language

### 3.1 Palette: "Peel"

Competitors are red/orange on white. We use the app icon's own colors (tangerine plus the teal headphones) on a warm ink or cream canvas. That way the brand is **consistent with the icon**, and the app still looks different from the category.

| Token | Dark | Light | Use |
|---|---|---|---|
| `canvas` | `#0F0D0B` warm ink | `#FBF6EF` cream | App background |
| `surface` | `#1A1714` | `#FFFFFF` | Cards |
| `surfaceHi` | `#252019` | `#F3ECE2` | Raised / pressed / inputs |
| `line` | `#FFFFFF` 8% | `#1A1714` 8% | Hairlines |
| `ink` | `#FFF7EE` | `#1A1512` | Primary text |
| `inkMuted` | `#FFF7EE` 60% | `#1A1512` 58% | Secondary text |
| **`peel`** (primary) | `#FF8A3D` | `#F2711C` | CTAs, active states, progress |
| `peelDeep` | `#FF5E3A` | `#E0521A` | Gradient end |
| **`groove`** (secondary) | `#3CC8B4` | `#139C8A` | Audio, waveform, success |
| `danger` | `#FF5C5C` | `#D93A3A` | Destructive |

Signature gradient: `peel → peelDeep` at 135°, used only on the primary CTA and the progress ring, so it always means "the main action".

### 3.2 Type

- **Plus Jakarta Sans** (400–800), bundled rather than fetched at runtime, since the app must work offline. It's friendly and geometric, and reads well at small sizes.
- **JetBrains Mono** 500/700 for timecodes, percentages and sizes, so the numbers don't jitter while they change.

| Style | Size / weight |
|---|---|
| Display | 34 / 800, −0.5 tracking |
| Title L | 24 / 700 |
| Title M | 18 / 700 |
| Body | 15 / 500 |
| Label | 13 / 600 |
| Caption | 12 / 500 |
| Numeric | JetBrains Mono 500 |

### 3.3 Shape & depth

- Radii: 12 (chips/inputs), 20 (cards), 28 (hero cards and sheets), and a full stadium shape for buttons.
- Depth comes from **surface tone, not shadows**. One soft colored glow sits under the primary CTA only.

---

## 4. Motion system

All values live in [`lib/design/motion.dart`](../lib/design/motion.dart).

| Token | Duration | Curve | Used for |
|---|---|---|---|
| `micro` | 120 ms | `standard` | Press states, toggles |
| `short` | 220 ms | `emphasized` | Chips, pill indicator, icon swaps |
| `medium` | 380 ms | `emphasized` | Cards expanding, list reorders |
| `long` | 560 ms | `emphasizedDecel` | Page transitions, container transforms |
| `hero` | 760 ms | `emphasizedDecel` | Result reveal, ring → check morph |

Curves: `emphasized = Cubic(0.2, 0, 0, 1)`, `emphasizedDecel = Cubic(0.05, 0.7, 0.1, 1)`, `emphasizedAccel = Cubic(0.3, 0, 0.8, 0.15)`.

Press spring: mass 1, stiffness 520, damping 28, pressing to a 0.96 scale.

### Choreography

| Moment | Transition |
|---|---|
| Home ↔ Library tab | **Fade-through** (outgoing fades and scales to 0.92, incoming fades in) |
| Home → Studio | **Shared axis (Z)**; the picked video's thumbnail is a **Hero** that lands in the preview |
| Studio **Convert** → Job | **Container transform**: the pill button grows into the full Job screen |
| Job progress | **Peel reveal**: the video frame is progressively "peeled" left to right into a live waveform, with a glowing seam at the edge |
| Job done | Ring **morphs into a checkmark** (path draw), a burst of 18 particles, a heavy haptic; the waveform becomes the player |
| Job error | Card does a horizontal shake (3 cycles, 360 ms) with a light haptic; the error text fades up |
| Lists | Staggered entrance: fade + 12 px rise, 40 ms apart, capped at 8 items |
| Format / quality pills | A sliding indicator animates between options (never a hard color swap), plus a selection haptic |
| Numbers (size estimate, %) | Rolling tween; monospaced digits, so nothing shifts sideways |
| Library row tap | Row **expands in place** into a mini player (size + fade); other rows glide aside |
| Swipe to delete | Row slides out; an **Undo** snackbar holds the real delete for 4 s |
| Mini-player | Slides up from the bottom nav with a spring; the play icon morphs (AnimatedIcon) |

**Reduced motion:** when `MediaQuery.disableAnimations` is on, all durations collapse to 0. The peel reveal becomes a plain progress bar and particles are skipped.

---

## 5. Information architecture

```
App shell (bottom nav: Convert · Library)          ┌── persistent mini-player (when audio is playing)
│
├── Convert (Home)
│     ├── Hero: "Drop in a video, get the sound"  → system photo picker (multi-select)
│     ├── Quick intents: Extract · Cut & convert · Ringtone · Batch
│     ├── Tip: "Share any video to AudioPeel"     (dismissible)
│     └── Recent (3)                              → tap = play in mini-player
│
├── Studio (1 video)                              ← also opened by Share / Open-with from any app
│     ├── Preview (video player, loops inside the trim range)
│     ├── Facts: duration · size · audio codec · ⚠ no-audio warning
│     ├── Trim: filmstrip + handles + ±0.1 s nudges + "Full"
│     ├── Format: MP3 · M4A · WAV · FLAC  (M4A shows "Instant" when the source is AAC)
│     ├── Quality: 128 · 192 · 256 · 320  (hidden for lossless)
│     ├── Enhance (collapsible): Normalize · Volume boost · Fade in/out · Album art · Title/Artist
│     ├── File name
│     └── [Convert · ≈ 3.2 MB]  ── container transform ──►  Job
│
├── Batch Studio (2+ videos)
│     ├── Reorderable list, swipe to remove
│     ├── Shared Format / Quality / Enhance
│     └── [Convert 5 videos] ──► Job (batch)
│
├── Job (single or batch)
│     ├── Converting: peel reveal, rolling %, real ETA, Cancel
│     ├── Done: check morph, player, "Saved to Music/AudioPeel"
│     │     Actions: Play · Share · Set as ringtone · Open folder
│     │     Secondary: Convert another · Back home
│     └── Error: shake, human message, Retry · Try MP3 instead · Pick another
│
├── Library
│     ├── Search (expands), filter chips: All · MP3 · M4A · Lossless · This week
│     ├── Date-grouped list; tap to expand into a player; swipe to delete (with undo)
│     └── Row actions: Share · Ringtone · Open with · Delete
│
└── Settings
      ├── Defaults: format, quality, normalize, album art
      ├── Appearance: System / Light / Dark (sliding segmented control)
      ├── Storage: Saved to Music/AudioPeel · Open folder · Clear temporary files
      └── About: Rate · Share app · Privacy policy · Privacy options (GDPR) · Version
```

**Removed:** the artificial splash screen, the coach-mark tour, "Auto-delete original" (dangerous and rarely used; deleting a content URI needs a system dialog anyway), the custom output-folder picker (unreliable under scoped storage), and banner ads on the Studio/Job screens.

---

## 6. Feature set vs competitors

| Capability | AudioPeel 2.0 | InShot | Bizcraft | Golden Mango |
|---|---|---|---|---|
| Video → MP3 | ✅ | ✅ | ✅ | ✅ |
| M4A **instant lossless copy** (auto-detected) | ✅ | ❌ | ❌ | ❌ |
| WAV / FLAC | ✅ | ✅ | ✅ | ✅ |
| Trim in the **same screen** as convert | ✅ | separate screen | separate screen | separate screen |
| Preview loops the trimmed range | ✅ | partial | partial | partial |
| Batch | ✅ | ❌ | ❌ | ✅ |
| Normalize / volume boost / fades | ✅ | ✅ | ✅ | ✅ |
| **Album art from a video frame** + title/artist tags | ✅ (MP3) | tag only | tag only | tag only |
| **No-audio detection** before converting | ✅ | ❌ | ❌ | ❌ |
| **Zero-copy open** (large videos open instantly) | ✅ | ? | ? | ? |
| **Share-to-AudioPeel** from any app | ✅ | ✅ | ? | ? |
| Output visible in Music / WhatsApp | ✅ (Music/AudioPeel) | ✅ | ✅ | ✅ |
| In-app player + persistent mini-player | ✅ | basic | basic | basic |
| Set as ringtone / notification / alarm | ✅ | ✅ | ✅ | ✅ |
| Undo delete | ✅ | ❌ | ❌ | ❌ |
| No broad media permission | ✅ (system photo picker) | ❌ | ❌ | ❌ |
| Offline, nothing uploaded | ✅ | ✅ | ✅ | ✅ |

---

## 7. Engineering architecture

```
lib/
├── design/            tokens.dart · motion.dart · theme.dart
├── models/            media_item · output_format · convert_options · job · audio_file (v2)
├── services/
│   ├── media_bridge.dart      ⇄ MainActivity.kt (MethodChannel "com.mcore.audiopeel/media")
│   ├── ffmpeg_service.dart    builds commands from ConvertOptions; SAF input (no copy)
│   ├── player_service.dart    one shared just_audio player
│   ├── review_service.dart    in-app review gating
│   ├── consent_service.dart   UMP / GDPR
│   ├── database_service.dart  schema v2 (+format, +display_path)
│   └── notification_service.dart (kept)
├── providers/         queue_provider · history_provider · settings_provider · ad_provider · player_provider
├── widgets/           pressable · peel_reveal · waveform · pill_selector · trim_bar · rolling_number
│                      mini_player · section_card · burst · app_icon_mark · banner_ad_widget · toast
└── screens/           shell · home · studio · batch_studio · job · library · settings
```

### Native media bridge (`MainActivity.kt`)

| Method | What it does | Why |
|---|---|---|
| `pickVideos(multiple)` | System **photo picker** on API 33+, `GET_CONTENT` below that; returns `content://` URIs | No permission needed, no copy |
| `probe(uri)` | Name, size, duration, resolution, `hasAudio`, audio MIME (via `MediaMetadataRetriever` + `MediaExtractor`) | Instant facts, AAC detection, no-audio warning |
| `thumbnail(uri, ms, width)` / `filmstrip(uri, count, width)` | JPEG frames on a background thread | Preview, trim filmstrip, album art |
| `saveToLibrary(tempPath, name, mime)` | MediaStore insert into `Music/AudioPeel` (with `IS_PENDING`); legacy file plus media scan on API ≤ 28 | Visible everywhere, no permission on API 29+ |
| `delete(uri)` / `share(uris, mime)` / `openWith(uri, mime)` / `openFolder()` | Output actions | |
| `setRingtone(uri, type)` | Ringtone / notification / alarm | |
| `initialShared()` + `onShared` callback | ACTION_SEND / SEND_MULTIPLE / VIEW for `video/*` | Share-to-app entry point |

FFmpeg reads the `content://` URI through `FFmpegKitConfig.getSafParameterForRead`, so **nothing is copied**, and writes to a temp file that is then moved into MediaStore.

### Conversion recipe

```
[-ss START -t DUR]  -i <saf>  [-i cover.jpg]
-map 0:a:0 [-map 1:0 -c:v mjpeg -disposition:v attached_pic -id3v2_version 3]
[-af loudnorm,volume=X,afade=in:d=1.5,afade=out:st=..:d=1.5]
MP3  : -c:a libmp3lame -b:a Kk -ar 44100
M4A  : -c:a copy (AAC source, no filters)  |  -c:a aac -b:a Kk   + -movflags +faststart
WAV  : -c:a pcm_s16le -ar 44100
FLAC : -c:a flac
[-metadata title=.. -metadata artist=..]  -y  <temp>
```

---

## 8. Compliance changes bundled with the redesign

- Removed `READ_MEDIA_VIDEO`, `READ_MEDIA_AUDIO`, `READ_EXTERNAL_STORAGE` and `requestLegacyExternalStorage`. `WRITE_EXTERNAL_STORAGE` stays, limited to `maxSdkVersion=28`, for the legacy save path only.
- Added UMP consent before ads, plus a "Privacy options" entry in Settings.
- Notification permission is requested on the first conversion, not at launch.
- Interstitials: none for the first 3 successful conversions, then at most every 2nd, and only when **leaving** the result screen.
- The in-app review prompt appears after the 2nd success, triggered by a Play or Share tap, at most once every 60 days.

**Still open (outside UI scope):** the Play Data safety form needs updating for AdMob; the `ffmpeg-kit-full-gpl` dependency is **GPL**, which conflicts with a proprietary app (the privacy policy says LGPL). Move to an LGPL build (for example a custom minimal build without x264/x265) before the next release.

---

## 9. QA checklist for the redesign

- [ ] Pick 1 video → Studio opens in < 300 ms even for a 2 GB file
- [ ] Pick 3 videos → Batch Studio
- [ ] Share a video from Google Photos / Files / WhatsApp → Studio opens (cold start and warm)
- [ ] Trim: handles, nudges and preview looping; output duration matches the trim
- [ ] M4A Instant on an AAC source finishes in about 1–2 s for a 5 min video
- [ ] Video without audio → warning shown and Convert disabled
- [ ] MP3 with album art shows the cover in Samsung Music / Google Files
- [ ] Output appears in Music/AudioPeel, WhatsApp → Audio, and Files → Audio
- [ ] Ringtone / notification / alarm (with and without WRITE_SETTINGS)
- [ ] Library: expand-to-play, swipe delete + undo, search, filters
- [ ] Mini-player persists across tabs and stops on file delete
- [ ] Reduced-motion setting disables animations
- [ ] Light/dark themes; font scale 130%; small phone (360 dp)
- [ ] API 26, 29, 33, 35 devices
