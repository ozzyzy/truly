# Truly — Stitch AI Prompt (MVP)

## App Concept

**Truly** is an iOS app for reclaiming small moments of intentional time. Three entry scenarios:
1. Push notification arrives → user taps → sees a suggested action → starts timer
2. User opens app → sees random action → can swap it or choose from library
3. User dislikes suggestion → app replaces it instantly with another random one

No planning, no to-do lists. Just: here's something good you could do right now.

---

## Design System

**Style:** Clean iOS minimal. Light, fresh, slightly airy. Not warm-brown — neutral-cool base with mint accent. Rounded, soft, approachable.

**Colors:**
- Background: `#F6FAF8` (near-white with very subtle mint tint)
- Card surface: `#FFFFFF`
- Surface 2: `#EDF5F1` (light mint-tinted fill)
- Text primary: `#1C1C1E` (standard iOS near-black)
- Text secondary: `#8E8E93` (standard iOS gray)
- Accent / mint: `#3DB88A` (medium-fresh mint green)
- Accent light: `#7DD4BC` (for backgrounds, pill fills)
- Accent dark: `#2A9070` (pressed state, bold use)
- Destructive-soft: `#F2827A` (dislikes, only when needed)
- Border: `rgba(0,0,0,0.06)`

**Typography:** SF Pro Rounded throughout.
- Display: 28–32pt bold, tracking -0.5
- Title: 20–22pt bold, tracking -0.4
- Body: 15pt regular
- Label: 11pt semibold, uppercase, tracking +0.07em
- Caption: 12pt regular secondary

**Cards:** `#FFFFFF`, border-radius 24pt, shadow `0 2px 16px rgba(60,180,140,0.08)`. No harsh borders.

**Primary button:** mint `#3DB88A`, border-radius 16pt, full-width, 54pt height. Text white bold.

**SF Symbols weight:** light or regular. No emojis anywhere.

---

## Animations (describe in every screen)

Full animation spec to implement in SwiftUI:

- **Card entrance:** `.spring(response: 0.4, dampingFraction: 0.75)` scale from 0.94 + opacity 0 → 1
- **Card swap (new random action):** outgoing card slides left + fades out over 0.25s, incoming card slides in from right with spring
- **Like (♥ tap):** heart icon scales 1.0 → 1.4 → 1.0 with `.spring`, fills mint color, tiny particle burst (4–5 small circles scatter from tap point)
- **Dislike (✕ tap):** card shakes horizontally (3 small oscillations, ~6pt travel, 0.3s), then triggers card swap animation
- **Timer ring:** `animatableData` on stroke progress, real-time smooth decrement. Ring color transitions peach→mint→sage as time runs down (optional, or stays mint throughout)
- **Timer start transition:** action card on main screen performs a hero-style expand — scales up and morphs into timer full-screen over 0.5s. If not feasible in Stitch, show as a clean full-screen push transition.
- **Done screen entrance:** content fades + slides up in sequence with 0.1s stagger — icon first, then title, then subtitle, then stats card
- **Sparkles icon:** on Done screen, `sparkles` SF Symbol animates with a brief `.symbolEffect(.bounce)` on appear
- **Stats number count-up:** minutes numbers animate from 0 to final value over 0.8s with ease-out
- **Haptics (note in spec):**
  - Timer start → `.impactOccurred(intensity: 0.8)`
  - Every 5 minutes during timer → `.impactOccurred(intensity: 0.3)` (subtle tick)
  - Done → `.notificationOccurred(.success)` (double tap feel)
  - Like → `.impactOccurred(intensity: 0.5)`
  - Dislike → `.impactOccurred(intensity: 0.4)`
- **Settings toggle:** standard iOS spring toggle, mint tint when on
- **Sheet presentation:** `.presentationDetents` with spring drag feel, background dims to 40% black

---

## Screen 1 — Main / Random Action

**Entry points:** push notification tap, or cold app open.

**Layout (full screen):**

Top area (20% height):
- Top-left: small app wordmark "truly" in secondary color, 13pt, lowercase, SF Rounded light weight
- Top-right: gear icon (`gearshape`) 20pt secondary — taps to Settings

