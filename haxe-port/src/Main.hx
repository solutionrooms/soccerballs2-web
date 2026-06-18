import audioPackage.Audio;
import editorPackage.GameLayers;
import flash.display.BitmapDataChannel;
import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.display.Stage;
import flash.display.StageQuality;
import flash.events.*;
import flash.filters.BlurFilter;
import flash.filters.ConvolutionFilter;
import flash.filters.DisplacementMapFilter;
import flash.system.System;
import flash.text.*;
import flash.net.URLRequest;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.*;
import flash.net.*;
import flash.ui.*;
import flash.display.StageDisplayState;
import flash.utils.Timer;
import licPackage.Lic;
import uIPackage.UI;

@:meta(Frame(factoryClass="Preloader"))

class Main extends MovieClip
{
    public var ftime : Float;
    public var currentTime : Float = 0;
    
    public var screenBD : BitmapData;
    public var screenB : Bitmap;
    
    
    public static var theRoot : MovieClip;
    public static var theStage : Stage;

    // DEBUG hook (exposed to JS as window.sb2LoadLevel) so a level can be started without clicking
    // through the menu — used to reproduce/diagnose the gamescreen transition headlessly.
    @:expose("sb2LoadLevel")
    public static function sb2LoadLevel(i : Int) : Void
    {
        Levels.currentIndex = i;
        UI.StartTransition("gamescreen", null, "");
    }

    public function new()
    {
        super();
        addEventListener(Event.ADDED_TO_STAGE, added_to_stage, false, 0, true);
    }
    
    public function added_to_stage(e : Event)
    {
        removeEventListener(Event.ADDED_TO_STAGE, added_to_stage);
        Lic.InitFromMain();
        Lic.Playtomic_Log();
        Lic.ShowIntro(NewInit4);
    }
    public function NewInit4()
    {
        // Force the generated SWF symbol classes to be compiled+kept (they are otherwise only resolved
        // dynamically by name and stripped by DCE). Referencing the array makes Haxe load KeepSymbols.
        if (KeepSymbols.symbols == null) return;
        theRoot = this;
        theStage = this.root.stage;
        // In the original SWF the Preloader (the [Frame(factoryClass="Preloader")] document factory)
        // set LicDef.stg and called InitSkus() via InitFromPreloader. OpenFL ignores that metadata and
        // runs Main directly, so do that here: LicDef.GetStage() is used pervasively by the UI, and
        // InitSkus() populates LicDef.skus (else GetSku/AreOtherGamesAdsAllowed crash on the
        // level-complete screen). SkuModify() is intentionally skipped (domain/site-lock glue).
        licPackage.LicDef.stg = this;
        licPackage.LicDef.InitSkus();
        Settings.Load();
        GameFont.Load(); // start loading the Komika Axis webfont; the preparing screen waits on GameFont.ready
        InitPerfOverlay();
        OptionsScreen.Init(theStage);
        MobileControls.Init(theStage);
        MobileAimPad.Init(theStage); // scheme C: aim-pad touch handlers
        SetPerfHud(Settings.perfHud); // apply the saved setting authoritatively (on OR off), overriding the ?fps URL default
        SetEverythingUpOnce();
    }

    // --- Performance overlay (toggle with the backtick/tilde key `; P is the in-game pause key) ------
    public static var __perfTF : TextField = null;
    public static var __perfOn : Bool = false;
    public static var __rafCount : Int = 0;       // every MainLoop call (= one requestAnimationFrame)
    public static var __updCount : Int = 0;       // every gated game update (target Defs.fps)
    public static var __perfStamp : Float = -1;
    public static var __gameFps : Float = 0;
    public static var __rafFps : Float = 0;
    public static var __blitsPerFrame : Int = 0;  // BitmapData composites in the last rendered frame (hw-independent)

    // Set HUD visibility from anywhere (options screen, boot, key toggle).
    public static function SetPerfHud(on : Bool) : Void
    {
        __perfOn = on;
        if (__perfTF != null) __perfTF.visible = on;
    }

