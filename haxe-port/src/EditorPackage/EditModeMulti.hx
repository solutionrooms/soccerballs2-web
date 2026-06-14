package editorPackage;

import editorPackage.editParamUI.EditParams;
import flash.display.BitmapData;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.geom.Rectangle;

/**
	 * ...
	 * @author ...
	 */
class EditModeMulti extends EditModeBase
{
    
    public var dragRectX0 : Int;
    public var dragRectX1 : Int;
    public var dragRectY0 : Int;
    public var dragRectY1 : Int;
    public var selectedObjects : Array<EditableObjectBase>;
    public var hoveredObj : EditableObjectBase;
    
    private var selectedParameters : ObjParameters;
    
    public function AfterUndo()
    {
        ClearSelected();
        hoveredObj = null;
    }
    
    
    public function ParameterChanged(op : ObjParameter)
    {
        Utils.print("param changed " + op.name + "  " + op.value);
        
        for (i in 0...selectedObjects.length)
        {
            var params : ObjParameters = selectedObjects[i].objParameters;
            
            if (params.Exists(op.name))
            {
                params.SetParam(op.name, op.value);
                op.multipleValues = false;
            }
        }
        EditParams.AddParameterListBox(selectedParameters, ParameterChanged);
    }
    
    private function SetSelectedParameters()
    {
        if (selectedObjects.length == 0)
        {
            EditParams.ClearParameterListBox();
        }
        else
        {
            selectedParameters = new ObjParameters();
            
            for (i in 0...selectedObjects.length)
            {
                var params : ObjParameters = selectedObjects[i].objParameters.Clone();
                selectedParameters.AddMultiParameters(params);
            }
            
            EditParams.AddParameterListBox(selectedParameters, ParameterChanged);
        }
    }
    
    private function SelectAll(updateParameters : Bool = true)
    {
        selectedObjects = new Array<EditableObjectBase>();
        var a : Array<Dynamic> = PhysEditor.GetAllObjectsList();
        for (eo in a)
        {
            AddToSelected(eo, updateParameters);
        }
    }
    private function ClearSelected()
    {
        selectedObjects = new Array<EditableObjectBase>();
        EditParams.ClearParameterListBox();
    }
    
    
    
    
    private function SetAllLevelsAllObjectsDefaultGameLayers()
    {
        Utils.print("SetAllLevelsAllObjectsDefaultGameLayers");
        var oldCurrentLevel : Int = Levels.currentIndex;
        var oldCurrentLevel1 : Int = PhysEditor.currentLevel;
        
        for (lindex in 0...Levels.list.length)
        {
            Levels.currentIndex = lindex;
            PhysEditor.currentLevel = lindex;
            SelectAll(false);
            SetDefaultGameLayers();
            
            Utils.print(" level " + lindex + "    num objects: " + selectedObjects.length);
        }
        
        Levels.currentIndex = oldCurrentLevel;
        PhysEditor.currentLevel = oldCurrentLevel1;
    }
    private function SetDefaultGameLayers()
    {
        for (eo in selectedObjects)
        {
            if (eo.objParameters != null)
            {
                if (eo.objParameters.Exists("game_layer"))
                {
                    if (Std.is(eo, EdObj))
                    {
                        var eobj : EdObj = try cast(eo, EdObj) catch(e:Dynamic) null;
                        
                        var po : PhysObj = Game.objectDefs.FindByName(eobj.typeName);
                        if (po != null)
                        {
                            var def : String = po.GetInstanceParamDefault("game_layer");
                            eobj.objParameters.SetParam("game_layer", def);
                        }
                    }
                    else if (Std.is(eo, EdLine))
                    {
                        var eline : EdLine = try cast(eo, EdLine) catch(e:Dynamic) null;
                        var pm : PolyMaterial = eline.GetCurrentPolyMaterial();
                        eline.objParameters.SetParam("game_layer", pm.defaultGameLayer);
                    }
                }
            }
        }
    }
    
    
    private function AddToSelected(obj : EditableObjectBase, updateParameters : Bool = true)
    {
        if (obj == null)
        {
            return;
        }
        var a : Int = Lambda.indexOf(selectedObjects, obj);
        if (a == -1)
        {
            selectedObjects.push(obj);
        }
        if (updateParameters)
        {
            SetSelectedParameters();
        }
    }
    private function RemoveFromSelected(obj : EditableObjectBase)
    {
        if (obj == null)
        {
            return;
        }
        var a : Int = Lambda.indexOf(selectedObjects, obj);
        if (a != -1)
        {
            selectedObjects.splice(a, 1);
        }
        SetSelectedParameters();
    }
    private function IsInSelectedList(obj : EditableObjectBase) : Bool
    {
        if (obj == null)
        {
            return false;
        }
        var a : Int = Lambda.indexOf(selectedObjects, obj);
        return (a != -1);
    }
    
