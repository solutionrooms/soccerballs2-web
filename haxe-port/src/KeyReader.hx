import flash.display.Stage;
import flash.events.KeyboardEvent;

/**
	* ...
	* @author Default
	*/
class KeyReader
{
    public static inline var KEY_RIGHT : Int = 39;
    public static inline var KEY_LEFT : Int = 37;
    public static inline var KEY_UP : Int = 38;
    public static inline var KEY_DOWN : Int = 40;
    public static inline var KEY_SPACE : Int = 32;
    public static inline var KEY_ENTER : Int = 13;
    public static inline var KEY_MINUS : Int = 189;
    public static inline var KEY_EQUALS : Int = 187;
    public static inline var KEY_DOT : Int = 190;
    
    public static inline var KEY_SQUIGGLE : Int = 192;
    
    public static inline var KEY_A : Int = 65;
    public static inline var KEY_B : Int = 66;
    public static inline var KEY_C : Int = 67;
    public static inline var KEY_D : Int = 68;
    public static inline var KEY_E : Int = 69;
    public static inline var KEY_F : Int = 70;
    public static inline var KEY_G : Int = 71;
    public static inline var KEY_H : Int = 72;
    public static inline var KEY_I : Int = 73;
    public static inline var KEY_J : Int = 74;
    public static inline var KEY_K : Int = 75;
    public static inline var KEY_L : Int = 76;
    public static inline var KEY_M : Int = 77;
    public static inline var KEY_N : Int = 78;
    public static inline var KEY_O : Int = 79;
    public static inline var KEY_P : Int = 80;
    public static inline var KEY_Q : Int = 81;
    public static inline var KEY_R : Int = 82;
    public static inline var KEY_S : Int = 83;
    public static inline var KEY_T : Int = 84;
    public static inline var KEY_U : Int = 85;
    public static inline var KEY_V : Int = 86;
    public static inline var KEY_W : Int = 87;
    public static inline var KEY_X : Int = 88;
    public static inline var KEY_Y : Int = 89;
    public static inline var KEY_Z : Int = 90;
    
    public static inline var KEY_1 : Int = 49;
    public static inline var KEY_2 : Int = 50;
    public static inline var KEY_3 : Int = 51;
    public static inline var KEY_4 : Int = 52;
    public static inline var KEY_5 : Int = 53;
    public static inline var KEY_6 : Int = 54;
    public static inline var KEY_7 : Int = 55;
    public static inline var KEY_8 : Int = 56;
    public static inline var KEY_9 : Int = 57;
    public static inline var KEY_0 : Int = 48;
    
    public static inline var KEY_NUM_0 : Int = 96;
    public static inline var KEY_NUM_1 : Int = 97;
    public static inline var KEY_NUM_2 : Int = 98;
    public static inline var KEY_NUM_3 : Int = 99;
    public static inline var KEY_NUM_4 : Int = 100;
    public static inline var KEY_NUM_5 : Int = 101;
    public static inline var KEY_NUM_6 : Int = 102;
    public static inline var KEY_NUM_7 : Int = 103;
    public static inline var KEY_NUM_8 : Int = 104;
    public static inline var KEY_NUM_9 : Int = 105;
    public static inline var KEY_NUM_PLUS : Int = 107;
    public static inline var KEY_NUM_MINUS : Int = 109;
    
    public static inline var KEY_ESCAPE : Int = 27;
    public static inline var KEY_TAB : Int = 9;
    public static inline var KEY_INSERT : Int = 45;
    public static inline var KEY_DELETE : Int = 46;
    public static inline var KEY_HOME : Int = 36;
    public static inline var KEY_END : Int = 35;
    public static inline var KEY_PAGEUP : Int = 33;
    public static inline var KEY_PAGEDOWN : Int = 34;
    
    public static inline var KEY_F1 : Int = 112;
    public static inline var KEY_F2 : Int = 113;
    public static inline var KEY_F3 : Int = 114;
    public static inline var KEY_F4 : Int = 115;
    public static inline var KEY_F5 : Int = 116;
    public static inline var KEY_F6 : Int = 117;
    public static inline var KEY_F7 : Int = 118;
    public static inline var KEY_F8 : Int = 119;
    public static inline var KEY_F9 : Int = 120;
    
    public static inline var KEY_SHIFT : Int = 16;
    public static inline var KEY_CONTROL : Int = 17;
    
    public static inline var KEY_BACKSPACE : Int = 8;
    public static inline var KEY_BACKSLASH : Int = 220;
    public static inline var KEY_FORWARDSLASH : Int = 191;
    public static inline var KEY_HASH : Int = 222;
    public static inline var KEY_SEMICOLON : Int = 186;
    public static inline var KEY_LEFTSQUAREBRACKET : Int = 219;
    public static inline var KEY_RIGHTSQUAREBRACKET : Int = 221;
    public static inline var KEY_TOPLEFT : Int = 223;
    public static inline var KEY_COMMA : Int = 188;
    public static inline var KEY_PERIOD : Int = 190;
    
    
    
    public static var active : Bool;
    public static var keysDown : Array<Int>;
    public static var keysCleared : Array<Bool>;
    public static var keysPressed : Array<Bool>;
    
    public static function Reset()
    {
        keysDown = new Array<Int>();
        keysCleared = new Array<Bool>();
        keysPressed = new Array<Bool>();
        var i : Int;
        for (i in 0...256)
        {
            keysDown[i] = as3hx.Compat.parseInt(0);
            keysPressed[i] = false;
            keysCleared[i] = false;
        }
        active = true;
    }
    public static function InitOnce(stage : Stage)
    {
        stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownListener);
        stage.addEventListener(KeyboardEvent.KEY_UP, keyUpListener);
        stage.focus = stage;
        Reset();
    }
    
    public function new()
    {
    }
    
    public static function Disable()
    {
        Reset();
        active = false;
    }
    public static function Enable()
    {
        active = true;
    }
    
    public static function UpdateOncePerFrame() : Void
    {
        if (active == false)
        {
            return;
        }
        var i : Int;
        for (i in 0...256)
        {
            if (keysDown[i] == 1)
            {
                keysPressed[i] = true;
                keysDown[i]++;
            }
            else
            {
                keysPressed[i] = false;
            }
        }
    }
    
    
    
    
    
    
    
    
    
    public static function Down(keyID : Int) : Bool
    {
        if (active == false)
        {
            return false;
        }
        if (keysCleared[keyID] == true)
        {
            return false;
        }
        return (keysDown[keyID] != 0);
    }
    
    public static function Pressed(keyID : Int) : Bool
    {
        if (active == false)
        {
            return false;
        }
        return keysPressed[keyID];
    }
    public static function ClearKey(keyID : Int) : Void
    {
        keysPressed[keyID] = false;
        keysDown[keyID] = 0;
        keysCleared[keyID] = true;
    }
    
    private static function keyDownListener(event : KeyboardEvent) : Void
    {
        if (active == false)
        {
            return;
        }
        var code : Int = event.keyCode;
        keysDown[code]++;
    }
    
    private static function keyUpListener(event : KeyboardEvent) : Void
    {
        if (active == false)
        {
            return;
        }
        var code : Int = event.keyCode;
        keysDown[code] = 0;
        keysCleared[code] = false;
    }
}