    public function InitPerfOverlay() : Void
    {
        if (theStage == null) return;
        var tf : TextField = new TextField();
        var fmt : TextFormat = new TextFormat("_typewriter", 12, 0x00FF66);
        tf.defaultTextFormat = fmt;
        tf.selectable = false;
        tf.mouseEnabled = false;
        tf.autoSize = TextFieldAutoSize.LEFT;
        tf.background = true;
        tf.backgroundColor = 0x000000;
        tf.x = 4;
        tf.y = 4;
        tf.visible = false;
        theStage.addChild(tf);
        __perfTF = tf;
        // Reliable enable regardless of keyboard layout / canvas focus: add ?fps (or ?perf) to the URL.
        try {
            var q : String = js.Browser.window.location.search;
            if (q != null && (q.indexOf("fps") >= 0 || q.indexOf("perf") >= 0)) { __perfOn = true; tf.visible = true; }
        } catch (err : Dynamic) {}
        // Toggle key: backtick/tilde (` , keyCode 192). P is the in-game pause key so it can't be used.
        // Persist so the choice survives reloads (same setting the options screen drives).
        var toggle = function() : Void { SetPerfHud(!__perfOn); Settings.perfHud = __perfOn; Settings.Save(); };
        // Benchmark: number keys 1-6 set the render-stress multiplier (1/2/4/8/16/32) — push every
        // sprite N times so the render cost scales N×, to reveal headroom on a fast CPU (RAF-capped).
        var stressLevels = [1, 2, 4, 8, 16, 32];
        var key = function(kc : Int) : Void {
            if (kc == 192) toggle();
            else if (kc >= 49 && kc <= 54) TileRenderer.stress = stressLevels[kc - 49];
        };
        theStage.addEventListener(KeyboardEvent.KEY_DOWN, function(e : KeyboardEvent) : Void { key(e.keyCode); });
        // also listen at the document level (some browsers/focus states don't deliver keys to the canvas)
        try {
            js.Browser.document.addEventListener("keydown", function(e) { key((untyped e).keyCode); });
        } catch (err : Dynamic) {}
    }

    // One-time renderer diagnostic: is the game canvas on hardware WebGL, or has it fallen back to
    // Canvas/software? (key to the iOS slowdown). Shows the GL renderer string when available.
    public static var __renderInfo : String = null;
    public static function GetRenderInfo() : String
    {
        if (__renderInfo != null) return __renderInfo;
        var s : String = "?";
        try { s = (flash.Lib.current.stage.context3D != null) ? "webgl" : "canvas2d"; } catch (e : Dynamic) {}
        try {
            var c : Dynamic = js.Browser.document.querySelector("#openfl-content canvas");
            if (c == null) c = js.Browser.document.querySelector("canvas");
            if (c != null)
            {
                var gl : Dynamic = c.getContext("webgl2");
                if (gl == null) gl = c.getContext("webgl");
                if (gl == null) gl = c.getContext("experimental-webgl");
                if (gl != null)
                {
                    var dbg : Dynamic = gl.getExtension("WEBGL_debug_renderer_info");
                    if (dbg != null) s += " | " + gl.getParameter(dbg.UNMASKED_RENDERER_WEBGL);
                }
                else s += " | no-gl-on-canvas";
                // backbuffer resolution + DPR: reveals if iOS is rendering at high-DPI (fill-rate suspect)
                try {
                    var dpr : Dynamic = js.Browser.window.devicePixelRatio;
                    s += "\nbuf " + c.width + "x" + c.height + " css " + Std.int(c.clientWidth) + "x" + Std.int(c.clientHeight) + " dpr" + dpr;
                } catch (e2 : Dynamic) {}
            }
        } catch (e : Dynamic) {}
        // only cache once the stage/context is actually up
        if (s != "?") __renderInfo = s;
        return s;
    }

    // Active render-diagnostic flags, so you can confirm a ?param actually took effect.
    public static function GetDiagFlags() : String
    {
        var d : String = "";
        try {
            if (TileRenderer.noTiles) d += " notiles";
            if (TileRenderer.noUnderlay) d += " nounderlay";
            if (TileRenderer.DEBUG_SHARE_TILESET) d += " batch1";
            if (TileRenderer.tilemap != null)
            {
                if (!TileRenderer.tilemap.tileBlendModeEnabled) d += " noblend";
                if (!TileRenderer.tilemap.tileColorTransformEnabled) d += " noct";
            }
        } catch (e : Dynamic) {}
        return d == "" ? " none" : d;
    }

