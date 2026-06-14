import flash.display.BitmapData;
import flash.display.MovieClip;
import flash.display3D.Context3DTextureFormat;
import flash.geom.Rectangle;

/**
	 * ...
	 * @author 
	 */
class TexturePages
{
    private static var pages : Array<TexturePage>;
    private static var dobjFrames : Array<DisplayObjFrame>;
    
    
    private static var txSize : Int = 2048;
    public static var doBestFit : Bool = true;
    
    
    public function new()
    {
    }
    
    public static function InitOnce()
    {
        pages = new Array<TexturePage>();
        dobjFrames = new Array<DisplayObjFrame>();
    }
    
    public static function AddDobjFrame(_dobj : DisplayObjFrame)
    {
        dobjFrames.push(_dobj);
    }
    
    public static function SortWidth(x : DisplayObjFrame, y : DisplayObjFrame) : Float
    {
        if (x.bitmapData.width < y.bitmapData.width)
        {
            return 1;
        }
        if (x.bitmapData.width > y.bitmapData.width)
        {
            return -1;
        }
        return 0;
    }
    public static function SortHeight(x : DisplayObjFrame, y : DisplayObjFrame) : Float
    {
        if (x.bitmapData.height < y.bitmapData.height)
        {
            return 1;
        }
        if (x.bitmapData.height > y.bitmapData.height)
        {
            return -1;
        }
        return 0;
    }
    public static function SortArea(x : DisplayObjFrame, y : DisplayObjFrame) : Float
    {
        var a0 : Float = x.bitmapData.width * x.bitmapData.height;
        var a1 : Float = y.bitmapData.width * y.bitmapData.height;
        
        if (a0 < a1)
        {
            return 1;
        }
        if (a0 > a1)
        {
            return -1;
        }
        return 0;
    }
    
    public static var currentPage : TexturePage;
    
    public static function LoadGraphicObjectsForPreparing()
    {
        if (false)
        {
            GraphicObjects.Load();
        }
    }
    public static function CreateSingleTextureFileForPreparing(index : Int)
    {
        if (false)
        {
            var mc : MovieClip = new TexturePagesMC();
            mc.gotoAndStop(index);
            var currentTP : TexturePage = new TexturePage(index, txSize, txSize);
            
            var rect : Rectangle = mc.getBounds(null);
            var BD : BitmapData = new BitmapData((rect.width), (rect.height), true, 0);
            BD.draw(mc, null, null, null, null, false);
            currentTP.s3dTexture = s3d.context3D.createTexture(rect.width, rect.height, Context3DTextureFormat.BGRA, true);
            currentTP.s3dTexture.uploadFromBitmapData(BD);
            BD.dispose();
            BD = null;
            pages.push(currentTP);
            mc = null;
        }
    }
    
    public static function Create()
    {
        if (Game.use_texturepages == false)
        {
            return;
        }
        
        if (Game.loadTextureFiles)
        {
            return;
            tfIndex = 0;
            var mc : MovieClip = new TexturePagesMC();
            for (i in 1...mc.totalFrames + 1)
            {
                mc.gotoAndStop(i);
                var currentTP : TexturePage = new TexturePage(tfIndex++, txSize, txSize);
                
                var rect : Rectangle = mc.getBounds(null);
                var BD : BitmapData = new BitmapData((rect.width), (rect.height), true, 0);
                BD.draw(mc, null, null, null, null, false);
                currentTP.s3dTexture = s3d.context3D.createTexture(rect.width, rect.height, Context3DTextureFormat.BGRA, true);
                currentTP.s3dTexture.uploadFromBitmapData(BD);
                BD.dispose();
                BD = null;
                pages.push(currentTP);
            }
            mc = null;
            GraphicObjects.Load();
            return;
        }
        
        
        dobjFrames = dobjFrames.sort(SortArea);
        
        
        for (dof in dobjFrames)
        {
            if (dof.bitmapData == null)
            {
            }
        }
        
        var a : Int = 0;
        
        for (dof in dobjFrames)
        {
            dof.assignedToTexturePage = false;
        }
        
        
        var tfIndex : Int = 0;
        var currentTP : TexturePage = new TexturePage(tfIndex++, txSize, txSize);
        
        var a : Int = 0;
        for (dof in dobjFrames)
        {
            if (dof.assignedToTexturePage == false)
            {
                if (dof.flags != "separatetexturepage")
                {
                    currentPage = currentTP;
                    var assigned : Bool = currentTP.AddDOF(dof);
                    a++;
                    if (assigned == false)
                    {
                        currentTP.Create();
                        pages.push(currentTP);
                        currentTP = new TexturePage(tfIndex++, txSize, txSize);
                        currentTP.AddDOF(dof);
                    }
                    
                    Utils.print("frame " + a);
                }
            }
        }
        currentTP.Create();
        pages.push(currentTP);
        
        for (dof in dobjFrames)
        {
            if (dof.assignedToTexturePage == false)
            {
                if (dof.flags == "separatetexturepage")
                {
                    var w : Int = dof.NearestSuperiorPow2(dof.sourceRect.width);
                    var h : Int = dof.NearestSuperiorPow2(dof.sourceRect.height);
                    
                    currentTP = new TexturePage(tfIndex++, w, h);
                    currentPage = currentTP;
                    
                    currentTP.AddDOF(dof);
                    currentTP.Create();
                    pages.push(currentTP);
                }
            }
        }
        
        
        var index : Int = 0;
        for (tp in pages)
        {
            tp.Save(index);
            index++;
        }
        
        
        for (dof in dobjFrames)
        {
        }
        Utils.traceerror("num frames: " + dobjFrames.length + "    num pages: " + pages.length);
        
        if (Game.saveTextureFiles)
        {
            GraphicObjects.Save();
        }
        
        Utils.traceerror("A num objects: " + GraphicObjects.displayObjs.length);
        
        
        Utils.traceerror("B num objects: " + GraphicObjects.displayObjs.length);
        var a : Int = 0;
    }
}

