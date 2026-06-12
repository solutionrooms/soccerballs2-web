# Soccer Balls 2 — web port

A pixel- and gameplay-faithful TypeScript port of the Flash game *Soccer Balls 2*
(original AS3 source: [solutionrooms/SoccerBalls2](https://github.com/solutionrooms/SoccerBalls2)).
Architecture mirrors `ultra_baloon`: TypeScript strict + Vite + raw Canvas 2D,
scene system, JSON data imported as modules, localStorage persistence.
Physics: [planck.js](https://github.com/piqnt/planck.js) mapped to the original
Nape behaviour (30px/m, average restitution combine, world drag, rolling-friction
emulation, kick applied as direct velocity).

## Run

```bash
npm install
npm run dev        # http://localhost:5173/soccerballs2/
npm test           # 58 tests: data integrity, headless physics, progression
npm run build      # production build into dist/
```

URL params: `?level=N` jumps straight to a level, `?debug=1` opens the
atlas/rig viewer (TAB switches modes).

## Asset pipeline (`tools/`)

All game data and art are extracted from the original repo (expected as a
sibling checkout at `../SoccerBalls2`):

| Script | Output |
|---|---|
| `extract-atlas.ts` | `src/data/atlas.json` + texture pages (137 objects, 813 frames) |
| `extract-objects.ts` | physobj defs, materials, polymats, layers |
| `extract-levels.ts` | all 36 levels (935 coins, 10 trophies) |
| `extract-misc.ts` | balance vars, strings, achievements |
| `extract-swf.ts` | frame labels + player/ref/keeper rigs from the SWF (needs `tools/vendor/ffdec.jar`, prerun `-swf2xml`) |
| `extract-ui.ts` | UI screen display-list layouts (`ui-layout.json`) |
| `convert-audio.sh` / `convert-swf-audio.sh` | ogg/m4a sfx + music |
| `audit-levels.ts` | all-levels static + simulation audit (run after behavior changes) |

## Deploy

Pushes to `main` build and deploy to GitHub Pages via
`.github/workflows/deploy.yml` (base path `/soccerballs2/`).
