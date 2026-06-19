package uIPackage;

import flash.display.MovieClip;
import flash.events.Event;
import flash.system.System;
import licPackage.Lic;
import licPackage.LicAds;
import licPackage.LicDef;

/**
	 * ...
	 * @author LongAnimals
	 */
class UIPreparingScreen extends UIScreenInstance
{
    
    public function new()
    {
        super();
    }
    override public function ExitScreen()
    {
    }
    override public function InitScreen()
    {
        mem1 = Std.int(System.totalMemory / 1024);
        
        titleMC = new ScreenPreparing();
        ScreenSize.ScaleMovieClip(titleMC);
        // The prep now completes in a single frame (~0.4s of real work, no per-frame fill animation),
        // so the "preparing artwork" graphic would only flash. Keep the MC (it drives ENTER_FRAME) but
        // hide it — the user goes from the loader straight to the title with no visible prep screen.
        titleMC.visible = false;

        Preparing.Modify();

        titleMC.addEventListener(Event.ENTER_FRAME, UpdatePreparingScreen, false, 0, true);

        Lic.PlayWithScoresButton((untyped titleMC).btn_PlayWithHighcores);

        if (Game.doWalkthrough)
        {
            (untyped titleMC).btn_PlayWithHighcores.visible = false;
        }

        preparingGraphicsIndex = 0;
        PreparingScreenSetBar();
    }
    public var preparingScreenDone : Bool = false;

    public var preparingGraphicsIndex : Int = 0;
    public var fontWaitFrames : Int = 0; // frames spent waiting on the Komika Axis webfont (time-boxed)

    public function UpdatePreparingScreen(e : Event)
    {
        if (titleMC == null)
        {
            return;
        }

        // Process the ENTIRE remaining prep list this frame. The real work is only ~0.5s total; the
        // old one-item-per-frame pacing just animated the fill bar for ~2-5s of pure wait. The single
        // async gate is the Komika Axis webfont — hold before the font item so the bitmap glyphs aren't
        // baked with a fallback. Time-boxed (~120 frames) so boot never hangs.
        var list : Array<Dynamic> = Preparing.GetPreparingList();
        while (preparingGraphicsIndex < list.length)
        {
            var po : PreparingObject = list[preparingGraphicsIndex];
            if (po.type == "font" && !GameFont.ready && fontWaitFrames < 120)
            {
                fontWaitFrames++;
                PreparingScreenSetBar();
                return; // wait one frame for the font, then resume the loop next frame
            }
            Preparing.DoPreparingObject(po);
            preparingGraphicsIndex++;
        }

        PreparingScreenSetBar();
        preparingScreenDone = true;
        titleMC.removeEventListener(Event.ENTER_FRAME, UpdatePreparingScreen);

        var mem2 : Int = as3hx.Compat.parseInt(System.totalMemory / 1024);
        var memused : Int = as3hx.Compat.parseInt(mem2 - mem1);
        Utils.print("memory used for gfx: " + memused + "k");

        if (Game.doWalkthrough)
        {
            UI.StartTransition("walkthrough");
        }
        else
        {
            UI.StartTransition("title");
        }
    }
    public function PreparingScreenSetBar()
    {
        if (titleMC == null)
        {
            return;
        }
        var pc : Float = Utils.ScaleTo(0, 1, 0, Preparing.GetPreparingList().length - 1, preparingGraphicsIndex);
        (untyped titleMC).loaderBar.loadBar.scaleX = pc;
    }
    public static var mem1 : Int = 0;
}


