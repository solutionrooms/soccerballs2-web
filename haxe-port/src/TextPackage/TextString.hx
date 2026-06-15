package textPackage;

import flash.utils.Dictionary;

/**
	 * ...
	 * @author
	 */
class TextString
{
    public var name : String;
    public var dictionary : Dictionary<Dynamic, Dynamic>;
    
    public function new()
    {
    }
    public function FromXML(x : FastXML)
    {
        dictionary = new Dictionary<Dynamic, Dynamic>();
        
        name = XmlHelper.GetAttrString(x.att.name, "");
        for (label in TextStrings.languageLabels)
        {
            var lbl : String = Std.string(label);
            if (x.x.exists(lbl))
            {
                var s : String = StringTools.replace(x.x.get(lbl), "ß", "ss");
                dictionary[lbl] = s;
            }
        }
        
        if (Reflect.field(dictionary, "en") == "")
        {
            Reflect.setField(dictionary, "en", name);
        }
    }
    
    public function GetLocalisedText() : String
    {
        return dictionary[TextStrings.languageLabels[TextStrings.currentLanguage]];
    }
}


