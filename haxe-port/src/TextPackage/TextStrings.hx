package textPackage;

import flash.display.MovieClip;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.utils.Dictionary;

/**
	 * ...
	 * @author
	 */
class TextStrings
{
    
    @:meta(Embed(source="../../bin/TextStrings.xml",mimeType="application/octet-stream"))

    public static var class_embedded_XML : Class<Dynamic>;
    
    
    public static var xml : FastXML;
    public static var list : Array<TextString>;
    public static var dict : Dictionary<Dynamic, Dynamic>;
    
    public static var initialised : Bool = false;
    
    public static var LANGUAGE_EN : Int = 0;
    public static var LANGUAGE_FR : Int = 1;
    public static var LANGUAGE_DE : Int = 2;
    public static var LANGUAGE_PT : Int = 3;
    public static var LANGUAGE_ES : Int = 4;
    public static var LANGUAGE_NL : Int = 5;
    public static var LANGUAGE_TR : Int = 6;
    public static var LANGUAGE_SE : Int = 7;
    public static var LANGUAGE_IT : Int = 8;
    
    public static var languageLabels = [
        "en", "fr", "de", "pt", "es", "nl", "tr", "se", "it"];
    
    
    public static var currentLanguage : Int = LANGUAGE_EN;
    
    public static function GetLabelFromIndex(index : Int) : String
    {
        return languageLabels[index];
    }
    
    public static var supportedLanguages : Array<Dynamic> = [
        LANGUAGE_EN, 
        LANGUAGE_FR, 
        LANGUAGE_DE, 
        LANGUAGE_PT, 
        LANGUAGE_ES, 
        LANGUAGE_NL, 
        
        LANGUAGE_SE, 
        LANGUAGE_IT];
    
    public function new()
    {
    }
    
    public static function InitOnce()
    {
        list = [];
        dict = new Dictionary<Dynamic, Dynamic>();
        
        FastXML.ignoreWhitespace = true;
        xml = try cast(new FastXML(Type.createInstance(class_embedded_XML, [])), FastXML) catch(e:Dynamic) null;
        
        var num : Int = xml.nodes.textstring.length();
        for (i in 0...num)
        {
            var x : FastXML;
            x = xml.nodes.textstring.get(i);
            var adt : TextString = new TextString();
            adt.FromXML(x);
            list.push(adt);
            dict[adt.name.toLowerCase()] = adt;
        }
        initialised = true;
    }
    
    public static function GetLocalisedText(str : String) : String
    {
        var ts : TextString = dict[str.toLowerCase()];
        if (ts == null)
        {
            return str;
        }
        return ts.GetLocalisedText();
    }
    
    
    public static function GetTextString(str : String) : TextString
    {
        if (dict == null)
        {
            return null;
        }
        var ts : TextString = Reflect.field(dict, str);
        return ts;
    }
    
    
    public static function SetAnimatedButtonText(mc : MovieClip, strName : String = null)
    {
        if (initialised == false)
        {
            return;
        }
        var txt : TextString;
        if (strName == null)
        {
            if ((untyped mc).buttonName == null)
            {
                return;
            }
            var s : String = (untyped mc).buttonName.text.toLowerCase();
            s = StringTools.replace(s, "\r", "");
            s = StringTools.replace(s, "\n", "");
            
            txt = GetTextString(s);
        }
        else
        {
            txt = GetTextString(strName);
        }
        if (txt != null)
        {
            (untyped mc).buttonName.text = txt.GetLocalisedText();
        }
    }
    
    public static function ReplaceTextFieldText(tf : TextField, strName : String = null)
    {
        var txt : TextString;
        if (strName == null)
        {
            var s : String = tf.text.toLowerCase();
            s = StringTools.replace(s, "\r", "");
            s = StringTools.replace(s, "\n", "");
            
            txt = GetTextString(s);
        }
        else
        {
            txt = GetTextString(strName);
        }
        
        if (txt != null)
        {
            tf.text = txt.GetLocalisedText();
        }
        else if (strName != null)
        {
            tf.text = strName;
        }
        
        
        
        if (tf.text == "\n")
        {
            return;
        }
        if (tf.text == "\r")
        {
            return;
        }
        if (tf.text == "")
        {
            return;
        }
        tf.text = StringTools.replace(tf.text, "\r", "");
        tf.text = StringTools.replace(tf.text, "\n", "");
        
        
        var tFormat : TextFormat;
        
        var carryOn : Bool = true;
        do
        {
            carryOn = true;
            if (tf.numLines != 1)
            {
                tFormat = tf.getTextFormat();
                
                var size : Float = as3hx.Compat.parseFloat(tFormat.size);
                size--;
                tFormat.size = Std.int(size);
                tf.setTextFormat(tFormat);
                carryOn = false;
                if (size < 8)
                {
                    carryOn = true;
                }
            }
        }
        while ((carryOn == false));
    }
}


