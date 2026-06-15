package editorPackage;

import haxe.Constraints.Function;
import editorPackage.editParamUI.EditParams;
import flash.display.BitmapData;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.geom.Rectangle;

/**
	 * ...
	 * @author LongAnimals
	 */
class EditModeAdjust extends EditModeBase
{
    public var currentAdjustObject : EdObj;
    public var currentAdjustObject_mouseX : Int = 0;
    public var currentAdjustObject_mouseY : Int = 0;
    public var currentAdjustObjectParam : Int = 0;
    public var dragRectX0 : Int;
    public var dragRectX1 : Int;
    public var dragRectY0 : Int;
    public var dragRectY1 : Int;
    
    public var currentPlacementObject : EdPlacementObj;
    
    
    public function new()
    {
        super();
    }
    
    override public function EnterMode() : Void
    {
        PhysEditor.CursorText_Show();
        PhysEditor.CursorText_Set("");
        SetSubMode("null");
        
        currentPlacementObject = null;
        
        currentAdjustObject = null;
    }
    
    override public function InitOnce() : Void
    {
        currentAdjustObject = null;
        InitKeypressModes();
    }
    
    
    public function PickSinglePlacementObject(obj : EdPlacementObj)
    {
        currentPlacementObject = obj;
    }
    
    public function SelectEditObject(poi : EdObj)
    {
        if (poi != null)
        {
            PickSinglePlacementObject(null);
            currentAdjustObject = poi;
            EditParams.AddParameterListBox(poi.objParameters);
        }
        else
        {
            ClearCurrentAdjustObject();
            EditParams.ClearParameterListBox();
        }
    }
    
    override public function OnMouseDown(e : MouseEvent) : Void
    {
        super.OnMouseDown(e);
        
        var z : Float = 1.0 / PhysEditor.zoom;
        Utils.print("HERE MouseDown");
        var poi : EdObj = null;        
        
        if (subMode == "place_rot")
        {
            currentAdjustObject_mouseX = mx;
        }
        if (subMode == "place_change")
        {
            currentAdjustObject_mouseX = mx;
        }
        if (subMode == "place_scale")
        {
            currentAdjustObject_mouseX = mx;
        }
        if (subMode == "dragpos")
        {
            PhysEditor.UndoTakeSnapshot();
            
            currentAdjustObject_mouseX = mxs;
            currentAdjustObject_mouseY = mys;
        }
        if (subMode == "dragrot")
        {
            currentAdjustObject_mouseX = mx;
        }
        if (subMode == "dragscale")
        {
            currentAdjustObject_mouseX = mx;
        }
        if (subMode == "pick")
        {
            PickObject();
        }
        if (subMode == "place")
        {
            PhysEditor.UndoTakeSnapshot();
            
            
            var level_instances : Array<Dynamic> = PhysEditor.GetCurrentLevelInstances();
            
            var physObj : PhysObj = null;            
            if (currentPlacementObject != null)
            {
                currentPlacementObject.xpos = mxs;
                currentPlacementObject.ypos = mys;
                
                var ob : EdPlacementObj = currentPlacementObject;
                
                ob.xpos = mxs;
                ob.ypos = mys;
                
                var posx : Float = ob.xpos;
                var posy : Float = ob.ypos;
                
                physObj = Game.objectDefs.FindByName(ob.typeName);
                var pieceName : String = physObj.name;
                
                if (false)
                {
                    var ppp : Point = PhysEditor.SnapToObjects(mxs, mys);
                    if (ppp != null)
                    {
                        Utils.print("snapped to point :" + mxs + " " + mys + "   ->   " + ppp.x + " " + ppp.y);
                        posx = ppp.x;
                        posy = ppp.y;
                    }
                }
                
                
                var pi : EdObj = Levels.CreateLevelObjInstanceAt(pieceName, posx, posy, ob.rot, ob.scale, "", null);
                
                var physobj : PhysObj = Game.objectDefs.FindByName(pieceName);
                if (physobj != null)
                {
                    for (i in 0...physObj.instanceParams.length)
                    {
                        var def : String = physObj.instanceParamsDefaults[i];
                        if (def == "")
                        {
                            def = null;
                        }
                        pi.objParameters.AddOrSet(physObj.instanceParams[i], def);
                    }
                }
                if (ob.objParameters != null)
                {
                    pi.objParameters = ob.objParameters.Clone();
                }
                pi.objParameters.SetParam("editor_layer", Std.string(EditorLayers.GetActive()));
                
                level_instances.push(pi);
                PhysEditor.SetCurrentLevelInstances(level_instances);
            }
        }
    }
    
    
    
    
    override public function OnMouseUp(e : MouseEvent) : Void
    {
        super.OnMouseUp(e);
        
        if (subMode == "place_rot")
        {
            SetSubMode("place");
        }
        if (subMode == "place_change")
        {
            SetSubMode("place");
        }
        if (subMode == "place_scale")
        {
            SetSubMode("place");
        }
        
        if (subMode == "dragpos")
        {
            SetSubMode("edit");
        }
        if (subMode == "dragrot")
        {
            SetSubMode("edit");
        }
        if (subMode == "dragscale")
        {
            SetSubMode("edit");
        }
    }
    
