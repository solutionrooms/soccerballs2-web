import flash.display.BlendMode;
import flash.display.MovieClip;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.Texture;
import flash.events.*;
import flash.text.TextField;
import flash.media.Sound;
import flash.net.URLRequest;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.*;
import flash.display.Loader;

class DisplayObjFrame
{
    
    public var bitmapData : BitmapData; // HD: rasterized at textureScale x (2x); GPU tile path draws it pre-scaled.
    // HD: cached 1x downscale of bitmapData for RAW consumers (beginBitmapFill terrain/poly fills, hitTest)
    // which read the bitmap's pixel dimensions directly. Built lazily by DisplayObj.GetBitmapData, so only
    // the few fill-material frames ever allocate it. Keeps fill patterns at their native (logical) size.
    public var bitmapDataLogical : BitmapData = null;
    public var xoffset : Float;
    public var yoffset : Float;
    // HD: bitmapData is rasterized at this multiple of the logical size (HD.SCALE in -Dhd; 1.0 otherwise).
    // The tile render matrices pre-scale by 1/textureScale so the 2x bitmap still draws at the native size.
    public var textureScale : Float = 1.0;
    public static var mat : Matrix = new Matrix();
    public static var colTrans : ColorTransform = new ColorTransform();
    public var sourceRect : Rectangle;
    public var point : Point;
    public var flags : String;
    
    public var s3dTexPageIndex : Int = 0;
    public var parentDobj : DisplayObj;
    public var s3dTexture : Texture;
    public var u0 : Float;
    public var v0 : Float;
    public var u1 : Float;
    public var v1 : Float;
    public var assignedToTexturePage : Bool;
    
    public var indices : Array<Int>;
    public var vertices : Array<Float>;
    public var vertices_extra : Array<Float>;
    public var vertices_transformed : Array<Float>;
    
    
    public function Load(x : FastXML)
    {
        flags = x.att.flags;
        xoffset = as3hx.Compat.parseFloat(x.att.xoffset);
        yoffset = as3hx.Compat.parseFloat(x.att.yoffset);
        sourceRect = new Rectangle();
        sourceRect.x = as3hx.Compat.parseFloat(x.att.sourceRectX);
        sourceRect.y = as3hx.Compat.parseFloat(x.att.sourceRectY);
        sourceRect.width = as3hx.Compat.parseFloat(x.att.sourceRectW);
        sourceRect.height = as3hx.Compat.parseFloat(x.att.sourceRectH);
        point = new Point();
        point.x = 0;
        point.y = 0;
        s3dTexPageIndex = as3hx.Compat.parseInt(x.att.s3dTexPageIndex);
        u0 = as3hx.Compat.parseFloat(x.att.u0);
        v0 = as3hx.Compat.parseFloat(x.att.v0);
        u1 = as3hx.Compat.parseFloat(x.att.u1);
        v1 = as3hx.Compat.parseFloat(x.att.v1);
        
        s3dTexture = TexturePages.pages[s3dTexPageIndex].s3dTexture;
        
        MakeVertexBuffer();
        assignedToTexturePage = true;
    }
    public function Save() : String
    {
        var s : String = "";
        s += "<frame ";
        s += XmlHelper.Attr("flags", flags);
        s += XmlHelper.Attr("xoffset", xoffset);
        s += XmlHelper.Attr("yoffset", yoffset);
        s += XmlHelper.Attr("sourceRectX", sourceRect.x);
        s += XmlHelper.Attr("sourceRectY", sourceRect.y);
        s += XmlHelper.Attr("sourceRectW", sourceRect.width);
        s += XmlHelper.Attr("sourceRectH", sourceRect.height);
        s += XmlHelper.Attr("pointX", point.x);
        s += XmlHelper.Attr("pointY", point.y);
        s += XmlHelper.Attr("s3dTexPageIndex", s3dTexPageIndex);
        s += XmlHelper.Attr("u0", u0);
        s += XmlHelper.Attr("v0", v0);
        s += XmlHelper.Attr("u1", u1);
        s += XmlHelper.Attr("v1", v1);
        s += "/>\n";
        return s;
    }
    
    public function new()
    {
        s3dTexture = null;
        flags = "";
    }
    
    public function Remove()
    {
        if (bitmapData != null)
        {
            bitmapData.dispose();
            bitmapData = null;
            sourceRect = null;
            point = null;
        }
    }
    
