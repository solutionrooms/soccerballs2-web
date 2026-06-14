import flash.errors.Error;
import haxe.Constraints.Function;
import flash.display.BitmapDataChannel;
import flash.display.DisplayObject;
import flash.display.Loader;
import flash.display.MovieClip;
import flash.events.Event;
import flash.events.HTTPStatusEvent;
import flash.events.IEventDispatcher;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.media.ID3Info;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.system.ApplicationDomain;
import flash.system.LoaderContext;
import flash.system.System;
import flash.text.Font;
import flash.text.TextFormat;
import flash.utils.Dictionary;

/**
	* ...
	* @author Default
	*/
class GraphicObjects
{
    
    
    private static var dict : Dictionary;
    private static var displayObjs : Array<DisplayObj>;
    
    public function new()
    {
    }
    
    @:meta(Embed(source="../bin/GraphicObjectsLayout.xml",mimeType="application/octet-stream"))

    private static var class_vars : Class<Dynamic>;
    
    public static function Load()
    {
        var xml : FastXML = try cast(new FastXML(Type.createInstance(class_vars, [])), FastXML) catch(e:Dynamic) null;
        FastXML.ignoreWhitespace = true;
        
        InitOnce();
        
        for (i in 0...xml.node.graphicobjects.innerData.node.object.innerData.length())
        {
            var x : FastXML = xml.nodes.graphicobjects.node.object.innerData[i];
            var dobj : DisplayObj = new DisplayObj(null, 1);
            dobj.Load(x);
            dict[dobj.origName] = dobj;
            displayObjs.push(dobj);
        }
    }
    public static function Save()
    {
        var s : String = "";
        
        s += "<data>\n";
        s += "<graphicobjects>\n";
        
        for (dobj in displayObjs)
        {
            s += dobj.Save();
        }
        s += "</graphicobjects>\n";
        s += "</data>\n";
        
        trace(s);
        
        if (false)
        {
            var fl : File = File.desktopDirectory.resolvePath("GraphicObjectsLayout.xml");
            var fs : FileStream = new FileStream();
            
            try
            {
                fs.open(fl, FileMode.WRITE);
                fs.writeUTFBytes(s);
                fs.close();
            }
            catch (e : IOErrorEvent)
            {
                trace(e.errorID);
            }
        }
    }
    
    public static function InitOnce() : Void
    {
        displayObjs = new Array<DisplayObj>();
        dict = new Dictionary();
    }
    
    public static function GetDisplayObjByIndex(_index : Int) : DisplayObj
    {
        return displayObjs[_index];
    }
    
    public static function GetDisplayObjByName(_name : String) : DisplayObj
    {
        var dob : DisplayObj;
        
        dob = Reflect.field(dict, _name);
        if (dob != null)
        {
            return dob;
        }
        dob = cast((_name), Add);
        return dob;
    }
    
    
    
    
    public static function AddFont(font : Font, size : Int, color : Int, _name : String)
    {
        var tf : TextFormat = new TextFormat();
        tf.font = font.fontName;
        tf.size = size;
        tf.color = color;
        
        var fontDobj : DisplayObj;
        fontDobj = new DisplayObj(null, 0, "", null, _name);  // don't create moveiclip  
        fontDobj.CreateFont(tf);
        
        Reflect.setField(dict, _name, fontDobj);
        displayObjs.push(fontDobj);
    }
    
    
    
    
    public static function Create(mcName : String, _instName : String, flags : String = "", _callback : Function = null) : Int
    {
        var classRef : Class<Dynamic> = Type.getClass(Type.resolveClass(mcName));
        var mc : MovieClip = try cast(Type.createInstance(classRef, []), MovieClip) catch(e:Dynamic) null;
        if (_callback != null)
        {
            _callback(mc);
        }
        
        displayObjs.push(new DisplayObj(mc, 1, flags));
        return 0;
    }
    
    public static function AddDobjEmptyBitmap(name : String, width : Int, height : Int, transparent : Bool) : DisplayObj
    {
        var dobj : DisplayObj = new DisplayObj(null, 1);
        dobj.frames = new Array<DisplayObjFrame>();
        var dof : DisplayObjFrame = new DisplayObjFrame();
        dof.bitmapData = new BitmapData(width, height, transparent, 0);
        dof.xoffset = 0;
        dof.yoffset = 0;
        dof.sourceRect = new Rectangle(0, 0, width, height);
        dof.point = new Point(0, 0);
        dobj.frames.push(dof);
        
        displayObjs.push(dobj);
        return dobj;
    }
    
    
    public static function Add(mcName : String, flags : String = "", _instName : String = null) : DisplayObj
    {
        if (_instName == null)
        {
            _instName = mcName;
        }
        
        var classRef : Class<Dynamic> = null;
        
        try
        {
            classRef = Type.getClass(Type.resolveClass(mcName));
        }
        catch (e : Error)
        {
            classRef = null;
        }
        if (classRef != null)
        {
            var mc : MovieClip = try cast(Type.createInstance(classRef, []), MovieClip) catch(e:Dynamic) null;
            
            var dispobj : DisplayObj = new DisplayObj(mc, 1, flags, null, _instName);
            Reflect.setField(dict, _instName, dispobj);
            displayObjs.push(dispobj);
            return dispobj;
        }
        else
        {
            Utils.traceerror("Graphic Objects - can't find obj: " + mcName);
            displayObjs.push(null);
        }
        return null;
    }
    
    public static function GetFrameIndexLabel(gindex : Int, label : String) : Int
    {
        var dobj : DisplayObj = displayObjs[gindex];
        for (o/* AS3HX WARNING could not determine type for var: o exp: EField(EIdent(dobj),labels) type: null */ in dobj.labels)
        {
            if (o.labelName == label)
            {
                return o.frameIndex;
            }
        }
        return 0;
    }
    
    
    public static function GetPixelAt(gindex : Int, _frame : Int, _x : Int, _y : Int) : Int
    {
        var bd : BitmapData = displayObjs[gindex].frames[_frame].bitmapData;
        var pix : Int = bd.getPixel32(_x, _y);
        return pix;
    }
}


