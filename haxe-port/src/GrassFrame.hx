import achievementPackage.Achievement;

/**
	 * ...
	 * @author 
	 */
class GrassFrame
{
    private var mcName : String;
    private var frameIndex : Int;
    private var dof : DisplayObjFrame;
    private var dofs : Array<DisplayObjFrame>;
    private var scales : Array<Float>;
    private var rots : Array<Int>;
    
    public function new(_index : Int, _name : String)
    {
        frameIndex = _index;
        mcName = _name;
        dofs = new Array<DisplayObjFrame>();
        scales = new Array<Float>();
        rots = new Array<Int>();
    }
    
    public function AddDof(dof : DisplayObjFrame, scale : Float, _rotint : Int)
    {
        dofs.push(dof);
        scales.push(scale);
        rots.push(_rotint);
    }
    
    public function GetNearestScaleFrame(scale : Float)
    {
        var bestI : Int = 0;
        var bestD : Float = 9999;
        for (i in 0...dofs.length)
        {
            var s : Float = scales[i];
            var d : Float = Math.abs(s - scale);
            if (d < bestD)
            {
                bestD = d;
                bestI = i;
            }
        }
        return bestI;
    }
}

