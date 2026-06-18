import haxe.Constraints.Function;
import flash.display.Graphics;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.display.StageQuality;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.Texture;
import flash.events.*;
import flash.filters.DropShadowFilter;
import flash.text.TextField;
import flash.media.Sound;
import flash.net.URLRequest;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.*;
import flash.display.Loader;
import flash.text.TextFormat;
import flash.text.TextFieldAutoSize;

import licPackage.LicDef;

class DisplayObj
{
    public var frames : Array<DisplayObjFrame>;
    public var frame : Int = 0;
    public var flags : String;
    public var labels : Array<Dynamic>;
    public var name : String;
    public var origMC : MovieClip;
    public var origName : String;
    
    
    public function Load(x : FastXML)
    {
        frame = 0;
        flags = x.att.flags;
        name = x.att.name;
        origName = x.att.origName;
        origMC = null;
        labels = [];
        frames = [];
        
        for (i in 0...x.nodes.frame.length())
        {
            var x1 : FastXML = x.nodes.frame.get(i);
            var f : DisplayObjFrame = new DisplayObjFrame();
            f.Load(x1);
            frames.push(f);
        }
    }
    public function Save() : String
    {
        var s : String = "";
        s += "<object ";
        s += XmlHelper.Attr("flags", flags);
        s += XmlHelper.Attr("name", name);
        s += XmlHelper.Attr("origName", origName);
        
        s += ">\n";
        for (dof in frames)
        {
            s += dof.Save();
        }
        
        s += "</object>\n";
        
        
        
        return s;
    }
    
    public function new(mc : MovieClip, scale : Float, _flags : String = "", _frameCB : Function = null, _name : String = "")
    {
        labels = [];
        flags = _flags;
        frame = 0;
        if (mc != null)
        {
            CreateBitmapsFromMovieClip(mc, flags, _frameCB, scale, _name);
            name = mc.name;
        }
        origMC = mc;
        origName = _name;
    }
    
    
    public function CreateFont(tf : TextFormat) : Void
    {
        frames = [];
        
        var i : Int = 0;        var j : Int = 0;        var x0 : Int = 0;        var y0 : Int = 0;        var mat : Matrix = new Matrix();
        var rect : Rectangle = null;        var B : Bitmap = null;        var BD : BitmapData = null;        
        for (i in 0...255)
        {
            var t : TextField = new TextField();
            t.textColor = 0xffffffff;
            t.selectable = false;
            // device-font path: the game font is a browser FontFace (GameFont / Komika Axis), not an
            // openfl-registered embedded font, so embedFonts must be false for the family to resolve.
            t.embedFonts = false;
            t.autoSize = TextFieldAutoSize.LEFT;
            t.x = 0;
            t.y = 0;
            
            
            
            t.text = String.fromCharCode(i);
            t.setTextFormat(tf);
            
            var dof = new DisplayObjFrame();
            
            rect = t.getBounds(null);
            mat.identity();
            mat.translate(-rect.x, -rect.y);
            
            dof.xoffset = 0;
            dof.yoffset = 0;
            
            BD = new BitmapData(Std.int(rect.width), Std.int(rect.height), true, 0);
            BD.draw(t, mat, null, null, null, true);
            
            BD.applyFilter(BD, BD.rect, Defs.pointZero, new DropShadowFilter(3, 45, 0, 1, 2, 2, 3, 3));
            dof.bitmapData = BD;
            
            dof.sourceRect = new Rectangle(0, 0, BD.width, BD.height);
            dof.point = new Point(0, 0);
            
            frames.push(dof);
            
            
            
            
            
            TexturePages.AddDobjFrame(dof);
        }
    }
    
