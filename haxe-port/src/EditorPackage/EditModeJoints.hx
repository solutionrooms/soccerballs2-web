package editorPackage;

import editorPackage.editParamUI.EditParams;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.geom.Rectangle;

/**
	 * ...
	 * @author LongAnimals
	 */
class EditModeJoints extends EditModeBase
{
    private var addlineActive : Bool;
    private var newLineType : Int;
    private var hoveredObj : EditableObjectBase;
    private var selectedJoint : EdJoint;
    private var copiedParameters : ObjParameters;
    private var currentAdjustObject_mouseX : Int = 0;
    private var currentAdjustObject_mouseY : Int = 0;
    
    public function new()
    {
        super();
    }
    
    override public function EnterMode() : Void
    {
        PhysEditor.CursorText_Show();
        PhysEditor.CursorText_Set("");
        cast(("null"), SetSubMode);
        selectedJoint = null;
        hoveredObj = null;
    }
    override public function InitOnce() : Void
    {
        copiedParameters = null;
        hoveredObj = null;
    }
    
    
    public function UpdateJoints_ObjectDeleted(objID : String)
    {
        if (objID == "")
        {
            return;
        }
        var jointList : Array<Dynamic> = GetCurrentLevelJoints();
        var deleteList : Array<Dynamic> = new Array<Dynamic>();
        for (joint in jointList)
        {
            if (joint.obj0Name == objID || joint.obj1Name == objID)
            {
                deleteList.push(joint);
            }
        }
        for (joint in deleteList)
        {
            jointList.splice(Lambda.indexOf(jointList, joint), 1);
        }
    }
    
    public function UpdateJoints_ObjectMoved(objID : String, x : Float, y : Float, da : Float = 0)
    {
        if (objID == "")
        {
            return;
        }
        var jointList : Array<Dynamic> = GetCurrentLevelJoints();
        for (joint in jointList)
        {
            if (joint.type == EdJoint.Type_Distance)
            {
                if (joint.obj0Name == objID)
                {
                    joint.dist_pos0.x += x;
                    joint.dist_pos0.y += y;
                }
                if (joint.obj1Name == objID)
                {
                    joint.dist_pos1.x += x;
                    joint.dist_pos1.y += y;
                }
            }
        }
    }
    
    
    
    
    private function RemoveAllJoints()
    {
        PhysEditor.GetCurrentLevel().joints = new Array<Dynamic>();
    }
    
    
    public function GetJointAtPosition(x : Int, y : Int) : EdJoint
    {
        var jointList : Array<Dynamic> = GetCurrentLevelJoints();
        for (joint in jointList)
        {
            if (joint.HitTest(x, y))
            {
                return joint;
            }
        }
        return null;
    }
    
    public function HitTestRectangle(r : Rectangle) : Array<Dynamic>
    {
        var a : Array<Dynamic> = new Array<Dynamic>();
        var jointList : Array<Dynamic> = GetCurrentLevelJoints();
        for (joint in jointList)
        {
            if (joint.HitTestRectangle(r))
            {
                a.push(joint);
            }
        }
        return a;
    }
    
    
    private function RemoveJoint(j : EdJoint)
    {
        cast((j), RemoveMarkedJoints);
        PhysEditor.DeleteJoint(j);
    }
    private function AddRevoluteJoint(x : Float, y : Float) : EdJoint
    {
        var j : EdJoint = new EdJoint();
        j.SetType(EdJoint.Type_Rev);
        j.rev_pos = new Point(x, y);
        
        var jointList : Array<Dynamic> = GetCurrentLevelJoints();
        jointList.push(j);
        
        Utils.print("added revolute joint " + x + " " + y);
        return j;
    }
    
    private function AddPrismaticJoint(x : Float, y : Float) : EdJoint
    {
        var j : EdJoint = new EdJoint();
        j.SetType(EdJoint.Type_Prismatic);
        j.prism_pos = new Point(x, y);
        j.prism_pos1 = new Point(x, y);
        
        var jointList : Array<Dynamic> = GetCurrentLevelJoints();
        jointList.push(j);
        
        Utils.print("added prismatic joint " + x + " " + y);
        return j;
    }
    
    private function AddDistanceJoint() : EdJoint
    {
        var j : EdJoint = new EdJoint();
        j.SetType(EdJoint.Type_Distance);
        var jointList : Array<Dynamic> = GetCurrentLevelJoints();
        jointList.push(j);
        
        Utils.print("added distance joint");
        return j;
    }
    