    override public function OnMouseMove(e : MouseEvent) : Void
    {
        super.OnMouseMove(e);
        
        var z : Float = 1.0 / PhysEditor.zoom;
        var z1 : Float = 1;
        
        var poi : EdObj = null;        
        if (subMode == "place")
        {
            SetCurrentPlacementObjectPosition();
        }
        
        
        if (e.buttonDown)
        {
            if (currentPlacementObject != null)
            {
                if (subMode == "place_rot")
                {
                    var dx : Float = mx - currentAdjustObject_mouseX;
                    currentPlacementObject.rot += (dx * 1);
                    currentAdjustObject_mouseX = mx;
                }
                if (subMode == "place_change")
                {
                    var dx : Float = mx - currentAdjustObject_mouseX;
                    if (Math.abs(dx) > 10)
                    {
                        if (dx < 0)
                        {
                            AddCurrentPlacementObject(-1);
                        }
                        if (dx > 0)
                        {
                            AddCurrentPlacementObject(1);
                        }
                        currentAdjustObject_mouseX = mx;
                    }
                }
                if (subMode == "place_scale")
                {
                    var dx : Float = mx - currentAdjustObject_mouseX;
                    currentPlacementObject.scale += (dx * 0.01);
                    currentAdjustObject_mouseX = mx;
                }
            }
            if (currentAdjustObject != null)
            {
                if (subMode == "dragrot")
                {
                    PhysEditor.UndoTakeSnapshot();
                    var dx : Float = mx - currentAdjustObject_mouseX;
                    poi = currentAdjustObject;
                    poi.rot += (dx * 1);
                    currentAdjustObject_mouseX = mx;
                }
                else if (subMode == "dragscale")
                {
                    PhysEditor.UndoTakeSnapshot();
                    var dx : Float = mx - currentAdjustObject_mouseX;
                    poi = currentAdjustObject;
                    poi.scale += (dx * 0.01);
                    currentAdjustObject_mouseX = mx;
                }
                else if (subMode == "dragpos")
                {
                    var i : Int = 0;
                    poi = currentAdjustObject;
                    var dx : Float = mxs - currentAdjustObject_mouseX;
                    var dy : Float = mys - currentAdjustObject_mouseY;
                    
                    poi.x += dx;
                    poi.y += dy;
                    PhysEditor.editModeObj_Joints.UpdateJoints_ObjectMoved(poi.id, dx, dy);
                    currentAdjustObject_mouseX = mxs;
                    currentAdjustObject_mouseY = mys;
                }
            }
        }
    }
    override public function OnMouseWheel(delta : Int) : Void
    {
        if (currentAdjustObject != null)
        {
            var index : Int = 0;            if (delta > 0)
            {
                PhysEditor.UndoTakeSnapshot();
                index = Game.objectDefs.FindIndexByName(currentAdjustObject.typeName);
                index++;
                if (index >= Game.objectDefs.GetNum())
                {
                    index = 0;
                }
                currentAdjustObject.typeName = Game.objectDefs.GetByIndex(index).name;
            }
            if (delta < 0)
            {
                PhysEditor.UndoTakeSnapshot();
                index = Game.objectDefs.FindIndexByName(currentAdjustObject.typeName);
                index--;
                if (index < 0)
                {
                    index = as3hx.Compat.parseInt(Game.objectDefs.GetNum() - 1);
                }
                currentAdjustObject.typeName = Game.objectDefs.GetByIndex(index).name;
            }
        }
        
        if (currentPlacementObject != null)
        {
            var index : Int = 0;            if (delta == 0)
            {
                return;
            }
            
            var dx : Float = 0;
            if (KeyReader.Down(KeyReader.KEY_CONTROL))
            {
                dx = delta * Utils.DegToRad(45);
                currentPlacementObject.rot += dx;
            }
            else if (KeyReader.Down(KeyReader.KEY_SHIFT))
            {
                dx = delta * 0.1;
                currentPlacementObject.scale += dx;
            }
            else
            {
                if (delta < 0)
                {
                    AddCurrentPlacementObject(-1);
                }
                if (delta > 0)
                {
                    AddCurrentPlacementObject(1);
                }
            }
        }
    }
    
