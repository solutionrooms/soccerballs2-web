// Canvas renderer for the fixed 700x525 stage, letterboxed into the window.
// All game drawing happens in stage coordinates; the renderer applies one
// stage->screen transform per frame.
import { STAGE_W, STAGE_H } from '../game/defs';

export class Renderer {
  readonly canvas: HTMLCanvasElement;
  readonly ctx: CanvasRenderingContext2D;
  width = 0; // CSS px
  height = 0;
  dpr = 1;

  // stage -> screen: screenX = stageX * scale + offX
  scale = 1;
  offX = 0;
  offY = 0;

  constructor(canvas: HTMLCanvasElement) {
    this.canvas = canvas;
    const ctx = canvas.getContext('2d', { alpha: false });
    if (!ctx) throw new Error('2D canvas unsupported');
    this.ctx = ctx;
    this.resize();
  }

  resize(): void {
    const dpr = Math.min(window.devicePixelRatio || 1, 2.5);
    const cssW = Math.max(1, Math.floor(window.innerWidth));
    const cssH = Math.max(1, Math.floor(window.innerHeight));
    this.dpr = dpr;
    this.width = cssW;
    this.height = cssH;
    const bw = Math.floor(cssW * dpr);
    const bh = Math.floor(cssH * dpr);
    // Reallocating the backing store clears it — only do so on real changes.
    if (this.canvas.width !== bw || this.canvas.height !== bh) {
      this.canvas.style.width = cssW + 'px';
      this.canvas.style.height = cssH + 'px';
      this.canvas.width = bw;
      this.canvas.height = bh;
    }
    this.scale = Math.min(cssW / STAGE_W, cssH / STAGE_H);
    this.offX = (cssW - STAGE_W * this.scale) / 2;
    this.offY = (cssH - STAGE_H * this.scale) / 2;
  }

  /** Clear screen and set the stage transform + clip. */
  beginFrame(): void {
    const { ctx } = this;
    ctx.setTransform(this.dpr, 0, 0, this.dpr, 0, 0);
    ctx.fillStyle = '#000';
    ctx.fillRect(0, 0, this.width, this.height);
    ctx.save();
    ctx.beginPath();
    ctx.rect(this.offX, this.offY, STAGE_W * this.scale, STAGE_H * this.scale);
    ctx.clip();
    ctx.translate(this.offX, this.offY);
    ctx.scale(this.scale, this.scale);
    ctx.imageSmoothingEnabled = true;
  }

  endFrame(): void {
    this.ctx.restore();
  }

  screenToStage(clientX: number, clientY: number): { x: number; y: number } {
    const rect = this.canvas.getBoundingClientRect();
    return {
      x: (clientX - rect.left - this.offX) / this.scale,
      y: (clientY - rect.top - this.offY) / this.scale,
    };
  }
}
