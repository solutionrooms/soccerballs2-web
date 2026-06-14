package achievementPackage;


/**
	 * ...
	 * @author LongAnimals
	 */
class AchievementTest
{
    private var functionName : String;
    private var functionParams : String;
    
    private var precalcedParamNames : Array<Dynamic>;
    private var precalcedParamValues : Array<Dynamic>;
    
    public function new()
    {
    }
    
    
    public function PreCalc()
    {
        Utils.GetParams(functionParams);
        
        precalcedParamNames = new Array<Dynamic>();
        for (s/* AS3HX WARNING could not determine type for var: s exp: EField(EIdent(Utils),paramNames) type: null */ in Utils.paramNames)
        {
            precalcedParamNames.push(s);
        }
        
        precalcedParamValues = new Array<Dynamic>();
        for (s/* AS3HX WARNING could not determine type for var: s exp: EField(EIdent(Utils),paramValues) type: null */ in Utils.paramValues)
        {
            precalcedParamValues.push(s);
        }
    }
}