    public var keypressModes : Array<Dynamic>;
    public function InitKeypressModes()
    {
        keypressModes = [];
        keypressModes.push(new EditSubModeData("null", false, 0, ""));
        keypressModes.push(new EditSubModeData("place", true, 0, "Place Object"));
        keypressModes.push(new EditSubModeData("place_scale", true, KeyReader.KEY_S, "Drag to Scale Place Object"));
        keypressModes.push(new EditSubModeData("place_rot", true, KeyReader.KEY_R, "Drag to Rotate Place Object"));
        keypressModes.push(new EditSubModeData("place_change", true, KeyReader.KEY_F, "Drag to Change Place Object"));
        keypressModes.push(new EditSubModeData("pick", true, KeyReader.KEY_P, ""));
        keypressModes.push(new EditSubModeData("duplicate", false, KeyReader.KEY_D, ""));
        keypressModes.push(new EditSubModeData("edit", true, KeyReader.KEY_E, "Edit"));
        keypressModes.push(new EditSubModeData("dragscale", true, KeyReader.KEY_S, "Drag for Scale"));
        keypressModes.push(new EditSubModeData("dragrot", true, KeyReader.KEY_R, "Drag for Rotation"));
        keypressModes.push(new EditSubModeData("dragpos", true, KeyReader.KEY_CONTROL, "Drag Object"));
        keypressModes.push(new EditSubModeData("delete", false, KeyReader.KEY_DELETE, ""));
        keypressModes.push(new EditSubModeData("copyparams", false, KeyReader.KEY_C, ""));
        keypressModes.push(new EditSubModeData("pasteparams", false, KeyReader.KEY_V, ""));
    }
    
    public function SetCursorTextFromKeypressName(modeName : String)
    {
        for (mode in keypressModes)
        {
            if (modeName == mode.name)
            {
                if (mode.displayName != "")
                {
                    PhysEditor.CursorText_Set(mode.displayName);
                }
            }
        }
    }
    
    public function HandleKeypressModifier(modeName : String, func : Function = null)
    {
        for (mode in keypressModes)
        {
            if (modeName == mode.name)
            {
                if (KeyReader.Down(mode.keyCode))
                {
                    if (mode.displayName != "")
                    {
                        PhysEditor.CursorText_Set(mode.displayName);
                    }
                    if (mode.setMode)
                    {
                        subMode = modeName;
                    }
                    if (func != null)
                    {
                        func();
                    }
                }
            }
        }
    }
    public function HandleKeypressModifierNotHeld(modeName : String, newMode : String)
    {
        for (mode in keypressModes)
        {
            if (modeName == mode.name)
            {
                if (KeyReader.Down(mode.keyCode) == false)
                {
                    SetSubMode(newMode);
                }
            }
        }
    }
    
    
    public function HandleKeypress(modeName : String, held : Bool, func : Function = null)
    {
        for (mode in keypressModes)
        {
            if (modeName == mode.name)
            {
                if (held == false)
                {
                    if (KeyReader.Pressed(mode.keyCode))
                    {
                        if (mode.displayName != "")
                        {
                            PhysEditor.CursorText_Set(mode.displayName);
                        }
                        if (mode.setMode)
                        {
                            subMode = modeName;
                        }
                        if (func != null)
                        {
                            func();
                        }
                    }
                }
                else if (held == true)
                {
                    if (KeyReader.Pressed(mode.keyCode))
                    {
                        if (mode.displayName != "")
                        {
                            PhysEditor.CursorText_Set(mode.displayName);
                        }
                        if (mode.setMode)
                        {
                            subMode = modeName;
                        }
                        if (func != null)
                        {
                            func();
                        }
                    }
                }
            }
        }
    }
    
