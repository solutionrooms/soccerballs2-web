# Soccer Balls 2 — Web Port: Open Issues

Found during play-testing on 2026-06-18 (haxe-port, deployed at solutionrooms.github.io/soccerballs2-web).
Each issue has a **severity**, the **symptom** (as reported), a **hypothesis** (unverified unless noted),
and a **starting point** in the code. Status: OPEN until fixed.

Severity key: 🔴 breaks the game / fidelity goal · 🟠 clearly-visible defect · 🟡 polish / cleanup / question.

---

## 1. 🟠 Fonts wrong in menus/messages + text not centred  — MOSTLY FIXED (2026-06-18)
**Resolution:** the in-game bitmap font (`font1`) was rasterized with a browser fallback because `Font20`
was a silent stub. Now: the user-provided **Komika Axis** (KOMIKAX.TTF → `assets/fonts/KomikaAxis.ttf`)
loads via the browser FontFace API (`GameFont.Load`), the preparing screen waits on it (`GameFont.ready`,
time-boxed), and `DisplayObj.CreateFont` bakes the glyphs from it (`embedFonts=false`). Menus/messages =
correct. The HUD's SWF dynamic text (score, level name) is a *separate* path (embedded SWF font, openfl-swf
rendered); centring it (`HudController.CentreHudText`) fixed the **score** and **level-name** banners.
Note: "ENgland" is faithful original data (`GameVars`), kept per user.
**REMAINING (deferred):** the three small icon counters (balls/stars/coins, `kicksText`/`starText`/
`coinsText`) stay slightly left-clipped. Diagnostics confirm the text is present, `visible`, `align=center`,
with NO mask/scrollRect — openfl-swf just won't visually centre these *narrow* embedded-font fields like it
does the wide ones. Not solved by align/wordWrap/autoSize/device-font. **Revisit** by rendering those three
numbers via the working bitmap `TextRenderer` (overlay Bitmap in the icon-box clip), or a deeper openfl-swf
text-layout fix. Cosmetic; gameplay unaffected.

**Symptom:** Capitalisation is wrong, e.g. "ENgland" (the second letter renders as a capital). Related:
text is often not centred within its box.
**Hypothesis:** Bitmap-font glyph mapping is off — the in-game font (`origName="font1"` in the atlas,
frame index = char code) is likely a small-caps face where lower- and upper-case map to different frames,
and the port is selecting the wrong frame for some letters. The centring is a knock-on: if per-glyph
advance/width is wrong, the measured string width used for centre-justify is wrong too.
**Starting point:** `Font20.hx`, `TextPackage/`, `EmbedTextStrings.hx`, the `TextRenderer` (used via
`TextRenderer.RenderAt(..., JUSTIFY_CENTRE, ...)`), and the atlas frame→char mapping. Compare a known
string's per-char frame indices vs the original.
**Effort:** medium · **Risk:** low (contained to text rendering).

---

## 2. 🔴 Z-order / layering broken — GPU-blit (Tilemap) regression  — FIXED (2026-06-18, user-confirmed)
**Resolution:** terrain fills were `bd.draw`-ed into the software underlay (always behind all GPU
sprites = two fixed depth bands). Fixed by emitting the terrain fill as a GPU **tile at the object's
real zpos** (`GameObj.RenderFillAsTile`, called from `RenderPhysicsLineObject_Static`), so terrain
interleaves with sprites in TileRenderer's zpos-ordered stream. Trophy-behind-grass and
clouds-behind-foreground both corrected. **Scope:** Static terrain (grass/mud/decor-mud) only; the
Surface/Movable spline-terrain variants (GameObj.hx ~586/978/1000/1193, NOT the minimap at 671) still
use the old underlay path — apply the same `RenderFillAsTile` swap if any level shows them mis-layered.
Dev build only; not yet promoted to `site/`.

