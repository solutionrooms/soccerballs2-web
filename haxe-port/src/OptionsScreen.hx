import flash.display.Sprite;
import flash.display.Stage;
import flash.display.StageDisplayState;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFieldAutoSize;
import flash.events.MouseEvent;
import flash.events.Event;

/**
 * Utilitarian options overlay (web port only — not part of the original AS3 game).
 *
 * A code-drawn stage overlay: a context-aware gear button (shown on menus and when paused) opens
 * a centered panel with three toggles — performance HUD, open-all-levels (dev), and mobile control
 * scheme A/B. All built from OpenFL display objects on Main.theStage so it does not interact with
 * the game's software bitmap render pipeline. Settings persist via [[Settings]] and apply live.
 */
class OptionsScreen
{
    public static var open : Bool = false;

    static var stageRef : Stage;
    static var gearBtn : Sprite;
    static var panel : Sprite;            // whole modal (dim bg + box), hidden unless open
    static var box : Sprite;              // the centered panel box

    static var rowPerf : Sprite;
    static var rowLevels : Sprite;
    static var rowControl : Sprite;
    static var rowSens : Sprite;
    static var rowCachedTerrain : Sprite;
    static var lblPerf : TextField;
    static var lblLevels : TextField;
    static var lblControl : TextField;
    static var lblSens : TextField;
    static var lblCachedTerrain : TextField;

    static inline var BOX_W : Float = 380;
    static inline var BOX_H : Float = 342;

    public static function Init(stage : Stage) : Void
    {
        if (stage == null) return;
        stageRef = stage;

        BuildGear();
        BuildPanel();

        stage.addChild(gearBtn);
        stage.addChild(panel);

        Reposition();
        try { stage.addEventListener(Event.RESIZE, function(_) : Void { Reposition(); }); } catch (e : Dynamic) {}
    }

    // ---- Gear button -------------------------------------------------------------------------

    static function BuildGear() : Void
    {
        gearBtn = new Sprite();
        gearBtn.buttonMode = true;
        gearBtn.mouseChildren = false;
        var g = gearBtn.graphics;
        // rounded backing so the cog is visible on any background
        g.beginFill(0x000000, 0.45);
        g.drawRoundRect(0, 0, 40, 40, 10, 10);
        g.endFill();
        DrawCog(gearBtn, 20, 20, 12, 6.5, 8, 0xDDDDDD);
        gearBtn.visible = false;
        gearBtn.addEventListener(MouseEvent.CLICK, function(_) : Void { Show(); });
    }

    // A cog silhouette as an alternating-radius polygon, with a hole in the middle.
    static function DrawCog(sp : Sprite, cx : Float, cy : Float, rOuter : Float, rInner : Float, teeth : Int, col : Int) : Void
    {
        var g = sp.graphics;
        g.beginFill(col, 1);
        var steps : Int = teeth * 2;
        for (i in 0...steps + 1)
        {
            var a : Float = (i / steps) * Math.PI * 2;
            var r : Float = (i % 2 == 0) ? rOuter : rInner;
            var x : Float = cx + Math.cos(a) * r;
            var y : Float = cy + Math.sin(a) * r;
            if (i == 0) g.moveTo(x, y); else g.lineTo(x, y);
        }
        g.endFill();
        // hub hole
        g.beginFill(0x000000, 0.55);
        g.drawCircle(cx, cy, rInner * 0.55);
        g.endFill();
    }

    // ---- Panel -------------------------------------------------------------------------------

