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

  private prevX = 0;
  private prevY = 0;
  private keysDown = new Set<string>();
  private keysPressed = new Set<string>();
  private renderer: Renderer;

  constructor(canvas: HTMLCanvasElement, renderer: Renderer) {
    this.renderer = renderer;

    // Listen on window (not just the canvas) so automation/synthetic events
    // and clicks dispatched at the document still register. A 'click' fallback
    // covers environments that don't deliver pointerdown to the canvas.
    const press = (e: PointerEvent | MouseEvent): void => {
      if ('pointerType' in e && e.pointerType === 'touch') this.isTouch = true;
      const p = this.renderer.screenToStage(e.clientX, e.clientY);
      this.x = p.x;
      this.y = p.y;
      this.buttonDown = true;
      this.buttonPressed = true;
    };
    window.addEventListener('pointerdown', (e) => {
      press(e);
      try {
        canvas.setPointerCapture(e.pointerId);
      } catch {
        // synthetic/automation events may lack a capturable pointer
      }
    });
    window.addEventListener('mousedown', press);
    window.addEventListener('click', (e) => {
      // only synthesize a press if pointerdown didn't already fire this gesture
      if (!this.buttonPressed) {
        press(e);
        this.buttonReleased = true;
        this.buttonDown = false;
      }
    });
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

  private updatePos(e: PointerEvent): void {
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
