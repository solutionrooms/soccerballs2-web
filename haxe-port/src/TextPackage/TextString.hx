package textPackage;

import flash.utils.Dictionary;

/**
	 * ...
	 * @author 
	 */
class TextString
{
    private var name : String;
    private var dictionary : Dictionary;
    
    public function new()
    {
    }
    public function FromXML(x : FastXML)
    {
        dictionary = new Dictionary();
        
        name = XmlHelper.GetAttrString(x.att.name, "");
        var attrs : FastXMLList = x.node.attributes.innerData();
        for (label/* AS3HX WARNING could not determine type for var: label exp: EField(EIdent(TextStrings),languageLabels) type: null */ in TextStrings.languageLabels)
        {
            for (attr in attrs)
            {
                if (attr.node.name.innerData() == label)
                {
                    var s : String = attr.node.valueOf.innerData();
                    s = StringTools.replace(s, "ß", "ss");
                    
                    dictionary[label] = s;
                }
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

