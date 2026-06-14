import nape.geom.Vec2;
import nape.phys.Body;
import nape.shape.Circle;

/**
	 * ...
	 * @author
	 */
class GOHelpers
{
    
    public function new()
    {
    }
    
    
    public static function DoExplosion(origGO : GameObj, centreX : Float, centreY : Float, maxRadius : Float, maxForce : Float)
    {
        var v : Vec = new Vec();
        for (go/* AS3HX WARNING could not determine type for var: go exp: EField(EIdent(GameObjects),objs) type: null */ in GameObjects.objs)
        {
            if (go.active && go != origGO)
            {
                var dx : Float = go.xpos - centreX;
                var dy : Float = go.ypos - centreY;
                
                v.SetFromDxDy(dx, dy);
                if (v.speed <= maxRadius)
                {
                    v.speed = maxForce;
                    go.ApplyImpulse(v.X(), v.Y());
                    
                    Utils.print(v.X() + " " + v.Y() + "   " + v.speed);
                }
            }
        }
    }
}