    private function ToggleSelected(obj : EditableObjectBase)
    {
        if (obj == null)
        {
            return;
        }
        if (IsInSelectedList(obj))
        {
            RemoveFromSelected(obj);
        }
        else
        {
            AddToSelected(obj);
        }
    }
    
    public function new()
    {
        super();
    }
    override public function InitOnce() : Void
    {
        selectedObjects = new Array<EditableObjectBase>();
        hoveredObj = null;
    }
    override public function EnterMode() : Void
    {
        PhysEditor.CursorText_Show();
        PhysEditor.CursorText_Set("");
        SetSubMode("null");
        
        selectedObjects = new Array<EditableObjectBase>();
        hoveredObj = null;
    }
    
    private var dragRot_WorldCentreX : Float;
    private var dragRot_CentreX : Float;
    private var dragRot_WorldCentreY : Float;
    private var dragRot_CentreY : Float;
    
    override public function OnMouseDown(e : MouseEvent) : Void
    {
        super.OnMouseDown(e);
        
        
        if (subMode == "drag")
        {
            PhysEditor.UndoTakeSnapshot();
            
            drag_mouseX = mxs;
            drag_mouseY = mys;
        }
        else if (subMode == "dragbox")
        {
            dragRectX0 = mxs;
            dragRectY0 = mys;
            dragRectX1 = mxs;
            dragRectY1 = mys;
            ClearSelected();
        }
        else if (subMode == "dragrot")
        {
            PhysEditor.UndoTakeSnapshot();
            drag_mouseX = mxs;
            dragRot_CentreX = mx;
            dragRot_CentreY = my;
            dragRot_WorldCentreX = mxs;
            dragRot_WorldCentreY = mys;
        }
        else
        {
            var obj : EditableObjectBase = PhysEditor.HitTestAnyObject(mxs, mys, mx, my);
            ToggleSelected(obj);
        }
    }
    
    private function SelectInDragBox(updateParameters : Bool = true)
    {
        var eob : EdObj;
        var r : Rectangle = GetDragRectangle();
        
        var a : Array<Dynamic> = PhysEditor.DragBoxAnyObject(r);
        
        ClearSelected();
        for (obj in a)
        {
            AddToSelected(obj, updateParameters);
        }
    }
    
    override public function OnMouseUp(e : MouseEvent) : Void
    {
        super.OnMouseUp(e);
        
        if (subMode == "dragbox")
        {
            SelectInDragBox(true);
            KeyReader.ClearKey(KeyReader.KEY_SHIFT);
        }
        else if (subMode == "dragrot")
        {
        }
        
        SetSubMode("null");
    }
    override public function OnMouseMove(e : MouseEvent) : Void
    {
        super.OnMouseMove(e);
        
        if (e.buttonDown)
        {
            hoveredObj = null;
            if (subMode == "dragbox")
            {
                dragRectX1 = mxs;
                dragRectY1 = mys;
                SelectInDragBox(false);
            }
            else if (subMode == "drag")
            {
                var dx : Float = mxs - drag_mouseX;
                var dy : Float = mys - drag_mouseY;
                for (obj in selectedObjects)
                {
                    obj.MoveBy(dx, dy);
                }
                drag_mouseX = mxs;
                drag_mouseY = mys;
            }
            else if (subMode == "dragrot")
            {
                var dx : Float = mxs - drag_mouseX;
                drag_mouseX = mxs;
                for (obj in selectedObjects)
                {
                    obj.RotateBy(dragRot_WorldCentreX, dragRot_WorldCentreY, dx * 0.01);
                }
            }
        }
        else
        {
            var obj : EditableObjectBase = PhysEditor.HitTestAnyObject(mxs, mys, mx, my);
            hoveredObj = obj;
        }
    }
    