    public function CreateBitmapsFromMovieClip(mc : MovieClip, flags : String, _frameCB : Function = null, scale : Float = 1, _name : String = "") : Void
    {
        var scl : Float = 1;
        
        
        
        
        
        frames = [];
        var i : Int = 0;        var j : Int = 0;        var x0 : Int = 0;        var y0 : Int = 0;        var mat : Matrix = new Matrix();
        var rect : Rectangle = null;        var B : Bitmap = null;        var BD : BitmapData = null;        var B1 : Bitmap = null;        var BD1 : BitmapData = null;        
        mc.gotoAndStop(1);
        
        
        var totalFrames : Int = mc.totalFrames;
        
        
        for (i in 0...totalFrames)
        {
            if (_frameCB != null)
            {
                _frameCB(mc);
            }
            if (mc.currentFrameLabel != null)
            {
                var o : Dynamic = {};
                o.labelName = mc.currentFrameLabel;
                o.frameIndex = i;
                labels.push(o);
            }
            
            
            var dof : DisplayObjFrame = new DisplayObjFrame();
            
            rect = mc.getBounds(null);
            
            
            
            
            
            rect.x = (rect.x * scale);
            rect.y = (rect.y * scale);
            rect.width = (rect.width * scale);
            rect.height = (rect.height * scale);
            
            if (flags != "separatetexturepage")
            {
                rect.x -= 2;
                rect.y -= 2;
                rect.width += 4;
                rect.height += 4;
            }
            
            x0 = Std.int(rect.left);
            y0 = Std.int(rect.top);
            mat.identity();
            mat.scale(scale, scale);
            mat.translate(-x0, -y0);
            dof.xoffset = as3hx.Compat.parseFloat(x0);
            dof.yoffset = as3hx.Compat.parseFloat(y0);
            
            if (mc.width != 0 && mc.height != 0)
            {
                if (Game.use_texturepages == false || flags == "separatetexturepage")
                {
                    BD = new BitmapData(Std.int(rect.width), Std.int(rect.height), true, 0);
                    BD.draw(mc, mat, null, null, null, false);
                    
                    dof.bitmapData = BD;
                    dof.sourceRect = new Rectangle(0, 0, rect.width, rect.height);
                }
                else
                {
                    mat.scale(scl, scl);
                    BD = new BitmapData(Std.int(rect.width * scl), Std.int(rect.height * scl), true, 0);
                    BD.draw(mc, mat, null, null, null, false);
                    
                    dof.bitmapData = BD;
                    dof.sourceRect = new Rectangle(0, 0, rect.width, rect.height);
                    
                    dof.MakeVertexBuffer();
                }
            }
            else
            {
                dof.bitmapData = null;
                dof.sourceRect = new Rectangle(0, 0, 1, 1);
            }
            
            
            
            dof.point = new Point(0, 0);
            dof.parentDobj = this;
            
            dof.flags = flags;
            
            TexturePages.AddDobjFrame(dof);
            
            frames.push(dof);
            
            mc.nextFrame();
        }
    }
    
    public function NearestSuperiorPow2(i : Int) : Int
    {
        var a : Int = 2;
        for (x in 0...12)
        {
            if (i <= a)
            {
                return a;
            }
            a *= 2;
        }
        return a;
    }
    
    public function DisposeOf()
    {
        for (f in frames)
        {
            f.Remove();
        }
        origMC = null;
    }
    
    public function CreateBlankBitmapsFromMovieClip(mc : MovieClip, flags : Int, _frameCB : Function = null) : Void
    {
        frames = [];
        var i : Int = 0;        var j : Int = 0;        var x0 : Int = 0;        var y0 : Int = 0;        var mat : Matrix = new Matrix();
        var rect : Rectangle = null;        var B : Bitmap = null;        var BD : BitmapData = null;        var B1 : Bitmap = null;        var BD1 : BitmapData = null;        
        mc.gotoAndStop(1);
        
        for (i in 0...mc.totalFrames)
        {
            if (_frameCB != null)
            {
                _frameCB(mc);
            }
            if (mc.currentFrameLabel != null)
            {
                var o : Dynamic = {};
                o.labelName = mc.currentFrameLabel;
                o.frameIndex = i;
                labels.push(o);
            }
            
            
            var dof : DisplayObjFrame = new DisplayObjFrame();
            
            rect = mc.getRect(null);
            rect.x = Math.floor(rect.x);
            rect.y = Math.floor(rect.y);
            rect.width = Math.ceil(rect.width);
            rect.height = Math.ceil(rect.height);
            
            x0 = Std.int(rect.left);
            y0 = Std.int(rect.top);
            mat.identity();
            mat.translate(-x0, -y0);
            dof.xoffset = as3hx.Compat.parseFloat(x0);
            dof.yoffset = as3hx.Compat.parseFloat(y0);
            
            
            if (mc.width != 0 && mc.height != 0)
            {
                dof.sourceRect = new Rectangle(0, 0, 1, 1);
                dof.bitmapData = null;
            }
            else
            {
                dof.bitmapData = null;
                dof.sourceRect = new Rectangle(0, 0, 1, 1);
            }
            
            
            dof.point = new Point(0, 0);
            
            frames.push(dof);
            
            mc.nextFrame();
        }
    }
    