Center (50% height):
- Large action card — white, border-radius 28pt, horizontal padding 28pt, vertical padding 32pt, shadow elevated
  - Top: category label, tiny uppercase secondary, e.g. "BODY"
  - SF Symbol icon centered, 52pt, mint color, e.g. `figure.walk`
  - Action title: 24pt bold, centered, e.g. "Evening walk"
  - Duration: mint pill chip centered, e.g. "20 min" — background `#EDF5F1`, text `#3DB88A`, border-radius 100pt, padding 4pt 12pt
  - Bottom of card: thin separator line, then two buttons side by side:
    - Left: `heart` SF Symbol, 22pt — secondary color, tapping fills mint (liked)
    - Right: `arrow.2.squarepath` SF Symbol, 22pt — secondary color, tapping swaps card (new random)

Below card (center-aligned):
- Link text: "choose something else →" in mint `#3DB88A`, 14pt — opens Library sheet

Bottom (fixed, above home indicator):
- Full-width mint button "Start" 54pt height, border-radius 16pt
- Subtext below button: "or tap ♥ to save for later" — 11pt secondary, centered (disappears after first like)

**Animation state:** card enters with spring scale on every cold open and every swap.

---

## Screen 2 — Library (Choose action)

**Presentation:** bottom sheet, ~88% screen height, spring drag. Background scrim 40% black.

**Layout:**
- Top handle bar (36×4pt, `#E0E0E0`, border-radius 2pt, centered)
- Title row: "Choose a moment" 20pt bold left + `xmark.circle.fill` right secondary
- Horizontal category chip scroll (no scroll indicator):
  - Chips: All · Body · Rest · Focus · Connection · Creative
  - Active chip: mint background `#3DB88A`, white text, border-radius 100pt
  - Inactive: `#EDF5F1` background, secondary text
  - Chips animate selection with `.spring` background color transition
- Below: vertical list of action rows (not grid — single column, easier to scan)
  - Row height: 64pt
  - Left: SF Symbol in mint circle (36pt circle, `#EDF5F1` fill, mint icon 18pt)
  - Center: action name 15pt semibold + category + duration in secondary 12pt below
  - Right: chevron `chevron.right` 14pt secondary
  - Separator: 1pt `rgba(0,0,0,0.05)` inset from left icon
  - Tap → sheet dismisses, card on main screen swaps with animation to selected action

**Liked actions section** (above category chips, if any liked):
- Label "Your favourites" secondary uppercase tiny
- Horizontal scroll of compact liked-action chips (white card, border-radius 14pt, icon + name, 44pt height, mint border 1pt)
- Visible only when ≥1 liked action exists

---

## Screen 3 — Timer

**Full screen. No navigation bar.**

Background: `#F6FAF8` (same as app background — not dark).

**Layout (vertically centered):**

Top strip (fixed):
- Left: `chevron.left` back button 16pt + "Back" 15pt secondary (confirms stop)
- Center: category label uppercase tiny secondary
- Right: `ellipsis` menu for future options (visible but inactive in MVP)

Center:
- Circular progress ring, 220pt diameter
  - Background ring: `#EDF5F1`, stroke 4pt
  - Progress ring: mint `#3DB88A`, stroke 4pt, linecap `.round`
  - Ring animates in real-time with smooth decrement
  - Inside ring: time remaining 38pt bold primary, tracking -1pt. Below: "remaining" 11pt secondary uppercase
- 20pt gap
- Action title 17pt semibold primary, centered
- Category · duration in secondary 13pt, centered

Controls (32pt below title):
- Three buttons in a horizontal row, center-aligned, 28pt gap:
  - `arrow.counterclockwise` — 44pt circle, white card shadow, secondary icon 18pt. Taps restarts timer with confirmation
  - `pause.fill` / `play.fill` — 58pt circle, mint background, white icon 22pt. Spring scale on tap.
  - `checkmark` — 44pt circle, white card shadow, secondary icon 18pt. Marks done early

**Animation:** ring decrements smoothly every second. Haptic every 5 minutes. On timer complete: ring briefly flashes (opacity pulse 1→0.5→1 over 0.3s), then auto-navigates to Done screen.

---

## Screen 4 — Done

**Full screen. Background `#F6FAF8`.**

**Layout (vertically centered, content fades in staggered):**

