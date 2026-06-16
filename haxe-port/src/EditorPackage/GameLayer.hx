package editorPackage;


/**
	 * ...
	 * @author
	 */
class GameLayer
{
    public var name : String;
    public var zpos : Float;
    public function new()
    {
    }
    public function FromXML(x : FastXML)
    {
        name = XmlHelper.GetAttrString(x.att.name, "");
        zpos = XmlHelper.GetAttrNumber(x.att.zpos, 0);
    }
}


