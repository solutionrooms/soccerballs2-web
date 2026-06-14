package editorPackage;


/**
	 * ...
	 * @author LongAnimals
	 */
class ObjParameters
{
    public var list : Array<ObjParameter>;
    
    public function new()
    {
        list = new Array<ObjParameter>();
    }
    
    public function AddMultiParameters(otherParams : ObjParameters)
    {
        for (p/* AS3HX WARNING could not determine type for var: p exp: EField(EIdent(otherParams),list) type: null */ in otherParams.list)
        {
            var shouldAdd : Bool = true;
            for (i in 0...list.length)
            {
                var origp : ObjParameter = list[i];
                if (origp.name == p.name)
                {
                    if (origp.value == p.value)
                    {
                    }
                    else
                    {
                        origp.value = "----";
                        origp.multipleValues = true;
                    }
                    
                    shouldAdd = false;
                }
            }
            
            if (shouldAdd)
            {
                Add(p.name, p.value);
            }
        }
    }
    
    
    
    
    public function Clone() : ObjParameters
    {
        var op : ObjParameters = new ObjParameters();
        
        op.list = new Array<ObjParameter>();
        for (p in list)
        {
            op.list.push(p.Clone());
        }
        return op;
    }
    
    public function GetByIndex(index : Int) : ObjParameter
    {
        return list[index];
    }
    public function ClearAll()
    {
        list = new Array<ObjParameter>();
    }
    public function AddOrSet(name : String, value : String)
    {
        if (value == null)
        {
            value = ObjectParameters.GetDefault(name);
        }
        for (i in 0...list.length)
        {
            var p : ObjParameter = list[i];
            if (p.name == name)
            {
                p.value = value;
                return;
            }
        }
        Add(name, value);
    }
    public function Add(name : String, value : String)
    {
        if (value == null)
        {
            value = ObjectParameters.GetDefault(name);
        }
        var op : ObjParameter = new ObjParameter();
        op.name = name;
        op.value = value;
        list.push(op);
    }
    
    public function ToString() : String
    {
        var s : String = "";
        for (i in 0...list.length)
        {
            var p : ObjParameter = list[i];
            s += p.name;
            s += "=";
            s += p.value;
            if (i != list.length - 1)
            {
                s += ",";
            }
        }
        return s;
    }
    
    public function ValuesFromString(s : String)
    {
        Utils.GetParams(s);
        
        for (i in 0...list.length)
        {
            var p : ObjParameter = list[i];
            if (Utils.GetParamExists(p.name))
            {
                p.value = Utils.GetParamString(p.name, p.value);
            }
        }
    }
    
    public function CreateAllFromString(s : String)
    {
        Utils.GetParams(s);
        
        ClearAll();
        for (i in 0...Utils.paramNames.length)
        {
            AddOrSet(Utils.paramNames[i], Utils.paramValues[i]);
        }
    }
    
    public function SetValueBoolean(param : String, val : Bool)
    {
        var s : String = "false";
        if (val == true)
        {
            s = "true";
        }
        SetParam(param, s);
    }
    public function SetValueString(param : String, val : String)
    {
        SetParam(param, val);
    }
    public function SetValueNumber(param : String, val : Float)
    {
        var n : String = Std.string(val);
        SetParam(param, n);
    }
    public function SetValueInt(param : String, val : Int)
    {
        var i : String = Std.string(val);
        SetParam(param, i);
    }
    
    public function GetValueBoolean(param : String) : Bool
    {
        var s : String = GetParam(param);
        if (s == "true")
        {
            return true;
        }
        return false;
    }
    public function GetValueString(param : String, _default : String = "") : String
    {
        var s : String = GetParam(param);
        return s;
    }
    public function GetValueNumber(param : String) : Float
    {
        var s : String = GetParam(param);
        return as3hx.Compat.parseFloat(s);
    }
    public function GetValueInt(param : String, _default : Int = 0) : Int
    {
        var s : String = GetParam(param);
        return as3hx.Compat.parseInt(s);
    }
    
    
    
    private function Exists(param : String) : Bool
    {
        for (i in 0...list.length)
        {
            var p : ObjParameter = list[i];
            if (p.name == param)
            {
                return true;
            }
        }
        return false;
    }
    private function GetParam(param : String) : String
    {
        for (i in 0...list.length)
        {
            var p : ObjParameter = list[i];
            if (p.name == param)
            {
                return p.value;
            }
        }
        return "";
    }
    
    private function SetParam(param : String, val : String) : String
    {
        for (i in 0...list.length)
        {
            var p : ObjParameter = list[i];
            if (p.name == param)
            {
                p.value = val;
            }
        }
        return "";
    }
}