    public function UpdatePerfOverlay() : Void
    {
        var now : Float = haxe.Timer.stamp();
        if (__perfStamp < 0) __perfStamp = now;
        var refresh : Bool = false;
        if ((now - __perfStamp) >= 0.5)
        {
            var dt : Float = now - __perfStamp;
            __gameFps = __updCount / dt;
            __rafFps = __rafCount / dt;
            __updCount = 0;
            __rafCount = 0;
            __perfStamp = now;
            refresh = true;
        }
        if (__perfOn && __perfTF != null)
        {
            // IMPORTANT: only rebuild the text ~2x/sec, not every frame. On the WebGL stage iOS Safari
            // re-uploads a changed TextField's texture (texImage2D) every frame it changes — updating
            // the text 60x/s was itself a per-frame GPU stall that dominated the frame and masked the
            // real render cost. Rebuilding it on the 0.5s tick keeps the TextField static in between.
            if (refresh)
            {
                var bodies : Int = -1;
                try { if (PhysicsBase.GetNapeSpace() != null) bodies = PhysicsBase.GetNapeSpace().bodies.length; } catch (e : Dynamic) {}
                __perfTF.text = "fps " + Std.int(__gameFps + 0.5) + "   raf " + Std.int(__rafFps + 0.5)
                    + "\ninterval " + Std.int(timeForFrame) + "ms   ourcode " + Std.int(timeForUpdate) + "ms"
                    + "\nblits " + __blitsPerFrame + "   tiles " + TileRenderer.lastCount
                    + (TileRenderer.stress > 1 ? "   stress x" + TileRenderer.stress : "")
                    + "\ndiag:" + GetDiagFlags()
                    + (bodies >= 0 ? "\nnape bodies " + bodies : "")
                    + "\nrender " + GetRenderInfo()
                    + "\ncap " + Std.int(Defs.fps) + "fps";
            }
            // keep it pinned on top even as screens are added/removed (cheap; no texture re-upload)
            if (theStage != null && __perfTF.parent == theStage && theStage.getChildIndex(__perfTF) != theStage.numChildren - 1)
                theStage.setChildIndex(__perfTF, theStage.numChildren - 1);
        }
    }

    
    public function InitDrawScreen() : Void
    {
        if (false)
        {
            return;
        }
        screenBD = new BitmapData(Defs.displayarea_w, Defs.displayarea_h, true, 0x0);
        screenB = new Bitmap(screenBD);
        // GPU sprite layer composited above screenB (the software underlay: background + vector terrain).
        TileRenderer.Init(Defs.displayarea_w, Defs.displayarea_h);
    }
    
    
    public function SetEverythingUpOnce() : Void
    {
        SetEverythingUpOnce2();
    }
    
    public function SetEverythingUpOnce2() : Void
    {
        MobileSpecific.Init();
        
        
        TexturePages.InitOnce();
        
        GraphicObjects.InitOnce();
        
        
        EngineDebug.InitOnce();
        KeyReader.InitOnce(theStage);
        MouseControl.InitOnce(theStage);
        Audio.InitOnce();
        PauseMenu.InitOnce();
        Particles.InitOnce(Defs.maxParticles);
        GameObjects.InitOnce(Defs.maxGameObjects);
        UI.InitOnce();
        InitDrawScreen();
        ExternalData.Load(SetEverythingUpOnce4);
    }
    
    public function SetEverythingUpOnce4()
    {
        ClearStage();
        Game.InitOnce(this);
        addEventListener(Event.ENTER_FRAME, MainLoop);
    }
    
    public function ClearStage()
    {
        var i : Int = 0;        i = as3hx.Compat.parseInt(this.numChildren - 1);
        while (i >= 0)
        {
            removeChildAt(i);
            i--;
        }
    }
    
    
    public function DisplayStageNames()
    {
        var i : Int = 0;        i = as3hx.Compat.parseInt(this.numChildren - 1);
        while (i >= 0)
        {
            var dob : DisplayObject = getChildAt(i);
            Utils.print(dob.name);
            i--;
        }
    }
    
    
    
    public function Render(bd : BitmapData)
    {
        this.x = 0;
        this.y = 0;
        Game.Render(bd);
    }
    