    private function getClass(obj : Dynamic) : Class<Dynamic>
    {
        return Class(Type.resolveClass(Type.getClassName(obj)));
    }
    
    override public function OnMouseWheel(delta : Int) : Void
    {
    }
    
    override public function Update() : Void
    {
        super.Update();
        
        if (KeyReader.Pressed(KeyReader.KEY_L) && (KeyReader.Down(KeyReader.KEY_SHIFT) == true))
        {
            SetAllLevelsAllObjectsDefaultGameLayers();
            return;
        }
        
        
        if (KeyReader.Pressed(KeyReader.KEY_TAB) && KeyReader.Down(KeyReader.KEY_CONTROL))
        {
            if (KeyReader.Down(KeyReader.KEY_SHIFT))
            {
                PhysEditor.UndoTakeSnapshot();
                PhysEditor.RemoveEverything();
            }
        }
        
        if (KeyReader.Pressed(KeyReader.KEY_D))
        {
            PhysEditor.UndoTakeSnapshot();
            DuplicateSelectedObjects();
        }
        if (KeyReader.Down(KeyReader.KEY_DELETE) || KeyReader.Down(KeyReader.KEY_SQUIGGLE))
        {
            PhysEditor.UndoTakeSnapshot();
            DeleteSelectedObjects();
        }
        
        
        if (KeyReader.Down(KeyReader.KEY_CONTROL))
        {
            SetSubMode("drag");
        }
        else if (KeyReader.Down(KeyReader.KEY_R))
        {
            SetSubMode("dragrot");
        }
        else if (KeyReader.Down(KeyReader.KEY_SHIFT))
        {
            if (subMode != "dragbox")
            {
                dragRectX0 = mxs;
                dragRectY0 = mys;
                dragRectX1 = mxs;
                dragRectY1 = mys;
                ClearSelected();
            }
            SetSubMode("dragbox");
        }
        else if (KeyReader.Pressed(KeyReader.KEY_C))
        {
            ClearSelected();
        }
        else if (KeyReader.Pressed(KeyReader.KEY_A))
        {
            SelectAll();
        }
        else if (KeyReader.Pressed(KeyReader.KEY_L) && (KeyReader.Down(KeyReader.KEY_SHIFT) == false))
        {
            SetDefaultGameLayers();
        }
        else
        {
            if (subMode == "dragbox")
            {
                SelectInDragBox(true);
            }
            SetSubMode("null");
        }
    }
    
    private var drag_mouseX : Float = 0;
    private var drag_mouseY : Float = 0;
    
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
        for (obj in selectedObjects)
        {
            obj.RenderHighlighted(EditableObjectBase.HIGHLIGHT_SELECTED);
        }
        
        if (subMode == "dragbox")
        {
            var r : Rectangle = GetDragRectangle().clone();
            
            var r1 : Rectangle = PhysEditor.GetMapPosRect(r);
            
            PhysEditor.FillRectangle(r1, 0xffffff, 1, 0.4);
            PhysEditor.RenderRectangle(r1, 0xffffff, 1, 1);
            
            Utils.RenderRectangle(bd, r1, 0xffffffff);
        }
        
