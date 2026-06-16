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
        
        // English text is stored in the `name` attribute; the `en` attribute is empty in the data.
        // AS3 `if (dictionary["en"] == "") dictionary["en"] = name;` — as3hx mis-converted this to
        // Reflect.field/setField, which don't interoperate with the array-access writes above on a
        // Map-backed Dictionary, leaving dictionary["en"] null and crashing TextField.text=null later.
        // Use array access, and treat null/undefined like "" so en always resolves to the name.
        if (dictionary["en"] == "" || dictionary["en"] == null)
        {
            dictionary["en"] = name;
        }
    }
    
    public function GetLocalisedText() : String
    {
        // The data does not have a translation for every (string, language) pair. AS3/openfl both
        // throw #2007 if a TextField.text is set to null, and the original never hit it because the
        // active language always resolved; guarantee a non-null result by falling back to English and
        // then to the source name (which carries the English text). Keeps clean-data behaviour intact.
        var s : String = dictionary[TextStrings.languageLabels[TextStrings.currentLanguage]];
        if (s == null) s = dictionary["en"];
        if (s == null) s = name;
        return s;
    }
}