    private function AddSwitchJoint() : EdJoint
    {
        var j : EdJoint = new EdJoint();
        j.SetType(EdJoint.Type_Switch);
        var jointList : Array<Dynamic> = GetCurrentLevelJoints();
        jointList.push(j);
        
        Utils.print("added switch joint");
        return j;
    }
    
    private function AddLogicJoint() : EdJoint
    {
        var j : EdJoint = new EdJoint();
        j.SetType(EdJoint.Type_LogicLink);
        var jointList : Array<Dynamic> = GetCurrentLevelJoints();
        jointList.push(j);
        
        Utils.print("added logic joint");
        return j;
    }
    
    private function AddWeldJoint() : EdJoint
    {
        var j : EdJoint = new EdJoint();
        j.SetType(EdJoint.Type_Weld);
        var jointList : Array<Dynamic> = GetCurrentLevelJoints();
        jointList.push(j);
        
        Utils.print("added weld joint");
        return j;
    }
    
    private function CopyParameters(j : EdJoint)
    {
        if (j == null)
        {
            return;
        }
        copiedParameters = j.objParameters.Clone();
    }
    private function PasteParameters(j : EdJoint)
    {
        if (j == null)
        {
            return;
        }
        if (copiedParameters == null)
        {
            return;
        }
        j.objParameters = copiedParameters.Clone();
    }
    
