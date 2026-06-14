
/**
	 * ...
	 * @author 
	 */
class S3dTriList
{
    public var indices : Array<Int>;
    public var vertices : Array<Float>;
    public var vertices_extra : Array<Float>;
    public function new()
    {
    }
    
    public function Init(numTriangles : Int, vertSize : Int, vertSize1 : Int)
    {
        indices = new Array<Int>();
        vertices = new Array<Float>();
        vertices_extra = new Array<Float>();
    }
}

