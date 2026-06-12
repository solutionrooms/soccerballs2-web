// Mouse/touch + keyboard input, in stage (700x525) coordinates.
// Mirrors MouseControl.as: position, velocity, pressed/released edge flags.
import type { Renderer } from '../render/renderer';

export class InputManager {
  // stage-space pointer position
  x = 0;
  y = 0;
  dx = 0;
  dy = 0;
  buttonDown = false;
  /** went down this frame */
  buttonPressed = false;
  /** went up this frame */
  buttonReleased = false;
  /** true once any touch input has been seen (enables drag-to-aim kicking) */
  isTouch = false;
  /** pointer position in CSS pixels within the canvas (for screen-space UI like the aim pad) */
  screenX = 0;
  screenY = 0;

  private prevX = 0;
  private prevY = 0;
  private keysDown = new Set<string>();
  private keysPressed = new Set<string>();
  private renderer: Renderer;

  constructor(canvas: HTMLCanvasElement, renderer: Renderer) {
    this.renderer = renderer;

    // Pointer events only — they unify mouse, touch and pen. (Adding mousedown
    // or click on top double-fires on desktop, since one mouse click emits all
    // three.) Listen on window so a press anywhere registers.
    const press = (e: PointerEvent): void => {
      if (e.pointerType === 'touch') this.isTouch = true;
      this.updatePos(e);
      this.buttonDown = true;
      this.buttonPressed = true;
      try {
        canvas.setPointerCapture(e.pointerId);
      } catch {
        // synthetic/automation events may lack a capturable pointer
      }
    };
    window.addEventListener('pointerdown', press);
    window.addEventListener('pointermove', (e) => this.updatePos(e));
    const up = (e: PointerEvent): void => {
      this.updatePos(e);
      if (this.buttonDown) this.buttonReleased = true;
      this.buttonDown = false;
    };
    window.addEventListener('pointerup', up);
    window.addEventListener('pointercancel', up);

    window.addEventListener('keydown', (e) => {
      if (!this.keysDown.has(e.code)) this.keysPressed.add(e.code);
      this.keysDown.add(e.code);
    });
    window.addEventListener('keyup', (e) => this.keysDown.delete(e.code));
    window.addEventListener('blur', () => {
      this.keysDown.clear();
      this.buttonDown = false;
    });
  }

  private updatePos(e: PointerEvent | MouseEvent): void {
    const rect = this.renderer.canvas.getBoundingClientRect();
    this.screenX = e.clientX - rect.left;
    this.screenY = e.clientY - rect.top;
    const p = this.renderer.screenToStage(e.clientX, e.clientY);
    this.x = p.x;
    this.y = p.y;
  }

  keyDown(code: string): boolean {
    return this.keysDown.has(code);
  }

  keyPressed(code: string): boolean {
    return this.keysPressed.has(code);
  }

  /** call once per frame after update+render */
  endFrame(): void {
    this.dx = this.x - this.prevX;
    this.dy = this.y - this.prevY;
    this.prevX = this.x;
    this.prevY = this.y;
    this.buttonPressed = false;
    this.buttonReleased = false;
    this.keysPressed.clear();
  }

  resetTransient(): void {
    this.buttonPressed = false;
    this.buttonReleased = false;
    this.keysPressed.clear();
  }
}
