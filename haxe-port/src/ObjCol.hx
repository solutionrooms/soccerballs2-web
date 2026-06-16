import flash.geom.Point;

/**
	 * ...
	 * @author ...
	 */
class ObjCol
{
    public var bodies : Array<Dynamic>;
    public var joints : Array<Dynamic>;
    
    public function new()
    {
        bodies = [];
        joints = [];
    }
    
    public function AddJoint(_x : Float, _y : Float, _type : Int, b0 : Int, b1 : Int, vals : Array<Dynamic>)
    {
        var j : ObjColJoint = new ObjColJoint();
        j.x = _x;
        j.y = _y;
        j.type = _type;
        j.b0 = b0;
        j.b1 = b1;
        
        if (j.type == 0)
        {
            j.enableLimit = vals[0];
            j.lowerAngle = vals[1];
            j.upperAngle = vals[2];
            j.enableMotor = vals[3];
            j.motorSpeed = vals[4];
            j.maxMotorTorque = vals[5];
        }
        
        joints.push(j);
    }
    
    public function AddBody(_type : Int, a : Array<Dynamic>) : ObjColBody
    {
        var body : ObjColBody = new ObjColBody();
        body.type = _type;
        body.AddShape(a);
        bodies.push(body);
        return body;
    }
}