    override public function Update() : Void
    {
        super.Update();
        
        
        
        if (subMode == "place")
        {
            SetCurrentPlacementObjectPosition();
        }
        
        if (subMode == "place")
        {
            HandleKeypress("pick", false, PickObject);
            HandleKeypress("edit", false, PickEditPiece);
            HandleKeypress("place_scale", true, null);
            HandleKeypress("place_rot", true, null);
            HandleKeypress("place_change", true, null);
        }
        
        if (subMode == "null")
        {
            HandleKeypress("pick", false, PickObject);
            HandleKeypress("edit", false, PickEditPiece);
        }
        
        
        
        if (subMode == "edit")
        {
            HandleKeypress("pick", false, PickObject);
            HandleKeypress("edit", false, PickEditPiece);
            HandleKeypress("duplicate", false, DuplicateEditObject);
            HandleKeypress("delete", false, DeleteEditObject);
            HandleKeypress("dragscale", true, null);
            HandleKeypress("dragrot", true, null);
            HandleKeypress("copyparams", false, CopyParameters);
            HandleKeypress("pasteparams", false, PasteParameters);
            HandleKeypressModifier("dragpos");
        }
        
        if (subMode == "dragpos")
        {
            HandleKeypressModifierNotHeld("dragpos", "edit");
        }
        
        
        if (KeyReader.Pressed(KeyReader.KEY_TAB) && KeyReader.Down(KeyReader.KEY_CONTROL))
        {
            PhysEditor.UndoTakeSnapshot();
            
            if (KeyReader.Down(KeyReader.KEY_SHIFT))
            {
                PhysEditor.RemoveEverything();
            }
            PhysEditor.GetCurrentLevel().instances = [];
        }
        
        
        if (currentAdjustObject != null)
        {
            var v : Float = 1;
            var rv : Float = 1;
            var rotvel : Float = 0;
            var xvel : Float = 0;
            var yvel : Float = 0;
            if (KeyReader.Down(KeyReader.KEY_CONTROL))
            {
                v *= 10;
                rv *= 10;
            }
            if (KeyReader.Down(KeyReader.KEY_SHIFT))
            {
                if (KeyReader.Down(KeyReader.KEY_LEFT))
                {
                    xvel = -v;
                }
                if (KeyReader.Down(KeyReader.KEY_RIGHT))
                {
                    xvel = v;
                }
                if (KeyReader.Down(KeyReader.KEY_UP))
                {
                    yvel = -v;
                }
                if (KeyReader.Down(KeyReader.KEY_DOWN))
                {
                    yvel = v;
                }
                
                if (xvel != 0 || yvel != 0)
                {
                    PhysEditor.UndoTakeSnapshot();
                }
                currentAdjustObject.x += xvel;
                currentAdjustObject.y += yvel;
            }
            
            if (KeyReader.Down(KeyReader.KEY_4))
            {
                currentAdjustObject.scale -= 0.01;
            }
            if (KeyReader.Down(KeyReader.KEY_5))
            {
                currentAdjustObject.scale += 0.01;
            }
            
            if (KeyReader.Down(KeyReader.KEY_6))
            {
                rotvel = -rv;
            }
            if (KeyReader.Down(KeyReader.KEY_7))
            {
                rotvel = rv;
            }
            
            if (KeyReader.Pressed(KeyReader.KEY_8))
            {
                index = Game.objectDefs.FindIndexByName(currentAdjustObject.typeName);
                index--;
                if (index < 0)
                {
                    index = as3hx.Compat.parseInt(Game.objectDefs.GetNum() - 1);
                }
                currentAdjustObject.typeName = Game.objectDefs.GetByIndex(index).name;
            }
            if (KeyReader.Pressed(KeyReader.KEY_9))
            {
                var index : Int = Game.objectDefs.FindIndexByName(currentAdjustObject.typeName);
                index++;
                if (index >= Game.objectDefs.GetNum())
                {
                    index = 0;
                }
                currentAdjustObject.typeName = Game.objectDefs.GetByIndex(index).name;
            }
            
            
            if (rotvel != 0)
            {
                PhysEditor.UndoTakeSnapshot();
            }
            currentAdjustObject.rot += rotvel;
            
            if (KeyReader.Pressed(KeyReader.KEY_I))
            {
                PhysEditor.UndoTakeSnapshot();
                CurrentAdjustObject_EnterID();
            }
        }
        if (currentPlacementObject != null)
        {
            rotvel = 0;
            
            if (KeyReader.Down(KeyReader.KEY_4))
            {
                currentPlacementObject.scale -= 0.01;
            }
            if (KeyReader.Down(KeyReader.KEY_5))
            {
                currentPlacementObject.scale += 0.01;
            }
            
            if (KeyReader.Down(KeyReader.KEY_6))
            {
                rotvel = -rv;
            }
            if (KeyReader.Down(KeyReader.KEY_7))
            {
                rotvel = rv;
            }
            currentPlacementObject.rot += rotvel;
            
            if (KeyReader.Pressed(KeyReader.KEY_8))
            {
                index = Game.objectDefs.FindIndexByName(currentPlacementObject.typeName);
                index--;
                if (index < 0)
                {
                    index = as3hx.Compat.parseInt(Game.objectDefs.GetNum() - 1);
                }
                currentPlacementObject.typeName = Game.objectDefs.GetByIndex(index).name;
            }
            if (KeyReader.Pressed(KeyReader.KEY_9))
            {
                var index : Int = Game.objectDefs.FindIndexByName(currentPlacementObject.typeName);
                index++;
                if (index >= Game.objectDefs.GetNum())
                {
                    index = 0;
                }
                currentPlacementObject.typeName = Game.objectDefs.GetByIndex(index).name;
            }
        }
    }
    
