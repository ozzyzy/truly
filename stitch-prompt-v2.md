# Truly — Stitch Prompt v2 (Correction Pass)

## What to fix from v1

This is a correction pass. The design system, color tokens, and card style from v1 are correct — keep them. The following issues must be fixed across all screens:

1. **Branding:** App name is **"truly"** — lowercase, light weight font, mint color `#006C4C`. Never "Breathable".
2. **No tab bar, no floating dock navigation anywhere.** Zero. Not on any screen.
3. **No user profile avatars.** Remove from every screen.
4. **No decorative photos or images.** The Done screen must not have a water photo. No landscape images anywhere in the app.
5. **No motivational quotes.** Remove "Focus is the art of knowing what to ignore" and any similar text.
6. **Help screen is out of scope.** Do not generate it.
7. **Settings:** one clean version only — use the simpler one (no drawer, no Sign Out, no Font Size).

---

## Design System (unchanged from v1)

**Colors:**
- Background: `#F6FAF8`
- Card: `#FFFFFF`
- Surface 2: `#EDF5F1`
- Text primary: `#181D1C`
- Text secondary: `#3D4A43`
- Accent mint: `#3DB88A`
- Accent dark: `#006C4C`
- Border: `rgba(0,0,0,0.06)`

**Font:** Plus Jakarta Sans throughout. Wordmark "truly": 20pt light, `#006C4C`, lowercase.

**Cards:** white, border-radius 16–24pt, shadow `0 12px 32px rgba(61,184,138,0.08)`.

**No tab bar. No bottom navigation. No drawer.**

---

## Screen 1 — Main / Random Action (keep v1 structure, fix branding only)

The v1 Random Action screen is the closest to correct. Keep it. Only fix:
- Replace any "Breathable" with "truly" (lowercase, light, mint)
- Remove profile avatar from header
- Header: left = "truly" wordmark, right = `settings` icon only

---

## Screen 2 — Library / Choose a moment (fix nav)

Keep the bottom sheet structure, category chips, favourites row, action list. Fix:
- **Remove the floating dock at the bottom entirely.** Replace with nothing — the sheet already has a close button.
- The sheet closes when user taps an action or the × button.
- No navigation inside the sheet.

---

## Screen 3 — Timer (fix branding)

Keep the ring, controls, and layout from v1. Fix:
- Replace "Breathable" wordmark in header with nothing — timer screen has no wordmark. Header is: `← Back` left, category label center, `···` right.
- Remove profile avatar.

---

## Screen 4 — Done (fix content)

Keep "Done." title, stats card (today / this week), and "Back to today" button. Fix:
- **Remove the water/nature decorative photo entirely.**
- **Remove the motivational quote** ("Focus is the art of knowing what to ignore").
- Remove profile avatar and "Breathable" wordmark.
- Top of screen: no header. Full-screen centered content only.
- Icon: `auto_awesome` Material Symbol, 52pt, mint color `#3DB88A`, centered.
- Below icon: "Done." 28pt bold, centered.
- Below title: "You gave yourself 20 minutes." 16pt secondary, centered.
- Stats card: unchanged from v1 — white card, "you reclaimed" label, two numbers side by side.
- Button: full-width mint `#3DB88A` rounded-full, "Back to today".
- Nothing else. Clean screen.

---

## Screen 5 — History (fix nav and branding)

Keep the weekly bar chart, "Recent moments" list, and "Saved actions" chips. Fix:
- **Remove the floating navigation dock at the bottom entirely.**
- Header: `← Back` left, "Your time" title right. No avatar.
- Remove "History" being highlighted as a nav item — there is no nav.
- "Saved actions" section title changed to "Saved" — keep the horizontal chip scroll.
- Overall screen: back arrow at top-left is the only way to navigate away.

---

## Screen 6 — Settings (use simpler version, cleaned up)

Use the simpler settings layout. Remove: Sign Out button, Navigation Drawer, Font Size row, "Recently Completed" row, version number in footer card.

**Final structure:**

Header: `← Back` + "Settings" title. No avatar, no wordmark.

**Section: Notifications**
- "Daily reminders" + toggle (mint when on)
- "Morning" → "9:00 AM"
- "Afternoon" → "13:00"
- "Evening" → "21:30"

**Section: Library**
- "Saved actions" → badge "3" mint pill + `chevron_right`
- "Reset dislikes" → secondary color text, no chevron (destructive-light action)

**Section: Appearance**
- "Theme" → "System" + `chevron_right`

**Section: About**
- "About Truly" → `chevron_right`
- "Share with a friend" → `chevron_right`

Footer: "Version 1.0.0" small secondary text, centered. No card around it.

---

## What NOT to generate

- No Help screen
- No onboarding screens
- No drawer navigation
- No profile avatars
- No decorative photos
- No tab bars or bottom docks
- No "Breathable" anywhere
- No quotes or inspirational text outside the Done screen's subtitle

---

## Summary of screens needed

1. Main / Random Action — 1 screen
2. Library sheet — 1 screen
3. Timer — 1 screen
4. Done — 1 screen
5. History — 1 screen
6. Settings — 1 screen

Total: 6 screens. Show each in iPhone 15 Pro frame (Dynamic Island).
