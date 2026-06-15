package licPackage;

import flash.display.MovieClip;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.net.URLRequest;
import flash.text.Font;
import flash.text.TextFormat;
import uIPackage.UI;

/**
	 * ...
	 * @author Julian
	 */
class OtherGames
{
    
    public function new()
    {
    }
    public static var otherGamesList : Array<Dynamic>;
    
    public static function GetOtherGamesMC(amount : Int = 4, type : Int = 0) : MovieClip
    {
        var classRef_otherGamesMC : Class<Dynamic> = Type.getClass(Type.resolveClass("otherGamesMC"));
        var classRef_otherGamesMC_TitleScreen : Class<Dynamic> = Type.getClass(Type.resolveClass("otherGamesMC_TitleScreen"));
        var classRef_otherGamesTextMC : Class<Dynamic> = Type.getClass(Type.resolveClass("otherGamesTextMC"));
        
        var mc : MovieClip = try cast(Type.createInstance(classRef_otherGamesMC, []), MovieClip) catch(e:Dynamic) null;
        if (type == 1)
        {
            mc = try cast(Type.createInstance(classRef_otherGamesMC_TitleScreen, []), MovieClip) catch(e:Dynamic) null;
        }
        if (type == 2)
        {
            mc = try cast(Type.createInstance(classRef_otherGamesTextMC, []), MovieClip) catch(e:Dynamic) null;
            amount = 4;
        }
        
        if (LicDef.AreOtherGamesAdsAllowed())
        {
            otherGamesList = [];
            otherGamesList.push({
                        button : "game1",
                        name : "DriftRunners2",
                        display : "Drift Runners 2",
                        select : true
                    });
            otherGamesList.push({
                        button : "game2",
                        name : "CoasterRacer",
                        display : "Coaster Racer",
                        select : true
                    });
            otherGamesList.push({
                        button : "game3",
                        name : "DriftRunners1",
                        display : "Drift Runners",
                        select : true
                    });
            otherGamesList.push({
                        button : "game4",
                        name : "NeonRace",
                        display : "Neon Race",
                        select : true
                    });
            
            otherGamesList.push({
                        button : "game5",
                        name : "GunExpress",
                        display : "Gun Express",
                        select : true
                    });
            otherGamesList.push({
                        button : "game6",
                        name : "HeatRush",
                        display : "Heat Rush",
                        select : true
                    });
            otherGamesList.push({
                        button : "game7",
                        name : "CycloManiacs",
                        display : "Cyclomaniacs",
                        select : true
                    });
            otherGamesList.push({
                        button : "game8",
                        name : "SoccerBalls",
                        display : "Soccer Balls",
                        select : true
                    });
            otherGamesList.push({
                        button : "game9",
                        name : "Zombooka2",
                        display : "Flaming Zombooka 2",
                        select : true
                    });
            otherGamesList.push({
                        button : "game10",
                        name : "Zombooka",
                        display : "Flaming Zombooka",
                        select : true
                    });
            
            otherGamesList.push({
                        button : "game11",
                        name : "CycloManiacs2",
                        display : "Cyclomaniacs 2",
                        select : true
                    });
            otherGamesList.push({
                        button : "game12",
                        name : "CoasterRacer2",
                        display : "Coaster Racer 2",
                        select : true
                    });
            otherGamesList.push({
                        button : "game13",
                        name : "FormulaRacer",
                        display : "Formula Racer",
                        select : true
                    });
            otherGamesList.push({
                        button : "game14",
                        name : "Zomgies2",
                        display : "Zomgies 2",
                        select : true
                    });
            otherGamesList.push({
                        button : "game15",
                        name : "GrandPrixGo",
                        display : "Grand Prix Go",
                        select : true
                    });
            otherGamesList.push({
                        button : "game16",
                        name : "BasketBalls",
                        display : "Basket Balls",
                        select : true
                    });
            otherGamesList.push({
                        button : "game17",
                        name : "NinjaAcademy",
                        display : "Sticky Ninja Academy",
                        select : true
                    });
            otherGamesList.push({
                        button : "game18",
                        name : "FlamingZombooka3",
                        display : "Flaming Zombooka 3",
                        select : true
                    });
            otherGamesList.push({
                        button : "game19",
                        name : "Offroaders",
                        display : "Offroaders",
                        select : true
                    });
            otherGamesList.push({
                        button : "game20",
                        name : "HotRod",
                        display : "Rod Hots Hot Rods",
                        select : true
                    });
            otherGamesList.push({
                        button : "game21",
                        name : "NeonRace2",
                        display : "Neon Race 2",
                        select : true
                    });
            otherGamesList.push({
                        button : "game22",
                        name : "BasketBallsLevelPack",
                        display : "BasketBalls Lev Pack",
                        select : true
                    });
            otherGamesList.push({
                        button : "game23",
                        name : "FormulaRacer2012",
                        display : "Formula Racer 2012",
                        select : true
                    });
            otherGamesList.push({
                        button : "game24",
                        name : "TokyoGuineaPop",
                        display : "Tokyo Guinea Pop",
                        select : true
                    });
            otherGamesList.push({
                        button : "game25",
                        name : "TurboGolf",
                        display : "Turbo Golf",
                        select : true
                    });
            otherGamesList.push({
                        button : "game26",
                        name : "DriftRunners3D",
                        display : "Drift Runners 3D",
                        select : true
                    });
            otherGamesList.push({
                        button : "game27",
                        name : "MuscleCars",
                        display : "V8 Muscle Cars",
                        select : true
                    });
            otherGamesList.push({
                        button : "game28",
                        name : "AmericanRacing",
                        display : "American Racing",
                        select : true
                    });
            
            var positions : Array<Dynamic> = [];
            
            var list : Array<Dynamic> = [];
            for (i in 0...otherGamesList.length)
            {
                if (otherGamesList[i].select == true)
                {
                    list.push(i);
                }
            }
            list = ShuffleIntList(list, 500);
            
            
            if (type == 2)
            {
                for (i in 0...amount)
                {
                    var o : Dynamic = otherGamesList[i];
                    var ro : Dynamic = Reflect.field(otherGamesList, Std.string(list[i]));
                    
                    var button : MovieClip = try cast(mc.getChildByName("game" + as3hx.Compat.parseInt(i + 1)), MovieClip) catch(e:Dynamic) null;
                    (untyped button).nameText.text = ro.display;
                    button.useHandCursor = true;
                    button.buttonMode = true;
                    (untyped button).linkName = ro.name;
                    button.addEventListener(MouseEvent.CLICK, OtherGamesPanel_ClickGameText);
                }
            }
            else
            {
                for (o in otherGamesList)
                {
                    mc[o.button].visible = false;
                    positions.push(new Point(mc[o.button].x, mc[o.button].y));
                }
                
                for (i in 0...amount)
                {
                    var o : Dynamic = otherGamesList[i];
                    var ro : Dynamic = Reflect.field(otherGamesList, Std.string(list[i]));
                    
                    mc[ro.button].visible = true;
                    mc[ro.button].x = positions[i].x;
                    mc[ro.button].y = positions[i].y;
                    var buttonMC : MovieClip = mc[ro.button];
                    UI.AddMCButton(buttonMC, OtherGamesPanel_ClickGame, null, OtherGamesPanel_Hover, OtherGamesPanel_Out);
                    
                    (untyped buttonMC).nameHolder.visible = false;
                }
            }
            
            return mc;
        }
        return null;
    }
    
