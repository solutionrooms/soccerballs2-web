package playtomic;

class PrivateLeaderboard extends Dynamic
{public var TableId : String;public var Name : String;public var Bitly : String;public var Permalink : String;public var Highest : Bool = true;public var RealName : String;public function new(tableid : String = null, name : String = null, bitly : String = null, permalink : String = null, highest : Bool = false, realname : String = null)
    {
        super();TableId = tableid;Name = name;Bitly = bitly;Permalink = permalink;Highest = highest;RealName = realname;
    }public function toString() : String
    {
        return "Playtomic.PrivateLeaderboard:" + "\nTableId: " + TableId + "\nName: " + Name + "\nBitly: " + Bitly + "\nPermalink: " + Permalink + "\nHighest: " + Highest + "\nRealName: " + RealName;
    }
}
