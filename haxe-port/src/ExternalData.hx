import haxe.Constraints.Function;
import flash.events.Event;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.*;
import flash.system.System;

/**
	* ...
	* @author Default
	*/
class ExternalData
{
    public static var loadExternalLevels : Bool = false;
    
    
    public function new()
    {
    }
    
    
    public static function OutputString(s : String)
    {
        System.setClipboard(s);
    }
    
    public static var xml : FastXML;
    public static var levelsXml : FastXML;
    
    
    
    
    @:meta(Embed(source="../bin/SoccerBalls2_Objects_Data.xml",mimeType="application/octet-stream"))

    public static var class_Data : Class<Dynamic>;
    @:meta(Embed(source="../bin/SoccerBalls2_Levels_Data.xml",mimeType="application/octet-stream"))

    public static var class_Levels : Class<Dynamic>;
    @:meta(Embed(source="../bin/SoccerBalls2_Levels_Julian_Data.xml",mimeType="application/octet-stream"))

    public static var class_Levels1 : Class<Dynamic>;
    @:meta(Embed(source="../bin/SoccerBalls2_Levels_Rob_Data.xml",mimeType="application/octet-stream"))

    public static var class_Levels2 : Class<Dynamic>;
    @:meta(Embed(source="../bin/SoccerBalls2_Levels_Testbed_Data.xml",mimeType="application/octet-stream"))

    public static var class_Levels3 : Class<Dynamic>;
    
    
    public static var xmlLoader : URLLoader;
    public static var cb : Function;
    public static function Load(_cb : Function)
    {
        cb = _cb;
        
        if (loadExternalLevels)
        {
            FastXML.ignoreWhitespace = true;
            xml = try cast(new FastXML(Type.createInstance(class_Data, [])), FastXML) catch(e:Dynamic) null;
            
            xmlLoader = new URLLoader();
            xmlLoader.addEventListener(Event.COMPLETE, levelXmlLoaded, false, 0, true);
            xmlLoader.load(new URLRequest("SoccerBalls2_Levels_Cathy_Data.xml"));
        }
        else
        {
            XmlAllLoadedInternal();
        }
    }
    
    public static function XmlAllLoadedInternal()
    {
        var i : Int;
        FastXML.ignoreWhitespace = true;
        
        xml = try cast(new FastXML(Type.createInstance(class_Data, [])), FastXML) catch(e:Dynamic) null;
        
        levelsXml = try cast(new FastXML(Type.createInstance(class_Levels, [])), FastXML) catch(e:Dynamic) null;
        var levelsXml1 : FastXML = try cast(new FastXML(Type.createInstance(class_Levels1, [])), FastXML) catch(e:Dynamic) null;
        var levelsXml2 : FastXML = try cast(new FastXML(Type.createInstance(class_Levels2, [])), FastXML) catch(e:Dynamic) null;
        var levelsXml3 : FastXML = try cast(new FastXML(Type.createInstance(class_Levels3, [])), FastXML) catch(e:Dynamic) null;
        
        
        var num : Int = levelsXml.nodes.level.length();
        for (i in 0...num)
        {
            var xl : FastXML = levelsXml.nodes.level.get(i);
            var creatorAttr : String = "creator";
            xl.setAttribute("creatorAttr", "final");
        }
        var num : Int = levelsXml1.nodes.level.length();
        for (i in 0...num)
        {
            var xl : FastXML = levelsXml1.nodes.level.get(i);
            var creatorAttr : String = "creator";
            xl.setAttribute("creatorAttr", "julian");
        }
        var num : Int = levelsXml2.nodes.level.length();
        for (i in 0...num)
        {
            var xl : FastXML = levelsXml2.nodes.level.get(i);
            var creatorAttr : String = "creator";
            xl.setAttribute("creatorAttr", "rob");
        }
        
        /*
			var num:int = levelsXml3.level.length();
			for (var i:int = 0; i < num; i++)
			{
				var xl:XML = levelsXml3.level[i];
				var creatorAttr:String = "creator";
				xl.@[creatorAttr] = "testbed";
			}
			*/
        
        
        if (Game.onlyFinalLevels == false)
        {
            var num = levelsXml1.nodes.level.length();
            for (i in 0...num)
            {
                var xl : FastXML = levelsXml1.nodes.level.get(i);
                levelsXml.appendChild(xl.x);
            }
            var num = levelsXml2.nodes.level.length();
            for (i in 0...num)
            {
                var xl : FastXML = levelsXml2.nodes.level.get(i);
                levelsXml.appendChild(xl.x);
            }
        }
        
        if (Game.onlyFinalLevels)
        {
            levelsXml = try cast(new FastXML(Type.createInstance(class_Levels, [])), FastXML) catch(e:Dynamic) null;
        }
        
        
        
        GetConstants();
        cb();
    }
    
    
    public static var constants : Dynamic;
    public static var gameconstants : Dynamic;
    public static function GetConstants()
    {
        constants = {};
        var num = xml.node.constants.nodes.constant.length();
        for (i in 0...num)
        {
            var vx : FastXML = xml.node.constants.nodes.constant.get(i);
            Reflect.setField(constants, Std.string(vx.att.name), vx.att.value);
        }
        
        gameconstants = {};
        var num = xml.node.gameconstants.nodes.constant.length();
        for (i in 0...num)
        {
            var vx : FastXML = xml.node.gameconstants.nodes.constant.get(i);
            Reflect.setField(gameconstants, Std.string(vx.att.name), vx.att.value);
        }
    }
    
    public static function dataXmlLoaded(e : Event)
    {
        var i : Int;
        FastXML.ignoreWhitespace = true;
        levelsXml = new FastXML(e.target.data);
        
        
        GetConstants();
        cb();
    }
    public static function levelXmlLoaded(e : Event)
    {
        var i : Int;
        FastXML.ignoreWhitespace = true;
        
        levelsXml = try cast(new FastXML(e.target.data), FastXML) catch(e:Dynamic) null;
        
        GetConstants();
        
        cb();
    }
    public static var ExternalData_static_initializer = {
        if (false == true)
        {
            loadExternalLevels = true;
        };
        true;
    }

}