    public static function OtherGamesPanel_Hover(e : MouseEvent)
    {
        var buttonMC : MovieClip = try cast(e.currentTarget, MovieClip) catch(e:Dynamic) null;
        (untyped buttonMC).nameHolder.visible = true;
    }
    public static function OtherGamesPanel_Out(e : MouseEvent)
    {
        var buttonMC : MovieClip = try cast(e.currentTarget, MovieClip) catch(e:Dynamic) null;
        (untyped buttonMC).nameHolder.visible = false;
    }
    
    public static function RandBetweenInt(r0 : Int, r1 : Int) : Int
    {
        var r : Int = as3hx.Compat.parseInt(Math.random() * ((r1 - r0) + 1));
        r += r0;
        return r;
    }
    
    public static function ShuffleIntList(a : Array<Dynamic>, amount : Int = 100) : Array<Dynamic>
    {
        var len : Int = a.length;
        for (i in 0...amount)
        {
            var p0 : Int = RandBetweenInt(0, len - 1);
            var p1 : Int = RandBetweenInt(0, len - 1);
            
            var x : Int = a[p0];
            a[p0] = a[p1];
            a[p1] = x;
        }
        return a;
    }
    
    
    public static function DoLinkFromName(name : String)
    {
        if (name == "CycloManiacs")
        {
            DoLink("http://www.kongregate.com/games/LongAnimals/cyclomaniacs" + LicDef.referralString, "othergames");
        }
        if (name == "Zombooka")
        {
            DoLink("http://www.kongregate.com/games/robotJAM/flaming-zombooka" + LicDef.referralString, "othergames");
        }
        if (name == "SoccerBalls")
        {
            DoLink("http://www.kongregate.com/games/turboNuke/soccer-balls" + LicDef.referralString, "othergames");
        }
        if (name == "Zombooka2")
        {
            DoLink("http://www.kongregate.com/games/turboNuke/flaming-zombooka-2" + LicDef.referralString, "othergames");
        }
        if (name == "CoasterRacer")
        {
            DoLink("http://www.kongregate.com/games/LongAnimals/coaster-racer" + LicDef.referralString, "othergames");
        }
        if (name == "SkiManiacs")
        {
            DoLink("http://www.kongregate.com/games/LongAnimals/ski-maniacs" + LicDef.referralString, "othergames");
        }
        if (name == "Toxers")
        {
            DoLink("http://www.kongregate.com/games/Rob_Almighty/toxers" + LicDef.referralString, "othergames");
        }
        if (name == "HarryQuantum")
        {
            DoLink("http://www.kongregate.com/games/LongAnimals/harry-quantum-tv-go-home" + LicDef.referralString, "othergames");
        }
        if (name == "DriftRunners1")
        {
            DoLink("http://www.kongregate.com/games/LongAnimals/drift-runners" + LicDef.referralString, "othergames");
        }
        if (name == "DriftRunners2")
        {
            DoLink("http://www.kongregate.com/games/LongAnimals/drift-runners-2" + LicDef.referralString, "othergames");
        }
        if (name == "NeonRace")
        {
            DoLink("http://www.kongregate.com/games/LongAnimals/neon-race" + LicDef.referralString, "othergames");
        }
        if (name == "GunExpress")
        {
            DoLink("http://www.kongregate.com/games/LongAnimals/gun-express" + LicDef.referralString, "othergames");
        }
        if (name == "HeatRush")
        {
            DoLink("http://www.kongregate.com/games/LongAnimals/heat-rush" + LicDef.referralString, "othergames");
        }
        
        if (name == "CycloManiacs2")
        {
            DoLink("http://www.kongregate.com/games/TurboNuke/cyclomaniacs-2" + LicDef.referralString, "othergames");
        }
        if (name == "CoasterRacer2")
        {
            DoLink("http://www.kongregate.com/games/LongAnimals/coaster-racer-2" + LicDef.referralString, "othergames");
        }
        if (name == "FormulaRacer")
        {
            DoLink("http://www.kongregate.com/games/TurboNuke/formula-racer" + LicDef.referralString, "othergames");
        }
        if (name == "Zomgies2")
        {
            DoLink("http://www.kongregate.com/games/LongAnimals/zomgies-2" + LicDef.referralString, "othergames");
        }
        if (name == "CorporationInc")
        {
            DoLink("http://www.kongregate.com/games/ArmorGames/corporation-inc" + LicDef.referralString, "othergames");
        }
        if (name == "SovietGiraffe")
        {
            DoLink("http://www.kongregate.com/games/ArmorGames/soviet-rocket-giraffe-go-go-go" + LicDef.referralString, "othergames");
        }
        if (name == "EleQuest")
        {
            DoLink("http://www.kongregate.com/games/ArmorGames/elephant-quest" + LicDef.referralString, "othergames");
        }
        if (name == "SushiCat2")
        {
            DoLink("http://www.kongregate.com/games/ArmorGames/sushi-cat-2" + LicDef.referralString, "othergames");
        }
        if (name == "GrandPrixGo")
        {
            DoLink("http://www.kongregate.com/games/TurboNuke/grand-prix-go" + LicDef.referralString, "othergames");
        }
        if (name == "SpacePunkRacer")
        {
            DoLink("http://www.kongregate.com/games/LongAnimals/space-punk-racer" + LicDef.referralString, "othergames");
        }
        if (name == "BasketBalls")
        {
            DoLink("http://www.kongregate.com/games/TurboNuke/basketballs" + LicDef.referralString, "othergames");
        }
        if (name == "NinjaAcademy")
        {
            DoLink("http://www.kongregate.com/games/LongAnimals/sticky-ninja-academy" + LicDef.referralString, "othergames");
        }
        if (name == "FlamingZombooka3")
        {
            DoLink("http://www.kongregate.com/games/TurboNuke/flaming-zombooka-3-carnival" + LicDef.referralString, "othergames");
        }
        if (name == "Offroaders")
        {
            DoLink("http://www.kongregate.com/games/TurboNuke/offroaders" + LicDef.referralString, "othergames");
        }
        if (name == "HotRod")
        {
            DoLink("http://www.kongregate.com/games/TurboNuke/rod-hots-hot-rod-racing" + LicDef.referralString, "othergames");
        }
        if (name == "NeonRace2")
        {
            DoLink("http://www.kongregate.com/games/LongAnimals/neon-race-2" + LicDef.referralString, "othergames");
        }
        if (name == "HarryQuantum2")
        {
            DoLink("http://www.kongregate.com/games/TurboNuke/harry-quantum-2" + LicDef.referralString, "othergames");
        }
        if (name == "BasketBallsLevelPack")
        {
            DoLink("http://www.kongregate.com/games/TurboNuke/basketballs-level-pack" + LicDef.referralString, "othergames");
        }
        if (name == "FormulaRacer2012")
        {
            DoLink("http://www.kongregate.com/games/TurboNuke/formula-racer-2012" + LicDef.referralString, "othergames");
        }
        if (name == "TokyoGuineaPop")
        {
            DoLink("http://www.kongregate.com/games/LongAnimals/tokyo-guinea-pop" + LicDef.referralString, "othergames");
        }
        if (name == "TurboGolf")
        {
            DoLink("http://www.kongregate.com/games/TurboNuke/turbo-golf" + LicDef.referralString, "othergames");
        }
        if (name == "DriftRunners3D")
        {
            DoLink("http://www.kongregate.com/games/LongAnimals/drift-runners-3d" + LicDef.referralString, "othergames");
        }
        if (name == "MuscleCars")
        {
            DoLink("http://www.kongregate.com/games/TurboNuke/v8-muscle-cars" + LicDef.referralString, "othergames");
        }
        if (name == "AmericanRacing")
        {
            DoLink("http://www.kongregate.com/games/TurboNuke/american-racing" + LicDef.referralString, "othergames");
        }
    }
    
    public static function DoLink(_url : String, _from : String)
    {
        flash.Lib.getURL(new URLRequest(_url), "_blank");
    }
    
    public static function OtherGamesPanel_ClickGameText(e : MouseEvent)
    {
        var name : String = (untyped e.currentTarget).linkName;
        DoLinkFromName(name);
    }
    
    
    public static function OtherGamesPanel_ClickGame(e : MouseEvent)
    {
        var name : String = e.currentTarget.name;
        
        var str : String = name.substr(4);
        var id : Int = as3hx.Compat.parseInt(str);
        
        var buttonO : Dynamic = null;
        
        for (o in otherGamesList)
        {
            if (o.button == name)
            {
                buttonO = o;
            }
        }
        
        DoLinkFromName(buttonO.name);
    }
}


