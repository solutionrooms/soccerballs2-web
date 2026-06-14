import editorPackage.PolyMaterials;

/**
	 * ...
	 * @author
	 */
class PolyDefs
{
    public static var instanceParams : Array<Dynamic>;
    public static var instanceParamsDefaults : Array<Dynamic>;
    
    public function new()
    {
    }
    
    public static function InitOnce()
    {
        instanceParams = new Array<Dynamic>();
        instanceParamsDefaults = new Array<Dynamic>();
        
        ObjectParameters.AddParam("line_material", "materiallist", PolyMaterials.GetNameByIndex(0), PolyMaterials.GetMaterialNameList());
        ObjectParameters.AddParamBool("line_spline", false);
        
        instanceParams.push("editor_layer");
        instanceParamsDefaults.push("1");
        instanceParams.push("game_layer");
        instanceParamsDefaults.push("Centre");
        instanceParams.push("line_material");
        instanceParamsDefaults.push(PolyMaterials.GetNameByIndex(0));
        instanceParams.push("line_spline");
        instanceParamsDefaults.push("false");
    }
}