    static function BuildPanel() : Void
    {
        panel = new Sprite();
        panel.visible = false;

        // full-stage dim that also swallows clicks behind the box
        var dim = new Sprite();
        dim.graphics.beginFill(0x000000, 0.6);
        dim.graphics.drawRect(0, 0, 10, 10); // resized in Reposition
        dim.graphics.endFill();
        dim.name = "dim";
        dim.addEventListener(MouseEvent.CLICK, function(_) : Void {}); // absorb
        panel.addChild(dim);

        box = new Sprite();
        var bg = box.graphics;
        bg.beginFill(0x18181C, 0.98);
        bg.drawRoundRect(0, 0, BOX_W, BOX_H, 16, 16);
        bg.endFill();
        bg.lineStyle(2, 0x00FF66, 0.9);
        bg.drawRoundRect(1, 1, BOX_W - 2, BOX_H - 2, 16, 16);
        panel.addChild(box);

        box.addChild(MakeText("OPTIONS", 20, 0x00FF66, 0, 12, BOX_W, true));

        rowPerf = MakeRow(46, "Performance HUD");
        lblPerf = cast rowPerf.getChildByName("val");
        rowPerf.addEventListener(MouseEvent.CLICK, function(_) : Void { TogglePerf(); });

        rowLevels = MakeRow(92, "Open all levels (dev)");
        lblLevels = cast rowLevels.getChildByName("val");
        rowLevels.addEventListener(MouseEvent.CLICK, function(_) : Void { ToggleLevels(); });

        rowControl = MakeRow(138, "Mobile controls");
        lblControl = cast rowControl.getChildByName("val");
        rowControl.addEventListener(MouseEvent.CLICK, function(_) : Void { ToggleControl(); });

        rowSens = MakeRow(184, "Aim sensitivity (C)");
        lblSens = cast rowSens.getChildByName("val");
        rowSens.addEventListener(MouseEvent.CLICK, function(_) : Void { ToggleSens(); });

        // The iOS perf fix: cache static terrain to GPU textures (upload once) instead of re-uploading
        // a full-screen bitmap per terrain object every frame. On by default; toggle off to compare.
        rowCachedTerrain = MakeRow(230, "Cached terrain (perf)");
        lblCachedTerrain = cast rowCachedTerrain.getChildByName("val");
        rowCachedTerrain.addEventListener(MouseEvent.CLICK, function(_) : Void { ToggleCachedTerrain(); });

        box.addChild(rowPerf);
        box.addChild(rowLevels);
        box.addChild(rowControl);
        box.addChild(rowSens);
        box.addChild(rowCachedTerrain);

        // FULLSCREEN + CLOSE buttons (side by side)
        var fsBtn = MakeButton("FULLSCREEN", 18, 162, function() : Void { ToggleFullscreen(); });
        fsBtn.y = BOX_H - 48;
        box.addChild(fsBtn);
        var closeBtn = MakeButton("CLOSE", BOX_W - 180, 162, function() : Void { Hide(); });
        closeBtn.y = BOX_H - 48;
        box.addChild(closeBtn);

        RefreshLabels();
    }

    static function MakeButton(label : String, x : Float, w : Float, onClick : Void -> Void) : Sprite
    {
        var b = new Sprite();
        b.buttonMode = true;
        b.mouseChildren = false;
        b.graphics.beginFill(0x333339, 1);
        b.graphics.drawRoundRect(0, 0, w, 34, 8, 8);
        b.graphics.endFill();
        b.addChild(MakeText(label, 15, 0xFFFFFF, 0, 7, w, true));
        b.x = x;
        b.addEventListener(MouseEvent.CLICK, function(_) : Void { onClick(); });
        return b;
    }

    // Toggle fullscreen. Works on desktop/Android; iOS Safari blocks the Fullscreen API (use
    // "Add to Home Screen" there for a standalone fullscreen instead).
    static function ToggleFullscreen() : Void
    {
        #if (js && html5)
        // Call the browser Fullscreen API directly from this click handler so the user-gesture context
        // is preserved (openfl's displayState path was being rejected/swallowed). Falls back to webkit.
        try {
            var doc : Dynamic = js.Browser.document;
            var fsEl : Dynamic = (doc.fullscreenElement != null) ? doc.fullscreenElement : doc.webkitFullscreenElement;
            if (fsEl == null) {
                var el : Dynamic = doc.documentElement; // whole page -> canvas + letterbox scale up together
                if (el.requestFullscreen != null) el.requestFullscreen();
                else if (el.webkitRequestFullscreen != null) el.webkitRequestFullscreen();
                else if (el.webkitRequestFullScreen != null) el.webkitRequestFullScreen();
            } else {
                if (doc.exitFullscreen != null) doc.exitFullscreen();
                else if (doc.webkitExitFullscreen != null) doc.webkitExitFullscreen();
            }
        } catch (e : Dynamic) {}
        #else
        try {
            var st = Main.theStage;
            if (st == null) return;
            st.displayState = (st.displayState == StageDisplayState.NORMAL) ? StageDisplayState.FULL_SCREEN_INTERACTIVE : StageDisplayState.NORMAL;
        } catch (e : Dynamic) {}
        #end
    }

    // a clickable row: label on the left, a value chip on the right (named "val")
    static function MakeRow(y : Float, label : String) : Sprite
    {
        var row = new Sprite();
        row.y = y;
        row.buttonMode = true;
        row.mouseChildren = false;
        // invisible hit area spanning the row
        row.graphics.beginFill(0xFFFFFF, 0.0);
        row.graphics.drawRect(0, 0, BOX_W, 44);
        row.graphics.endFill();
        row.addChild(MakeText(label, 16, 0xFFFFFF, 24, 12, 230, false));
        var val = MakeText("", 16, 0x00FF66, BOX_W - 130, 12, 106, true);
        val.name = "val";
        val.background = true;
        val.backgroundColor = 0x2A2A30;
        row.addChild(val);
        return row;
    }