    private var currentJoint : EdJoint = null;
    override public function OnMouseDown(e : MouseEvent) : Void
    {
        super.OnMouseDown(e);
        
        var obj : EditableObjectBase;
        
        
        if (subMode == "newrev")
        {
            PhysEditor.UndoTakeSnapshot();
            currentJoint = AddRevoluteJoint(mxs, mys);
            cast(("firstrev"), SetSubMode);
        }
        else if (subMode == "newprism")
        {
            PhysEditor.UndoTakeSnapshot();
            currentJoint = AddPrismaticJoint(mxs, mys);
            
            obj = GetCurrentObj();
            if (obj != null)
            {
                if (obj.id == "")
                {
                    obj.id = PhysEditor.CreateNewUniqueID();
                }
                currentJoint.obj0Name = obj.id;
            }
            cast(("secondprism"), SetSubMode);
        }
        else if (subMode == "secondprism")
        {
            PhysEditor.UndoTakeSnapshot();
            
            obj = GetCurrentObj();
            if (obj != null)
            {
                if (obj.id == "")
                {
                    obj.id = PhysEditor.CreateNewUniqueID();
                }
                currentJoint.obj1Name = obj.id;
            }
            cast(("firstprismaxis"), SetSubMode);
        }
        else if (subMode == "firstprismaxis")
        {
            currentJoint.prism_pos = new Point(mxs, mys);
            cast(("secondprismaxis"), SetSubMode);
        }
        else if (subMode == "secondprismaxis")
        {
            currentJoint.prism_pos1 = new Point(mxs, mys);
            cast(("null"), SetSubMode);
        }
        else if (subMode == "new_switch")
        {
            GetHoveredObjIncludingJoints();
            obj = hoveredObj;
            if (obj != null)
            {
                PhysEditor.UndoTakeSnapshot();
                currentJoint = AddSwitchJoint();
                
                if (obj.id == "")
                {
                    obj.id = PhysEditor.CreateNewUniqueID();
                }
                currentJoint.obj0Name = obj.id;
                cast(("second_switch"), SetSubMode);
            }
        }
        else if (subMode == "second_switch")
        {
            GetHoveredObjIncludingJoints();
            obj = hoveredObj;
            if (obj != null)
            {
                PhysEditor.UndoTakeSnapshot();
                if (obj.id == "")
                {
                    obj.id = PhysEditor.CreateNewUniqueID();
                }
                currentJoint.obj1Name = obj.id;
                cast(("null"), SetSubMode);
            }
        }
        else if (subMode == "new_logic")
        {
            GetHoveredObj();
            obj = GetCurrentObj();
            if (obj != null)
            {
                PhysEditor.UndoTakeSnapshot();
                currentJoint = AddLogicJoint();
                
                if (obj.id == "")
                {
                    obj.id = PhysEditor.CreateNewUniqueID();
                }
                currentJoint.obj0Name = obj.id;
                cast(("second_logic"), SetSubMode);
            }
        }
        else if (subMode == "second_logic")
        {
            GetHoveredObjIncludingJoints();
            obj = GetCurrentObjIncludingJoints();
            if (obj != null)
            {
                PhysEditor.UndoTakeSnapshot();
                if (obj.id == "")
                {
                    obj.id = PhysEditor.CreateNewUniqueID();
                }
                currentJoint.obj1Name = obj.id;
                cast(("null"), SetSubMode);
            }
        }
        else if (subMode == "new_weld")
        {
            GetHoveredObj();
            obj = GetCurrentObj();
            if (obj != null)
            {
                PhysEditor.UndoTakeSnapshot();
                currentJoint = AddWeldJoint();
                
                if (obj.id == "")
                {
                    obj.id = PhysEditor.CreateNewUniqueID();
                }
                currentJoint.obj0Name = obj.id;
                cast(("second_weld"), SetSubMode);
            }
        }
        else if (subMode == "second_weld")
        {
            GetHoveredObj();
            obj = GetCurrentObj();
            if (obj != null)
            {
                PhysEditor.UndoTakeSnapshot();
                if (obj.id == "")
                {
                    obj.id = PhysEditor.CreateNewUniqueID();
                }
                currentJoint.obj1Name = obj.id;
                cast(("null"), SetSubMode);
            }
        }
        else if (subMode == "newdist")
        {
            GetHoveredObj();
            
            obj = GetCurrentObj();
            if (obj != null)
            {
                PhysEditor.UndoTakeSnapshot();
                currentJoint = AddDistanceJoint();
                
                if (obj.id == "")
                {
                    obj.id = PhysEditor.CreateNewUniqueID();
                }
                currentJoint.obj0Name = obj.id;
                currentJoint.dist_pos0.x = mxs;
                currentJoint.dist_pos0.y = mys;
                currentJoint.obj1Name = obj.id;
                currentJoint.dist_pos1.x = mxs;
                currentJoint.dist_pos1.y = mys;
                cast(("seconddist"), SetSubMode);
            }
            else
            {
                currentJoint = AddDistanceJoint();
                currentJoint.dist_pos0.x = mxs;
                currentJoint.dist_pos0.y = mys;
                currentJoint.dist_pos1.x = mxs;
                currentJoint.dist_pos1.y = mys;
                cast(("seconddist"), SetSubMode);
            }
        }
        else if (subMode == "firstdist")
        {
            obj = GetCurrentObj();
            if (obj != null)
            {
                if (obj.id == "")
                {
                    obj.id = PhysEditor.CreateNewUniqueID();
                }
                currentJoint.obj0Name = obj.id;
                currentJoint.dist_pos0.x = mxs;
                currentJoint.dist_pos0.y = mys;
                cast(("seconddist"), SetSubMode);
            }
            else
            {
                currentJoint.obj0Name = "";
                currentJoint.dist_pos0.x = mxs;
                currentJoint.dist_pos0.y = mys;
                cast(("seconddist"), SetSubMode);
            }
        }
        else if (subMode == "seconddist")
        {
            obj = GetCurrentObj();
            if (obj != null)
            {
                if (obj.id == "")
                {
                    obj.id = PhysEditor.CreateNewUniqueID();
                }
                currentJoint.obj1Name = obj.id;
                currentJoint.dist_pos1.x = mxs;
                currentJoint.dist_pos1.y = mys;
                cast(("null"), SetSubMode);
            }
            else
            {
                currentJoint.obj1Name = "";
                currentJoint.dist_pos1.x = mxs;
                currentJoint.dist_pos1.y = mys;
                cast(("null"), SetSubMode);
            }
        }
        else if (subMode == "firstrev")
        {
            obj = GetCurrentObj();
            if (obj != null)
            {
                if (obj.id == "")
                {
                    obj.id = PhysEditor.CreateNewUniqueID();
                }
                currentJoint.obj0Name = obj.id;
            }
            cast(("secondrev"), SetSubMode);
        }
        else if (subMode == "secondrev")
        {
            obj = GetCurrentObj();
            if (obj != null)
            {
                if (obj.id == "")
                {
                    obj.id = PhysEditor.CreateNewUniqueID();
                }
                currentJoint.obj1Name = obj.id;
            }
            cast(("null"), SetSubMode);
        }
        else if (subMode == "drag")
        {
            selectedJoint = GetJointAtPosition(mxs, mys);
            currentJoint = selectedJoint;
            if (selectedJoint != null)
            {
                currentAdjustObject_mouseX = mx;
                currentAdjustObject_mouseY = my;
            }
        }
        else
        {
            selectedJoint = GetJointAtPosition(mxs, mys);
            currentJoint = selectedJoint;
            
            if (selectedJoint != null)
            {
                EditParams.AddParameterListBox(selectedJoint.objParameters);
            }
            else
            {
                EditParams.ClearParameterListBox();
            }
        }
    }
    