    public function AddCurrentPlacementObject(amt : Int)
    {
        if (amt < 0)
        {
            index = Game.objectDefs.FindIndexByName(currentPlacementObject.typeName);
            index--;
            if (index < 0)
            {
                index = as3hx.Compat.parseInt(Game.objectDefs.GetNum() - 1);
            }
            currentPlacementObject.typeName = Game.objectDefs.GetByIndex(index).name;
        }
        if (amt > 0)
        {
            var index : Int = Game.objectDefs.FindIndexByName(currentPlacementObject.typeName);
            index++;
            if (index >= Game.objectDefs.GetNum())
            {
                index = 0;
            }
            currentPlacementObject.typeName = Game.objectDefs.GetByIndex(index).name;
        }
    }
    
    public var copiedParameters : ObjParameters = null;
    public function CopyParameters()
    {
        if (currentAdjustObject != null)
        {
            copiedParameters = currentAdjustObject.objParameters.Clone();
            EdConsole.Add("Copy Parameters");
        }
    }
    public function PasteParameters()
    {
        if (copiedParameters == null)
        {
            return;
        }
        if (currentAdjustObject == null)
        {
            return;
        }
        PhysEditor.UndoTakeSnapshot();
        currentAdjustObject.objParameters = copiedParameters.Clone();
        EditParams.ClearParameterListBox();
        EditParams.AddParameterListBox(currentAdjustObject.objParameters);
        EdConsole.Add("Paste Parameters");
    }
    
    
    
    
    override public function Render(bd : BitmapData) : Void
    {
        super.Render(bd);
        
        
        bd.fillRect(Defs.screenRect, 0xff445566);
        PhysEditor.RenderBackground(bd);
        
        PhysEditor.RenderSortedEdObjs();
        
        PhysEditor.Editor_RenderJoints(bd);
        
        
        PhysEditor.Editor_RenderGrid(bd);
        
        if (subMode == "edit" || subMode == "dragpos")
        {
            if (currentAdjustObject != null)
            {
                currentAdjustObject.RenderHighlighted(EditableObjectBase.HIGHLIGHT_SELECTED);
            }
        }
        
        
        if (subMode == "place" || subMode == "place_rot" || subMode == "place_scale" || subMode == "place_change")
        {
            var physObj : PhysObj = null;            if (currentPlacementObject != null)
            {
                var ob : EdPlacementObj = currentPlacementObject;
                physObj = Game.objectDefs.FindByName(ob.typeName);
                var p : Point = PhysEditor.GetMapPos(ob.xpos + ob.xoff, ob.ypos + ob.yoff);
                PhysObj.RenderAt(physObj, p.x, p.y, ob.rot, ob.scale * PhysEditor.zoom, bd, PhysEditor.linesScreen.graphics, true);
            }
        }
    }
    
