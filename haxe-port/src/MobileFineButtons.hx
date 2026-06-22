import flash.display.Stage;

/**
 * Mobile control scheme D add-on — four on-screen arrow buttons in the letterbox dead-space, on the
 * OPPOSITE side to the aim-pad joystick (scheme C). They drive the SAME kick-aim fine-tune as the
 * desktop arrow keys (Game.aimFineX/Y via Game.UpdateAimFine): one point per tap, hold to accelerate.
 *
 * Scheme D = the aim-pad (coarse aim, one margin) + these fine buttons (precise aim, the other margin).
 * Like MobileAimPad these are DOM elements (position:fixed) placed in the margin OUTSIDE the 700x525
 * canvas. A tight D-pad cluster, clamped fully on-screen, with the long-press "pick up" (iOS callout /
 * native drag / text selection) suppressed so holding a button just fine-tunes.
 */
class MobileFineButtons
{
    static var stageRef : Stage;
    static var wrap : Dynamic = null;

    static inline var BTN : Float = 52;      // button size (px) — compact
    static inline var GAP : Float = 2;       // small gap between buttons (tight D-pad)

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
            var step = BTN + GAP;
            wrap = doc.createElement("div");
            styleEl(wrap, "position:fixed; z-index:99999; display:none; touch-action:none;"
                + " -webkit-touch-callout:none; -webkit-user-select:none; user-select:none;"
                + " width:" + span + "px; height:" + span + "px;");

            mkBtn(doc, "▲", step,        0,          function(v) downU = v); // up
            mkBtn(doc, "▼", step,        step * 2,   function(v) downD = v); // down
            mkBtn(doc, "◀", 0,           step,       function(v) downL = v); // left
            mkBtn(doc, "▶", step * 2,    step,       function(v) downR = v); // right

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
            + " border-radius:12px; background:rgba(255,255,255,0.12); border:3px solid rgba(255,255,255,0.5);"
            + " box-sizing:border-box; touch-action:none; display:flex; align-items:center; justify-content:center;"
            + " color:rgba(255,255,255,0.85); font-size:26px; line-height:1;"
            // suppress the long-press "pick up": no text selection, no iOS callout, no native drag
            + " user-select:none; -webkit-user-select:none; -webkit-touch-callout:none; -webkit-user-drag:none;");
        b.innerHTML = glyph;
        var down = function(e : Dynamic) { set(true);  hi(b, true);  try { e.preventDefault(); e.stopPropagation(); } catch (er : Dynamic) {} };
        var up   = function(e : Dynamic) { set(false); hi(b, false); try { e.stopPropagation(); } catch (er : Dynamic) {} };
        var block = function(e : Dynamic) { try { e.preventDefault(); } catch (er : Dynamic) {} };
        untyped b.addEventListener("pointerdown", down, { passive: false });
        untyped b.addEventListener("pointerup", up);
        untyped b.addEventListener("pointercancel", up);
        untyped b.addEventListener("pointerleave", up);
        // kill the things that "pick up" the button on a long hold
        untyped b.addEventListener("contextmenu", block);
        untyped b.addEventListener("dragstart", block);
        untyped b.addEventListener("selectstart", block);
        untyped b.addEventListener("touchstart", block, { passive: false });
        wrap.appendChild(b);
        #end
    }

    static function hi(b : Dynamic, on : Bool) : Void
    {
        try { b.style.background = on ? "rgba(255,255,255,0.32)" : "rgba(255,255,255,0.12)"; } catch (e : Dynamic) {}
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

    // Place the cluster OPPOSITE the aim-pad and always fully on-screen: landscape -> LEFT side
    // (in the left margin if it fits, else hugging the edge), portrait -> TOP margin. Clamped to the
    // viewport so no arrow can fall off the screen.
    static function position() : Void
    {
        #if (js && html5)
        try
        {
            var win = js.Browser.window;
            var c : Dynamic = js.Browser.document.querySelector("canvas");
            if (c == null) return;
            var r = c.getBoundingClientRect();
            var iw : Float = win.innerWidth;
            var ih : Float = win.innerHeight;
            var span : Float = BTN * 3 + GAP * 2;

            var left : Float;
            var top : Float;
            if (iw >= ih)
            {
                // landscape: aim-pad on the right -> arrows on the LEFT, vertically centred
                var leftMargin : Float = r.left;
                left = (leftMargin >= span + 12) ? (leftMargin - span) / 2 : 8;
                top = ih / 2 - span / 2;
            }
            else
            {
                // portrait: aim-pad at the bottom -> arrows in the TOP margin, horizontally centred
                var topMargin : Float = r.top;
                top = (topMargin >= span + 12) ? (topMargin - span) / 2 : 8;
                left = iw / 2 - span / 2;
            }

            // clamp fully on-screen
            if (left < 6) left = 6;
            if (left + span > iw - 6) left = iw - span - 6;
            if (top < 6) top = 6;
            if (top + span > ih - 6) top = ih - span - 6;

            wrap.style.left = left + "px";
            wrap.style.top = top + "px";
        }
        catch (e : Dynamic) {}
        #end
    }
}
