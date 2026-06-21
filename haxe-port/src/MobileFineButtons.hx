import flash.display.Stage;

/**
 * Mobile control scheme D add-on — four on-screen arrow buttons in the letterbox dead-space, on the
 * OPPOSITE side to the aim-pad joystick (scheme C). They drive the SAME kick-aim fine-tune as the
 * desktop arrow keys (Game.aimFineX/Y via Game.UpdateAimFine): one point per tap, hold to accelerate.
 *
 * Scheme D = the aim-pad (coarse aim, one margin) + these fine buttons (precise aim, the other margin).
 * Like MobileAimPad these are DOM elements (position:fixed) placed in the margin OUTSIDE the 700x525
 * canvas, so they never overlap the play field and can't trip the aim-pad's tap-to-fire.
 */
class MobileFineButtons
{
    static var stageRef : Stage;
    static var wrap : Dynamic = null;

    static inline var BTN : Float = 62;      // button size (px)
    static inline var GAP : Float = 6;       // gap between buttons

    // held state — read by Game.UpdateAimFine alongside the physical arrow keys
    static var downU : Bool = false;
    static var downD : Bool = false;
    static var downL : Bool = false;
    static var downR : Bool = false;

    public static function LeftDown()  : Bool { return downL; }
    public static function RightDown() : Bool { return downR; }
    public static function UpDown()    : Bool { return downU; }
    public static function DownDown()  : Bool { return downD; }

    public static function IsActive() : Bool
    {
        if (Settings.mobileControlScheme != Settings.SCHEME_D) return false;
        if (OptionsScreen.open) return false;
        try
        {
            if (Game.gameState != Game.gameState_Play) return false;
            if (PauseMenu.IsPaused()) return false;
        }
        catch (e : Dynamic) { return false; }
        return true;
    }

    public static function Init(stage : Stage) : Void
    {
        #if (js && html5)
        if (stage == null) return;
        stageRef = stage;
        try
        {
            var doc = js.Browser.document;
            var span = BTN * 3 + GAP * 2;
            wrap = doc.createElement("div");
            styleEl(wrap, "position:fixed; z-index:99999; display:none; touch-action:none;"
                + " width:" + span + "px; height:" + span + "px;");

            mkBtn(doc, "▲", BTN + GAP,        0,             function(v) downU = v); // up
            mkBtn(doc, "▼", BTN + GAP,        (BTN + GAP) * 2, function(v) downD = v); // down
            mkBtn(doc, "◀", 0,                BTN + GAP,      function(v) downL = v); // left
            mkBtn(doc, "▶", (BTN + GAP) * 2,  BTN + GAP,      function(v) downR = v); // right

            doc.body.appendChild(wrap);
        }
        catch (e : Dynamic) {}
        #end
    }

    static function mkBtn(doc : Dynamic, glyph : String, x : Float, y : Float, set : Bool -> Void) : Void
    {
        #if (js && html5)
        var b : Dynamic = doc.createElement("div");
        styleEl(b, "position:absolute; left:" + x + "px; top:" + y + "px; width:" + BTN + "px; height:" + BTN + "px;"
            + " border-radius:14px; background:rgba(255,255,255,0.12); border:3px solid rgba(255,255,255,0.5);"
            + " box-sizing:border-box; touch-action:none; display:flex; align-items:center; justify-content:center;"
            + " color:rgba(255,255,255,0.85); font-size:30px; line-height:1; user-select:none; -webkit-user-select:none;");
        b.innerHTML = glyph;
        var down = function(e : Dynamic) { set(true);  hi(b, true);  try { e.preventDefault(); e.stopPropagation(); } catch (er : Dynamic) {} };
        var up   = function(e : Dynamic) { set(false); hi(b, false); try { e.stopPropagation(); } catch (er : Dynamic) {} };
        untyped b.addEventListener("pointerdown", down, { passive: false });
        untyped b.addEventListener("pointerup", up);
        untyped b.addEventListener("pointercancel", up);
        untyped b.addEventListener("pointerleave", up);
        wrap.appendChild(b);
        #end
    }

    static function hi(b : Dynamic, on : Bool) : Void
    {
        try { b.style.background = on ? "rgba(255,255,255,0.30)" : "rgba(255,255,255,0.12)"; } catch (e : Dynamic) {}
    }

    static function styleEl(el : Dynamic, css : String) : Void { try { el.setAttribute("style", css); } catch (e : Dynamic) {} }

    public static function Tick() : Void
    {
        #if (js && html5)
        if (wrap == null) return;
        var on = IsActive();
        wrap.style.display = on ? "block" : "none";
        if (!on) { downU = downD = downL = downR = false; return; }
        position();
        #end
    }

    // place the cluster in the dead-space OPPOSITE the aim-pad (which goes bottom in portrait / right
    // in landscape): aim-pad bottom -> buttons in the TOP gap; aim-pad right -> buttons in the LEFT gap.
    static function position() : Void
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
            var span = BTN * 3 + GAP * 2;
            if (bottomGap >= rightGap && bottomGap > 70)
            {
                // aim-pad is bottom -> arrows in the TOP margin, centred horizontally
                wrap.style.left = (win.innerWidth / 2 - span / 2) + "px";
                wrap.style.top  = Math.max(2, (r.top - span) / 2) + "px";
            }
            else
            {
                // aim-pad is right -> arrows in the LEFT margin, centred vertically
                wrap.style.left = Math.max(2, (r.left - span) / 2) + "px";
                wrap.style.top  = (win.innerHeight / 2 - span / 2) + "px";
            }
        }
        catch (e : Dynamic) {}
        #end
    }
}
