import flash.display.Sprite;
import flash.display.Stage;
import flash.events.MouseEvent;

/**
 * Mobile control scheme B (web port only — not part of the original AS3 game).
 *
 * Faithful by construction: the original kick derives BOTH aim direction and power purely from
 * Game.mouse_x/y (GameObj: dx = worldMouse - ball, power = that distance through the kick curve).
 * So this scheme changes only the INPUT SOURCE — it never touches the kick physics:
 *   - a virtual joystick sets a "virtual cursor": stick deflection direction = kick direction,
 *     deflection magnitude = reach = power (mapped onto the game's kick_dist range);
 *   - a tap near the ball fires Game.doKick.
 *
 * Scheme A (Settings.SCHEME_A) leaves the existing pointer behaviour untouched.
 *
 * NOTE (v1): the OpenFL stage is a fixed 700x525 that the browser CSS-letterboxes, so the joystick
 * is drawn as a translucent overlay ON the play field (bottom in portrait, right in landscape, per
 * the browser window aspect) rather than in the letterbox margin. Moving it into the true margin
 * would need a DOM overlay or a window-filling canvas — a follow-up.
 */
class MobileControls
{
    static var stageRef : Stage;
    static var joy : Sprite;        // joystick base + thumb overlay
    static var thumb : Sprite;

    // joystick geometry in 700x525 stage space
    static var baseX : Float = 600;
    static var baseY : Float = 262;
    static inline var RADIUS : Float = 64;

    // current deflection in [-1,1] (non-self-centering: latches until re-aimed or a kick fires)
    static var defX : Float = 0;
    static var defY : Float = 0;

    static var dragging : Bool = false;

    // tap tracking (a tap = short, low-movement press that isn't on the joystick)
    static var downX : Float = 0;
    static var downY : Float = 0;
    static var downT : Float = 0;
    static var downWasTap : Bool = false;

    public static function Init(stage : Stage) : Void
    {
        if (stage == null) return;
        stageRef = stage;

        joy = new Sprite();
        joy.mouseEnabled = false;
        joy.mouseChildren = false;
        joy.visible = false;

        var g = joy.graphics;
        g.lineStyle(3, 0xFFFFFF, 0.45);
        g.beginFill(0xFFFFFF, 0.08);
        g.drawCircle(0, 0, RADIUS);
        g.endFill();

        thumb = new Sprite();
        thumb.mouseEnabled = false;
        var tg = thumb.graphics;
        tg.beginFill(0xFFFFFF, 0.35);
        tg.drawCircle(0, 0, RADIUS * 0.42);
        tg.endFill();
        joy.addChild(thumb);

        stage.addChild(joy);

        stage.addEventListener(MouseEvent.MOUSE_DOWN, onDown);
        stage.addEventListener(MouseEvent.MOUSE_MOVE, onMove);
        stage.addEventListener(MouseEvent.MOUSE_UP, onUp);
    }

    // Active when scheme B is selected and we're in live (unpaused) gameplay, options closed.
    public static function IsActive() : Bool
    {
        if (Settings.mobileControlScheme != Settings.SCHEME_B) return false;
        if (OptionsScreen.open) return false;
        try
        {
            if (Game.gameState != Game.gameState_Play) return false;
            if (PauseMenu.IsPaused()) return false;
        }
        catch (e : Dynamic) { return false; }
        return true;
    }

    static function inJoystick(x : Float, y : Float) : Bool
    {
        var dx = x - baseX;
        var dy = y - baseY;
        return (dx * dx + dy * dy) <= (RADIUS * 1.35) * (RADIUS * 1.35);
    }

    static function onDown(e : MouseEvent) : Void
    {
        if (!IsActive()) return;
        if (inJoystick(e.stageX, e.stageY))
        {
            dragging = true;
            downWasTap = false;
            updateDeflection(e.stageX, e.stageY);
        }
        else
        {
            // candidate tap (kick) — confirmed on release if it stayed put
            downWasTap = true;
            downX = e.stageX;
            downY = e.stageY;
            downT = haxe.Timer.stamp();
        }
    }