        if (subMode == "dragrot")
        {
            Utils.RenderCircle(bd, dragRot_CentreX, dragRot_CentreY, 10, 0xffffffff);
        }
    }
    override public function RenderHud(x : Int, y : Int) : Int
    {
        var s : String;
        s = "Click Objects To Select / unselect";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "CTRL: drag selected";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "R: rotate selected";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "C: Clear Selection";
        y += PhysEditor.AddInfoText("a", x, y, s);
        
        if (hoveredObj != null)
        {
            s = "Hovered: " + hoveredObj.GetEditorHoverName();
            y += PhysEditor.AddInfoText("a", x, y, s);
        }
        
        return y;
    }
    
    private var subMode : String;
    private function SetSubMode(s : String)
    {
        subMode = s;
        
        
        
        
        if (s == "drag")
        {
            PhysEditor.CursorText_Set("Drag Selected Objects");
        }
        else if (s == "dragbox")
        {
            PhysEditor.CursorText_Set("Drag Selection Box");
        }
        else if (s == "dragrot")
        {
            PhysEditor.CursorText_Set("Drag Rotation");
        }
        else
        {
            PhysEditor.CursorText_Set("");
        }
    }
    
    private function GetDragRectangle() : Rectangle
    {
        var x0 : Int = dragRectX0;
        var x1 : Int = dragRectX1;
        var y0 : Int = dragRectY0;
        var y1 : Int = dragRectY1;
        if (dragRectX1 < dragRectX0)
        {
            x0 = dragRectX1;
            x1 = dragRectX0;
        }
        if (dragRectY1 < dragRectY0)
        {
            y0 = dragRectY1;
            y1 = dragRectY0;
        }
        
        var r : Rectangle = new Rectangle(x0, y0, (x1 - x0), (y1 - y0));
        return r;
    }
    
    private function DeleteSelectedObjects()
    {
        for (obj in selectedObjects)
        {
            if (obj.classType != "joint")
            {
                PhysEditor.DeleteObject(obj);
                PhysEditor.editModeObj_Joints.UpdateJoints_ObjectDeleted(obj.id);
            }
        }
        for (obj in selectedObjects)
        {
            if (obj.classType == "joint")
            {
                PhysEditor.DeleteObject(obj);
            }
        }
        ClearSelected();
        hoveredObj = null;
    }
    private function DuplicateSelectedObjects()
    {
        var paramsToChange : Array<Dynamic> = new Array<Dynamic>();
        
        PhysEditor.ClearAllPreviousIDs();
        
        var a : Array<Dynamic> = new Array<Dynamic>();
        for (obj in selectedObjects)
        {
            var obj1 : EditableObjectBase = obj.Duplicate();
            if (obj1 != null)
            {
                obj1.prev_id = obj.id;
                obj1.id = PhysEditor.CreateNewUniqueID();
                a.push(obj1);
                obj1.MoveBy(32, 32);
                
                
                var paramIndex : Int = 0;
                for (p/* AS3HX WARNING could not determine type for var: p exp: EField(EField(EIdent(obj1),objParameters),list) type: null */ in obj1.objParameters.list)
                {
                    var op : ObjParam = ObjectParameters.GetObjectParamByName(p.name);
                    if (op != null)
                    {
                        if (op.type == "linelink")
                        {
                            paramsToChange.push(p);
                        }
                    }
                    paramIndex++;
                }
            }
        }
        
        for (p in paramsToChange)
        {
            for (obj1 in a)
            {
                if (obj1.prev_id == p.value)
                {
                    p.value = obj1.id;
                }
            }
        }
        
        
        ClearSelected();
        for (obj in a)
        {
            if (obj.classType == "obj")
            {
                PhysEditor.GetCurrentLevelInstances().push(obj);
            }
            if (obj.classType == "line")
            {
                PhysEditor.GetCurrentLevelLines().push(obj);
            }
            if (obj.classType == "joint")
            {
                PhysEditor.GetCurrentLevelJoints().push(obj);
            }
            AddToSelected(obj);
        }
        
        
        for (obj in a)
        {
            if (obj.classType == "joint")
            {
                var j : EdJoint = try cast(obj, EdJoint) catch(e:Dynamic) null;
                j.UpdateLinkages();
            }
            AddToSelected(obj);
        }
        
        
        PhysEditor.ClearAllPreviousIDs();
    }
}


