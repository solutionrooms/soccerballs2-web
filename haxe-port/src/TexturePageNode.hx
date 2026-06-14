import flash.geom.Rectangle;

/**
	 * ...
	 * @author 
	 */
class TexturePageNode
{
    private var child : Array<TexturePageNode>;
    private var theDof : DisplayObjFrame;
    private var rect : Rectangle;
    public function new()
    {
        child = new Array<TexturePageNode>();
        child.push(null);
        child.push(null);
        
        theDof = null;
        rect = new Rectangle(0, 0, 1, 1);
    }
    
    private function DofFitsIntoRect(dof : DisplayObjFrame) : Bool
    {
        if (
            (dof.bitmapData.width <= rect.width) &&
            (dof.bitmapData.height <= rect.height))
        {
            return true;
        }
        return false;
    }
    private function DofFitsIntoRectPerfectly(dof : DisplayObjFrame) : Bool
    {
        if (
            (dof.bitmapData.width == rect.width) &&
            (dof.bitmapData.height == rect.height))
        {
            return true;
        }
        return false;
    }
    
    public function Insert(dof : DisplayObjFrame) : TexturePageNode
    {
        if (child[0] != null && child[1] != null)
        
        // isn't leaf{
            
            {
                var newNode : TexturePageNode = child[0].Insert(dof);
                if (newNode != null)
                {
                    return newNode;
                }
                
                return child[1].Insert(dof);
            }
        }
        else
        {
            if (theDof != null)
            {
                return null;
            }
            
            if (cast((dof), DofFitsIntoRect) == false)
            {
                return null;
            }
            
            if (cast((dof), DofFitsIntoRectPerfectly))
            {
                dof.sourceRect.copyFrom(rect);
                theDof = dof;
                
                TexturePages.currentPage.items.push(dof);
                dof.assignedToTexturePage = true;
                
                return this;
            }
            
            child[0] = new TexturePageNode();
            child[1] = new TexturePageNode();
            
            var bw : Int = dof.bitmapData.width;
            var bh : Int = dof.bitmapData.height;
            var dw : Float = rect.width - bw;
            var dh : Float = rect.height - bh;
            
            if (dw > dh)
            {
                child[0].rect = new Rectangle(rect.left, rect.top, bw, rect.height);
                child[1].rect = new Rectangle(rect.left + bw, rect.top, rect.width - bw, rect.height);
            }
            else
            {
                child[0].rect = new Rectangle(rect.left, rect.top, rect.width, bh);
                child[1].rect = new Rectangle(rect.left, rect.top + bh, rect.width, rect.height - bh);
            }
            
            return child[0].Insert(dof);
        }
    }
}

