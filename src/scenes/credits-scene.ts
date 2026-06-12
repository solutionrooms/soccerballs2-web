// Credits, rendered from the original screen_credits layout.
import type { Scene, SceneContext } from './scene';

export class CreditsScene implements Scene {
  update(ctx: SceneContext): void {
    if (!ctx.input.buttonPressed) return;
    const hit = ctx.ui.hitTest('screen_credits', 0, ctx.input.x, ctx.input.y, new Set(['btn_back']));
    if (hit === 'btn_back') {
      ctx.audio.playSfx('sfx_click');
      void import('./title-scene').then(({ TitleScene }) => ctx.setScene(new TitleScene()));
    }
  }

  render(ctx: SceneContext): void {
    const r = ctx.r;
    r.beginFrame();
    const g = r.ctx;
    ctx.atlas.draw(g, 'backgrounds', 0, 0, 0);
    const hover = ctx.ui.hitTest('screen_credits', 0, ctx.input.x, ctx.input.y, new Set(['btn_back']));
    ctx.ui.draw(g, 'screen_credits', 0, { hover });
    r.endFrame();
  }
}