    static function onMove(e : MouseEvent) : Void
    {
        if (!IsActive()) return;
        if (dragging) updateDeflection(e.stageX, e.stageY);
        else if (downWasTap)
        {
            var dx = e.stageX - downX;
            var dy = e.stageY - downY;
            if ((dx * dx + dy * dy) > 24 * 24) downWasTap = false; // moved too far to be a tap
        }
    }

    static function onUp(e : MouseEvent) : Void
    {
        if (dragging)
        {
            dragging = false; // latch deflection (do not recentre) so the aim persists
            return;
        }
        if (!IsActive()) return;
        if (downWasTap && (haxe.Timer.stamp() - downT) < 0.6)
        {
            if (nearBall(e.stageX, e.stageY)) Game.doKick = true;
        }
        downWasTap = false;
    }

    static function updateDeflection(x : Float, y : Float) : Void
    {
        var dx = (x - baseX) / RADIUS;
        var dy = (y - baseY) / RADIUS;
        var m = Math.sqrt(dx * dx + dy * dy);
        if (m > 1) { dx /= m; dy /= m; }
        defX = dx;
        defY = dy;
    }

    static function nearBall(x : Float, y : Float) : Bool
    {
        var ball : Dynamic = GameVars.footballGO;
        if (ball == null) return false;
        var bx : Float = ball.xpos - Game.camera.x;
        var by : Float = ball.ypos - Game.camera.y;
        var dx = x - bx;
        var dy = y - by;
        return (dx * dx + dy * dy) <= 130 * 130;
    }

    /**
     * Feed the joystick deflection into Game.mouse_x/y as a virtual cursor. Call BEFORE the per-frame
     * game update so the aiming code (and trajectory preview) read it. Direction = stick direction,
     * distance from the ball = deflection * reach (=> power through the kick curve).
     */
    public static function UpdateAim() : Void
    {
        if (!IsActive()) return;
        var ball : Dynamic = GameVars.footballGO;
        if (ball == null) return;

        var reach : Float = 120;
        try { var k = Vars.GetVarAsNumber("kick_dist1"); if (!Math.isNaN(k) && k > 0) reach = k; } catch (e : Dynamic) {}

        var worldX : Float = ball.xpos + defX * reach;
        var worldY : Float = ball.ypos + defY * reach;
        Game.mouse_x = worldX - Game.camera.x;
        Game.mouse_y = worldY - Game.camera.y;
    }

    // Called when a kick fires so the next aim starts from centre.
    public static function ResetAim() : Void
    {
        defX = 0;
        defY = 0;
    }

    /** Position/show the joystick overlay each frame. */
    public static function Tick() : Void
    {
        if (joy == null) return;
        var on = IsActive();
        joy.visible = on;
        if (!on) return;

        Reposition();
        joy.x = baseX;
        joy.y = baseY;
        thumb.x = defX * RADIUS;
        thumb.y = defY * RADIUS;

        if (stageRef != null)
        {
            try { if (joy.parent == stageRef) stageRef.setChildIndex(joy, stageRef.numChildren - 1); } catch (e : Dynamic) {}
        }
    }

    // place the joystick: portrait -> bottom-centre, landscape -> right-centre (within 700x525)
    static function Reposition() : Void
    {
        var portrait : Bool = false;
        try
        {
            var w : Float = js.Browser.window.innerWidth;
            var h : Float = js.Browser.window.innerHeight;
            portrait = h > w;
        }
        catch (e : Dynamic) {}

        if (portrait)
        {
            baseX = Defs.displayarea_w / 2;
            baseY = Defs.displayarea_h - (RADIUS + 16);
        }
        else
        {
            baseX = Defs.displayarea_w - (RADIUS + 16);
            baseY = Defs.displayarea_h / 2;
        }
    }
}