    override public function OnMouseUp(e : MouseEvent) : Void
    {
        super.OnMouseUp(e);
        
        var poi : EdObj;
        var line : EdLine;
    }
    
    
    private var hoveredJoint : EditableObjectBase = null;
    private function ClearHoveredJoint()
    {
        hoveredJoint = null;
    }
    private function GetHoveredJoint()
    {
        hoveredJoint = null;
        var obj : EditableObjectBase = PhysEditor.HitTestJoint(mxs, mys);
        if (obj != null)
        {
            if (obj.classType == "joint")
            {
                hoveredJoint = obj;
            }
        }
    }
    private function GetHoveredObj() : EditableObjectBase
    {
        hoveredObj = null;
        var obj : EditableObjectBase = PhysEditor.HitTestAnyObjectNoJoints(mxs, mys, mx, my);
        if (obj != null)
        {
            hoveredObj = obj;
        }
        return hoveredObj;
    }
    private function GetHoveredObjIncludingJoints() : EditableObjectBase
    {
        hoveredObj = null;
        var obj : EditableObjectBase = PhysEditor.HitTestAnyObject(mxs, mys, mx, my);
        if (obj != null)
        {
            hoveredObj = obj;
        }
        return hoveredObj;
    }
    
    private function GetCurrentObjIncludingJoints() : EditableObjectBase
    {
        var obj : EditableObjectBase = PhysEditor.HitTestAnyObject(mxs, mys, mx, my);
        return obj;
    }
    private function GetCurrentObj() : EditableObjectBase
    {
        var obj : EditableObjectBase = PhysEditor.HitTestAnyObjectNoJoints(mxs, mys, mx, my);
        if (obj != null)
        {
            if (obj.classType != "joint")
            {
                return obj;
            }
        }
        return null;
    }
    
    
    override public function OnMouseMove(e : MouseEvent) : Void
    {
        super.OnMouseMove(e);
        
        var obj : EditableObjectBase;
        
        var poi : EdObj;
        var line : EdLine;
        
        var l : Level = GetCurrentLevel();
        
        ClearHoveredJoint();
        hoveredObj = null;
        
        if (e.buttonDown == false)
        {
            if (subMode == "newdist" || subMode == "firstdist")
            {
                obj = GetHoveredObj();
                if (obj == null)
                {
                    PhysEditor.CursorText_Set("[DIST] First Object: BG");
                }
                else
                {
                    PhysEditor.CursorText_Set("[DIST] First Object: " + obj.GetEditorHoverName());
                }
            }
            else if (subMode == "seconddist")
            {
                obj = GetHoveredObj();
                if (obj == null)
                {
                    PhysEditor.CursorText_Set("[DIST] Second Object: BG");
                }
                else
                {
                    PhysEditor.CursorText_Set("[DIST] Second Object: " + obj.GetEditorHoverName());
                }
            }
            else if (subMode == "new_switch")
            {
                obj = GetHoveredObjIncludingJoints();
                if (obj == null)
                {
                    PhysEditor.CursorText_Set("[SWITCH] First Object: BG");
                }
                else
                {
                    PhysEditor.CursorText_Set("[SWITCH] First Object: " + obj.GetEditorHoverName());
                }
            }
            else if (subMode == "second_switch")
            {
                obj = GetHoveredObjIncludingJoints();
                if (obj == null)
                {
                    PhysEditor.CursorText_Set("[SWITCH] Second Object: BG");
                }
                else
                {
                    PhysEditor.CursorText_Set("[SWITCH] Second Object: " + obj.GetEditorHoverName());
                }
            }
            else if (subMode == "new_logic")
            {
                obj = GetHoveredObj();
                if (obj == null)
                {
                    PhysEditor.CursorText_Set("[LOGIC] First Object: BG");
                }
                else
                {
                    PhysEditor.CursorText_Set("[LOGIC] First Object: " + obj.GetEditorHoverName());
                }
            }
            else if (subMode == "second_logic")
            {
                obj = GetHoveredObjIncludingJoints();
                if (obj == null)
                {
                    PhysEditor.CursorText_Set("[LOGIC] Second Object: BG");
                }
                else
                {
                    PhysEditor.CursorText_Set("[LOGIC] Second Object: " + obj.GetEditorHoverName());
                }
            }
            else if (subMode == "new_weld")
            {
                obj = GetHoveredObj();
                if (obj == null)
                {
                    PhysEditor.CursorText_Set("[WELD] First Object: BG");
                }
                else
                {
                    PhysEditor.CursorText_Set("[WELD] First Object: " + obj.GetEditorHoverName());
                }
            }
            else if (subMode == "second_weld")
            {
                obj = GetHoveredObj();
                if (obj == null)
                {
                    PhysEditor.CursorText_Set("[WELD] Second Object: BG");
                }
                else
                {
                    PhysEditor.CursorText_Set("[WELD] Second Object: " + obj.GetEditorHoverName());
                }
            }
            else if (subMode == "firstrev")
            {
                GetHoveredObj();
                
                obj = GetCurrentObj();
                if (obj == null)
                {
                    PhysEditor.CursorText_Set("[REV] First Object: BG");
                }
                else
                {
                    PhysEditor.CursorText_Set("[REV] First Object: " + obj.GetEditorHoverName());
                }
            }
            else if (subMode == "secondrev")
            {
                GetHoveredObj();
                
                obj = GetCurrentObj();
                if (obj == null)
                {
                    PhysEditor.CursorText_Set("[REV] Second Object: BG");
                }
                else
                {
                    PhysEditor.CursorText_Set("[REV] Second Object: " + obj.GetEditorHoverName());
                }
            }
            else if (subMode == "drag")
            {
                GetHoveredJoint();
            }
            else if (subMode == "null")
            {
                GetHoveredJoint();
            }
            
            return;
        }
        
        if (subMode == "drag")
        {
            if (selectedJoint != null)
            {
                var dx : Float = mx - currentAdjustObject_mouseX;
                var dy : Float = my - currentAdjustObject_mouseY;
                selectedJoint.MoveBy(dx, dy);
                currentAdjustObject_mouseX = mx;
                currentAdjustObject_mouseY = my;
            }
        }
    }
    
    
    override public function OnMouseWheel(delta : Int) : Void
    {
    }
    
