import flash.display.Sprite;
import flash.display.Stage;
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
    static var lblPerf : TextField;
    static var lblLevels : TextField;
    static var lblControl : TextField;

    static inline var BOX_W : Float = 380;
    static inline var BOX_H : Float = 300;

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

        box.addChild(MakeText("OPTIONS", 22, 0x00FF66, 0, 18, BOX_W, true));

        rowPerf = MakeRow(70, "Performance HUD");
        lblPerf = cast rowPerf.getChildByName("val");
        rowPerf.addEventListener(MouseEvent.CLICK, function(_) : Void { TogglePerf(); });

        rowLevels = MakeRow(130, "Open all levels (dev)");
        lblLevels = cast rowLevels.getChildByName("val");
        rowLevels.addEventListener(MouseEvent.CLICK, function(_) : Void { ToggleLevels(); });

        rowControl = MakeRow(190, "Mobile controls");
        lblControl = cast rowControl.getChildByName("val");
        rowControl.addEventListener(MouseEvent.CLICK, function(_) : Void { ToggleControl(); });

        box.addChild(rowPerf);
        box.addChild(rowLevels);
        box.addChild(rowControl);

        // CLOSE button
        var closeBtn = new Sprite();
        closeBtn.buttonMode = true;
        closeBtn.mouseChildren = false;
        var cg = closeBtn.graphics;
        cg.beginFill(0x333339, 1);
        cg.drawRoundRect(0, 0, 120, 34, 8, 8);
        cg.endFill();
        closeBtn.addChild(MakeText("CLOSE", 16, 0xFFFFFF, 0, 7, 120, true));
        closeBtn.x = (BOX_W - 120) / 2;
        closeBtn.y = BOX_H - 48;
        closeBtn.addEventListener(MouseEvent.CLICK, function(_) : Void { Hide(); });
        box.addChild(closeBtn);

        RefreshLabels();
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
        if (lblControl != null) { lblControl.text = (Settings.mobileControlScheme == Settings.SCHEME_B) ? "B" : "A"; }
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
        Settings.mobileControlScheme = (Settings.mobileControlScheme == Settings.SCHEME_B) ? Settings.SCHEME_A : Settings.SCHEME_B;
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