1. `sparkles` SF Symbol, 52pt, mint color, centered. `.symbolEffect(.bounce)` on appear.
2. 24pt gap
3. "Done." 28pt bold primary, centered. No exclamation mark.
4. "You gave yourself 20 minutes." 16pt secondary, centered.
5. 36pt gap
6. Stats card: white, border-radius 24pt, shadow, padding 20pt horizontal 24pt vertical:
   - "you reclaimed" secondary uppercase tiny, centered
   - Horizontal split, 1pt vertical divider (40pt tall, `rgba(0,0,0,0.08)`):
     - Left: bold 24pt primary "35 min" (count-up animation) + "today" 12pt secondary below
     - Right: bold 24pt primary "2 hr 10 min" (count-up animation) + "this week" 12pt secondary
7. 32pt gap
8. Full-width mint button "Back to today" — taps back to Main screen with card entrance animation

**Haptic on screen appear:** `.notificationOccurred(.success)`

---

## Screen 5 — History

**Regular push screen.**

Top: "Your time" 22pt bold left. Right: `calendar` icon secondary, taps filter (V2, show as inactive).

**This week card:** white, border-radius 20pt, padding 20pt:
- "This week" secondary tiny uppercase
- "4 hr 20 min" bold 28pt primary (count-up on appear)
- 7-column day chart below — M T W T F S S
  - Each column: small rounded bar (8pt wide, max 40pt tall), height proportional to minutes
  - Filled: mint `#3DB88A`. Empty: `#EDF5F1`. Today's bar: slightly darker mint + dot below day letter
  - Day letter: 10pt secondary below each bar. Today: mint color

**Section:** "Recent moments" secondary uppercase tiny, margin 24pt top

**Completed cells** (list, white cards, 8pt gap, border-radius 16pt):
- 64pt height
- Left: SF Symbol in mint circle 36pt
- Center: action name 14pt semibold + date/duration 12pt secondary
- Right: `checkmark.circle.fill` mint 20pt
- Show 6 items, then "See all" mint link

**Liked section** (below recent):
- "Saved actions" secondary uppercase tiny
- Horizontal scroll of liked-action chips (same as library)

---

## Screen 6 — Settings

**Regular push screen. Background `#F6FAF8`.**

Top: "Settings" 22pt bold.

**Grouped white card sections, border-radius 20pt. No icons on rows.**

**Section: Notifications**
- "Daily reminders" → toggle (mint when on)
- "Morning" → right value "9:00 AM" secondary, chevron
- "Afternoon" → right value "13:00" secondary, chevron
- "Evening" → right value "21:30" secondary, chevron
- Time pickers appear as inline expander rows (not separate screen)

**Section: Library**
- "Saved actions" → shows count badge "3" mint pill, chevron → opens liked actions list
- "Reset dislikes" → secondary color text (soft, not red)

**Section: Appearance**
- "Theme" → right value "System" secondary, chevron → Light / Dark / System picker

**Section: Shortcuts**
- "Set up Instagram shortcut" → chevron → info screen explaining iOS Shortcuts setup (V2 feature, show as coming soon with mint badge "Soon")

**Section: About**
- "About Truly" → chevron
- "Share with a friend" → chevron

Row height: 50pt. Separator: 1pt `rgba(0,0,0,0.05)` inset. Toggle tint: mint `#3DB88A`.

---

## App Icon

**1024×1024pt, iOS rounded corners applied by system.**

**Background:** clean mint gradient, top-left `#7DD4BC` → bottom-right `#2A9070`. Subtle, not neon.

**Mark:** white, centered. A simple organic drop / teardrop shape (vertical orientation, slightly wider at bottom, pointed top). Inside: two minimal clock hands — hour pointing straight up, minute pointing ~1–2 o'clock. Hands are thin white strokes (2.5pt, linecap round), meeting at a small filled circle center (4pt diameter). No tick marks, no numbers, no border on clock face.

**Feel:** fresh, calm, natural. Mint = reclaimed time, growth, breathing. Not a productivity icon.

---

## Key Principles for Stitch

- No tab bar anywhere in the app
- No blue anywhere — mint is the only accent color
- Every neutral has zero warm tint — clean cool-neutral base
- Cards never have borders — only shadow for elevation
- Minimum border-radius everywhere: 16pt
- Use SF Symbols throughout, weight light or regular
- Show in iPhone 15 Pro frame (Dynamic Island)
- Status bar: dark content on light background