    public var timeForFrame : Float;
    public function calcFrameTime()
    {
        var oldTime : Float = currentTime;
        currentTime = Math.round(haxe.Timer.stamp() * 1000);
        
        timeForFrame = currentTime - oldTime;
        
        if (currentTime < oldTime)
        {
            oldTime = currentTime - 100;
        }
        if (currentTime > oldTime + (100 * 10))
        {
            oldTime = 100 * 10;
        }
        
        ftime = 1 / (1000 / Defs.fps) * (currentTime - oldTime);
        
        framecounter++;
        secondCounter += (currentTime - oldTime);
        
        if (secondCounter > 1000)
        {
            fps = (as3hx.Compat.parseFloat(framecounter) / secondCounter) * 1000;
            framecounter = 0;
            secondCounter = 0;
        }
    }
    public var fps : Float;
    public var framecounter : Int = 0;
    public var secondCounter : Float = 0.0;
    
    
    
    
    public var renderCount : Int = 0;
    public var frameSkipCount : Int = 0;
    
    public var timeForUpdate : Float = 0;
    public var renderSkip : Bool = false;
    
    public function RunLevel()
    {
        var oldTime : Float = Math.round(haxe.Timer.stamp() * 1000);
        
        if (Game.doWalkthrough)
        {
            return;
        }
        
        Game.UpdateGameplay();
        
        var maxTime : Float = 1000 / Defs.fps;
        
        
        if (false)
        {
            if (timeForUpdate > maxTime && frameSkipCount < 3)
            {
                screenBD.copyPixels(Game.backgroundScreenBD, screenBD.rect, Defs.pointZero);
                
                
                frameSkipCount++;
            }
            else
            {
                Render(Game.backgroundScreenBD);
                
                screenBD.copyPixels(Game.backgroundScreenBD, screenBD.rect, Defs.pointZero);
                
                frameSkipCount = 0;
            }
        }
        else
        {
            if (false)
            {
                useFrameSkip = false;
            }
            
            if (useFrameSkip)
            {
                if (timeForUpdate > (1000 / Defs.fps))
                {
                }
                else
                {
                    Render(screenBD);
                }
            }
            else if (true)
            {
                Render(screenBD);
            }
            else if (renderSkip == true)
            {
                renderSkip = false;
            }
            else
            {
                Render(screenBD);
                renderSkip = true;
            }
        }
        
        
        timeForUpdate = Math.round(haxe.Timer.stamp() * 1000) - oldTime;
    }
    
    public var useFrameSkip : Bool = true;
    
    public static var debugLoopCount : Int = 0;
    @:expose("sb2LoopCount") public static function sb2LoopCount() : Int { return debugLoopCount; }

    @:expose("sb2BallY") public static function sb2BallY() : Float {
        var go : Dynamic = GameVars.footballGO;
        if (go == null) return -88888;
        return go.ypos; // synced from physics each frame (GameObjects.UpdateGOsFromPhysics_Nape)
    }

    @:expose("sb2BallInfo") public static function sb2BallInfo() : String {
        var go : Dynamic = GameVars.footballGO;
        if (go == null) return "null";
        return "x=" + Std.int(go.xpos) + " y=" + Std.int(go.ypos) + " xvel=" + go.xvel + " yvel=" + go.yvel
            + " mass=" + go.GetBodyMass(0) + " state=" + go.state;
    }

    @:expose("sb2TestKick") public static function sb2TestKick(speed : Float, angleDeg : Float) : Void {
        var go : Dynamic = GameVars.footballGO;
        if (go == null) return;
        var player : Dynamic = go.football_playerGO;
        if (player != null) player.player_currentFootball = null; // release the player's hold so the kick sticks
        var v = new Vec();
        v.Set(angleDeg * Math.PI / 180.0, speed);
        go.Football_Launch(v);
    }

    @:expose("sb2GroundInfo") public static function sb2GroundInfo() : String {
        var space = PhysicsBase.GetNapeSpace();
        var total = 0; var dynBodies = 0; var staticBodies = 0; var staticShapes = 0; var sensorShapes = 0;
        for (b in space.bodies) {
            total++;
            if (b.isStatic()) { staticBodies++; staticShapes += b.shapes.length; }
            else dynBodies++;
            for (s in b.shapes) if (s.sensorEnabled) sensorShapes++;
        }
        return "totalBodies=" + total + " static=" + staticBodies + " dyn=" + dynBodies
            + " staticShapes=" + staticShapes + " sensorShapes=" + sensorShapes;
    }

