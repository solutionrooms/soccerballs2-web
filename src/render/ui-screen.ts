// Renders the original UI screens from the SWF display-list layouts
// (src/data/ui-layout.json) + the per-character art PNGs in assets/ui/.
// Buttons get hover/down art states and hit-testing by instance name.
import uiJson from '../data/ui-layout.json';

interface UiChild {
  charId: number;
  kind: string;
  name: string;
  x: number;
  y: number;
  scaleX: number;
  scaleY: number;
  rotDeg: number;
  text?: { html: string; fontHeightTwips: number; align: number; x: number; y: number; w: number; h: number };
}
interface UiScreenDef {
  frames: { label: string | null; children: UiChild[] }[];
}
interface ArtInfo {
  ox: number;
  oy: number;
  w: number;
  h: number;
}

const data = uiJson as unknown as {
  screens: Record<string, UiScreenDef>;
  art: Record<string, ArtInfo>;
};

function stripHtml(html: string): string {
  return html
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<[^>]+>/g, '')
    .trim();
}

function htmlColor(html: string): string {
  const m = html.match(/color="(#[0-9a-fA-F]{6})"/);
  return m ? m[1] : '#ffffff';
}

/**
 * fillText that survives the extracted Komika Axis TTF's zero-width space
 * glyph: words are laid out manually with a 0.32em gap.
 */
export function fillTextSafe(ctx: CanvasRenderingContext2D, text: string, x: number, y: number): void {
  if (!text.includes(' ')) {
    ctx.fillText(text, x, y);
    return;
  }
  const em = ctx.measureText('M').width;
  if (ctx.measureText(' ').width > em * 0.15) {
    ctx.fillText(text, x, y);
    return;
  }
  const gap = em * 0.32;
  const words = text.split(' ');
  const widths = words.map((w) => ctx.measureText(w).width);
  const total = widths.reduce((a, b) => a + b, 0) + gap * (words.length - 1);
  let sx = x;
  if (ctx.textAlign === 'center') sx = x - total / 2;
  else if (ctx.textAlign === 'right' || ctx.textAlign === 'end') sx = x - total;
  const prevAlign = ctx.textAlign;
  ctx.textAlign = 'left';
  for (let i = 0; i < words.length; i++) {
    ctx.fillText(words[i], sx, y);
    sx += widths[i] + gap;
  }
  ctx.textAlign = prevAlign;
}

function htmlSize(html: string, fallbackTwips: number): number {
  const m = html.match(/size="(\d+)"/);
  return m ? Number(m[1]) : fallbackTwips / 20;
}

