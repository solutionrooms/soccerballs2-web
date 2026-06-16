import flash.display.BitmapData;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.Texture;
import flash.events.Event;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.net.FileReference;
import flash.utils.ByteArray;

/**
	 * ...
	 * @author
	 */
class TexturePage
{
    public var items : Array<DisplayObjFrame>;
    public var width : Int = 0;
    public var height : Int = 0;
    public var index : Int = 0;
    
    public var cellSize : Int = 0;
    public var currentCellX : Int = 0;
    public var currentCellY : Int = 0;
    
    public var bd : BitmapData;
    public var s3dTexture : Texture;
    
    public function new(_index : Int, _w : Int, _h : Int)
    {
        width = _w;
        height = _h;
        items = [];
        index = _index;
    }
    
    public var firstNode : TexturePageNode = null;
    
    
    
    public function AddDOF(dof : DisplayObjFrame) : Bool
    {
        if (firstNode == null)
        {
            firstNode = new TexturePageNode();
            firstNode.rect = new Rectangle(0, 0, width, height);
        }
        if (firstNode.Insert(dof) == null)
        {
            return false;
        }
        return true;
    }
    
    
    
    
    
    public function Create()
    {
        if (false == false)
        {
            return;
        }
        if ((null : openfl.display3D.Context3D) == null)
        {
            return;
        }
        
        s3dTexture = (null : openfl.display3D.Context3D).createTexture(width, height, Context3DTextureFormat.BGRA, true);
        bd = new BitmapData(width, height, true, 0);
        
        
        for (dof in items)
        {
            bd.copyPixels(dof.bitmapData, dof.bitmapData.rect, new Point(dof.sourceRect.x, dof.sourceRect.y));
            
            dof.u0 = 1 / as3hx.Compat.parseFloat(width) * dof.sourceRect.x;
            dof.v0 = 1 / as3hx.Compat.parseFloat(height) * dof.sourceRect.y;
            dof.u1 = 1 / as3hx.Compat.parseFloat(width) * (dof.sourceRect.x + dof.bitmapData.width);
            dof.v1 = 1 / as3hx.Compat.parseFloat(height) * (dof.sourceRect.y + dof.bitmapData.height);
            dof.s3dTexture = s3dTexture;
            dof.MakeVertexBuffer();
            
            dof.bitmapData.dispose();
            dof.bitmapData = null;
            dof.s3dTexPageIndex = index;
        }
        if (Game.saveTextureFiles == false)
        {
            bd.dispose();
        }
    }
    
    
    
    
    
    
    public function Save(index : Int)
    {
        if (Game.saveTextureFiles)
        {
        }
    }
}


