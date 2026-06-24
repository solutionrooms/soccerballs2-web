# Publishing Soccer Balls 2 to GameDistribution

Step-by-step for building, testing, zipping and uploading the GD release.

GD game ID (hash): `8339bd11fe664f56a33f81c0c8d04ca7` (already baked into the release build's `index.html`).

---

## 1. Build the release

```bash
npm run replica:release
```

This builds with `-Dreplica -Drelease -Dgdsdk`:
- `-Drelease` strips ALL debug code (the `sb2*` console hooks, debug keys, perf HUD, corner-click
  debug toggles, the hidden skip-level button, console spam). The hidden settings menu is gone in
  every build.
- `-Dgdsdk` injects the GameDistribution SDK into `index.html`.
- Output goes to `haxe-port/bin/html5/bin/` (it does **not** touch `haxe-port/site/`, so the live
  GitHub Pages build is left alone).

The normal dev build (`npm run replica:build`) keeps all the dev tooling and has **no** ads — use it
for development on :8753 as before.

## 2. Test it locally first

`localhost:8753` serves `bin/html5/bin/`, so after `npm run replica:release` you're testing the exact
release build. Check:
- No hidden settings menu (the secret bottom-left corner does nothing).
- Controls default correctly: **desktop → mode A**, **mobile/tablet → mode C (medium sensitivity)**.
- Level-failed screen: the star sits cleanly after "YOUR BEST: n" (no overlap).
- The game still plays normally. On localhost GD may show a test ad or nothing (no fill) — that's
  expected; the real ad check happens in GD's iframe (step 5).

## 3. Zip the production folder

GD wants `index.html` at the **root of the zip** + assets, ≤ 50 MB. The clean folder is
`bin/html5/bin/`, minus the 7 MB `original/` folder (dev-reference SWFs the game never loads).

```bash
cd haxe-port/bin/html5/bin
zip -r ../../../soccerballs2-gd.zip index.html favicon.png SoccerBalls2.js nape-replica.js assets lib manifest
```

That produces `haxe-port/soccerballs2-gd.zip` (~15 MB), with `index.html` at the root and `original/`
omitted.

> **manifest.json note:** our build emits lime's `manifest/default.json` (an asset manifest). GD's
> older docs mention a root `manifest.json`, but modern GD derives game metadata from the upload form
> (below). If the uploader rejects the zip for a missing `manifest.json`, say so and we'll add one.

## 4. Upload + fill the form

Upload the zip at <https://developer.gamedistribution.com/>. Suggested form answers:

| Field | Value |
|---|---|
| Optimized width × height | **700 × 525** |
| Genre | **Puzzle** (or *Sports* — pick one) |
| Tags | soccer, football, physics, puzzle, ball, kick, skill, aim, referee, casual, 1 player, funny, levels, stars |
| Intended Target Audience | **Both** |
| Age Group | **Everyone / all ages** (gentle cartoon slapstick, no blood) |
| Languages | English, Italian, French, German, Spanish, Portuguese, Dutch, Turkish, Swedish |
| "Game Doesn't Contain Text" | **OFF** (the game has text) |

**Description:**
> Soccer Balls 2 is a physics puzzle packed with slapstick fun. Bend, bank and blast soccer balls
> across dozens of tricky stages to knock every referee off the pitch — using as few kicks as you can.
> Master the angles, play off walls, crates and moving keepers, and earn three gold stars on every
> level. Easy to pick up, tough to perfect.

**Instructions:**
> Drag back from the ball to aim and set your power, then release to kick. Knock all the referees off
> the screen to clear the level — the fewer kicks you use, the more gold stars you earn. On phones and
> tablets, drag the on-screen aim pad to aim and tap to shoot.

**Key game features:**
> • Dozens of hand-crafted physics puzzle levels  • Simple drag-to-kick controls (mouse & touch)
> • 3-star scoring rewards clever, efficient shots  • Bank shots, breakable crates, moving keepers
> • Quick casual sessions, satisfying to master  • Plays on desktop, mobile and tablet

## 5. Verify + activate

After uploading, GD shows a **"revision" iframe link** to test before activation. Open it, **watch the
pre-roll ad completely** (don't cancel it) — that's what flags the SDK integration as valid. Then click
**Request activation**. (Activation can take up to ~2 weeks.)

---

## How the ads work (already wired)

GD rules followed: ads only fire from a button tap, never during gameplay, and the game freezes + mutes
while an ad plays.

- **Pre-roll:** fired when the player taps a level to start it (`UILevelSelect.levelPressed`).
- **Mid-roll:** fired on the Level Complete and Level Failed buttons — Next and Replay/Retry
  (`UILevelComplete` / `UILevelFailedScreen`). The SDK throttles how often a real ad shows, so calling
  it on every such button is fine (and is GD best practice).
- **Pause/mute:** GD's `onEvent` calls `window.sb2GdPause` (freeze sim + mute all audio) on
  `SDK_GAME_PAUSE` and `window.sb2GdResume` (resume + restore the player's mute preference) on
  `SDK_GAME_START`. See `haxe-port/src/GD.hx`.

No rewarded ads are wired (we can add one later if you want a watch-to-continue / hint mechanic).

## Deploying the same build to GitHub Pages (optional, separate)

The GD zip and the GitHub Pages `/` site are independent. If you also want the public site to be this
release build:

```bash
cp -R haxe-port/bin/html5/bin/. haxe-port/site/
# then commit + push main (the deploy workflow ships haxe-port/site/)
```