export class UiScreens {
  private images = new Map<string, HTMLImageElement | null>();
  private baseUrl: string;

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl;
  }

  private img(name: string): HTMLImageElement | null {
    let img = this.images.get(name);
    if (img !== undefined) return img;
    img = new Image();
    img.src = `${this.baseUrl}${name}.png`;
    img.onerror = () => this.images.set(name, null);
    this.images.set(name, img);
    return img;
  }

  screen(name: string): UiScreenDef | undefined {
    return data.screens[name];
  }

  /**
   * Draw one screen frame. `hidden` filters children by instance name;
   * `textOverrides` replaces TextField content; `hover`/`down` pick button art
   * states for the named child.
   */
  draw(
    ctx: CanvasRenderingContext2D,
    screenName: string,
    frame: number,
    opts: {
      hidden?: Set<string>;
      textOverrides?: Record<string, string>;
      hover?: string | null;
      down?: string | null;
      offsetX?: number;
      offsetY?: number;
      scale?: number;
      /** canvas filter applied to the whole screen draw (e.g. grayscale) */
      filter?: string;
      /** force centre alignment for these named TextFields */
      centerTexts?: Set<string>;
      /** hide children by character id (for unnamed placeholder sprites) */
      hiddenCharIds?: Set<number>;
    } = {},
  ): void {
    const screen = data.screens[screenName];
    const fi = frame < 0 ? (screen?.frames.length ?? 1) - 1 : Math.min(frame, (screen?.frames.length ?? 1) - 1);
    const f = screen?.frames[fi];
    if (!f) return;
    const offX = opts.offsetX ?? 0;
    const offY = opts.offsetY ?? 0;
    ctx.save();
    if (opts.scale && opts.scale !== 1) {
      ctx.translate(offX, offY);
      ctx.scale(opts.scale, opts.scale);
      ctx.translate(-offX, -offY);
    }
    if (opts.filter) ctx.filter = opts.filter;

    for (const child of f.children) {
      if (child.name && opts.hidden?.has(child.name)) continue;
      if (opts.hiddenCharIds?.has(child.charId)) continue;

      if (child.kind === 'text' && child.text) {
        const override = child.name ? opts.textOverrides?.[child.name] : undefined;
        const content = override ?? stripHtml(child.text.html);
        if (!content) continue;
        const size = htmlSize(child.text.html, child.text.fontHeightTwips) * child.scaleY;
        ctx.save();
        ctx.font = `${size}px "Komika Axis", sans-serif`;
        ctx.fillStyle = htmlColor(child.text.html);
        ctx.textBaseline = 'top';
        const tx = child.x + child.text.x * child.scaleX + offX;
        const ty = child.y + child.text.y * child.scaleY + offY;
        const tw = child.text.w * child.scaleX;
        // align: 0=left 1=right 2=center
        const align = child.name && opts.centerTexts?.has(child.name) ? 2 : child.text.align;
        ctx.textAlign = align === 2 ? 'center' : align === 1 ? 'right' : 'left';
        const ax = align === 2 ? tx + tw / 2 : align === 1 ? tx + tw : tx;
        content.split('\n').forEach((line, i) => {
          fillTextSafe(ctx, line, ax, ty + 2 + i * size * 1.15);
        });
        ctx.restore();
        continue;
      }

      const art = data.art[String(child.charId)];
      if (!art) continue;
      let imgName = String(child.charId);
      if (child.kind === 'button' && child.name) {
        if (opts.down === child.name) imgName = `${child.charId}_down`;
        else if (opts.hover === child.name) imgName = `${child.charId}_over`;
      }
      let image = this.img(imgName);
      if ((!image || !image.complete || !image.naturalWidth) && imgName !== String(child.charId)) {
        image = this.img(String(child.charId));
      }
      if (!image || !image.complete || !image.naturalWidth) continue;

      ctx.save();
      ctx.translate(child.x + offX, child.y + offY);
      if (child.rotDeg) ctx.rotate((child.rotDeg * Math.PI) / 180);
      ctx.scale(child.scaleX, child.scaleY);
      ctx.drawImage(image, art.ox, art.oy, art.w, art.h);
      ctx.restore();
    }
    ctx.restore();
  }

  /** topmost named child whose bounds contain the stage point */
  hitTest(screenName: string, frame: number, x: number, y: number, names?: Set<string>): string | null {
    const screen = data.screens[screenName];
    const fi = frame < 0 ? (screen?.frames.length ?? 1) - 1 : Math.min(frame, (screen?.frames.length ?? 1) - 1);
    const f = screen?.frames[fi];
    if (!f) return null;
    for (let i = f.children.length - 1; i >= 0; i--) {
      const child = f.children[i];
      if (!child.name) continue;
      if (names && !names.has(child.name)) continue;
      const art = data.art[String(child.charId)];
      let x0: number;
      let y0: number;
      let w: number;
      let h: number;
      if (child.kind === 'text' && child.text) {
        x0 = child.x + child.text.x * child.scaleX;
        y0 = child.y + child.text.y * child.scaleY;
        w = child.text.w * child.scaleX;
        h = child.text.h * child.scaleY;
      } else if (art) {
        x0 = child.x + art.ox * child.scaleX;
        y0 = child.y + art.oy * child.scaleY;
        w = art.w * child.scaleX;
        h = art.h * child.scaleY;
      } else {
        continue;
      }
      if (x >= x0 && x <= x0 + w && y >= y0 && y <= y0 + h) return child.name;
    }
    return null;
  }
}
