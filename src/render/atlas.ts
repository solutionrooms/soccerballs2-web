// Sprite atlas: texture pages + frame rects from GraphicObjectsLayout.xml
// (extracted to atlas.json). Frame registration mirrors DisplayObj.as:
// draw position = origin + (ox, oy), where ox/oy are the clip-bounds offsets.
import atlasJson from '../data/atlas.json';

export interface AtlasFrame {
  page: number;
  x: number;
  y: number;
  w: number;
  h: number;
  ox: number;
  oy: number;
}

export interface AtlasObject {
  flags: string;
  frames: AtlasFrame[];
}

const objects = (atlasJson as { objects: Record<string, AtlasObject> }).objects;

export class Atlas {
  private pages: HTMLImageElement[] = [];

  async load(baseUrl: string): Promise<void> {
    const pageIndices = new Set<number>();
    for (const obj of Object.values(objects)) {
      for (const f of obj.frames) pageIndices.add(f.page);
    }
    await Promise.all(
      [...pageIndices].map(
        (i) =>
          new Promise<void>((resolve, reject) => {
            const img = new Image();
            img.onload = () => resolve();
            img.onerror = () => reject(new Error(`failed to load page-${i}.png`));
            img.src = `${baseUrl}page-${i}.png`;
            this.pages[i] = img;
          }),
      ),
    );
  }

  get(name: string): AtlasObject | undefined {
    return objects[name];
  }

  names(): string[] {
    return Object.keys(objects);
  }

  frameCount(name: string): number {
    return objects[name]?.frames.length ?? 0;
  }

  /**
   * Draw a frame with its sprite origin at (x, y), with optional rotation
   * (degrees, Flash convention), uniform scale, x-flip and alpha.
   * `image` overrides the page bitmap (used by the kit-tint cache).
   */
  draw(
    ctx: CanvasRenderingContext2D,
    name: string,
    frame: number,
    x: number,
    y: number,
    opts: {
      rot?: number;
      scale?: number;
      scaleY?: number;
      xflip?: boolean;
      alpha?: number;
      image?: CanvasImageSource;
    } = {},
  ): void {
    const obj = objects[name];
    if (!obj) return;
    const f = obj.frames[Math.max(0, Math.min(frame | 0, obj.frames.length - 1))];
    if (!f || f.w === 0 || f.h === 0) return;
    const img = opts.image ?? this.pages[f.page];
    if (!img) return;

    const rot = opts.rot ?? 0;
    const sx = (opts.scale ?? 1) * (opts.xflip ? -1 : 1);
    const sy = opts.scaleY ?? opts.scale ?? 1;
    const alpha = opts.alpha ?? 1;

    ctx.save();
    if (alpha !== 1) ctx.globalAlpha *= alpha;
    ctx.translate(x, y);
    if (rot) ctx.rotate((rot * Math.PI) / 180);
    if (sx !== 1 || sy !== 1) ctx.scale(sx, sy);
    ctx.drawImage(img, f.x, f.y, f.w, f.h, f.ox, f.oy, f.w, f.h);
    ctx.restore();
  }

  // Kit tinting: Flash applied ColorTransform(1,1,1,1, r-255, g-255, b-255, 0)
  // to white tint_* overlay sprites — a per-channel additive offset with
  // clamping, so white pixels become exactly the kit color. Cached offscreens.
  private tintCache = new Map<string, HTMLCanvasElement | null>();

  private tintedFrame(name: string, frame: number, rgb: [number, number, number]): HTMLCanvasElement | null {
    const key = `${name}#${frame}#${rgb.join(',')}`;
    let canvas = this.tintCache.get(key);
    if (canvas !== undefined) return canvas;
    const f = this.frame(name, frame);
    const page = f ? this.pages[f.page] : undefined;
    if (!f || !page || f.w === 0 || f.h === 0) {
      this.tintCache.set(key, null);
      return null;
    }
    canvas = document.createElement('canvas');
    canvas.width = f.w;
    canvas.height = f.h;
    const c2d = canvas.getContext('2d')!;
    c2d.drawImage(page, f.x, f.y, f.w, f.h, 0, 0, f.w, f.h);
    const img = c2d.getImageData(0, 0, f.w, f.h);
    const d = img.data;
    const offR = rgb[0] - 255;
    const offG = rgb[1] - 255;
    const offB = rgb[2] - 255;
    for (let i = 0; i < d.length; i += 4) {
      d[i] = Math.max(0, Math.min(255, d[i] + offR));
      d[i + 1] = Math.max(0, Math.min(255, d[i + 1] + offG));
      d[i + 2] = Math.max(0, Math.min(255, d[i + 2] + offB));
    }
    c2d.putImageData(img, 0, 0);
    this.tintCache.set(key, canvas);
    return canvas;
  }

  /** draw() with the kit ColorTransform applied (cached per frame+color). */
  drawTinted(
    ctx: CanvasRenderingContext2D,
    name: string,
    frame: number,
    x: number,
    y: number,
    rgb: [number, number, number],
    opts: { rot?: number; scale?: number; scaleY?: number; xflip?: boolean; alpha?: number } = {},
  ): void {
    const obj = objects[name];
    if (!obj) return;
    const fi = Math.max(0, Math.min(frame | 0, obj.frames.length - 1));
    const f = obj.frames[fi];
    const tinted = this.tintedFrame(name, fi, rgb);
    if (!f || !tinted) return;

    const rot = opts.rot ?? 0;
    const sx = (opts.scale ?? 1) * (opts.xflip ? -1 : 1);
    const sy = opts.scaleY ?? opts.scale ?? 1;
    ctx.save();
    if (opts.alpha !== undefined && opts.alpha !== 1) ctx.globalAlpha *= opts.alpha;
    ctx.translate(x, y);
    if (rot) ctx.rotate((rot * Math.PI) / 180);
    if (sx !== 1 || sy !== 1) ctx.scale(sx, sy);
    ctx.drawImage(tinted, 0, 0, f.w, f.h, f.ox, f.oy, f.w, f.h);
    ctx.restore();
  }

  /** Raw source rect access (tint cache, golden tests). */
  frame(name: string, frame: number): AtlasFrame | undefined {
    return objects[name]?.frames[frame];
  }

  page(i: number): HTMLImageElement | undefined {
    return this.pages[i];
  }
}