    @:expose("sb2DynShapes") public static function sb2DynShapes() : String {
        var space = PhysicsBase.GetNapeSpace();
        var out = "";
        for (b in space.bodies) {
            if (!b.isStatic()) {
                for (sh in b.shapes) {
                    var f = sh.filter;
                    out += "[at(" + Std.int(b.position.x) + "," + Std.int(b.position.y) + ") cG=" + f.collisionGroup
                        + " cM=" + f.collisionMask + " sG=" + f.sensorGroup + " sM=" + f.sensorMask
                        + " sensorEn=" + sh.sensorEnabled + "] ";
                }
            }
        }
        return out;
    }

    @:expose("sb2GroundShape") public static function sb2GroundShape() : String {
        var space = PhysicsBase.GetNapeSpace();
        for (b in space.bodies) {
            if (b.isStatic() && b.shapes.length > 0) {
                for (sh in b.shapes) {
                    var f = sh.filter;
                    return "first static shape: cG=" + f.collisionGroup + " cM=" + f.collisionMask
                        + " sG=" + f.sensorGroup + " sM=" + f.sensorMask + " sensorEn=" + sh.sensorEnabled;
                }
            }
        }
        return "no static shapes";
    }

    @:expose("sb2MakeBallSolid") public static function sb2MakeBallSolid() : Void {
        var space = PhysicsBase.GetNapeSpace();
        for (b in space.bodies) {
            if (!b.isStatic()) {
                for (sh in b.shapes) if (sh.sensorEnabled && b.position.y < 450) sh.sensorEnabled = false;
            }
        }
    }

    @:expose("sb2RealKick") public static function sb2RealKick(mouseX : Float, mouseY : Float) : Void {
        Game.mouse_x = mouseX;
        Game.mouse_y = mouseY;
        Game.doKick = true; // player (state 1, aiming) picks this up next frame -> kick anim -> launch
    }

    @:expose("sb2ForceFail") public static function sb2ForceFail() : Void {
        GameVars.numKicks = GameVars.maxKicks; // next held-ball frame triggers the out-of-kicks fail
    }

    @:expose("sb2BBox") public static function sb2BBox() : String {
        var r : Dynamic = Game.boundingRectangle;
        if (r == null) return "null";
        return "x=" + r.x + " y=" + r.y + " w=" + r.width + " h=" + r.height + " (right=" + (r.x+r.width) + " bottom=" + (r.y+r.height) + ")";
    }

    // Decoupled fixed-timestep loop. openfl HTML5 dispatches ENTER_FRAME every requestAnimationFrame and
    // ignores stage.frameRate, so the raw rate = display refresh. Run the game logic/physics at a fixed
    // Defs.fps (1/60 s) WITH CATCH-UP, and render once per frame. This keeps game SPEED correct and
    // independent of the render rate: too-fast displays don't speed it up, and heavy/render-bound levels
    // that can't render within 1/60 s still advance the simulation at the right pace (previously they
    // ran at ~half speed because the physics stepped once per slow render frame).
    public static var __loopStamp : Float = -1;
    public static var __accum : Float = 0;

