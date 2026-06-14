package achievementPackage;

import flash.display.MovieClip;

/**
	 * ...
	 * @author ...
	 */
class Achievements
{
    
    @:meta(Embed(source="../../bin/Achievements.xml",mimeType="application/octet-stream"))

    private static var class_embedded_XML : Class<Dynamic>;
    
    private static var xml : FastXML;
    
    public static var list : Array<Achievement>;
    public static var unlockedList : Array<Achievement>;
    public static var testFunctions : AchievementTestFunctions;
    private static var displayQueue : AchievementDisplayQueue;
    private static var currentAch : Achievement;
    
    
    private static function LoadXml()
    {
        var x : FastXML = xml;
        var numAch = x.nodes.achievement.length();
        for (i in 0...numAch)
        {
            var ax : FastXML = x.nodes.achievement.get(i);
            var ach : Achievement = new Achievement();
            ach.index = i;
            ach.specificLevelName = XmlHelper.GetAttrString(ax.att.specificlevel, "1-01");
            ach.name = XmlHelper.GetAttrString(ax.att.name, "undefined");
            ach.description = XmlHelper.GetAttrString(ax.att.desc, "undefined");
            ach.toUnlockText = XmlHelper.GetAttrString(ax.att.tounlock, "undefined");
            ach.completeFunction = XmlHelper.GetAttrString(ax.node.pass.innerData.att.func, "");
            ach.completeFunctionParams = XmlHelper.GetAttrString(ax.node.pass.innerData.att.params, "");
            
            ach.name = cast((ach.name), GetFullString);
            ach.description = cast((ach.description), GetFullString);
            ach.toUnlockText = cast((ach.toUnlockText), GetFullString);
            
            var numTests : Int = ax.nodes.test.length();
            for (j in 0...numTests)
            {
                var tx : FastXML = ax.nodes.test.get(j);
                
                var test : AchievementTest = new AchievementTest();
                test.functionName = XmlHelper.GetAttrString(tx.att.func, "");
                test.functionParams = XmlHelper.GetAttrString(tx.att.params, "");
                test.PreCalc();
                ach.testList.push(test);
            }
            
            ach.specificLevel = as3hx.Compat.parseInt(ach.specificLevelName) - 1;
            
            /*
				if (ach.testFunction in this)
				{
					Utils.trace("test function " + ach.testFunction + " exists");
				}
				else
				{
					Utils.trace("test function " + ach.testFunction + " doesnt exist");
				}
				*/
            
            list.push(ach);
        }
    }
    
    public static function ClearAll()
    {
        for (ach in list)
        {
            ach.complete = false;
        }
    }
    public static function InitOnce()
    {
        testFunctions = new AchievementTestFunctions();
        displayQueue = new AchievementDisplayQueue();
        
        list = new Array<Achievement>();
        unlockedList = new Array<Achievement>();
        
        FastXML.ignoreWhitespace = true;
        xml = try cast(new FastXML(Type.createInstance(class_embedded_XML, [])), FastXML) catch(e:Dynamic) null;
        
        LoadXml();
        
        displayQueue.Reset();
    }
    private function new()
    {
    }
    
    
    
    
    private static function GetFullString(s : String, replaceLevel : Bool = true) : String
    {
        var num : Int;
        var s1 : String;
        var a : Array<Dynamic> = new Array<Dynamic>();
        a = s.split(" ");
        
        var newstring : String = "";
        
        if (s == "Level Completion")
        {
            var aaa : Int = 0;
        }
        
        for (word in a)
        {
            if (word == " ")
            {
            }
            else if (false)
            
            //word.match("&Level")){
                
                {
                    s1 = word.substr(6);
                    num = as3hx.Compat.parseInt(s1);
                    var l : Level = Levels.GetLevel(num - 1);
                    if (replaceLevel)
                    {
                        word = "'" + l.displayName + "'";
                        newstring += word;
                        newstring += " ";
                    }
                }
            }
            else
            {
                newstring += word;
                newstring += " ";
            }
        }
        if (newstring.charAt(newstring.length - 1) == " ")
        {
            newstring = newstring.substring(0, newstring.length - 1);
        }
        return newstring;
    }
    
    
    
    
    public static function CountAchievementsComplete() : Int
    {
        var count : Int = 0;
        for (ach in list)
        {
            if (ach.complete)
            {
                count++;
            }
        }
        return count;
    }
    
    public static function GetAchievementIndex(ach : Achievement) : Int
    {
        var index : Int = 0;
        for (ach1 in list)
        {
            if (ach1 == ach)
            {
                return index;
            }
            index++;
        }
        return 0;
    }
    
    public static function GetAchievementByName(name : String) : Achievement
    {
        for (ach in list)
        {
            if (ach.name == name)
            {
                return ach;
            }
        }
        return null;
    }
    
    public static function AllComplete() : Bool
    {
        for (ach in list)
        {
            if (ach.complete == false)
            {
                return false;
            }
        }
        return true;
    }
    
    
    public static function TestNone()
    {
        unlockedList = new Array<Achievement>();
    }
    public static function TestAll()
    {
        testFunctions.UpdateFromGameVars();
        unlockedList = new Array<Achievement>();
        
        for (ach in list)
        {
            if (ach.complete == false)
            {
                var doit : Bool = true;
                if (ach.specificLevel != -1)
                {
                    if (ach.specificLevel != Levels.currentIndex)
                    {
                        doit = false;
                    }
                }
                if (doit)
                {
                    var numCorrect : Int = 0;
                    var numTests : Int = ach.testList.length;
                    for (testIndex in 0...numTests)
                    {
                        var test : AchievementTest = ach.testList[testIndex];
                        var testFuncName : String = test.functionName;
                        
                        Utils.paramNames = test.precalcedParamNames;
                        Utils.paramValues = test.precalcedParamValues;
                        var result : Bool = Reflect.field(testFunctions, testFuncName)();
                        if (result)
                        {
                            numCorrect++;
                        }
                        else
                        {
                            break;
                        }
                    }
                    if (numCorrect == numTests)
                    
                    // AND all the tests.{
                        
                        {
                            currentAch = ach;
                            Utils.GetParams(ach.completeFunctionParams);
                            testFunctions[ach.completeFunction]();
                            ach.complete = true;
                            unlockedList.push(ach);
                        }
                    }
                    else
                    {
                    }
                }
            }
        }
        displayQueue.AddUnlockedList(unlockedList);
    }
    
    
    
    
    public static function UpdateDisplayQueue() : Bool
    {
        return displayQueue.Update();
    }
    
    public static function GetLevelAchievements(_level : Int) : Array<Dynamic>
    {
        _level++;
        var newarray : Array<Dynamic> = new Array<Dynamic>();
        for (ach in list)
        {
            if (ach.specificLevel == _level)
            {
                newarray.push(ach);
            }
        }
        return newarray;
    }
    
    public static function ResetForLevel() : Void
    {
        displayQueue.Reset();
        testFunctions.ResetForLevel();
    }
    
    
    public static function ToSharedObject() : Dynamic
    {
        var o : Dynamic = {};
        o.completes = new Array<Dynamic>();
        
        for (ach in list)
        {
            o.completes.push(ach.complete);
        }
        
        return o;
    }
    
    public static function FromSharedObject(o : Dynamic)
    {
        if (o == null)
        {
            return;
        }
        if (o.completes == null)
        {
            return;
        }
        
        var index : Int = 0;
        
        for (b/* AS3HX WARNING could not determine type for var: b exp: EField(EIdent(o),completes) type: null */ in o.completes)
        {
            list[index].complete = b;
            index++;
        }
    }
}

