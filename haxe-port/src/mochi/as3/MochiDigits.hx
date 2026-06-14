  /*** MochiServices* Connection class for all MochiAds Remote Services* @author Mochi Media* @version 3.0*/  package mochi.as3;

@:final class MochiDigits
{
    public var value(get, set) : Float;
private var Fragment : Float;private var Sibling : MochiDigits;private var Encoder : Float;  /**         * Method: MochiDigits         * Construct and initialize the value of a MochiDigit         * @param   digit: initialization value         * @param   index: internal use only         */  public function new(digit : Float = 0, index : Int = 0)
    {
        Encoder = 0;setValue(digit, index);
    }private function get_value() : Float
    {
        return as3hx.Compat.parseFloat(Std.string(this));
    }private function set_value(v : Float) : Float
    {
        setValue(v);
        return v;
    }  /**         * Method: add         * Increments the stored value by a specified amount         * @param   inc: Value to add to the stored variable         */  public function addValue(inc : Float) : Void
    {
        value += inc;
    }  /**         * Method: setValue         * Resets the stored value         * @param   digit: initialization value         * @param   index: internal use only         */  public function setValue(digit : Float = 0, index : Int = 0) : Void
    {
        var s : String = Std.string(digit);Fragment = s.charCodeAt(index++) ^ Encoder;if (index < s.length)
        {
            Sibling = new MochiDigits(digit, index);
        }
        else
        {
            Sibling = null;
        }reencode();
    }  /**         * Method: reencode         * Reencodes the stored number without changing its value         */  public function reencode() : Void
    {
        var newEncode : Int = as3hx.Compat.parseInt(0x7FFFFFFF * Math.random());Fragment = Fragment ^ newEncode ^ Encoder;Encoder = newEncode;
    }  /**         * Method: toString         * Returns the stored number as a formatted string         */  public function toString() : String
    {
        var s : String = String.fromCharCode(Fragment ^ Encoder);if (Sibling != null)
        {
            s += Std.string(Sibling);
        }return s;
    }
}