    override public function RenderHud(x : Int, y : Int) : Int
    {
        var s : String = null;        
        y += PhysEditor.AddInfoText("a", x, y, "E: Pick obj to edit");
        y += PhysEditor.AddInfoText("a", x, y, "P: Pick obj to place");
        
        if (subMode == "null")
        {
        }
        if (subMode == "edit")
        {
            if (currentAdjustObject != null)
            {
                y += PhysEditor.AddInfoText("a", x, y, "R: rotate");
                y += PhysEditor.AddInfoText("a", x, y, "S: scale");
                y += PhysEditor.AddInfoText("a", x, y, "F: change type");
                y += PhysEditor.AddInfoText("a", x, y, "D: duplicate");
                y += PhysEditor.AddInfoText("a", x, y, "DEL: delete");
                y += PhysEditor.AddInfoText("a", x, y, "CTRL (hold): drag");
                
                s = "";
                y += PhysEditor.AddInfoText("a", x, y, "Shift + Arrows: Move Piece");
                s = "6/7: Rotate: ";
                s += currentAdjustObject.rot;
                y += PhysEditor.AddInfoText("a", x, y, s);
                s = "4/5: Scale: ";
                s += currentAdjustObject.scale;
                y += PhysEditor.AddInfoText("a", x, y, s);
                s = "8/9: Change block type";
                y += PhysEditor.AddInfoText("a", x, y, s);
                y += PhysEditor.AddInfoText("a", x, y, "C: Copy Parameters");
                y += PhysEditor.AddInfoText("a", x, y, "V: Paste Parameters");
                
                s = "I: Object ID: ";
                if (currentAdjustObject == null)
                {
                    s += "NONE";
                }
                else
                {
                    s += currentAdjustObject.id;
                }
                y += PhysEditor.AddInfoText("a", x, y, s);
                
                s = "Object type: ";
                if (currentAdjustObject == null)
                {
                    s += "NONE";
                }
                else
                {
                    s += currentAdjustObject.typeName;
                }
                y += PhysEditor.AddInfoText("a", x, y, s);
            }
        }
        if (subMode == "place")
        {
            y += PhysEditor.AddInfoText("a", x, y, "R: rotate");
            y += PhysEditor.AddInfoText("a", x, y, "S: scale");
            y += PhysEditor.AddInfoText("a", x, y, "F: change type");
        }
        
        
        
        if (currentAdjustObject != null)
        {
            s = "Pos: " + currentAdjustObject.x + " " + currentAdjustObject.y + "     Rot: " + currentAdjustObject.rot;
            y += PhysEditor.AddInfoText("a", x, y, s);
        }
        
        return y;
    }
    
    
    