    public function CreateSingleBitmapdataFrame(frame : Int, _frameCB : Function = null) : Void
    {
        var i : Int = 0;        var j : Int = 0;        var x0 : Int = 0;        var y0 : Int = 0;        var mat : Matrix = new Matrix();
        var rect : Rectangle = null;        var B : Bitmap = null;        var BD : BitmapData = null;        var B1 : Bitmap = null;        var BD1 : BitmapData = null;        
        origMC.gotoAndStop(frame + 1);
        
        if (_frameCB != null)
        {
            _frameCB(origMC);
        }
        
        
        var dof : DisplayObjFrame = frames[frame];
        
        rect = origMC.getRect(null);
        rect.x = Math.floor(rect.x);
        rect.y = Math.floor(rect.y);
        rect.width = Math.ceil(rect.width);
        rect.height = Math.ceil(rect.height);
        
        x0 = Std.int(rect.left);
        y0 = Std.int(rect.top);
        mat.identity();
        mat.translate(-x0, -y0);
        dof.xoffset = as3hx.Compat.parseFloat(x0);
        dof.yoffset = as3hx.Compat.parseFloat(y0);
        
        
        if (origMC.width != 0 && origMC.height != 0)
        {
            BD = new BitmapData(Std.int(rect.width), Std.int(rect.height), true, 0);
            BD.draw(origMC, mat);
            dof.bitmapData = BD;
            dof.sourceRect = new Rectangle(0, 0, BD.width, BD.height);
        }
        else
        {
            dof.bitmapData = null;
            dof.sourceRect = new Rectangle(0, 0, 1, 1);
        }
        
        
        dof.point = new Point(0, 0);
    }
    
    
    
    public function GetFrame(_frame : Int) : DisplayObjFrame
    {
        var dof : DisplayObjFrame = frames[_frame];
        return dof;
    }
    public function GetBitmapData(_frame : Int) : BitmapData
    {
        var dof : DisplayObjFrame = frames[_frame];
        return dof.bitmapData;
    }
    public function GetSourceRect(_frame : Int) : Rectangle
    {
        var dof : DisplayObjFrame = frames[_frame];
        return dof.sourceRect;
    }
    public function GetWidth(_frame : Int) : Int
    {
        var dof : DisplayObjFrame = frames[_frame];
        return Std.int(dof.sourceRect.width);
    }
    public function GetHeight(_frame : Int) : Int
    {
        var dof : DisplayObjFrame = frames[_frame];
        return Std.int(dof.sourceRect.height);
    }
    public function GetXOffset(_frame : Int) : Float
    {
        var dof : DisplayObjFrame = frames[_frame];
        return dof.xoffset;
    }
    public function GetYOffset(_frame : Int) : Float
    {
        var dof : DisplayObjFrame = frames[_frame];
        return dof.yoffset;
    }
    
    public function GetNumFrames() : Int
    {
        return frames.length;
    }
    
    public function GetRandomFrame() : Int
    {
        return Utils.RandBetweenInt(0, frames.length - 1);
    }
    
    public function GetLabelAtThisFrame(frame : Int) : String
    {
        for (o in labels)
        {
            if (o.frameIndex == frame)
            {
                return o.labelName;
            }
        }
        return "";
    }
    
    public function GetFrameIndexLabel(label : String) : Int
    {
        for (o in labels)
        {
            if (o.labelName == label)
            {
                return o.frameIndex;
            }
        }
        Utils.traceerror("Error finding label " + label + " in dobj " + origName);
        return 0;
    }
    public function DoesFrameIndexLabelExist(label : String) : Bool
    {
        for (o in labels)
        {
            if (o.labelName == label)
            {
                return true;
            }
        }
        return false;
    }
    
    
    public var mat : Matrix = new Matrix();
    public function RenderAtRotScaled_Vector(_frame : Int, screenBD : BitmapData, xpos : Float, ypos : Float, renderScale : Float = 1.0, rot : Float = 0.0, ct : ColorTransform = null, _doSmooth : Bool = false, xflip : Bool = false)
    {
        origMC.gotoAndStop(_frame + 1);
        mat.identity();
        if (xflip)
        {
            mat.scale(-1, 1);
        }
        mat.rotate(rot);
        mat.scale(renderScale, renderScale);
        mat.translate(xpos, ypos);
        
        // GPU tile path: push the frame's rasterised bitmap rather than re-drawing the vector MC.
        var __vbd : BitmapData = frames[_frame].bitmapData;
        if (__vbd != null) TileRenderer.Push(__vbd, mat, ct);
    }