    private var subMode : String;
    private function SetSubMode(s : String)
    {
        subMode = s;
        
        
        if (s == "new_switch")
        {
            PhysEditor.CursorText_Set("new switch joint - first object");
        }
        if (s == "swcond_switch")
        {
            PhysEditor.CursorText_Set("switch joint - second object");
        }
        if (s == "new_logic")
        {
            PhysEditor.CursorText_Set("new logic joint - first object");
        }
        if (s == "second_logic")
        {
            PhysEditor.CursorText_Set("logic joint - second object");
        }
        if (s == "new_weld")
        {
            PhysEditor.CursorText_Set("new weld joint - first object");
        }
        if (s == "second_weld")
        {
            PhysEditor.CursorText_Set("weld joint - second object");
        }
        if (s == "newprism")
        {
            PhysEditor.CursorText_Set("new prismatic joint - first object");
        }
        if (s == "secondprism")
        {
            PhysEditor.CursorText_Set("prism select second object");
        }
        if (s == "firstprismaxis")
        {
            PhysEditor.CursorText_Set("prism select axis point A");
        }
        if (s == "secondprismaxis")
        {
            PhysEditor.CursorText_Set("prism select axis point A");
        }
        if (s == "firstdist")
        {
            PhysEditor.CursorText_Set("first dist point");
        }
        if (s == "seconddist")
        {
            PhysEditor.CursorText_Set("second dist point");
        }
        if (s == "firstrev")
        {
            PhysEditor.CursorText_Set("[REV] first object");
        }
        if (s == "secondrev")
        {
            PhysEditor.CursorText_Set("[REV] second object");
        }
        
        if (s == "null")
        {
            PhysEditor.CursorText_Set("");
        }
        if (s == "newrev")
        {
            PhysEditor.CursorText_Set("new revolute joint");
        }
        if (s == "newdist")
        {
            PhysEditor.CursorText_Set("new distance joint");
        }
        if (s == "drag")
        {
            PhysEditor.CursorText_Set("drag joint");
        }
    }
    
