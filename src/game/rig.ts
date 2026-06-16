// Skeletal rig playback for player/ref/keeper, mirroring AnimHierarchy.as.
// rigs.json: per timeline frame, per part {part, clip, x, y, r, sc}.
// labels.json: frame labels per clip; anim ranges are "<name>"/"<name>_end"
// (GameObj_Base.SetAnimRange).
import rigsJson from '../data/rigs.json';
import labelsJson from '../data/labels.json';
import type { Atlas } from '../render/atlas';

export interface RigPart {
  part: string;
  clip: string;
  x: number;
  y: number;
  r: number;
  sc: number;
}

type RigData = Record<string, RigPart[][]>;
type LabelData = Record<string, { frame: number; label: string }[]>;

const rigs = rigsJson as unknown as RigData;
const labels = labelsJson as unknown as LabelData;

export function rigFrameCount(rigName: string): number {
  return rigs[rigName]?.length ?? 0;
}

/** First frame with the label, optionally at or after `from` (kick anims repeat "release_ball"). */
export function labelFrame(clipName: string, label: string, from = 0): number {
  const list = labels[clipName];
  if (!list) return 0;
  return list.find((l) => l.label === label && l.frame >= from)?.frame ?? 0;
}

export function clipLabels(clipName: string): { frame: number; label: string }[] {
  return labels[clipName] ?? [];
}

/** Anim range "kick3" -> [start, end] frames via "<name>" and "<name>_end" labels. */
export function animRange(clipName: string, name: string): [number, number] {
  return [labelFrame(clipName, name), labelFrame(clipName, name + '_end')];
}

export interface RigPartOverride {
  /** per part name: hide, or swap frame index of the part's atlas clip */
  hidden?: Set<string>;
  frames?: Map<string, number>;
  /** per part name: substitute atlas object (kit style swaps) */
  clips?: Map<string, string>;
  /** per clip name: tinted offscreen image (kit colors) */
  images?: Map<string, CanvasImageSource>;
  /** per clip name: kit ColorTransform color for tint_* overlay parts */
  tints?: Map<string, [number, number, number]>;
  /** per part name: force the part's rotation (deg) instead of the frame's,
   *  matching AnimHierarchy.Frame_SetPartRot — used so the head tracks the ball.
   *  This value is the final part rotation; the rig's flip still mirrors it. */
  setRot?: Map<string, number>;
}

/**
 * Draw one rig frame with the rig origin at (x, y).
 * Parts render in array order (back to front), matching the FLA layering
 * captured at extraction time.
 */
export function drawRig(
  ctx: CanvasRenderingContext2D,
  atlas: Atlas,
  rigName: string,
  frame: number,
  x: number,
  y: number,
  opts: { scale?: number; xflip?: boolean; alpha?: number; override?: RigPartOverride } = {},
): void {
  const rig = rigs[rigName];
  if (!rig) return;
  const f = rig[Math.max(0, Math.min(frame | 0, rig.length - 1))];
  if (!f) return;
  const scale = opts.scale ?? 1;
  const flip = opts.xflip ? -1 : 1;

  for (const part of f) {
    if (opts.override?.hidden?.has(part.part)) continue;
    const clip = opts.override?.clips?.get(part.part) ?? part.clip;
    const frameIdx = opts.override?.frames?.get(part.part) ?? 0;
    const px = x + part.x * scale * flip;
    const py = y + part.y * scale;
    // a forced rotation (head-follow) replaces the frame rotation directly, as in
    // the AS3 Frame_SetPartRot path; otherwise apply the frame rotation * flip.
    const forced = opts.override?.setRot?.get(part.part);
    const drawOpts = {
      rot: forced !== undefined ? forced : part.r * flip,
      scale: part.sc * scale,
      xflip: opts.xflip,
      alpha: opts.alpha,
    };
    const tint = opts.override?.tints?.get(clip);
    if (tint) {
      atlas.drawTinted(ctx, clip, frameIdx, px, py, tint, drawOpts);
    } else {
      atlas.draw(ctx, clip, frameIdx, px, py, {
        ...drawOpts,
        image: opts.override?.images?.get(clip),
      });
    }
  }
}
