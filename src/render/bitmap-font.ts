// In-game bitmap font: atlas object "font1", frame index = char code
// (DisplayObj.CreateFont / TextRenderer.as).
import type { Atlas } from './atlas';

export class BitmapFont {
  constructor(
    private atlas: Atlas,
    private fontName = 'font1',
  ) {}

  charWidth(code: number): number {
    const f = this.atlas.frame(this.fontName, code);
    return f ? f.w : 0;
  }

  measure(text: string, scale = 1, spacing = 0): number {
    let w = 0;
    for (let i = 0; i < text.length; i++) {
      w += (this.charWidth(text.charCodeAt(i)) + spacing) * scale;
    }
    return w;
  }

  draw(
    ctx: CanvasRenderingContext2D,
    text: string,
    x: number,
    y: number,
    opts: { scale?: number; spacing?: number; align?: 'left' | 'center' | 'right'; alpha?: number } = {},
  ): void {
    const scale = opts.scale ?? 1;
    const spacing = opts.spacing ?? 0;
    let cx = x;
    if (opts.align === 'center') cx -= this.measure(text, scale, spacing) / 2;
    else if (opts.align === 'right') cx -= this.measure(text, scale, spacing);
    for (let i = 0; i < text.length; i++) {
      const code = text.charCodeAt(i);
      this.atlas.draw(ctx, this.fontName, code, cx, y, { scale, alpha: opts.alpha });
      cx += (this.charWidth(code) + spacing) * scale;
    }
  }
}