**Symptom:** Clouds render *in front of* foreground scenery. Trophy (behind ref, left) shows *in front of*
grass in our build; in the original it's correctly hidden behind the grass. The two look like the same
root bug. Reported as introduced "when we shifted to GPU Blit."
**Hypothesis (high confidence on cause):** the Tilemap/GPU-blit conversion (task #40) changed draw order.
The game composites by `game_layer` z (zpos) — clouds/background must draw *behind* foreground/scenery and
in-front objects must respect per-object z within a layer. Batching into tilemaps likely flattened or
re-ordered those layers, so cross-layer ordering is no longer honoured. This is **our regression** (there's
a known-good pre-blit state to diff against), which makes it tractable.
**Starting point:** `TileRenderer.hx` and the render/composite path in `Game.hx`; `GameLayers` z-table.
Check how layers are flushed/ordered into the tilemap(s) vs the old per-object blit order.
**Effort:** medium · **Risk:** medium (touches the render pipeline) · **Note:** systemic — fixing the
layer-ordering model fixes clouds, trophy, and any "similar" cases at once.

---

## 3. 🔴 No sound anywhere  — FIXED (2026-06-18, user-confirmed)
**Resolution:** audio was never wired (only a silent `SfxClick` stub, zero audio files, `AddSound`
resolved by class name only → null). Converted the 39 original WAVs → OGG into `assets/audio/{sfx,music}/`,
added an external `type="sound"` asset rule in project.xml, and rewrote `Audio.AddSound` to load by name
via `openfl.utils.Assets.getSound` (with trailing-digit fallback for `sfx_pop`, legacy class fallback
kept). Music names mapped: menus_music→Sambatastico, music_ingame1→Cuban Nights Loop 01,
music_boss→Samba Street Festival (swappable by re-converting). Resume-on-gesture already handled autoplay.
Dev build only; not yet promoted to `site/`.

**Symptom:** No audio at all (sfx or music).
**Hypothesis:** Web audio not actually starting. Candidates: (a) AudioContext never resumed after a user
gesture (browsers block autoplay until a click), (b) a residual of the earlier "startup probe muted
everything" bug (commit 8049def) still silencing output, (c) sample/music load or name-mapping failing
silently (original tolerates missing sounds by design). Needs a console check during a click to see which.
**Starting point:** `AudioPackage/`, `AmbientSound.hx`; trace the resume-on-first-input path and the
startup mute/probe logic. (Will need the user to run it and copy console output — physics-style logging.)
**Effort:** unknown (could be a one-line resume, could be deeper) · **Risk:** low.

---

## 4. 🟡 Remove or hide many logos  — OPEN
**Symptom:** Too many sponsor/branding logos and external buttons (e.g. "more GAMES").
**Hypothesis:** Straightforward UI suppression — hide the relevant display objects / buttons on the menu
and in-game HUD. Aligns with the plan's "skip ads/analytics (mochi/playtomic)" decision.
**Starting point:** `ScreenMainMenu.hx`, `ScreenMatchSelect.hx`, HUD; identify the named logo/button nodes
and gate their visibility. **Needs a list** from the user of exactly which logos to remove vs keep.
**Effort:** low · **Risk:** low. Related to #6 (walkthrough button could be hidden the same way).

---

## 5. 🟡 Initial load screen ("ball filling up") — keep or skip?  — QUESTION
**Symptom:** A loading screen (ball fills up) shows on first load. Is it doing anything important?
**Hypothesis:** It's the `Preloader` gating asset load. On web, assets are served via the lime manifest;
if they're effectively instant / already resolved, the preloader may be vestigial and skippable (or can be
shortened to a single frame). Need to confirm it isn't actually blocking on a real async asset fetch.
**Starting point:** `Preloader.hx` — check whether it waits on real load progress or just plays an
animation for a fixed time.
**Effort:** low · **Risk:** low.

---

## 6. 🟠 Walkthrough button doesn't work (on levels)  — OPEN
**Symptom:** The in-level WALKTHROUGH button does nothing.
**Hypothesis:** Walkthrough mode was de-scoped in the original plan ("Skip: walkthrough mode"), so the
button is present but unwired. The infra partly exists (`Walkthrough.hx`, `ScreenWalkthrough*.hx`,
`WalkthroughRecordings`, `Game.doWalkthrough`). **Decision needed:** wire it up vs hide the button
(if hiding, folds into #4).
**Starting point:** `Game.hx:265` (`if (doWalkthrough) Walkthrough.InitScreens()`), `ScreenWalkthrough.hx`,
the button's click handler on the level screen.
**Effort:** low (hide) / medium-high (fully wire) · **Risk:** low.

---

## 7. 🟠 Mobile controls  — NEEDS DETAIL
**Symptom:** (Unspecified) — something wrong with mobile controls.
**Hypothesis:** N/A until specifics. Scheme B (joystick + tap-kick) exists (task #38, toggle in Options).
**Starting point:** `MobileControls.hx`, `MobileSpecific.hx`, `Settings.mobileControlScheme`.
**Needs from user:** what's broken — layout, responsiveness, kick aiming, which device/orientation?
**Effort:** unknown · **Risk:** low.

---

## Suggested tackle order (rationale)

1. **#2 Z-order (GPU-blit regression)** — 🔴, *our* regression (clear before/after), systemic (one fix
   resolves clouds + trophy + similar), and it directly serves the pixel-fidelity goal.
2. **#3 No sound** — 🔴, total-absence show-stopper; independent of rendering so can run in parallel; may
   be a quick AudioContext-resume fix.
3. **#1 Fonts/centring** — 🟠, very visible, contained to the text renderer.
4. **#4 + #6 Logos & walkthrough button** — 🟡/🟠, low-effort UI cleanup, best done together.
5. **#5 Load screen** — 🟡, quick once #2/#3 settle.
6. **#7 Mobile controls** — blocked on details.
