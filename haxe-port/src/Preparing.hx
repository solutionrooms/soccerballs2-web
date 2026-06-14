import uIPackage.PreparingObject;

/**
	 * ...
	 * @author 
	 */
class Preparing
{
    
    
    
    public function new()
    {
    }
    
    
    public static function GetPreparingList() : Array<Dynamic>
    {
        if (false)
        {
            return preparingList_Mobile;
        }
        else
        {
            return preparingList;
        }
    }
    
    
    private static var isInitialised : Bool = false;
    
    public static function Modify()
    {
        for (i in 0...modifyList.length / 2)
        {
            var s0 : String = modifyList[(i * 2)];
            var s1 : String = modifyList[(i * 2) + 1];
            for (po/* AS3HX WARNING could not determine type for var: po exp: EIdent(preparingList) type: null */ in preparingList)
            {
                if (po.name == s0)
                {
                    po.data = s1;
                }
            }
        }
    }
    
    public static function DoPreparingObject(po : PreparingObject)
    {
        if (po.data != "skip")
        {
            if (po.type == "graphicobjects")
            {
                TexturePages.LoadGraphicObjectsForPreparing();
            }
            if (po.type == "texturepage")
            {
                TexturePages.CreateSingleTextureFileForPreparing(as3hx.Compat.parseInt(po.name));
            }
            else if (po.type == "gfx")
            {
                if (po.data == "separatetexturepage")
                {
                    GraphicObjects.Add(po.name, po.data);
                }
                else if (po.data == "notexturepage")
                {
                    GraphicObjects.Add(po.name, po.data);
                }
                else
                {
                    GraphicObjects.Add(po.name, "");
                }
            }
            else if (po.type == "font")
            {
                GraphicObjects.AddFont(new Font20(), 12, 0xffffffff, "font1");
            }
        }
    }
    
    public static function Start()
    {
        if (isInitialised)
        {
            return;
        }
        
        if (Game.loadTextureFiles)
        {
            TexturePages.Create();
            isInitialised = true;
            return;
        }
        
        
        Modify();
        
        for (i in 0...preparingList.length)
        {
            var po : PreparingObject = preparingList[i];
            cast((po), DoPreparingObject);
        }
        TexturePages.Create();
        isInitialised = true;
    }
    
    
    private static var modifyList : Array<Dynamic> = [
        "backgrounds", "separatetexturepage", 
        "FillSoil", "separatetexturepage", 
        "FillEdge", "separatetexturepage", 
        "Fill", "separatetexturepage", 
        "FillSoilEdge", "separatetexturepage", 
        "opponent", "skip", 
        "opponentWalk", "skip", 
        "player", "skip", 
        "ref", "skip", 
        "keeper", "skip"
    ];
    