    public function Editor_RenderObjects_AdjustMode(bd : BitmapData)
    {
        var level_instances : Array<Dynamic> = GetCurrentLevelInstances();
        
        if (PhysEditor.objectZSortMode)
        {
            level_instances = PhysEditor.SortInstancesByZ(level_instances);
        }
        
        
        for (poi in level_instances)
        {
            var po : PhysObj = Game.objectDefs.FindByName(poi.typeName);
            
            var p : Point = PhysEditor.GetMapPos(poi.x, poi.y);
            
            var doit : Bool = true;
            
            if (poi == currentAdjustObject)
            {
                if ((PhysEditor.updateTimer & 2) != 0)
                {
                    doit = false;
                }
            }
            
            if (doit)
            {
                if (po.editorRenderFunctionName != null)
                {
                    var renderer : EditorGameRenderer = new EditorGameRenderer();
                    renderer[po.editorRenderFunctionName](po, poi);
                }
                else
                {
                    PhysObj.RenderAt(po, p.x, p.y, poi.rot, poi.scale * PhysEditor.zoom, bd, PhysEditor.linesScreen.graphics, true);
                }
            }
        }
    }
    
    
    
    
    
    
    public function GetDragRectangle() : Rectangle
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
    
    
    public function ClearCurrentAdjustObject()
    {
        currentAdjustObject = null;
    }
    
    public function CurrentAdjustObject_EnterID()
    {
        if (currentAdjustObject == null)
        {
            return;
        }
        PhysEditor.AddTextEntry(100, 100, "object ID ", currentAdjustObject.id, CurrentAdjustObject_EnterID_Done);
    }
    public function CurrentAdjustObject_EnterID_Done(text : String)
    {
        Utils.print("here " + text);
        currentAdjustObject.id = text;
    }
    
    public var subMode : String;
    public function SetSubMode(s : String)
    {
        subMode = s;
        SetCursorTextFromKeypressName(s);
    }
    
    public function PickObject()
    {
        var poi : EdObj = null;        
        poi = PhysEditor.HitTestPhysObjGraphics(mx, my);
        if (poi != null)
        {
            var po : EdPlacementObj = new EdPlacementObj(poi.typeName, poi.objParameters);
            po.scale = poi.scale;
            po.rot = poi.rot;
            PickSinglePlacementObject(po);
            ClearCurrentAdjustObject();
            SetSubMode("place");
            KeyReader.ClearKey(KeyReader.KEY_P);
        }
        else
        {
            PickSinglePlacementObject(null);
            ClearCurrentAdjustObject();
            SetSubMode("null");
            KeyReader.ClearKey(KeyReader.KEY_P);
        }
    }
    
    public function PickEditPiece()
    {
        var poi : EdObj = null;        
        poi = PhysEditor.HitTestPhysObjGraphics(mx, my);
        SelectEditObject(poi);
        SetSubMode("edit");
    }
    
    public function DeleteEditObject()
    {
        if (currentAdjustObject == null)
        {
            return;
        }
        
        PhysEditor.UndoTakeSnapshot();
        PhysEditor.editModeObj_Joints.UpdateJoints_ObjectDeleted(currentAdjustObject.id);
        PhysEditor.RemoveFromLevelInstances(currentAdjustObject);
        SelectEditObject(null);
        PickSinglePlacementObject(null);
    }
    
    public function DuplicateEditObject()
    {
        if (currentAdjustObject == null)
        {
            return;
        }
        
        var poi : EdObj = null;        
        var newpoi : EdObj = currentAdjustObject.Clone();
        
        var level_instances : Array<Dynamic> = PhysEditor.GetCurrentLevelInstances();
        newpoi.x += 20;
        newpoi.y += 20;
        level_instances.push(newpoi);
        PhysEditor.SetCurrentLevelInstances(level_instances);
        ClearCurrentAdjustObject();
        SelectEditObject(newpoi);
        EditParams.AddParameterListBox(newpoi.objParameters);
        PickSinglePlacementObject(null);
    }
    
    public function SetCurrentPlacementObjectPosition()
    {
        if (currentPlacementObject != null)
        {
            currentPlacementObject.xpos = mxs;
            currentPlacementObject.ypos = mys;
        }
    }
}


