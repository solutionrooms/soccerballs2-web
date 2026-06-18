import flash.display.Stage;

/**
 * Mobile control scheme C — "Aim Pad" (web port only; not in the original AS3 game).
 *
 * A VISIBLE on-screen joystick placed in the letterbox dead-space (the black bars: bottom in portrait,
 * right in landscape) — so your thumb is off the ball and the trajectory arc stays visible. Like scheme
 * B it only swaps the INPUT SOURCE, never the kick physics: the joystick deflection sets a virtual cursor
 * offset from the ball (direction = aim, magnitude = power through the kick curve) written into
 * Game.mouse_x/y; a tap on the play field fires (Game.doKick). Game.hx suppresses the normal click-kick
 * while scheme C is selected.
 *
 *   - Drag the joystick: aim. Release: the aim LATCHES (persists until you re-aim or kick).
 *   - Hold a SECOND finger on the play field while moving the joystick: FINE mode — the aim nudges at
 *     1/4 speed for precise adjustment (the 2nd finger does NOT fire).
 *   - Tap the play field (no 2nd finger): fire the kick with the current aim.
 *
 * The joystick is a real DOM element with its own pointer handlers — reliable on iOS Safari and outside
 * the 700x525 canvas, in the dead-space the user asked for.
 */
class MobileAimPad
{
    static var stageRef : Stage;

    // deflection in [-1,1] (latches on release so the aim persists)
    static var defX : Float = 0;
    static var defY : Float = 0;
    static var reach : Float = 300;           // world px at full deflection = kick_dist1 (full power)
    static inline var FINE : Float = 0.25;    // 2nd-finger fine sensitivity
    static inline var TAP_MOVE : Float = 14;  // px movement under which a play-field press is a tap
    static inline var HUD_H : Float = 60;     // bottom HUD bar height excluded from tap-to-fire

    // DOM joystick
    static var base : Dynamic = null;
    static var thumb : Dynamic = null;
    static inline var R : Float = 70;         // joystick radius (px)
    static var joyId : Int = -999;            // pointerId dragging the joystick
    static var cx : Float = 0;                // joystick centre in client px (re-anchored after fine)
    static var cy : Float = 0;
    static var joyClientX : Float = 0;        // last client pos of the joystick finger (for fine deltas)
    static var joyClientY : Float = 0;

    // fine modifier (a 2nd finger held on the play field while the joystick is held)
    static var fineActive : Bool = false;
    static var fineId : Int = -999;

    // total active pointers (joystick + play-field). A fire-tap is only valid when it is the SOLE
    // pointer down — so a 2nd finger can never fire even if the joystick pointer tracking hiccups.
    static var activeCount : Int = 0;

    // play-field tap (fire)
    static var tapId : Int = -999;
    static var tapX : Float = 0;
    static var tapY : Float = 0;
    static var tapMoved : Float = 0;
    static var tapStageY : Float = 0;

    public static function Init(stage : Stage) : Void
    {
        #if (js && html5)
        if (stage == null) return;
        stageRef = stage;
        try
        {
            var doc = js.Browser.document;

            base = doc.createElement("div");
            styleEl(base, "position:fixed; width:" + (R * 2) + "px; height:" + (R * 2) + "px; border-radius:50%;"
                + " background:rgba(255,255,255,0.10); border:3px solid rgba(255,255,255,0.5);"
                + " touch-action:none; z-index:99999; display:none; box-sizing:border-box;");
            thumb = doc.createElement("div");
            styleEl(thumb, "position:absolute; width:" + (R * 0.86) + "px; height:" + (R * 0.86) + "px;"
                + " border-radius:50%; background:rgba(255,255,255,0.38); left:" + (R - R * 0.43) + "px;"
                + " top:" + (R - R * 0.43) + "px; pointer-events:none;");
            base.appendChild(thumb);
            doc.body.appendChild(base);

            untyped base.addEventListener("pointerdown", onJoyDown);
            untyped base.addEventListener("pointermove", onJoyMove, { passive: false });
            untyped base.addEventListener("pointerup", onJoyUp);
            untyped base.addEventListener("pointercancel", onJoyUp);

            untyped doc.addEventListener("pointerdown", onTapDown);
            untyped doc.addEventListener("pointermove", onTapMove);
            untyped doc.addEventListener("pointerup", onTapUp);
            untyped doc.addEventListener("pointercancel", onTapUp);

            var c : Dynamic = doc.querySelector("canvas");
            if (c != null) c.style.touchAction = "none";
        }
        catch (e : Dynamic) {}
        #end
    }

