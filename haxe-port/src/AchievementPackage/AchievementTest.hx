package achievementPackage;


/**
	 * ...
	 * @author LongAnimals
	 */
class AchievementTest
{
    public var functionName : String;
    public var functionParams : String;
    
    public var precalcedParamNames : Array<Dynamic>;
    public var precalcedParamValues : Array<Dynamic>;
    
    public function new()
    {
    }
    
    
    public function PreCalc()
    {
        Utils.GetParams(functionParams);
        
        precalcedParamNames = [];
        for (s/* AS3HX WARNING could not determine type for var: s exp: EField(EIdent(Utils),paramNames) type: null */ in Utils.paramNames)
        {
            precalcedParamNames.push(s);
        }
        
        precalcedParamValues = [];
        for (s/* AS3HX WARNING could not determine type for var: s exp: EField(EIdent(Utils),paramValues) type: null */ in Utils.paramValues)
        {
            precalcedParamValues.push(s);
        }
    }
}


