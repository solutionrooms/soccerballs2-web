// M0 debug viewer: validates the asset pipeline end to end.
//  - Atlas mode: browse every atlas object/frame (arrows)
//  - Rig mode (TAB): play player/ref/keeper anim ranges from rigs.json+labels.json
import type { Scene, SceneContext } from './scene';
import { STAGE_W, STAGE_H } from '../game/defs';
import { drawRig, rigFrameCount, clipLabels } from '../game/rig';

const RIGS = ['player', 'ref', 'keeper'];

export class DebugViewerScene implements Scene {
  private mode: 'atlas' | 'rig' = 'atlas';
  private names: string[] = [];
  private objIndex = 0;
  private frameIndex = 0;
  private playing = true;
  private tick = 0;

  private rigIndex = 0;
  private rangeIndex = 0;
  private rigFrame = 0;

  onEnter(ctx: SceneContext): void {
    this.names = ctx.atlas.names();
  }

  update(ctx: SceneContext): void {
    const inp = ctx.input;
    if (inp.keyPressed('Tab')) {
      this.mode = this.mode === 'atlas' ? 'rig' : 'atlas';
    }
    if (inp.keyPressed('Space')) this.playing = !this.playing;

    if (this.mode === 'atlas') {
      if (inp.keyPressed('ArrowRight')) this.bumpObj(ctx, 1);
      if (inp.keyPressed('ArrowLeft')) this.bumpObj(ctx, -1);
      if (inp.keyPressed('ArrowUp')) this.frameIndex++;
      if (inp.keyPressed('ArrowDown')) this.frameIndex--;
      if (this.playing && ++this.tick % 4 === 0) this.frameIndex++;
      const count = ctx.atlas.frameCount(this.names[this.objIndex]);
      if (count > 0) this.frameIndex = ((this.frameIndex % count) + count) % count;
    } else {
      if (inp.keyPressed('ArrowRight')) this.bumpRange(1);
      if (inp.keyPressed('ArrowLeft')) this.bumpRange(-1);
      if (inp.keyPressed('ArrowUp')) {
        this.rigIndex = (this.rigIndex + 1) % RIGS.length;
        this.rangeIndex = 0;
        this.rigFrame = 0;
      }
      const [start, end] = this.currentRange();
      if (this.playing) {
        this.rigFrame++;
        if (this.rigFrame > end) this.rigFrame = start;
      }
      if (this.rigFrame < start || this.rigFrame > end) this.rigFrame = start;
    }
  }

  private bumpObj(ctx: SceneContext, dir: number): void {
    this.objIndex = (this.objIndex + dir + this.names.length) % this.names.length;
    this.frameIndex = 0;
    void ctx;
  }

  private ranges(): { name: string; start: number; end: number }[] {
    const rig = RIGS[this.rigIndex];
    const labels = clipLabels(rig);
    const out: { name: string; start: number; end: number }[] = [];
    for (const l of labels) {
      if (l.label.endsWith('_end')) continue;
      const endLabel = labels.find((e) => e.label === l.label + '_end');
      out.push({ name: l.label, start: l.frame, end: endLabel?.frame ?? l.frame });
    }
    return out.length ? out : [{ name: 'all', start: 0, end: rigFrameCount(rig) - 1 }];
  }

  private bumpRange(dir: number): void {
    const ranges = this.ranges();
    this.rangeIndex = (this.rangeIndex + dir + ranges.length) % ranges.length;
    this.rigFrame = ranges[this.rangeIndex].start;
  }

  private currentRange(): [number, number] {
    const r = this.ranges()[this.rangeIndex % this.ranges().length];
    return [r.start, r.end];
  }

  render(ctx: SceneContext): void {
    const r = ctx.r;
    r.beginFrame();
    const g = r.ctx;
    g.fillStyle = '#3a7d2c';
    g.fillRect(0, 0, STAGE_W, STAGE_H);

    if (this.mode === 'atlas') {
      const name = this.names[this.objIndex];
      const count = ctx.atlas.frameCount(name);
      // crosshair at sprite origin
      g.strokeStyle = 'rgba(255,255,255,0.4)';
      g.beginPath();
      g.moveTo(STAGE_W / 2 - 20, STAGE_H / 2);
      g.lineTo(STAGE_W / 2 + 20, STAGE_H / 2);
      g.moveTo(STAGE_W / 2, STAGE_H / 2 - 20);
      g.lineTo(STAGE_W / 2, STAGE_H / 2 + 20);
      g.stroke();
      ctx.atlas.draw(g, name, this.frameIndex, STAGE_W / 2, STAGE_H / 2);
      this.caption(ctx, `${this.objIndex + 1}/${this.names.length}  ${name}  frame ${this.frameIndex + 1}/${count}`);
      ctx.font.draw(g, 'FONT1 TEST 0123456789', 10, 40);
    } else {
      const rig = RIGS[this.rigIndex];
      const range = this.ranges()[this.rangeIndex % this.ranges().length];
      drawRig(g, ctx.atlas, rig, this.rigFrame, STAGE_W / 2, STAGE_H / 2 + 60);
      this.caption(ctx, `rig ${rig}  anim ${range.name} [${range.start}-${range.end}]  frame ${this.rigFrame}`);
    }
  }

  private caption(ctx: SceneContext, text: string): void {
    const g = ctx.r.ctx;
    g.fillStyle = 'rgba(0,0,0,0.6)';
    g.fillRect(0, 0, STAGE_W, 26);
    g.fillStyle = '#fff';
    g.font = '13px monospace';
    g.textBaseline = 'middle';
    g.fillText(text + '   [TAB mode, arrows browse, SPACE pause]', 8, 13);
    ctx.r.endFrame();
  }
}
