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
    private var items : Array<DisplayObjFrame>;
    private var width : Int;
    private var height : Int;
    private var index : Int;
    
    private var cellSize : Int;
    private var currentCellX : Int;
    private var currentCellY : Int;
    
    private var bd : BitmapData;
    private var s3dTexture : Texture;
    
    public function new(_index : Int, _w : Int, _h : Int)
    {
        width = _w;
        height = _h;
        items = new Array<DisplayObjFrame>();
        index = _index;
    }
    
    private var firstNode : TexturePageNode = null;
    
    
    
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
        if (s3d.context3D == null)
        {
            return;
        }
        
        s3dTexture = s3d.context3D.createTexture(width, height, Context3DTextureFormat.BGRA, true);
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
        dof.s3dTexture.uploadFromBitmapData(bd);
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