    public function MainLoop(e : Event) : Void
    {
        __rafCount++; // every ENTER_FRAME / requestAnimationFrame (the raw render rate)
        var step : Float = 1.0 / Defs.fps;
        var now : Float = haxe.Timer.stamp();
        if (__loopStamp < 0) __loopStamp = now;
        __accum += (now - __loopStamp);
        __loopStamp = now;
        if (__accum > step * 5) __accum = step * 5; // anti-spiral clamp after a stall (tab switch / GC)

        var steps : Int = 0;
        while (__accum >= step)
        {
            __accum -= step;
            __updCount++;
            debugLoopCount++;
            // one full original "frame" of logic+physics (no render) — run N times to catch up to realtime
            KeyReader.UpdateOncePerFrame();
            Audio.UpdateOncePerFrame();
            MobileControls.UpdateAim(); // scheme B: feed joystick deflection into Game.mouse_x/y before the update
            MobileAimPad.UpdateAim();   // scheme C: feed aim-pad virtual cursor into Game.mouse_x/y
            GameVars.InitForFrame();
            if (!Game.doWalkthrough) Game.UpdateGameplay();
            // TRAJECTORY PROBE: same format/threshold as the patched original SWF's [ORIG] log, so the
            // ball's per-frame velocity+spin+pos can be diffed against the original to find where they split.
            if (NapeContacts.probeEnabled)
            {
                var __fb = GameVars.footballGO;
                if (__fb != null && __fb.nape_bodies != null && __fb.nape_bodies.length > 0)
                {
                    var __v = __fb.GetBodyLinearVelocity(0);
                    if (__v.length > 30)
                    {
                        trace("[PORT] vel=(" + Std.int(__v.x) + "," + Std.int(__v.y) + ") spd=" + Std.int(__v.length)
                            + " spin=" + (Std.int(__fb.nape_bodies[0].angularVel * 100) / 100)
                            + " pos=(" + Std.int(__fb.xpos) + "," + Std.int(__fb.ypos) + ")");
                    }
                }
            }
            GameVars.ExitForFrame();
            steps++;
        }
        if (steps > 0 && screenBD != null)
        {
            BitmapData.__drawCalls = 0; // count BitmapData composites for this displayed frame
            Render(screenBD); // render once per displayed frame, after catching the simulation up
            __blitsPerFrame = BitmapData.__drawCalls;
            calcFrameTime();
            timeForUpdate = (haxe.Timer.stamp() - now) * 1000;
        }
        // Keep the software underlay's visibility in sync with the live diagnostic toggle, so flipping
        // "Render underlay" in Options takes effect immediately (an invisible Bitmap isn't re-uploaded to
        // the GPU each frame — that's the whole point of the A/B test).
        if (screenB != null) screenB.visible = !TileRenderer.noUnderlay;
        UpdatePerfOverlay();
        OptionsScreen.Tick();
        MobileControls.Tick();
            MobileAimPad.Tick();

        // one-time terrain-collision geometry dump when a level becomes playable (copy [SB2] lines back)
        try {
            var fb : Dynamic = GameVars.footballGO;
            if (fb != null && !__diagDone) { __diagDone = true; sb2DiagGround(); }
            if (fb == null) __diagDone = false;
        } catch (e : Dynamic) {}
    }

    static var __diagDone : Bool = false;
    static var __ballLogCount : Int = 0;

    // Dump the grass collision body's triangles — validity (Nape rejects bad winding/degenerate polys
    // as non-VALID) and signed-area winding — to test why a kicked ball passes through the top surface.
    public static function sb2DiagGround() : Void {
        var space = PhysicsBase.GetNapeSpace();
        trace("[SB2] === ground diagnostic ===");
        for (b in space.bodies) {
            if (!b.isStatic()) continue;
            var isGround = false;
            for (sh in b.shapes) { var f = sh.filter; if (f.collisionGroup == 1 && !sh.sensorEnabled) { isGround = true; break; } }
            if (!isGround) continue;
            var bx = b.position.x; var by = b.position.y;
            var tris = 0; var coversBall = 0;
            var minx = 1e9; var maxx = -1e9; var miny = 1e9; var maxy = -1e9;
            for (sh in b.shapes) {
                tris++;
                var ab = sh.bounds; // world-space AABB — definitive
                if (ab.x < minx) minx = ab.x; if (ab.x + ab.width > maxx) maxx = ab.x + ab.width;
                if (ab.y < miny) miny = ab.y; if (ab.y + ab.height > maxy) maxy = ab.y + ab.height;
                // does this triangle's AABB cover the ball's column (x~319) near floor (y~415-470)?
                if (ab.x <= 330 && ab.x + ab.width >= 310 && ab.y <= 470 && ab.y + ab.height >= 410) coversBall++;
            }
            trace("[SB2] grass body@(" + Std.int(bx) + "," + Std.int(by) + ") shapes=" + tris
                + " worldBounds=(" + Std.int(minx) + "," + Std.int(miny) + ")..(" + Std.int(maxx) + "," + Std.int(maxy) + ")"
                + " | trianglesCoveringBallColumn(x310-330,y410-470)=" + coversBall);
        }
        trace("[SB2] === end ground diagnostic ===");
    }
}

