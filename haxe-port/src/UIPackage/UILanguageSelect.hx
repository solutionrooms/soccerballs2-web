package uIPackage;

import achievementPackage.Achievement;
import achievementPackage.Achievements;
import audioPackage.Audio;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.MovieClip;
import flash.events.MouseEvent;
import flash.filters.ColorMatrixFilter;
import flash.geom.ColorTransform;
import flash.geom.Rectangle;
import flash.ui.Mouse;
import licPackage.Lic;
import licPackage.Tracking;
import textPackage.TextStrings;

/**
	 * ...
	 * @author LongAnimals
	 */
class UILanguageSelect extends UIScreenInstance
{
    
    public function new()
    {
        super();
    }
    
    override public function ExitScreen()
    {
        UI.RemoveAllButtons();
    }
    
    override public function InitScreen()
    {
        Audio.PlayMusic("menus_music");
        
        UI.StartAddButtons();
        
        Mouse.show();
        
        titleMC = new ScreenLanguage();
        ScreenSize.ScaleMovieClip(titleMC);
        titleMC.gotoAndStop(1);
        
        UI.AddAnimatedMCButton(titleMC.btn_back, buttonBackPressed);
        
        TextStrings.ReplaceTextFieldText(titleMC.textTitle);
        
        AddFlags();
        UpdateFlags();
    }
    
    private function GetFlagFrameFromName(name : String) : Int
    {
        var i : Int = 1;
        for (s/* AS3HX WARNING could not determine type for var: s exp: EIdent(availableFlags) type: null */ in availableFlags)
        {
            if (s == name)
            {
                return i;
            }
            i++;
        }
        return 1;
    }
    
    private var availableFlags : Array<Dynamic> = new Array<Dynamic>(
        "en", 
        "es", 
        "de", 
        "fr", 
        "nl", 
        "pt", 
        "tr", 
        "se", 
        "it");
    
    
    
    
    
    
    
    
    
    private var flagMCs : Array<Dynamic>;
    
    private function UpdateFlags()
    {
        for (mc in flagMCs)
        {
            if (mc.languageID == TextStrings.currentLanguage)
            {
                mc.selected.visible = true;
            }
            else
            {
                mc.selected.visible = false;
            }
        }
    }
    private function AddFlags()
    {
        flagMCs = new Array<Dynamic>();
        var supported : Array<Dynamic> = TextStrings.supportedLanguages;
        
        var ox : Int = 50;
        var x : Float = ox;
        var y : Float = 100;
        var xp : Int = 0;
        for (languageID in supported)
        {
            var mc : MovieClip = new LanguageFlags();
            mc.languageID = languageID;
            mc.gotoAndStop(GetFlagFrameFromName(TextStrings.languageLabels[languageID]));
            titleMC.addChild(mc);
            UI.AddBarebonesMCButton(mc, flagClicked);
            mc.x = x;
            mc.y = y;
            x += 150;
            xp++;
            if (xp >= 4)
            {
                xp = 0;
                x = ox;
                y += 100;
            }
            flagMCs.push(mc);
        }
    }
    
    
    private function flagClicked(e : MouseEvent)
    {
        var mc : MovieClip = try cast(e.currentTarget, MovieClip) catch(e:Dynamic) null;
        TextStrings.currentLanguage = mc.languageID;
        
        Tracking.Event("language", TextStrings.GetLabelFromIndex(mc.languageID));
        
        
        UpdateFlags();
        TextStrings.ReplaceTextFieldText(titleMC.textTitle, "languages");
        SaveData.Save();
        UI.StartTransition("title");
    }
    private function buttonBackPressed(e : MouseEvent)
    {
        UI.StartTransition("title");
    }
}



