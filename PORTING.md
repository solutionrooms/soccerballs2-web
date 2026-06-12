# Behavior porting contract (M2)

Target: faithful TypeScript ports of `GameObj.as` behaviors into `src/game/behaviors/<family>.ts`.

## Source of truth
- AS3 source: `/Users/jonscott/Projects/SoccerBalls2/src/GameObj.as` (+ `GameObj_Base.as`, `GameVars.as`, `Vars.as` via `src/data/vars.json`)
- Port the logic *exactly*: same state numbers, same timer values (frames at 60fps), same constants, same sfx names, same score values. Quote the AS3 line range you ported in a comment above each function.

## Types you code against (do not redefine)
- `GameObj` / `GameContext` / `GameObjects` from `src/game/gameobj.ts`:
  - GameObj: `id name type collisionType state xpos ypos zpos dir(deg) scale xflip visible dead dobjName frame frameVel animStart animEnd animFrame timer timerMax ballTimer stillTimer startx starty toPosX toPosY body(planck.Body|null) physicsStationary params refA refB updateFn renderFn onHitFn` and `param(name,def)` / `paramNum(name,def)`.
  - `updateFn(go, g)` runs at fixed 60Hz. `renderFn(go, g, ctx2d)` draws in world space (camera transform already applied). `onHitFn(go, hitter, g, sensor)` fires on begin-contact.
  - GameContext `g`: `physics atlas level audio objects mouseX mouseY cameraX cameraY bounds`.
- Physics: `PhysicsWorld` from `src/physics/world.ts` — px-space statics: `getPosPx/setPosPx/setVelPx/getVelPx/applyImpulsePx/massNape`; instance: `raycastFloorY(x, fromY, maxDist)`, `createBody`, `destroyBody`. 30px = 1m; planck `Body` methods available (`setLinearVelocity` is in METERS — prefer the px statics).
- Helpers from `./core`: `setAnim(go, clip, name)` `cycleAnim(go)` `playAnim(go)->bool(done)` `parkBody(go)` `setCollisionEnabled(go, on)` `footballLaunch(ball, jx, jy)` `footballMoveToPlayer(ball, player, g)` `playerSetHasFootball(player, ball)` `spawnPopup(g, x, y, dobjName)` `spawnSmokePuff(g, x, y)` `kickAim`.
- Rig anim: `setAnim`/`cycleAnim`/`playAnim` use labels from `src/game/rig.ts` (`animRange(clip, name)` resolves `<name>`/`<name>_end` labels; `labelFrame(clip, label, from)`); draw rigs with `drawRig(ctx, g.atlas, '<player|ref|keeper>', frame, x, y, {xflip, scale})`.
- Sprites: `g.atlas.draw(ctx, dobjName, frame, x, y, {rot, scale, xflip, alpha})`; `g.atlas.frameCount(name)`.
- Constants: `VARS` (VarsData.xml numbers), `FPS`, `STAGE_W/H` from `src/game/defs.ts`; math helpers in `src/game/utils.ts` (`scaleTo`, `scaleToPreLimit`, `distBetween`, `easePowerInOut`).
- Audio: `g.audio.playSfx(name, vol?, pan?)`.
- Level counters: `g.level` (`numKicks maxKicks numGoalsScored totalGoals numRefsHit totalRefs addScore(n) phase doKick` ...).

## File shape
Each family file exports init functions named after the AS3 initfunction in camelCase
(e.g. `InitSpikyBall` -> `export function initSpikyBall(go: GameObj, g: GameContext): void`).
Also export a `registry: Record<string, (go: GameObj, g: GameContext) => void>` mapping the
EXACT AS3 initfunction name (e.g. `"InitSpikyBall"`) to the init. `level-loader.ts` merges registries.

The default renderFn (atlas clip+frame at xpos/ypos with dir/scale/xflip) is already set
before init runs — only override when the AS3 render differs.

## Rules
- TypeScript strict; no `any` unless unavoidable; file must compile with `npx tsc --noEmit` from the repo root `/Users/jonscott/Projects/soccerballs2-web`.
- Frame-locked logic: timers count frames at 60fps exactly like the AS3 (`Defs.fps` = 60).
- Where AS3 reads `Vars.GetVarAsNumber("x")` use `VARS.x`.
- Where behavior depends on a feature that does not exist yet (e.g. particles system), spawn the nearest existing primitive (`spawnPopup`/`spawnSmokePuff`) and leave a `// TODO(M5):` comment.
- Do NOT modify existing files except your own new family file. Report anything you need changed in existing files instead.