    static function styleEl(el : Dynamic, css : String) : Void { try { el.setAttribute("style", css); } catch (e : Dynamic) {} }

    public static function IsActive() : Bool
    {
        if (Settings.mobileControlScheme != Settings.SCHEME_C) return false;
        if (OptionsScreen.open) return false;
        try
        {
            if (Game.gameState != Game.gameState_Play) return false;
            if (PauseMenu.IsPaused()) return false;
        }
        catch (e : Dynamic) { return false; }
        return true;
    }

    // ---- joystick (aim) -------------------------------------------------------------------------

    static function joyCentre() : Void
    {
        #if (js && html5)
        try { var r = base.getBoundingClientRect(); cx = r.left + R; cy = r.top + R; } catch (e : Dynamic) {}
        #end
    }

    static function onJoyDown(e : Dynamic) : Void
    {
        if (!IsActive()) return;
        if (joyId != -999) { try { e.stopPropagation(); } catch (er : Dynamic) {} return; } // ignore extra fingers on the stick
        activeCount++;
        joyId = e.pointerId;
        // capture the pointer so dragging off the small joystick still tracks (and joyId stays reliable,
        // so a 2nd finger is read as fine, not a fire-tap)
        try { base.setPointerCapture(e.pointerId); } catch (er : Dynamic) {}
        joyCentre();
        joyClientX = e.clientX; joyClientY = e.clientY;
        setAbsolute(e.clientX, e.clientY);
        try { e.preventDefault(); e.stopPropagation(); } catch (er : Dynamic) {}
    }

    static function onJoyMove(e : Dynamic) : Void
    {
        if (joyId == -999 || e.pointerId != joyId) return;
        if (fineActive)
        {
            // nudge the aim by the joystick-finger delta at 1/4 speed (precise adjustment)
            var sm = sensMult();
            defX += (e.clientX - joyClientX) / R * FINE * sm;
            defY += (e.clientY - joyClientY) / R * FINE * sm;
            clampDef();
            updateThumb();
        }
        else
        {
            setAbsolute(e.clientX, e.clientY);
        }
        joyClientX = e.clientX; joyClientY = e.clientY;
        try { e.preventDefault(); e.stopPropagation(); } catch (er : Dynamic) {}
    }

    static function onJoyUp(e : Dynamic) : Void
    {
        if (e.pointerId != joyId) return;
        activeCount = (activeCount > 0) ? activeCount - 1 : 0;
        try { base.releasePointerCapture(e.pointerId); } catch (er : Dynamic) {}
        joyId = -999; // latch deflection (do not recentre) so the aim persists for tap-to-fire
        try { e.stopPropagation(); } catch (er : Dynamic) {}
    }

    // Low/Med/High sensitivity: lower = the stick needs more travel for the same aim (finer).
    static function sensMult() : Float
    {
        return switch (Settings.aimSensitivity) { case 0: 0.5; case 2: 1.0; default: 0.7; };
    }

    static function setAbsolute(clientX : Float, clientY : Float) : Void
    {
        var sm = sensMult();
        var dx = (clientX - cx) / R * sm;
        var dy = (clientY - cy) / R * sm;
        var m = Math.sqrt(dx * dx + dy * dy);
        if (m > 1) { dx /= m; dy /= m; }
        defX = dx;
        defY = dy;
        updateThumb();
    }

    static function clampDef() : Void
    {
        var m = Math.sqrt(defX * defX + defY * defY);
        if (m > 1) { defX /= m; defY /= m; }
    }

    static function updateThumb() : Void
    {
        #if (js && html5)
        if (thumb != null) { thumb.style.left = (R - R * 0.43 + defX * R) + "px"; thumb.style.top = (R - R * 0.43 + defY * R) + "px"; }
        #end
    }

    // ---- play-field: 2nd finger = fine modifier, a tap = fire -----------------------------------