    public static var preparingList_Mobile : Array<Dynamic> = [
        new PreparingObject("texturepage", "1"), 
        new PreparingObject("texturepage", "2"), 
        new PreparingObject("texturepage", "3"), 
        new PreparingObject("texturepage", "4"), 
        new PreparingObject("texturepage", "5"), 
        new PreparingObject("texturepage", "6"), 
        new PreparingObject("texturepage", "7"), 
        new PreparingObject("texturepage", "8"), 
        new PreparingObject("texturepage", "9"), 
        new PreparingObject("texturepage", "10"), 
        new PreparingObject("texturepage", "11"), 
        new PreparingObject("texturepage", "12"), 
        new PreparingObject("texturepage", "13"), 
        new PreparingObject("texturepage", "14"), 
        new PreparingObject("texturepage", "15"), 
        new PreparingObject("texturepage", "16"), 
        new PreparingObject("texturepage", "17"), 
        new PreparingObject("texturepage", "18"), 
        new PreparingObject("texturepage", "19"), 
        new PreparingObject("texturepage", "20"), 
        new PreparingObject("graphicobjects")
    ];
    
    
    public static var preparingList : Array<Dynamic> = [
        
        new PreparingObject("font", "font"), 
        
        
        new PreparingObject("gfx", "post_moveable"), 
        new PreparingObject("gfx", "walkthroughMarker"), 
        new PreparingObject("gfx", "conveyor"), 
        new PreparingObject("gfx", "sand_block"), 
        new PreparingObject("gfx", "jump_mark"), 
        new PreparingObject("gfx", "dressingObjects"), 
        new PreparingObject("gfx", "FastForwardLines"), 
        new PreparingObject("gfx", "powerArrow"), 
        new PreparingObject("gfx", "walkthroughArrow"), 
        new PreparingObject("gfx", "popup_trophy"), 
        new PreparingObject("gfx", "cannonSmoke"), 
        new PreparingObject("gfx", "player_arrow"), 
        new PreparingObject("gfx", "editor_walkthroughText"), 
        new PreparingObject("gfx", "editor_helpText"), 
        new PreparingObject("gfx", "popup_lastkick"), 
        new PreparingObject("gfx", "popup_pop"), 
        new PreparingObject("gfx", "popup_redcard"), 
        new PreparingObject("gfx", "popup_rays"), 
        new PreparingObject("gfx", "whiteRect"), 
        new PreparingObject("gfx", "editor_linker"), 
        new PreparingObject("gfx", "editor_patrolMarker"), 
        new PreparingObject("gfx", "editor_jumpArrow"), 
        new PreparingObject("gfx", "rocks"), 
        new PreparingObject("gfx", "goalposts"), 
        new PreparingObject("gfx", "cornerFlag"), 
        new PreparingObject("gfx", "bushes"), 
        new PreparingObject("gfx", "trees"), 
        new PreparingObject("gfx", "FillSoilEdge"), 
        new PreparingObject("gfx", "cloud"), 
        new PreparingObject("gfx", "opponent"), 
        new PreparingObject("gfx", "opponentWalk"), 
        new PreparingObject("gfx", "football"), 
        new PreparingObject("gfx", "football_gold"), 
        new PreparingObject("gfx", "spikyball"), 
        new PreparingObject("gfx", "football_tiny"), 
        new PreparingObject("gfx", "football_large"), 
        new PreparingObject("gfx", "football_veryLarge"), 
        new PreparingObject("gfx", "backgrounds"), 
        new PreparingObject("gfx", "Fill"), 
        new PreparingObject("gfx", "FillEdge"), 
        new PreparingObject("gfx", "woodenCrate1"), 
        new PreparingObject("gfx", "woodenCrate2"), 
        new PreparingObject("gfx", "woodenCrate1_part1"), 
        new PreparingObject("gfx", "woodenCrate1_part2"), 
        new PreparingObject("gfx", "woodenCrate1_part3"), 
        new PreparingObject("gfx", "woodenCrate1_part4"), 
        new PreparingObject("gfx", "woodenCrate1_part5"), 
        new PreparingObject("gfx", "woodenCrate1_part6"), 
        new PreparingObject("gfx", "woodenCrate1_part7"), 
        new PreparingObject("gfx", "woodenCrate1_part8"), 
        new PreparingObject("gfx", "ref_upperArm"), 
        new PreparingObject("gfx", "ref_foreArm"), 
        new PreparingObject("gfx", "ref_topLeg"), 
        new PreparingObject("gfx", "ref_foot"), 
        new PreparingObject("gfx", "ref_head"), 
        new PreparingObject("gfx", "ref_body"), 
        new PreparingObject("gfx", "ref"), 
        new PreparingObject("gfx", "woodenCrate2_part1"), 
        new PreparingObject("gfx", "woodenCrate2_part2"), 
        new PreparingObject("gfx", "woodenCrate2_part3"), 
        new PreparingObject("gfx", "woodenCrate2_part4"), 
        new PreparingObject("gfx", "woodenCrate2_part5"), 
        new PreparingObject("gfx", "woodenCrate2_part6"), 
        new PreparingObject("gfx", "woodenCrate2_part7"), 
        new PreparingObject("gfx", "woodenCrate2_part8"), 
        new PreparingObject("gfx", "starling"), 
        new PreparingObject("gfx", "starlingFly"), 
        new PreparingObject("gfx", "starling_feathers"), 
        new PreparingObject("gfx", "parrot"), 
        new PreparingObject("gfx", "parrotFly"), 
        new PreparingObject("gfx", "feathers"), 
        new PreparingObject("gfx", "keeper_upperArm"), 
        new PreparingObject("gfx", "keeper_foreArm"), 
        new PreparingObject("gfx", "keeper_topLeg"), 
        new PreparingObject("gfx", "keeper_foot"), 
        new PreparingObject("gfx", "keeper_head"), 
        new PreparingObject("gfx", "keeper_body"), 
        new PreparingObject("gfx", "keeper"), 
        new PreparingObject("gfx", "switch_Timer"), 
        new PreparingObject("gfx", "switch_Once"), 
        new PreparingObject("gfx", "switch_StopGo"), 
        new PreparingObject("gfx", "switch_weight"), 
        new PreparingObject("gfx", "switch_twoWay"), 
        new PreparingObject("gfx", "Switchable_Block_Disappear"), 
        new PreparingObject("gfx", "woodenPost0"), 
        new PreparingObject("gfx", "woodPost0_part1"), 
        new PreparingObject("gfx", "woodPost0_part2"), 
        new PreparingObject("gfx", "woodPost0_part3"), 
        new PreparingObject("gfx", "woodenPost0_fixed"), 
        new PreparingObject("gfx", "metalPost0"), 
        new PreparingObject("gfx", "metalPost0_fixed"), 
        new PreparingObject("gfx", "crate_metalSmall"), 
        new PreparingObject("gfx", "crate_metalLarge"), 
        new PreparingObject("gfx", "hinge"), 
        new PreparingObject("gfx", "Pickups"), 
        new PreparingObject("gfx", "Pickups_Trophies"), 
        new PreparingObject("gfx", "cannon_top"), 
        new PreparingObject("gfx", "cannon_base"), 
        new PreparingObject("gfx", "plusOneShot"), 
        new PreparingObject("gfx", "grass1"), 
        new PreparingObject("gfx", "grass4"), 
        new PreparingObject("gfx", "grass5"), 
        new PreparingObject("gfx", "grass6"), 
        new PreparingObject("gfx", "grass2"), 
        new PreparingObject("gfx", "grass3"), 
        new PreparingObject("gfx", "grass_fairway"), 
        new PreparingObject("gfx", "grass_rough"), 
        new PreparingObject("gfx", "popup_goal"), 
        new PreparingObject("gfx", "fx_smoke"), 
        new PreparingObject("gfx", "generalTimer"), 
        new PreparingObject("gfx", "fx_sparkles"), 
        new PreparingObject("gfx", "fx_sparkles_gold"), 
        new PreparingObject("gfx", "beachBall"), 
        new PreparingObject("gfx", "wormhole_small"), 
        new PreparingObject("gfx", "wormhole_large"), 
        new PreparingObject("gfx", "FillSoil"), 
        new PreparingObject("gfx", "tint_topArm"), 
        new PreparingObject("gfx", "player_toparmLines"), 
        new PreparingObject("gfx", "player_upperArm"), 
        new PreparingObject("gfx", "player_foreArm"), 
        new PreparingObject("gfx", "tint_topLeg"), 
        new PreparingObject("gfx", "player_shortLines"), 
        new PreparingObject("gfx", "player_topLeg"), 
        new PreparingObject("gfx", "tint_socks"), 
        new PreparingObject("gfx", "player_legLines"), 
        new PreparingObject("gfx", "player_foot"), 
        new PreparingObject("gfx", "player_head"), 
        new PreparingObject("gfx", "player_headBig"), 
        new PreparingObject("gfx", "tint_shirtbase"), 
        new PreparingObject("gfx", "tint_shirtStripes"), 
        new PreparingObject("gfx", "tint_hoopsEXP"), 
        new PreparingObject("gfx", "shirt_lines"), 
        new PreparingObject("gfx", "player_body"), 
        new PreparingObject("gfx", "player"), 
        new PreparingObject("gfx", "scenery_rocks"), 
        new PreparingObject("gfx", "dressingSoil"), 
        new PreparingObject("gfx", "Spawner"), 
        new PreparingObject("gfx", "circus_sign"), 
        new PreparingObject("gfx", "billboard5"), 
        new PreparingObject("gfx", "windblock"), 
        new PreparingObject("gfx", "Icecream")
    ];
}

