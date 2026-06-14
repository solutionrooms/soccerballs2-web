import flash.utils.ByteArray;

class Base64
{
    private static var encodeChars : Array<Dynamic> = 
        ["A", "B", "C", "D", "E", "F", "G", "H", 
        "I", "J", "K", "L", "M", "N", "O", "P", 
        "Q", "R", "S", "T", "U", "V", "W", "X", 
        "Y", "Z", "a", "b", "c", "d", "e", "f", 
        "g", "h", "i", "j", "k", "l", "m", "n", 
        "o", "p", "q", "r", "s", "t", "u", "v", 
        "w", "x", "y", "z", "0", "1", "2", "3", 
        "4", "5", "6", "7", "8", "9", "+", "/"
    ];
    private static var decodeChars : Array<Dynamic> = 
        [-1, -1, -1, -1, -1, -1, -1, -1, 
        -1, -1, -1, -1, -1, -1, -1, -1, 
        -1, -1, -1, -1, -1, -1, -1, -1, 
        -1, -1, -1, -1, -1, -1, -1, -1, 
        -1, -1, -1, -1, -1, -1, -1, -1, 
        -1, -1, -1, 62, -1, -1, -1, 63, 
        52, 53, 54, 55, 56, 57, 58, 59, 
        60, 61, -1, -1, -1, -1, -1, -1, 
        -1, 0, 1, 2, 3, 4, 5, 6, 
        7, 8, 9, 10, 11, 12, 13, 14, 
        15, 16, 17, 18, 19, 20, 21, 22, 
        23, 24, 25, -1, -1, -1, -1, -1, 
        -1, 26, 27, 28, 29, 30, 31, 32, 
        33, 34, 35, 36, 37, 38, 39, 40, 
        41, 42, 43, 44, 45, 46, 47, 48, 
        49, 50, 51, -1, -1, -1, -1, -1
    ];
    
    
    public static function encode(data : ByteArray) : String
    {
        var s : String = "";
        data.position = 0;
        
        var len : Int = data.length;
        for (i in 0...len)
        {
            var c : Int = data.readByte();
            s += ByteToHex(c);
        }
        return s;
    }
    public static function decode(str : String) : ByteArray
    {
        var ba : ByteArray = new ByteArray();
        var len : Int = str.length;
        
        var i : Int = 0;
        while (i < len)
        {
            var s : String = str.substr(i, 2);
            
            if (s != null && s != "")
            {
                var c : Int = HexToByte(s);
                ba.writeByte(c);
            }
            else
            {
                Utils.print("decodeERROR: " + s);
                return null;
            }
            i += 2;
        }
        return ba;
    }
    
    public static function ByteToHex(b : Int) : String
    {
        var hex : Array<Dynamic> = new Array<Dynamic>("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F");
        var u : Int = b >> 4;
        u = u & 0xf;
        var s : String = "";
        s += hex[u];
        b = b & 0xf;
        s += hex[b];
        return s;
    }
    
    public static function HexToByte(str : String) : Int
    {
        var hex : Array<Dynamic> = new Array<Dynamic>("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F");
        
        if (str == null)
        {
            return 0;
        }
        if (str.length != 2)
        {
            return 0;
        }
        
        var s0 : String = str.charAt(0);
        var s1 : String = str.charAt(1);
        
        var u0 : Int = 0;
        u0 = hex.lastIndexOf(s0);
        var u1 : Int = 0;
        u1 = hex.lastIndexOf(s1);
        
        var u : Int = 0;
        u = as3hx.Compat.parseInt(u0 << 4);
        u = u | u1;
        
        
        return u;
    }
    
    
    public static function encode1(data : ByteArray) : String
    {
        data.position = 0;
        var out : Array<Dynamic> = [];
        var i : Int = 0;
        var j : Int = 0;
        var r : Int = as3hx.Compat.parseInt(data.length % 3);
        var len : Int = as3hx.Compat.parseInt(data.length - r);
        var c : Int;
        while (i < len)
        {
            c = as3hx.Compat.parseInt(data[i++] << 16 | data[i++] << 8) | data[i++];
            out[j++] = encodeChars[c >> 18] + encodeChars[as3hx.Compat.parseInt(c >> 12) & 0x3f] + encodeChars[as3hx.Compat.parseInt(c >> 6) & 0x3f] + encodeChars[c & 0x3f];
        }
        if (r == 1)
        {
            c = data[i++];
            out[j++] = encodeChars[c >> 2] + encodeChars[(c & 0x03) << 4] + "==";
        }
        else if (r == 2)
        {
            c = as3hx.Compat.parseInt(data[i++] << 8) | data[i++];
            out[j++] = encodeChars[c >> 10] + encodeChars[as3hx.Compat.parseInt(c >> 4) & 0x3f] + encodeChars[(c & 0x0f) << 2] + "=";
        }
        
        return out.join("");
    }
    public static function decode1(str : String) : ByteArray
    {
        var c1 : Int;
        var c2 : Int;
        var c3 : Int;
        var c4 : Int;
        var i : Int;
        var len : Int;
        var out : ByteArray;
        len = str.length;
        i = 0;
        out = new ByteArray();
        while (i < len)
        {
            do
            {
                c1 = decodeChars[str.charCodeAt(i++) & 0xff];
            }
            while ((i < len && c1 == -1));
            if (c1 == -1)
            {
                break;
            }
            
            do
            {
                c2 = decodeChars[str.charCodeAt(i++) & 0xff];
            }
            while ((i < len && c2 == -1));
            if (c2 == -1)
            {
                break;
            }
            out.writeByte((c1 << 2) | ((c2 & 0x30) >> 4));
            
            do
            {
                c3 = str.charCodeAt(i++) & 0xff;
                if (c3 == 61)
                {
                    return out;
                }
                c3 = decodeChars[c3];
            }
            while ((i < len && c3 == -1));
            if (c3 == -1)
            {
                break;
            }
            out.writeByte(((c2 & 0x0f) << 4) | ((c3 & 0x3c) >> 2));
            
            do
            {
                c4 = str.charCodeAt(i++) & 0xff;
                if (c4 == 61)
                {
                    return out;
                }
                c4 = decodeChars[c4];
            }
            while ((i < len && c4 == -1));
            if (c4 == -1)
            {
                break;
            }
            out.writeByte(((c3 & 0x03) << 6) | c4);
        }
        return out;
    }

    public function new()
    {
    }
}