    static function onTapDown(e : Dynamic) : Void
    {
        if (!IsActive()) return;
        var hadCompany = activeCount > 0; // something else already down -> this can't be a clean solo tap
        activeCount++;
        // a finger landing on the play field WHILE the joystick is held = fine modifier (not a fire tap)
        if (joyId != -999 && !fineActive && e.pointerId != joyId)
        {
            fineActive = true; fineId = e.pointerId;
            return;
        }
        // only a SOLE pointer can become a fire-tap candidate
        if (hadCompany || tapId != -999) return;
        tapId = e.pointerId; tapX = e.clientX; tapY = e.clientY; tapMoved = 0;
        tapStageY = clientToStageY(e.clientY);
    }

    static function onTapMove(e : Dynamic) : Void
    {
        if (e.pointerId != tapId) return;
        var ddx = e.clientX - tapX; var ddy = e.clientY - tapY;
        tapX = e.clientX; tapY = e.clientY;
        tapMoved += Math.sqrt(ddx * ddx + ddy * ddy);
    }

    static function onTapUp(e : Dynamic) : Void
    {
        activeCount = (activeCount > 0) ? activeCount - 1 : 0;
        if (e.pointerId == fineId)
        {
            fineActive = false; fineId = -999;
            // re-anchor the absolute centre so the joystick doesn't jump on the next plain move
            cx = joyClientX - defX * R; cy = joyClientY - defY * R;
            return;
        }
        if (e.pointerId != tapId) return;
        if (IsActive() && tapMoved < TAP_MOVE && tapStageY > 0 && tapStageY < (Defs.displayarea_h - HUD_H))
        {
            Game.doKick = true;
        }
        tapId = -999;
    }

    static function clientToStageY(clientY : Float) : Float
    {
        #if (js && html5)
        try
        {
            var c : Dynamic = js.Browser.document.querySelector("canvas");
            if (c != null) { var r = c.getBoundingClientRect(); if (r.height > 0) return (clientY - r.top) / r.height * Defs.displayarea_h; }
        }
        catch (e : Dynamic) {}
        #end
        return -1;
    }

    /** Feed the virtual cursor into Game.mouse_x/y BEFORE the per-frame update (mirrors scheme B). */
    public static function UpdateAim() : Void
    {
        if (!IsActive()) return;
        var ball : Dynamic = GameVars.footballGO;
        if (ball == null) return;
        try { var k = Vars.GetVarAsNumber("kick_dist1"); if (!Math.isNaN(k) && k > 0) reach = k; } catch (e : Dynamic) {}
        Game.mouse_x = (ball.xpos + defX * reach) - Game.camera.x;
        Game.mouse_y = (ball.ypos + defY * reach) - Game.camera.y;
    }

    public static function ResetAim() : Void
    {
        defX = 0; defY = 0;
        updateThumb();
    }

    // Screen-space (display-area px) position of the virtual aim cursor — the analogue of the desktop
    // mouse position, so the camera can scroll TOWARD the aim (see further the way you're shooting).
    // centre + deflection*reach, matching how UpdateAim places the world cursor at ball + defX*reach.
    public static function ScrollCursorX() : Float { return Defs.displayarea_w2 + defX * reach; }
    public static function ScrollCursorY() : Float { return Defs.displayarea_h2 + defY * reach; }

    public static function Tick() : Void
    {
        #if (js && html5)
        if (base != null)
        {
            var on = IsActive();
            base.style.display = on ? "block" : "none";
            if (on) positionJoystick();
        }
        #end
        // NOTE: the aim is intentionally LATCHED — it persists after you release the joystick (and across
        // shots) until you move the stick again, so you can deflect-then-tap. (No per-frame auto-reset.)
    }

    // place the joystick in the letterbox dead-space: bottom-centre (portrait) or right-centre (landscape)
    static function positionJoystick() : Void
    {
        #if (js && html5)
        try
        {
            var win = js.Browser.window;
            var c : Dynamic = js.Browser.document.querySelector("canvas");
            if (c == null) return;
            var r = c.getBoundingClientRect();
            var bottomGap = win.innerHeight - r.bottom;
            var rightGap = win.innerWidth - r.right;
            if (bottomGap >= rightGap && bottomGap > R)
            {
                base.style.left = (win.innerWidth / 2 - R) + "px";
                base.style.top = (r.bottom + (bottomGap - R * 2) / 2) + "px";
            }
            else
            {
                base.style.left = (r.right + (rightGap - R * 2) / 2) + "px";
                base.style.top = (win.innerHeight / 2 - R) + "px";
            }
        }
        catch (e : Dynamic) {}
        #end
    }
}