    public function MakeVertexBuffer()
    {
        var currentV : Int = 0;
        var currentVE : Int = 0;
        var currentI : Int = 0;
        
        vertices = [];
        vertices_transformed = [];
        vertices_extra = [];
        indices = [];
        
        
        
        
        vertices[currentV++] = 0;
        vertices[currentV++] = 0;
        vertices[currentV++] = 1;
        vertices_extra[currentVE++] = u0;
        vertices_extra[currentVE++] = v0;
        vertices_extra[currentVE++] = 1;
        vertices_extra[currentVE++] = 1;
        vertices_extra[currentVE++] = 1;
        
        vertices[currentV++] = sourceRect.width;
        vertices[currentV++] = 0;
        vertices[currentV++] = 1;
        vertices_extra[currentVE++] = u1;
        vertices_extra[currentVE++] = v0;
        vertices_extra[currentVE++] = 1;
        vertices_extra[currentVE++] = 1;
        vertices_extra[currentVE++] = 1;
        
        vertices[currentV++] = 0;
        vertices[currentV++] = sourceRect.height;
        vertices[currentV++] = 1;
        vertices_extra[currentVE++] = u0;
        vertices_extra[currentVE++] = v1;
        vertices_extra[currentVE++] = 1;
        vertices_extra[currentVE++] = 1;
        vertices_extra[currentVE++] = 1;
        
        vertices[currentV++] = sourceRect.width;
        vertices[currentV++] = sourceRect.height;
        vertices[currentV++] = 1;
        vertices_extra[currentVE++] = u1;
        vertices_extra[currentVE++] = v1;
        vertices_extra[currentVE++] = 1;
        vertices_extra[currentVE++] = 1;
        vertices_extra[currentVE++] = 1;
        
        
        indices[currentI++] = 0;
        indices[currentI++] = 1;
        indices[currentI++] = 2;
        indices[currentI++] = 1;
        indices[currentI++] = 3;
        indices[currentI++] = 2;
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
    
    
    public function ReUploadBitmap(bd : BitmapData)
    {
        bitmapData = bd;
    }
    
    public function CreateStandalone(bd : BitmapData, xoff : Float, yoff : Float, reuse : Bool = false)
    {
        if (bitmapData != null)
        {
            return;
        }
        bitmapData = bd;
        xoffset = 0;
        yoffset = 0;
        sourceRect = new Rectangle(0, 0, bd.width, bd.height);
        point = new Point(0, 0);
    }
    
    
    public var m3d : Matrix3D = new Matrix3D();
    public function RenderAt(screenBD : BitmapData, xpos : Float, ypos : Float) : Void
    {
        point.x = xpos + xoffset;
        point.y = ypos + yoffset;

        if (textureScale == 1.0)
        {
            TileRenderer.PushAt(bitmapData, point.x, point.y);
        }
        else if (bitmapData != null)
        {
            // HD: T x texture, draw at logical size — scale the bitmap pixels down by 1/T, then place.
            mat.identity();
            mat.scale(1 / textureScale, 1 / textureScale);
            mat.translate(point.x, point.y);
            TileRenderer.Push(bitmapData,mat, null);
        }
    }
    
    public function RenderAtXFlip(screenBD : BitmapData, xpos : Float, ypos : Float) : Void
    {
        mat.identity();
        
        mat.translate(xoffset, yoffset);
        mat.scale(-1.0, 1);
        mat.translate(xpos, ypos);
        
        
        {
            if (bitmapData != null)
            {
                TileRenderer.Push(bitmapData,mat, null);
            }
        }
    }
    
    
    public function HitTestRotScaled(screenBD : BitmapData, xpos : Float, ypos : Float, scale : Float = 1.0, rot : Float = 0.0, ct : ColorTransform = null, _doSmooth : Bool = false) : Bool
    {
        return screenBD.hitTest(new Point(0, 0), 255, bitmapData, new Point(xpos + xoffset, ypos + yoffset), 255);
    }
    
    
    
    public function RenderAtRotScaledWithOffset(screenBD : BitmapData, xpos : Float, ypos : Float, scale : Float = 1.0, rot : Float = 0.0, ct : ColorTransform = null, _doSmooth : Bool = false, offsetX : Float = 0, offsetY : Float = 0) : Void
    {
        mat.identity();
        mat.scale(1 / textureScale, 1 / textureScale); // HD: T x texture -> logical units (no-op when textureScale==1)
        mat.translate(xoffset, yoffset);
        mat.rotate(rot);
        mat.translate(-xoffset, -yoffset);
        
        mat.translate(offsetX, offsetY);
        mat.scale(scale, scale);
        mat.translate(-offsetX, -offsetY);
        mat.translate(xpos + (xoffset * scale), ypos + (yoffset * scale));
        
        
        if (bitmapData != null)
        {
            TileRenderer.Push(bitmapData,mat, ct);
        }
    }
    
    public static var z_azis : Vector3D = new Vector3D(0, 0, 1);
    
    public function RenderAtRotScaled(screenBD : BitmapData, xpos : Float, ypos : Float, scale : Float = 1.0, rot : Float = 0.0, ct : ColorTransform = null, _doSmooth : Bool = false) : Void
    {
        mat.identity();
        mat.scale(1 / textureScale, 1 / textureScale); // HD: T x texture -> logical units (no-op when textureScale==1)
        mat.translate(xoffset, yoffset);
        mat.rotate(rot);
        mat.translate(-xoffset, -yoffset);
        
        mat.scale(scale, scale);
        mat.translate(xpos + (xoffset * scale), ypos + (yoffset * scale));
        
        if (bitmapData != null)
        {
            TileRenderer.Push(bitmapData,mat, ct);
        }
    }
    
    public function RenderAtRotScaled_Xflip(screenBD : BitmapData, xpos : Float, ypos : Float, scale : Float = 1.0, rot : Float = 0.0, ct : ColorTransform = null, _doSmooth : Bool = false) : Void
    {
        mat.identity();
        mat.scale(1 / textureScale, 1 / textureScale); // HD: T x texture -> logical units (no-op when textureScale==1)
        mat.translate(xoffset, yoffset);
        mat.rotate(rot);
        mat.translate(-xoffset, -yoffset);
        
        mat.scale(scale, scale);
        mat.translate(xoffset * scale, yoffset * scale);
        mat.scale(-1.0, 1);
        mat.translate(xpos, ypos);
        
        if (bitmapData != null)
        {
            TileRenderer.Push(bitmapData,mat, ct);
        }
    }
    
    public function RenderAtRotScaledAdditive(screenBD : BitmapData, xpos : Float, ypos : Float, scale : Float = 1.0, rot : Float = 0.0, ct : ColorTransform = null, _doSmooth : Bool = false) : Void
    {
        mat.identity();
        mat.scale(1 / textureScale, 1 / textureScale); // HD: T x texture -> logical units (no-op when textureScale==1)
        mat.translate(xoffset, yoffset);
        mat.rotate(rot);
        mat.translate(-xoffset, -yoffset);
        
        mat.scale(scale, scale);
        mat.translate(xpos + (xoffset * scale), ypos + (yoffset * scale));
        
        if (bitmapData != null)
        {
            TileRenderer.Push(bitmapData,mat, null, BlendMode.ADD);
        }
    }
    
    
    
    public function RenderAtRotScaledLayer(screenBD : BitmapData, xpos : Float, ypos : Float, scale : Float = 1.0, rot : Float = 0.0, ct : ColorTransform = null, _doSmooth : Bool = false) : Void
    {
        mat.identity();
        mat.scale(1 / textureScale, 1 / textureScale); // HD: T x texture -> logical units (no-op when textureScale==1)
        mat.translate(xoffset, yoffset);
        mat.rotate(rot);
        mat.translate(-xoffset, -yoffset);
        
        mat.scale(scale, scale);
        mat.translate(xpos + (xoffset * scale), ypos + (yoffset * scale));
        
        if (bitmapData != null)
        {
            TileRenderer.Push(bitmapData,mat, null, BlendMode.LAYER);
        }
    }
    
    public function RenderAtRotScaledOverlay(screenBD : BitmapData, xpos : Float, ypos : Float, scale : Float = 1.0, rot : Float = 0.0, ct : ColorTransform = null, _doSmooth : Bool = false) : Void
    {
        mat.identity();
        mat.scale(1 / textureScale, 1 / textureScale); // HD: T x texture -> logical units (no-op when textureScale==1)
        mat.translate(xoffset, yoffset);
        mat.rotate(rot);
        mat.translate(-xoffset, -yoffset);
        
        mat.scale(scale, scale);
        mat.translate(xpos + (xoffset * scale), ypos + (yoffset * scale));
        
        if (bitmapData != null)
        {
            TileRenderer.Push(bitmapData,mat, null, BlendMode.OVERLAY);
        }
    }
    
    public function RenderAtRotScaled_SourceRect(screenBD : BitmapData, xpos : Float, ypos : Float, scale : Float = 1.0, rot : Float = 0.0, ct : ColorTransform = null, _doSmooth : Bool = false, sourceRect : Rectangle = null, xo : Int = 0, yo : Int = 0) : Void
    {
        mat.identity();
        mat.scale(1 / textureScale, 1 / textureScale); // HD: T x texture -> logical units (no-op when textureScale==1)
        mat.translate(xoffset, yoffset);
        mat.rotate(rot);
        mat.translate(-xoffset, -yoffset);
        
        mat.scale(scale, scale);
        mat.translate(xpos + ((xoffset - xo) * scale), ypos + ((yoffset - yo) * scale));
        
        sourceRect.x = xpos;
        sourceRect.y = ypos;
        
        if (bitmapData != null)
        {
            TileRenderer.Push(bitmapData,mat, ct); // (clipRect from the old draw is not reproduced on the GPU tile path)
        }
    }
}

