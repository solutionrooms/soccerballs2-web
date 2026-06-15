import flash.geom.Matrix;
import flash.geom.Point;

/**
	 * ...
	 * @author ...
	 */
class PhysObjShape
{
    public static inline var Type_Poly : Int = 0;
    public static inline var Type_Circle : Int = 1;
    
    public var type : Int = 0;
    public var name : String;
    public var collisionCategory : Int = 0;
    public var collisionMask : Int = 0;
    public var sensorCategory : Int = 0;
    public var sensorMask : Int = 0;
    
    public var materialName : String;
    
    public var density : Float;
    public var friction : Float;
    public var restitution : Float;
    
    public var poly_points : Array<Dynamic>;
    public var poly_rot : Float;
    
    public var circle_pos : Point;
    public var circle_radius : Float;
    
    public function new()
    {
        type = 0;
        name = "";
        poly_points = [];
        circle_pos = new Point();
        circle_radius = 0;
        poly_rot = 0;
        collisionCategory = 0;
        collisionMask = 0;
        materialName = "";
    }
    
    public function Caclulate()
    {
        if (type == Type_Poly)
        {
            var m : Matrix = new Matrix();
            m.rotate(poly_rot);
            var newpts : Array<Dynamic> = [];
            for (p in poly_points)
            {
                var p1 : Point = m.transformPoint(p);
                newpts.push(p1);
            }
            poly_points = newpts;
        }
    }
}