    static function MakeText(s : String, size : Int, col : Int, x : Float, y : Float, w : Float, center : Bool) : TextField
    {
        var tf = new TextField();
        var fmt = new TextFormat("_sans", size, col, true);
        if (center) fmt.align = "center";
        tf.defaultTextFormat = fmt;
        tf.selectable = false;
        tf.mouseEnabled = false;
        tf.x = x;
        tf.y = y;
        tf.width = w;
        tf.height = size + 12;
        tf.text = s;
        return tf;
    }

    static function RefreshLabels() : Void
    {
        if (lblPerf != null) { lblPerf.text = Settings.perfHud ? "ON" : "OFF"; lblPerf.textColor = Settings.perfHud ? 0x00FF66 : 0x999999; }
        if (lblLevels != null) { lblLevels.text = Settings.openAllLevels ? "ON" : "OFF"; lblLevels.textColor = Settings.openAllLevels ? 0x00FF66 : 0x999999; }
        if (lblControl != null) { lblControl.text = (Settings.mobileControlScheme == Settings.SCHEME_C) ? "C" : (Settings.mobileControlScheme == Settings.SCHEME_B) ? "B" : "A"; }
        if (lblSens != null) { lblSens.text = switch (Settings.aimSensitivity) { case 0: "LOW"; case 2: "HIGH"; default: "MED"; }; }
        if (lblCachedTerrain != null) { lblCachedTerrain.text = Settings.cachedTerrain ? "ON" : "OFF"; lblCachedTerrain.textColor = Settings.cachedTerrain ? 0x00FF66 : 0x999999; }
    }

    static function ToggleSens() : Void
    {
        Settings.aimSensitivity = (Settings.aimSensitivity + 1) % 3;
        Settings.Save();
        RefreshLabels();
    }

    // ---- Toggles -----------------------------------------------------------------------------

    static function TogglePerf() : Void
    {
        Settings.perfHud = !Settings.perfHud;
        Settings.Save();
        Main.SetPerfHud(Settings.perfHud);
        RefreshLabels();
    }

    static function ToggleLevels() : Void
    {
        Settings.openAllLevels = !Settings.openAllLevels;
        Settings.Save();
        RefreshLabels();
    }

    static function ToggleControl() : Void
    {
        // cycle A -> B (joystick) -> C (aim pad) -> A
        Settings.mobileControlScheme = (Settings.mobileControlScheme + 1) % 3;
        Settings.Save();
        RefreshLabels();
    }

    // The iOS perf fix: cache each static terrain object's rasterisation to a GPU texture (upload once)
    // instead of re-uploading a full-screen bitmap per object every frame. Applies live — the per-object
    // cache builds lazily on the next render.
    static function ToggleCachedTerrain() : Void
    {
        Settings.cachedTerrain = !Settings.cachedTerrain;
        Settings.Save();
        RefreshLabels();
    }

    // ---- Show / hide -------------------------------------------------------------------------

    public static function Show() : Void
    {
        if (panel == null) return;
        RefreshLabels();
        Reposition();
        panel.visible = true;
        open = true;
        PinTop();
    }

    public static function Hide() : Void
    {
        if (panel == null) return;
        panel.visible = false;
        open = false;
    }

    /**
     * Called each frame from Main. Shows the gear on menus / when paused, hides it during active
     * gameplay, and keeps the overlay on top of late-added screens.
     */
    public static function Tick() : Void
    {
        if (gearBtn == null) return;
        var showGear : Bool = false;
        try { showGear = (Game.gameState == Game.gameState_UI) || PauseMenu.IsPaused(); } catch (e : Dynamic) {}
        // never show the bare gear while the panel itself is open
        gearBtn.visible = showGear && !open;
        if (open) PinTop();
    }

    static function PinTop() : Void
    {
        if (stageRef == null) return;
        try
        {
            if (panel.parent == stageRef) stageRef.setChildIndex(panel, stageRef.numChildren - 1);
        }
        catch (e : Dynamic) {}
    }

    static function Reposition() : Void
    {
        if (stageRef == null) return;
        var sw : Float = stageRef.stageWidth;
        var sh : Float = stageRef.stageHeight;
        if (sw <= 0) sw = 700;
        if (sh <= 0) sh = 525;

        if (gearBtn != null) { gearBtn.x = sw - 48; gearBtn.y = 8; }

        if (panel != null)
        {
            var dim = panel.getChildByName("dim");
            if (dim != null)
            {
                var s : Sprite = cast dim;
                s.width = sw;
                s.height = sh;
            }
            if (box != null)
            {
                box.x = (sw - BOX_W) / 2;
                box.y = (sh - BOX_H) / 2;
            }
        }
    }
}