    public var sprite : Sprite = new Sprite();
    public function RenderAtRotScaled_VectorSprite(_frame : Int, screenBD : BitmapData, xpos : Float, ypos : Float, renderScale : Float = 1.0, rot : Float = 0.0, ct : ColorTransform = null, _doSmooth : Bool = false, xflip : Bool = false)
    {
        origMC.gotoAndStop(_frame + 1);
        mat.identity();
        if (xflip)
        {
            mat.scale(-1, 1);
        }
        mat.rotate(rot);
        mat.scale(renderScale, renderScale);
        mat.translate(xpos, ypos);
        
        var bd : BitmapData = frames[frame].bitmapData;
        if (bd != null) TileRenderer.Push(bd, mat, null);
    }
    
    
    public function RenderAtRotScaled(_frame : Int, screenBD : BitmapData, xpos : Float, ypos : Float, renderScale : Float = 1.0, rot : Float = 0.0, ct : ColorTransform = null, _doSmooth : Bool = false)
    {
        var dof : DisplayObjFrame = frames[_frame];
        dof.RenderAtRotScaled(screenBD, xpos, ypos, renderScale, rot, ct, _doSmooth);
    }
    public function RenderAtRotScaled_Xflip(_frame : Int, screenBD : BitmapData, xpos : Float, ypos : Float, renderScale : Float = 1.0, rot : Float = 0.0, ct : ColorTransform = null, _doSmooth : Bool = false)
    {
        var dof : DisplayObjFrame = frames[_frame];
        dof.RenderAtRotScaled_Xflip(screenBD, xpos, ypos, renderScale, rot, ct, _doSmooth);
    }
    public function RenderAtRotScaledWithOffset(_frame : Int, screenBD : BitmapData, xpos : Float, ypos : Float, renderScale : Float = 1.0, rot : Float = 0.0, ct : ColorTransform = null, _doSmooth : Bool = false, offsetX : Float = 0, offsetY : Float = 0)
    {
        var dof : DisplayObjFrame = frames[_frame];
        dof.RenderAtRotScaledWithOffset(screenBD, xpos, ypos, renderScale, rot, ct, _doSmooth, offsetX, offsetY);
    }
    
    public function RenderAtRotScaledAdditive(_frame : Int, screenBD : BitmapData, xpos : Float, ypos : Float, renderScale : Float = 1.0, rot : Float = 0.0, ct : ColorTransform = null, _doSmooth : Bool = false)
    {
        var dof : DisplayObjFrame = frames[_frame];
        dof.RenderAtRotScaledAdditive(screenBD, xpos, ypos, renderScale, rot, ct, _doSmooth);
    }
    
    public function RenderAtRotScaledLayer(_frame : Int, screenBD : BitmapData, xpos : Float, ypos : Float, renderScale : Float = 1.0, rot : Float = 0.0, ct : ColorTransform = null, _doSmooth : Bool = false)
    {
        var dof : DisplayObjFrame = frames[_frame];
        dof.RenderAtRotScaledLayer(screenBD, xpos, ypos, renderScale, rot, ct, _doSmooth);
    }
    
    public function RenderAtRotScaledOverlay(_frame : Int, screenBD : BitmapData, xpos : Float, ypos : Float, renderScale : Float = 1.0, rot : Float = 0.0, ct : ColorTransform = null, _doSmooth : Bool = false)
    {
        var dof : DisplayObjFrame = frames[_frame];
        dof.RenderAtRotScaledOverlay(screenBD, xpos, ypos, renderScale, rot, ct, _doSmooth);
    }
    
    public function RenderAt(_frame : Int, screenBD : BitmapData, xpos : Float, ypos : Float)
    {
        if (_frame >= frames.length)
        {
            return;
        }
        var dof : DisplayObjFrame = frames[_frame];
        dof.RenderAt(screenBD, xpos, ypos);
    }
    public function RenderAtXFlip(_frame : Int, screenBD : BitmapData, xpos : Float, ypos : Float)
    {
        var dof : DisplayObjFrame = frames[_frame];
        dof.RenderAtXFlip(screenBD, xpos, ypos);
    }
    
    
    
    public function HitTestRotScaled(_frame : Int, screenBD : BitmapData, xpos : Float, ypos : Float, renderScale : Float = 1.0, rot : Float = 0.0, ct : ColorTransform = null, _doSmooth : Bool = false) : Bool
    {
        var dof : DisplayObjFrame = frames[_frame];
        return dof.HitTestRotScaled(screenBD, xpos, ypos, renderScale, rot, ct, _doSmooth);
    }
    
    public function GetMaxFrames() : Int
    {
        return frames.length;
    }
    
    public function SetFrame(f : Int)
    {
        frame = f;
        if (frame < 0)
        {
            frame = 0;
        }
        if (frame >= frames.length)
        {
            frame = as3hx.Compat.parseInt(frames.length - 1);
        }
    }
}




