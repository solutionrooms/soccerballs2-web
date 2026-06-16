import flash.display3D.textures.Texture;
import flash.geom.Matrix3D;

/**
	 * ...
	 * @author
	 */
class S3dSpr
{
    public var type : Int = 0;
    
    public var indices : Array<Int>;
    public var vertices : Array<Float>;
    public var verticesTransformed : Array<Float>;
    public var verticesExtra : Array<Float>;
    
    public var texture : Texture;
    public var x0 : Float;
    public var x1 : Float;
    public var y0 : Float;
    public var y1 : Float;
    public var rot : Float;
    public var u0 : Float;
    public var v0 : Float;
    public var u1 : Float;
    public var v1 : Float;
    public var tintR : Float;
    public var tintG : Float;
    public var tintB : Float;
    public var z : Float;
    public var matrix : Matrix3D;
    public var rgba : Int = 0;
    
    public var sorted : Bool;
    
    public function new()
    {
        tintR = 1;
        tintG = 1;
        tintB = 1;
        matrix = new Matrix3D();
        rgba = 0;
    }
    
    public function ResetTint()
    {
        tintR = 1;
        tintG = 1;
        tintB = 1;
    }
    public function SetTint(r : Float, g : Float, b : Float)
    {
        tintR = r;
        tintG = g;
        tintB = b;
    }
    
    public function ClearMatrix()
    {
        matrix.identity();
    }
    public function SetMatrix(m : Matrix3D)
    {
        matrix.copyFrom(m);
    }
    public function InitRectangle(_tx : Texture, _z : Float, _x : Float, _y : Float, _x1 : Float, _y1 : Float, _dir : Float, _u0 : Float = 0, _v0 : Float = 0, _u1 : Float = 1, _v1 : Float = 1)
    {
        texture = _tx;
        x0 = _x;
        y0 = _y;
        x1 = _x1;
        y1 = _y1;
        rot = _dir;
        u0 = _u0;
        v0 = _v0;
        u1 = _u1;
        v1 = _v1;
        z = _z;
        type = 1;
    }
    
    public var qx0 : Float;
    public var qy0 : Float;
    public var qz0 : Float;
    public var qu0 : Float;
    public var qv0 : Float;
    public var qx1 : Float;
    public var qy1 : Float;
    public var qz1 : Float;
    public var qu1 : Float;
    public var qv1 : Float;
    public var qx2 : Float;
    public var qy2 : Float;
    public var qz2 : Float;
    public var qu2 : Float;
    public var qv2 : Float;
    public var qx3 : Float;
    public var qy3 : Float;
    public var qz3 : Float;
    public var qu3 : Float;
    public var qv3 : Float;
    public function InitQuad(_tx : Texture, _z : Float,
            _qx0 : Float, _qy0 : Float, _qz0 : Float, _qu0 : Float, _qv0 : Float,
            _qx1 : Float, _qy1 : Float, _qz1 : Float, _qu1 : Float, _qv1 : Float,
            _qx2 : Float, _qy2 : Float, _qz2 : Float, _qu2 : Float, _qv2 : Float,
            _qx3 : Float, _qy3 : Float, _qz3 : Float, _qu3 : Float, _qv3 : Float)
    {
        qx0 = _qx0;
        qy0 = _qy0;
        qz0 = _qz0;
        qu0 = _qu0;
        qv0 = _qv0;
        
        qx1 = _qx1;
        qy1 = _qy1;
        qz1 = _qz1;
        qu1 = _qu1;
        qv1 = _qv1;
        
        qx2 = _qx2;
        qy2 = _qy2;
        qz2 = _qz2;
        qu2 = _qu2;
        qv2 = _qv2;
        
        qx3 = _qx3;
        qy3 = _qy3;
        qz3 = _qz3;
        qu3 = _qu3;
        qv3 = _qv3;
        
        z = _z;
        texture = _tx;
        type = 2;
    }
    
    public function InitTriangle(_tx : Texture, _z : Float,
            _qx0 : Float, _qy0 : Float, _qz0 : Float, _qu0 : Float, _qv0 : Float,
            _qx1 : Float, _qy1 : Float, _qz1 : Float, _qu1 : Float, _qv1 : Float,
            _qx2 : Float, _qy2 : Float, _qz2 : Float, _qu2 : Float, _qv2 : Float)
    {
        qx0 = _qx0;
        qy0 = _qy0;
        qz0 = _qz0;
        qu0 = _qu0;
        qv0 = _qv0;
        
        qx1 = _qx1;
        qy1 = _qy1;
        qz1 = _qz1;
        qu1 = _qu1;
        qv1 = _qv1;
        
        qx2 = _qx2;
        qy2 = _qy2;
        qz2 = _qz2;
        qu2 = _qu2;
        qv2 = _qv2;
        
        z = _z;
        texture = _tx;
        type = 3;
    }
    
    
    public function InitTriangleList(_tx : Texture, _z : Float,
            _indices : Array<Int>, _vertices : Array<Float>, _verticesExtra : Array<Float>)
    {
        z = _z;
        texture = _tx;
        type = 4;
        indices = _indices;
        vertices = _vertices;
        verticesExtra = _verticesExtra;
    }
    
    public function InitLine(_tx : Texture, _z : Float, _x : Float, _y : Float, _x1 : Float, _y1 : Float, _u0 : Float = 0, _v0 : Float = 0, _u1 : Float = 1, _v1 : Float = 1)
    {
        texture = _tx;
        x0 = _x;
        y0 = _y;
        x1 = _x1;
        y1 = _y1;
        u0 = _u0;
        v0 = _v0;
        u1 = _u1;
        v1 = _v1;
        z = _z;
        type = 0;
    }
}