    override public function Update() : Void
    {
        super.Update();
        
        
        if (selectedJoint != null)
        {
            if (KeyReader.Pressed(KeyReader.KEY_E))
            {
                if (selectedJoint.type == EdJoint.Type_Rev)
                {
                    cast(("firstrev"), SetSubMode);
                }
                if (selectedJoint.type == EdJoint.Type_Distance)
                {
                    cast(("firstrev"), SetSubMode);
                }
            }
            else if (KeyReader.Pressed(KeyReader.KEY_C))
            {
                cast((selectedJoint), CopyParameters);
            }
            else if (KeyReader.Pressed(KeyReader.KEY_V))
            {
                PhysEditor.UndoTakeSnapshot();
                cast((selectedJoint), PasteParameters);
            }
            else if (KeyReader.Down(KeyReader.KEY_DELETE) || KeyReader.Down(KeyReader.KEY_SQUIGGLE))
            {
                PhysEditor.UndoTakeSnapshot();
                cast((selectedJoint), RemoveJoint);
            }
        }
        
        if (KeyReader.Pressed(KeyReader.KEY_R))
        {
            cast(("newrev"), SetSubMode);
        }
        else if (KeyReader.Pressed(KeyReader.KEY_D))
        {
            cast(("newdist"), SetSubMode);
        }
        else if (KeyReader.Pressed(KeyReader.KEY_P))
        {
            cast(("newprism"), SetSubMode);
        }
        else if (KeyReader.Pressed(KeyReader.KEY_S))
        {
            cast(("new_switch"), SetSubMode);
        }
        else if (KeyReader.Pressed(KeyReader.KEY_L))
        {
            cast(("new_logic"), SetSubMode);
        }
        else if (KeyReader.Pressed(KeyReader.KEY_W))
        {
            cast(("new_weld"), SetSubMode);
        }
        
        
        if (subMode == "null" || subMode == "drag")
        {
            if (KeyReader.Down(KeyReader.KEY_CONTROL))
            {
                cast(("drag"), SetSubMode);
            }
            else
            {
                cast(("null"), SetSubMode);
            }
        }
        if (KeyReader.Pressed(KeyReader.KEY_TAB) && KeyReader.Down(KeyReader.KEY_CONTROL))
        {
            PhysEditor.UndoTakeSnapshot();
            if (KeyReader.Down(KeyReader.KEY_SHIFT))
            {
                PhysEditor.RemoveEverything();
            }
            RemoveAllJoints();
        }
    }
    
    private function RemoveMarkedJoints(ob : EditableObjectBase)
    {
        if (hoveredJoint == ob)
        {
            hoveredJoint = null;
        }
        if (selectedJoint == ob)
        {
            EditParams.ClearParameterListBox();
            selectedJoint = null;
        }
    }
    
    override public function Render(bd : BitmapData) : Void
    {
        super.Render(bd);
        bd.fillRect(Defs.screenRect, 0xff445566);
        PhysEditor.RenderBackground(bd);
        PhysEditor.RenderSortedEdObjs();
        PhysEditor.Editor_RenderJoints(bd);
        PhysEditor.Editor_RenderMiniMap();
        PhysEditor.Editor_RenderGrid(bd);
        
        
        if (hoveredObj != null)
        {
            hoveredObj.RenderHighlighted(EditableObjectBase.HIGHLIGHT_HOVER);
        }
        if (hoveredJoint != null)
        {
            hoveredJoint.RenderHighlighted(EditableObjectBase.HIGHLIGHT_HOVER);
        }
        if (selectedJoint != null)
        {
            selectedJoint.RenderHighlighted(EditableObjectBase.HIGHLIGHT_SELECTED);
        }
    }
    override public function RenderHud(x : Int, y : Int) : Int
    {
        var s : String;
        
        s = "R: Add Revolute Joint";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "D: Add Distance Joint";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "P: Add Prismatic Joint";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "S: Add Switch Joint";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "L: Add Logic Joint";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "W: Add Weld Joint";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "DEL: Delete Joint";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "C: Copy parameters";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "V: Paste parameters";
        y += PhysEditor.AddInfoText("a", x, y, s);
        
        return y;
    }
}

