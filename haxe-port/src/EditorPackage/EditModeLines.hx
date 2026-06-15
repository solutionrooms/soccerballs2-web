package editorPackage;

import editorPackage.editParamUI.EditParams;
import flash.display.BitmapData;
import flash.events.MouseEvent;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

/**
	 * ...
	 * @author LongAnimals
	 */
class EditModeLines extends EditModeBase
{
    public var addlineActive : Bool;
    public var hoveredLineIndex : Int;
    public var hoveredPointIndex : Int;
    public var hoveredPointLineIndex : Int;
    public var dragPoint : Point;
    public var lastLineSelectedIndex : Int;
    public var copiedParameters : ObjParameters;
    
    public var freeLine_MinDist : Int = 10;
    
    public function new()
    {
        super();
    }
    
    
    public function CopyParameters()
    {
        var l : EdLine = GetCurrentLine();
        if (l == null)
        {
            return;
        }
        copiedParameters = l.objParameters.Clone();
    }
    public function PasteParameters()
    {
        var l : EdLine = GetCurrentLine();
        if (l == null)
        {
            return;
        }
        if (copiedParameters == null)
        {
            return;
        }
        PhysEditor.UndoTakeSnapshot();
        l.objParameters = copiedParameters.Clone();
    }
    
    override public function EnterMode() : Void
    {
        PhysEditor.CursorText_Show();
        PhysEditor.CursorText_Set("");
        SetSubMode("null");
        hoveredLineIndex = -1;
        hoveredPointIndex = -1;
        hoveredPointLineIndex = -1;
        currentLineIndex = -1;
    }
    override public function InitOnce() : Void
    {
        currentLineIndex = -1;
        currentPointIndex = -1;
        addlineActive = false;
        var l : Level = GetCurrentLevel();
        currentLineIndex = l.lines.length - 1;
        hoveredLineIndex = -1;
        lastLineSelectedIndex = -1;
        dragPoint = new Point(0, 0);
        copiedParameters = null;
    }
    
    
    override public function OnMouseDown(e : MouseEvent) : Void
    {
        super.OnMouseDown(e);
        
        
        if (subMode == "scaleline")
        {
            Lines_SelectLineByArea(mxs, mys);
            Lines_StartScale(mxs, mys);
        }
        else if (subMode == "rotateline")
        {
            Lines_SelectLineByArea(mxs, mys);
            Lines_StartRotate(mxs, mys);
        }
        else if (subMode == "freeline")
        {
            FreeLine_Start();
        }
        else if (subMode == "newline")
        {
            PhysEditor.UndoTakeSnapshot();
            addlineActive = true;
            currentPointIndex = -1;
            Lines_NewLine();
            Lines_AddPoint(mxs, mys);
            var line : EdLine = Lines_GetLineByIndex(currentLineIndex);
            EditParams.AddParameterListBox(line.objParameters);
            SetSubMode("addpoint");
        }
        else if (subMode == "newrectangle")
        {
            PhysEditor.UndoTakeSnapshot();
            addlineActive = true;
            currentPointIndex = -1;
            Lines_NewRect();
            var line : EdLine = Lines_GetLineByIndex(currentLineIndex);
            EditParams.AddParameterListBox(line.objParameters);
            SetSubMode("addpoint");
            return;
        }
        else if (subMode == "dragpoint")
        {
            PhysEditor.UndoTakeSnapshot();
            Lines_SelectPoint(mxs, mys);
        }
        else if (subMode == "dragline")
        {
            PhysEditor.UndoTakeSnapshot();
            Lines_SelectLineByArea(mxs, mys);
            dragPoint = new Point(mxs, mys);
        }
        else if (addlineActive)
        {
            if (GetCurrentLinePrimitiveType() == EdLine.PRIMITIVE_LINE)
            {
                PhysEditor.UndoTakeSnapshot();
                Lines_AddPoint(mxs, mys);
                Utils.print("adding point at " + mxs + " " + mys);
            }
        }
    }
    
    override public function OnMouseUp(e : MouseEvent) : Void
    {
        super.OnMouseUp(e);
        
        if (subMode == "scaleline")
        {
            var scale : Float = 1 + ((mxs - scaleCentreX) * 0.005);
            Lines_Scale(scale);
        }
        else if (subMode == "freeline")
        {
            FreeLine_End();
        }
    }
    
    public function GetHoveredLine()
    {
        var li : Int = currentLineIndex;
        var pi : Int = currentPointIndex;
        Lines_SelectLineByArea(mxs, mys);
        if (currentLineIndex == -1)
        {
            Lines_SelectLine(mxs, mys);
        }
        hoveredLineIndex = currentLineIndex;
        Lines_SelectPoint(mxs, mys);
        hoveredPointIndex = currentPointIndex;
        hoveredPointLineIndex = currentLineIndex;
        currentLineIndex = li;
        currentPointIndex = pi;
    }
    
    override public function OnMouseMove(e : MouseEvent) : Void
    {
        super.OnMouseMove(e);
        
        var l : Level = GetCurrentLevel();
        
        hoveredLineIndex = -1;
        GetHoveredLine();
        
        if (subMode == "dragline" && e.buttonDown == false)
        {
            GetHoveredLine();
        }
        if (subMode == "scaleline" && e.buttonDown == false)
        {
            GetHoveredLine();
        }
        if (subMode == "rotateline" && e.buttonDown == false)
        {
            GetHoveredLine();
        }
        
        
        if (e.buttonDown == false)
        {
            return;
        }
        else if (subMode == "freeline")
        {
            FreeLine_Move();
        }
        
        if (subMode == "newrectangle")
        {
            PhysEditor.UndoTakeSnapshot();
            Lines_DragRect(mxs, mys);
        }
        
        if (subMode == "dragpoint")
        {
            if (currentPointIndex != -1)
            {
                var line : EdLine = l.lines[currentLineIndex];
                if (line.primitiveType == EdLine.PRIMITIVE_LINE)
                {
                    var p : Point = line.points[currentPointIndex];
                    p.x = mxs;
                    p.y = mys;
                    
                    
                    Utils.print(mxs + " " + mys);
                }
                if (line.primitiveType == EdLine.PRIMITIVE_RECTANGLE)
                {
                    var p : Point = line.points[currentPointIndex];
                    if (currentPointIndex == 0)
                    {
                        if (mxs < line.points[2].x && mys < line.points[2].y)
                        {
                            p.x = mxs;
                            p.y = mys;
                            line.points[1].y = mys;
                            line.points[3].x = mxs;
                        }
                    }
                    if (currentPointIndex == 2)
                    {
                        if (mxs > line.points[0].x && mys > line.points[0].y)
                        {
                            p.x = mxs;
                            p.y = mys;
                            line.points[1].x = mxs;
                            line.points[3].y = mys;
                        }
                    }
                }
            }
        }
        if (subMode == "dragline")
        {
            if (currentLineIndex != -1)
            {
                var dx : Float = mxs - dragPoint.x;
                var dy : Float = mys - dragPoint.y;
                for (p/* AS3HX WARNING could not determine type for var: p exp: EField(EArray(EField(EIdent(l),lines),EIdent(currentLineIndex)),points) type: null */ in l.lines[currentLineIndex].points)
                {
                    p.x += dx;
                    p.y += dy;
                }
                dragPoint = new Point(mxs, mys);
            }
        }
        else if (subMode == "scaleline")
        {
            var scale : Float = 1 + ((mxs - scaleCentreX) * 0.005);
            Lines_Scale(scale);
        }
        else if (subMode == "rotateline")
        {
            var rot : Float = ((mxs - rotateCentreX) * 0.005);
            Lines_Rotate(rot);
        }
    }
    
    
    public function UpdateObjectsWhichSnapToLines()
    {
        var l : Level = GetCurrentLevel();
        var line : EdLine = l.lines[currentLineIndex];
        
        var l1 : Int = currentPointIndex;
        var l0 : Int = as3hx.Compat.parseInt(currentPointIndex - 1);
        if (l0 < 0)
        {
            l0 = as3hx.Compat.parseInt(line.points.length - 1);
        }
        var l2 : Int = as3hx.Compat.parseInt(currentPointIndex + 1);
        if (l2 >= line.points.length)
        {
            l2 = 0;
        }
        
        
        for (q in 0...2)
        {
            var p : Point = line.points[l1];
            var p1 : Point = line.points[l2];
            
            if (q == 1)
            {
                p = line.points[l0];
                p1 = line.points[l1];
            }
            
            var x0 : Float = p.x;
            var x1 : Float = p1.x;
            if (x0 > x1)
            {
                x0 = p1.x;
                x1 = p.x;
            }
            var y0 : Float = p.y;
            var y1 : Float = p1.y;
            
            
            var list : Array<Dynamic> = [];
            var percents : Array<Dynamic> = [];
            var yoffs : Array<Dynamic> = [];
            
            var level_instances : Array<Dynamic> = GetCurrentLevelInstances();
            for (obj in level_instances)
            {
                var po : PhysObj = Game.objectDefs.FindByName(obj.typeName);
                if (po.snapToFloor)
                {
                    if (obj.x >= x0 && obj.x <= x1)
                    {
                        list.push(obj);
                        var pc : Float = Utils.ScaleTo(0, 1, x0, x1, obj.x);
                        percents.push(pc);
                        
                        var y : Float = Utils.ScaleTo(y0, y1, 0, 1, pc);
                        
                        yoffs.push(obj.y - y);
                    }
                }
            }
            
            
            if (list.length != 0)
            {
                var p : Point = new Point(mxs, mys);
                var p1 : Point = line.points[l2];
                
                if (q == 1)
                {
                    p = line.points[l0];
                    p1 = new Point(mxs, mys);
                }
                
                var x0 : Float = p.x;
                var x1 : Float = p1.x;
                if (x0 > x1)
                {
                    x0 = p1.x;
                    x1 = p.x;
                }
                var y0 : Float = p.y;
                var y1 : Float = p1.y;
                
                for (i in 0...list.length)
                {
                    obj = list[i];
                    pc = percents[i];
                    var yoff : Float = yoffs[i];
                    
                    var y : Float = Utils.ScaleTo(y0, y1, 0, 1, pc);
                    obj.y = y + yoff;
                    
                    var x : Float = Utils.ScaleTo(x0, x1, 0, 1, pc);
                    obj.x = x;
                }
            }
        }
    }
    
    override public function OnMouseWheel(delta : Int) : Void
    {
    }
    
    public var subMode : String;
    public function SetSubMode(s : String)
    {
        subMode = s;
        
        if (s == "null")
        {
            PhysEditor.CursorText_Set("");
        }
        if (s == "addpoint")
        {
            PhysEditor.CursorText_Set("add point");
        }
        if (s == "newline")
        {
            PhysEditor.CursorText_Set("new line");
        }
        if (s == "freeline")
        {
            PhysEditor.CursorText_Set("free line");
        }
        if (s == "newrectangle")
        {
            PhysEditor.CursorText_Set("new rectangle");
        }
        if (s == "dragpoint")
        {
            PhysEditor.CursorText_Set("drag point");
        }
        if (s == "dragline")
        {
            PhysEditor.CursorText_Set("drag line");
        }
        if (s == "scaleline")
        {
            PhysEditor.CursorText_Set("scale line");
        }
        if (s == "rotateline")
        {
            PhysEditor.CursorText_Set("rotate line");
        }
    }
    
    override public function Update() : Void
    {
        super.Update();
        
        
        if (currentLineIndex != -1)
        {
            if (currentPointIndex != -1)
            {
                if (KeyReader.Pressed(KeyReader.KEY_K))
                {
                    PhysEditor.UndoTakeSnapshot();
                    var firstPointIndex : Int = currentPointIndex;
                    Lines_SelectPoint(mxs, mys);
                    if (firstPointIndex != currentPointIndex)
                    {
                        Lines_SplitPoly(currentLineIndex, firstPointIndex, currentPointIndex);
                    }
                }
            }
            
            
            if (KeyReader.Pressed(KeyReader.KEY_DELETE) || KeyReader.Pressed(KeyReader.KEY_SQUIGGLE))
            {
                PhysEditor.UndoTakeSnapshot();
                Lines_DeleteSelectedLine();
                EditParams.AddParameterListBoxOrClear(null);
            }
            else if (KeyReader.Pressed(KeyReader.KEY_X))
            {
                if (GetCurrentLinePrimitiveType() == EdLine.PRIMITIVE_LINE)
                {
                    PhysEditor.UndoTakeSnapshot();
                    Lines_DeletePoint(mxs, mys);
                }
            }
            else if (KeyReader.Pressed(KeyReader.KEY_E))
            {
                Lines_PickPieceForObjCol();
            }
            else if (KeyReader.Pressed(KeyReader.KEY_D))
            {
                PhysEditor.UndoTakeSnapshot();
                Lines_DuplicateSelectedLine();
            }
            else if (KeyReader.Pressed(KeyReader.KEY_C))
            {
                CopyParameters();
            }
            else if (KeyReader.Pressed(KeyReader.KEY_V))
            {
                PhysEditor.UndoTakeSnapshot();
                PasteParameters();
            }
            else if (KeyReader.Pressed(KeyReader.KEY_S))
            {
                if (GetCurrentLinePrimitiveType() == EdLine.PRIMITIVE_LINE)
                {
                    PhysEditor.UndoTakeSnapshot();
                    Lines_InsertPointAtMousePos(mxs, mys);
                }
            }
            else if (KeyReader.Pressed(KeyReader.KEY_A))
            {
                if (GetCurrentLinePrimitiveType() == EdLine.PRIMITIVE_LINE)
                {
                    PhysEditor.UndoTakeSnapshot();
                    Lines_InsertPoint(mxs, mys);
                }
            }
            else if (KeyReader.Down(KeyReader.KEY_Q))
            {
                if (GetCurrentLinePrimitiveType() == EdLine.PRIMITIVE_LINE)
                {
                    PhysEditor.UndoTakeSnapshot();
                    Lines_SelectPoint(mxs, mys);
                }
            }
        }
        
        if (KeyReader.Pressed(KeyReader.KEY_L))
        {
            Lines_SelectLineByArea(mxs, mys);
            if (currentLineIndex == -1)
            {
                Lines_SelectLine(mxs, mys);
            }
            var line : EdLine = Lines_GetLineByIndex(currentLineIndex);
            lastLineSelectedIndex = currentLineIndex;
            AddLineParameterListBoxOrClear(line);
        }
        if (KeyReader.Pressed(KeyReader.KEY_N))
        {
            SetSubMode("newline");
        }
        if (KeyReader.Pressed(KeyReader.KEY_SPACE))
        {
            SetSubMode("null");
            currentLineIndex = -1;
            currentPointIndex = -1;
            AddLineParameterListBoxOrClear(null);
        }
        
        
        if (KeyReader.Pressed(KeyReader.KEY_TAB) && KeyReader.Down(KeyReader.KEY_CONTROL))
        {
            PhysEditor.UndoTakeSnapshot();
            if (KeyReader.Down(KeyReader.KEY_SHIFT))
            {
                PhysEditor.RemoveEverything();
            }
            PhysEditor.GetCurrentLevel().lines = [];
            currentLineIndex = -1;
            currentPointIndex = -1;
        }
        
        if (KeyReader.Down(KeyReader.KEY_T))
        {
            SetSubMode("scaleline");
        }
        else if (KeyReader.Down(KeyReader.KEY_Y))
        {
            SetSubMode("rotateline");
        }
        else if (KeyReader.Down(KeyReader.KEY_M))
        {
            SetSubMode("newrectangle");
        }
        else if (KeyReader.Down(KeyReader.KEY_SHIFT))
        {
            SetSubMode("dragpoint");
        }
        else if (KeyReader.Down(KeyReader.KEY_CONTROL))
        {
            SetSubMode("dragline");
        }
        else if (subMode != "pick" && subMode != "newline" && subMode != "freeline")
        {
            if (subMode == "addpoint" && KeyReader.Pressed(KeyReader.KEY_F))
            {
                SetSubMode("freeline");
            }
            else if (addlineActive)
            {
                if (currentLineIndex != -1)
                {
                    if (GetCurrentLine().primitiveType == EdLine.PRIMITIVE_LINE)
                    {
                        SetSubMode("addpoint");
                    }
                    else
                    {
                        SetSubMode("null");
                    }
                }
                else
                {
                    SetSubMode("null");
                }
            }
            else
            {
                SetSubMode("null");
            }
        }
        
        var l : Level = GetCurrentLevel();
        
        if (KeyReader.Pressed(KeyReader.KEY_9))
        {
            addlineActive = (addlineActive == false);
        }
        
        if (KeyReader.Pressed(KeyReader.KEY_R))
        {
            PhysEditor.UndoTakeSnapshot();
            Lines_Reverse();
            return;
        }
        if (KeyReader.Pressed(KeyReader.KEY_I))
        {
            PhysEditor.UndoTakeSnapshot();
            Lines_EnterID();
            return;
        }
        
        if (KeyReader.Pressed(KeyReader.KEY_LEFTSQUAREBRACKET))
        {
            Lines_ScrollToFirstPointOfSelectedLine();
        }
        if (KeyReader.Pressed(KeyReader.KEY_RIGHTSQUAREBRACKET))
        {
            Lines_ScrollToLastPointOfSelectedLine();
        }
    }
    
    public function AddLineParameterListBoxOrClear(l : EdLine)
    {
        if (l == null)
        {
            EditParams.AddParameterListBoxOrClear(null);
        }
        else
        {
            EditParams.AddParameterListBoxOrClear(l.objParameters);
        }
    }
    
    override public function Render(bd : BitmapData) : Void
    {
        super.Render(bd);
        bd.fillRect(Defs.screenRect, 0xff445566);
        PhysEditor.RenderBackground(bd);
        PhysEditor.RenderSortedEdObjs();
        PhysEditor.Editor_RenderMiniMap();
        PhysEditor.Editor_RenderJoints(bd);
        
        
        PhysEditor.Editor_RenderLineToCursor();
        
        
        
        
        var hoveredLine : EdLine = GetCurrentLevel().GetLineByIndex(hoveredLineIndex);
        if (hoveredLine != null)
        {
            hoveredLine.RenderHighlighted(EditableObjectBase.HIGHLIGHT_HOVER);
        }
        
        var hoveredLine : EdLine = GetCurrentLevel().GetLineByIndex(hoveredLineIndex);
        if (hoveredLine != null)
        {
            hoveredLine.RenderHighlightSelectedPoint(hoveredPointIndex, 0xffffff00, 3);
        }
        
        var l : EdLine = GetCurrentLine();
        if (l != null)
        {
            l.RenderHighlighted(EditableObjectBase.HIGHLIGHT_SELECTED);
            l.RenderHighlightSelectedPoint(currentPointIndex, 0xffffffff, 4);
        }
        
        PhysEditor.Editor_RenderGrid(bd);
    }
    override public function RenderHud(x : Int, y : Int) : Int
    {
        var s : String = null;        s = "I: Line ID: ";
        if (currentLineIndex != -1)
        {
            var line : EdLine = GetCurrentLevel().lines[currentLineIndex];
            s += line.id;
        }
        else
        {
            s += "NONE";
        }
        
        
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "L: Select Line";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "DEL: Delete Line";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "X: Delete Point";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "D: Duplicate Poly";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "SHIFT Drag Point";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "CTRL Drag Line";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "N: New line";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "F: Free Line Mode";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "M: Make Box";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "S: Insert Point On Line";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "Q: Select Point";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "A: Insert Point After";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "T: Scale Line (drag)";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "Y: Rotate Line (drag)";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "8: Change Type";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "9: Toggle addline display";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "R: Reverse Line Direction";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "[ and ]: Move to first / last point of selected line";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "ScrollPos: " + PhysEditor.scrollX + " " + PhysEditor.scrollY;
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "CursorPos: " + as3hx.Compat.parseInt(MouseControl.x + PhysEditor.scrollX) + " " + as3hx.Compat.parseInt(MouseControl.y + PhysEditor.scrollY);
        y += PhysEditor.AddInfoText("a", x, y, s);
        
        if (currentLineIndex != -1)
        {
            var line : EdLine = GetCurrentLevel().lines[currentLineIndex];
        }
        return y;
    }
    
    
    
    
    public var currentLineIndex : Int;
    public var currentPointIndex : Int;
    
    public function GetCurrentLinePrimitiveType() : String
    {
        if (GetCurrentLine() == null)
        {
            return "";
        }
        return GetCurrentLine().primitiveType;
    }
    
    public function GetCurrentLine() : EdLine
    {
        if (currentLineIndex == -1)
        {
            return null;
        }
        var l : Level = GetCurrentLevel();
        var line : EdLine = l.lines[currentLineIndex];
        return line;
    }
    
    public function Lines_EnterID()
    {
        if (currentLineIndex == -1)
        {
            return;
        }
        var l : Level = GetCurrentLevel();
        var line : EdLine = l.lines[currentLineIndex];
        PhysEditor.AddTextEntry(100, 100, "line id ", line.id, Lines_EnterID_Done);
    }
    public function Lines_EnterID_Done(text : String)
    {
        var l : Level = GetCurrentLevel();
        var line : EdLine = l.lines[currentLineIndex];
        line.id = text;
    }
    
    
    public function Lines_Reverse()
    {
        if (currentLineIndex == -1)
        {
            return;
        }
        var l : Level = GetCurrentLevel();
        
        var pts : Array<Dynamic> = l.lines[currentLineIndex].points;
        
        var newpts : Array<Dynamic> = pts.reverse();
        
        l.lines[currentLineIndex].points = newpts;
    }
    public function Lines_MinDistanceBetweenPoints(dist : Float)
    {
        if (currentLineIndex == -1)
        {
            return;
        }
        var l : Level = GetCurrentLevel();
        var pts : Array<Dynamic> = l.lines[currentLineIndex].points;
        var newpts : Array<Dynamic> = [];
        var removecount : Int = 0;
        
        for (i in 0...pts.length)
        {
            var p : Point = pts[i];
            newpts.push(p.clone());
            
            for (j in i + 1...pts.length)
            {
                var p1 : Point = pts[j];
                var d : Float = Utils.DistBetweenPoints(p.x, p.y, p1.x, p1.y);
                if (d < dist)
                {
                    removecount++;
                    i++;
                }
                else
                {
                    j = 9999999;
                }
            }
        }
        
        l.lines[currentLineIndex].points = newpts;
        Utils.print("removecount " + removecount);
    }
    public function Lines_AddPoint(x : Float, y : Float)
    {
        if (currentLineIndex == -1)
        {
            return;
        }
        var l : Level = GetCurrentLevel();
        var p : Point = new Point(x, y);
        var pts : Array<Dynamic> = l.lines[currentLineIndex].points;
        pts.push(p);
        l.lines[currentLineIndex].points = pts;
    }
    
    public function Lines_InsertPointAtMousePos(x : Float, y : Float)
    {
        var l : Level = GetCurrentLevel();
        if (currentLineIndex == -1)
        {
            return;
        }
        
        var numPoints = l.lines[currentLineIndex].points.length;
        var a0 : Array<Dynamic> = l.lines[currentLineIndex].points;
        
        var i : Int = 0;        for (i in 0...numPoints - 1)
        {
            var p0 : Point = a0[i];
            var p1 : Point = a0[i + 1];
            
            var t : Float = Collision.ClosestPointOnLine(p0.x, p0.y, p1.x, p1.y, x, y);
            if (t >= 0.0 && t <= 1)
            {
                if (Utils.DistBetweenPoints(x, y, Collision.closestX, Collision.closestY) < 2)
                {
                    currentPointIndex = i;
                    Lines_InsertPointOnCurrentLine(x, y);
                    return;
                }
            }
        }
    }
    
    public function Lines_InsertPointOnCurrentLine(x : Float, y : Float)
    {
        var l : Level = GetCurrentLevel();
        
        
        if (currentLineIndex != -1 && currentPointIndex != -1)
        {
            var a0 : Array<Dynamic> = l.lines[currentLineIndex].points;
            
            if (currentPointIndex == a0.length - 1)
            {
                return;
            }
            
            var newPoint : Point = new Point(x, y);
            
            as3hx.Compat.arraySplice(a0, currentPointIndex + 1, 0, [newPoint]);
            
            
            currentPointIndex = as3hx.Compat.parseInt(currentPointIndex + 1);
        }
    }
    
    
    public function Lines_InsertPoint(x : Float, y : Float)
    {
        var l : Level = GetCurrentLevel();
        
        var lineIndex : Int = 0;
        var selectedLineIndex : Int = currentLineIndex;
        var selectedPointIndex : Int = currentPointIndex;
        if (selectedLineIndex == -1 || selectedPointIndex == -1)
        {
            return;
        }
        
        
        var a0 : Array<Dynamic> = l.lines[selectedLineIndex].points;
        
        if (selectedPointIndex == a0.length - 1)
        {
            var newPoint : Point = new Point(x, y);
            a0.push(newPoint);
            l.lines[selectedLineIndex].points = a0;
            currentPointIndex++;
            return;
        }
        var p0 : Point = a0[selectedPointIndex].clone();
        var p1 : Point = a0[selectedPointIndex + 1].clone();
        
        var newPoint : Point = new Point(x, y);
        
        as3hx.Compat.arraySplice(a0, selectedPointIndex + 1, 0, [newPoint]);
        
        l.lines[selectedLineIndex].points = a0;
        currentPointIndex++;
    }
    
    
    public function Lines_PickPieceForObjCol()
    {
        PhysEditor.oldEditMode = PhysEditor.editMode;
        PhysEditor.editModeObj_PickPieceForLink.returnFunction = PickObjectForObjColReturnFunction;
        PhysEditor.SetEditMode(PhysEditor.editMode_PickPieceForLink, false);
        PhysEditor.CursorText_Set("Pick Object For ObjCol");
    }
    public function PickObjectForObjColReturnFunction(poi : EdObj)
    {
        var id : String = "";
        if (poi != null)
        {
            CreateObjLineCollision(poi);
        }
        PhysEditor.SetEditMode(PhysEditor.oldEditMode, false);
        PhysEditor.CursorText_Set("");
    }
    
    public function CreateObjLineCollision(poi : EdObj) : Void
    {
        var a : Array<Dynamic> = [];
        var l : EdLine = GetCurrentLine();
        if (l == null)
        {
            return;
        }
        for (p/* AS3HX WARNING could not determine type for var: p exp: EField(EIdent(l),points) type: null */ in l.points)
        {
            var p1 : Point = new Point(p.x - poi.x, p.y - poi.y);
            a.push(p1);
        }
        
        Utils.print(poi.typeName);
        
        var s : String = "";
        s += "vertices=\"";
        for (i in 0...a.length)
        {
            p = a[i];
            s += as3hx.Compat.parseInt(p.x) + "," + as3hx.Compat.parseInt(p.y);
            if (i != a.length - 1)
            {
                s += ", ";
            }
        }
        s += "\"";
        Utils.print(s);
        ExternalData.OutputString(s);
    }
    
    
    public function Lines_DuplicateSelectedLine()
    {
        var l : Level = GetCurrentLevel();
        if (currentLineIndex != -1)
        {
            var line : EdLine = l.lines[currentLineIndex];
            var newLine : EdLine = line.Clone();
            
            newLine.id = "";
            for (p/* AS3HX WARNING could not determine type for var: p exp: EField(EIdent(newLine),points) type: null */ in newLine.points)
            {
                p.x += 10;
                p.y += 10;
            }
            l.lines.push(newLine);
            currentLineIndex = as3hx.Compat.parseInt(l.lines.length - 1);
        }
    }
    
    
    public function Lines_DeleteSelectedLine()
    {
        var l : Level = GetCurrentLevel();
        if (currentLineIndex != -1)
        {
            var edLine : EdLine = Lines_GetLineByIndex(currentLineIndex);
            PhysEditor.editModeObj_Joints.UpdateJoints_ObjectDeleted(edLine.id);
            
            
            var a2 : Array<Dynamic> = [];
            var index : Int = 0;
            for (line/* AS3HX WARNING could not determine type for var: line exp: EField(EIdent(l),lines) type: null */ in l.lines)
            {
                if (index != currentLineIndex)
                {
                    a2.push(line.Clone());
                }
                index++;
            }
            l.lines = a2;
            currentPointIndex = -1;
            currentLineIndex = -1;
        }
    }
    
    
    
    public function Lines_DeletePoint(x : Float, y : Float)
    {
        var l : Level = GetCurrentLevel();
        var lineIndex : Int = 0;
        var selectedLineIndex : Int = -1;
        var selectedPointIndex : Int = -1;
        
        for (line/* AS3HX WARNING could not determine type for var: line exp: EField(EIdent(l),lines) type: null */ in l.lines)
        {
            var pointIndex : Int = 0;
            for (p/* AS3HX WARNING could not determine type for var: p exp: EField(EIdent(line),points) type: null */ in line.points)
            {
                if (Utils.DistBetweenPoints(p.x, p.y, x, y) < 3 * (1 / PhysEditor.zoom))
                {
                    selectedLineIndex = lineIndex;
                    selectedPointIndex = pointIndex;
                }
                pointIndex++;
            }
            lineIndex++;
        }
        
        if (selectedLineIndex != -1 && selectedPointIndex != -1)
        {
            var a0 : Array<Dynamic> = l.lines[selectedLineIndex].points;
            var a1 : Array<Dynamic> = [];
            var i : Int = 0;            for (i in 0...a0.length)
            {
                if (i != selectedPointIndex)
                {
                    a1.push(a0[i].clone());
                }
            }
            l.lines[selectedLineIndex].points = a1;
            
            var a2 : Array<Dynamic> = [];
            for (line/* AS3HX WARNING could not determine type for var: line exp: EField(EIdent(l),lines) type: null */ in l.lines)
            {
                if (line.points.length != 0)
                {
                    a2.push(line.Clone());
                }
                else
                {
                    currentLineIndex = -1;
                }
            }
            l.lines = a2;
            currentPointIndex = -1;
        }
    }
    public function Lines_ScrollToFirstPointOfSelectedLine()
    {
        if (currentLineIndex == -1)
        {
            return;
        }
        var l : Level = GetCurrentLevel();
        var a : Array<Dynamic> = l.lines[currentLineIndex].points;
        var p : Point = a[0];
        PhysEditor.scrollX = p.x - (Defs.displayarea_w * 0.5);
        PhysEditor.scrollY = p.y - (Defs.displayarea_h * 0.5);
    }
    
    public function Lines_ScrollToLastPointOfSelectedLine()
    {
        if (currentLineIndex == -1)
        {
            return;
        }
        var l : Level = GetCurrentLevel();
        var a : Array<Dynamic> = l.lines[currentLineIndex].points;
        var p : Point = a[a.length - 1];
        PhysEditor.scrollX = p.x - (Defs.displayarea_w * 0.5);
        PhysEditor.scrollY = p.y - (Defs.displayarea_h * 0.5);
    }
    
    
    public function Lines_DragRect(x : Int, y : Int)
    {
        if (currentLineIndex == -1)
        {
            return;
        }
        var l : Level = GetCurrentLevel();
        var line : EdLine = l.lines[currentLineIndex];
        
        if (line.points.length != 4)
        {
            return;
        }
        line.points[2].x = x;
        line.points[2].y = y;
        line.points[1].x = x;
        line.points[3].y = y;
    }
    
    
    public function Lines_NewRect()
    {
        var line : EdLine = new EdLine();
        line.type = 0;
        var l : Level = GetCurrentLevel();
        
        var size : Float = 0;
        
        line.primitiveType = EdLine.PRIMITIVE_RECTANGLE;
        line.AddPoint(mxs, mys);
        line.AddPoint(mxs + size, mys);
        line.AddPoint(mxs + size, mys + size);
        line.AddPoint(mxs, mys + size);
        
        var prevLine : EdLine = GetCurrentLevel().GetLineByIndex(lastLineSelectedIndex);
        if (prevLine != null)
        {
            line.objParameters = prevLine.objParameters.Clone();
        }
        
        
        l.lines.push(line);
        
        currentLineIndex = as3hx.Compat.parseInt(l.lines.length - 1);
        currentPointIndex = 2;
        
        Utils.print("New line " + currentLineIndex);
    }
    
    
    public function HitTestRectangle(r : Rectangle) : Array<Dynamic>
    {
        var a : Array<Dynamic> = [];
        var list : Array<Dynamic> = GetCurrentLevelLines();
        for (line in list)
        {
            if (line.HitTestRectangle(r))
            {
                a.push(line);
            }
        }
        return a;
    }
    
    
    public function Lines_NewLine()
    {
        var prevLine : EdLine = GetCurrentLevel().GetLineByIndex(lastLineSelectedIndex);
        
        var line : EdLine = new EdLine();
        
        if (prevLine != null)
        {
            line.objParameters = prevLine.objParameters.Clone();
        }
        line.objParameters.SetParam("editor_layer", Std.string(EditorLayers.GetActive()));
        
        line.type = 0;
        var l : Level = GetCurrentLevel();
        l.lines.push(line);
        currentLineIndex = as3hx.Compat.parseInt(l.lines.length - 1);
        Utils.print("New line " + currentLineIndex);
        lastLineSelectedIndex = currentLineIndex;
    }
    
    public function Lines_GetLineByIndex(_index : Int) : EdLine
    {
        if (_index == -1)
        {
            return null;
        }
        var l : Level = GetCurrentLevel();
        return l.lines[_index];
    }
    
    
    public function Lines_SelectLine(x : Float, y : Float)
    {
        var l : Level = GetCurrentLevel();
        var lineIndex : Int = 0;
        currentLineIndex = -1;
        for (line/* AS3HX WARNING could not determine type for var: line exp: EField(EIdent(l),lines) type: null */ in l.lines)
        {
            var i : Int = 0;            var a0 : Array<Dynamic> = line.points;
            var numPoints : Int = line.points.length;
            for (i in 0...numPoints)
            {
                var j : Int = as3hx.Compat.parseInt(i + 1);
                if (j >= numPoints)
                {
                    j = 0;
                }
                var p0 : Point = a0[i];
                var p1 : Point = a0[j];
                
                var t : Float = Collision.ClosestPointOnLine(p0.x, p0.y, p1.x, p1.y, x, y);
                if (t >= 0.0 && t <= 1)
                {
                    if (Utils.DistBetweenPoints(x, y, Collision.closestX, Collision.closestY) < 2)
                    {
                        currentLineIndex = lineIndex;
                        currentPointIndex = -1;
                        return;
                    }
                }
            }
            lineIndex++;
        }
    }
    
    public function Lines_SelectLineByPoint(x : Float, y : Float)
    {
        var l : Level = GetCurrentLevel();
        var lineIndex : Int = 0;
        currentLineIndex = -1;
        for (line/* AS3HX WARNING could not determine type for var: line exp: EField(EIdent(l),lines) type: null */ in l.lines)
        {
            for (p/* AS3HX WARNING could not determine type for var: p exp: EField(EIdent(line),points) type: null */ in line.points)
            {
                if (Utils.DistBetweenPoints(p.x, p.y, x, y) < 3)
                {
                    currentLineIndex = lineIndex;
                    currentPointIndex = -1;
                    return;
                }
            }
            lineIndex++;
        }
    }
    
    public function Lines_SelectLineByArea(x : Float, y : Float)
    {
        var l : Level = GetCurrentLevel();
        var lineIndex : Int = 0;
        currentLineIndex = -1;
        for (line/* AS3HX WARNING could not determine type for var: line exp: EField(EIdent(l),lines) type: null */ in l.lines)
        {
            var layer : Int = 0;
            if (line.objParameters.GetParam("editor_layer") != "")
            {
                layer = as3hx.Compat.parseInt(line.objParameters.GetValueInt("editor_layer") - 1);
            }
            
            if (EditorLayers.IsVisible(layer) == true)
            {
                var polyMaterial : PolyMaterial = line.GetCurrentPolyMaterial();
                
                if (polyMaterial.edType == "outline")
                {
                    if (line.PointOnLine(x, y))
                    {
                        currentLineIndex = lineIndex;
                        currentPointIndex = -1;
                        return;
                    }
                }
                else if (line.PointInPoly(x, y))
                {
                    currentLineIndex = lineIndex;
                    currentPointIndex = -1;
                    return;
                }
            }
            lineIndex++;
        }
    }
    
    public function Lines_MovePoints(x : Float, y : Float)
    {
        if (currentLineIndex == -1)
        {
            return;
        }
        var l : Level = GetCurrentLevel();
        var points : Array<Dynamic> = l.lines[currentLineIndex].points;
        
        var maxd : Float = 100;
        var d : Float = Math.NaN;        
        
        for (p in points)
        {
            d = Utils.DistBetweenPoints(p.x, p.y, x, y);
            if (d < maxd)
            {
                d = maxd - d;
                d = Utils.ScaleTo(0, 5, 0, maxd, d);
                if (p.y < y)
                {
                    p.y -= d;
                }
                else if (p.y > y)
                {
                    p.y += d;
                }
            }
        }
    }
    
    public function Lines_Subdivide(x : Float, y : Float)
    {
        if (currentLineIndex == -1 || currentPointIndex == -1)
        {
            return;
        }
        
        var l : Level = GetCurrentLevel();
        var lineIndex : Int = 0;
        var selectedLineIndex : Int = -1;
        var selectedPointIndex : Int = -1;
        
        for (line/* AS3HX WARNING could not determine type for var: line exp: EField(EIdent(l),lines) type: null */ in l.lines)
        {
            var pointIndex : Int = 0;
            for (p/* AS3HX WARNING could not determine type for var: p exp: EField(EIdent(line),points) type: null */ in line.points)
            {
                if (Utils.DistBetweenPoints(p.x, p.y, x, y) < 3)
                {
                    selectedLineIndex = lineIndex;
                    selectedPointIndex = pointIndex;
                }
                pointIndex++;
            }
            lineIndex++;
        }
        if (selectedLineIndex != -1 && selectedPointIndex != -1)
        {
            if (selectedPointIndex == currentPointIndex)
            {
                return;
            }
            var p0 : Int = currentPointIndex;
            var p1 : Int = selectedPointIndex;
            if (p1 < p0)
            {
                var p2 : Int = p0;
                p1 = p0;
                p0 = p2;
            }
            
            var newpoints : Array<Dynamic> = [];
            
            var i : Int = 0;            var points : Array<Dynamic> = l.lines[selectedLineIndex].points;
            for (i in p0...p1)
            {
                var pt0 : Point = points[i].clone();
                var pt1 : Point = points[i + 1].clone();
                var pt2 : Point = new Point((pt0.x + pt1.x) / 2, (pt0.y + pt1.y) / 2);
                newpoints.push(pt2);
                newpoints.push(pt1);
            }
            
            var ps : Array<Dynamic> = [];
            for (i in 0...p0 + 1)
            {
                ps.push(points[i].clone());
            }
            for (pt2 in newpoints)
            {
                ps.push(pt2.clone());
            }
            for (i in p1 + 1...points.length)
            {
                ps.push(points[i].clone());
            }
            l.lines[selectedLineIndex].points = ps;
        }
    }
    
    
    
    
    public var scaleCentreX : Float;
    public var scaleCentreY : Float;
    public var scalePositions : Array<Dynamic>;
    
    public function Lines_StartScale(x : Float, y : Float)
    {
        scaleCentreX = x;
        scaleCentreY = y;
        scalePositions = [];
        
        var l : Level = GetCurrentLevel();
        if (currentLineIndex != -1)
        {
            for (p/* AS3HX WARNING could not determine type for var: p exp: EField(EArray(EField(EIdent(l),lines),EIdent(currentLineIndex)),points) type: null */ in l.lines[currentLineIndex].points)
            {
                scalePositions.push(p.clone());
            }
        }
    }
    public function Lines_Scale(scale : Float)
    {
        var l : Level = GetCurrentLevel();
        if (currentLineIndex != -1)
        {
            for (i in 0...l.lines[currentLineIndex].points.length)
            {
                var p : Point = scalePositions[i];
                var x : Float = scaleCentreX + ((p.x - scaleCentreX) * scale);
                var y : Float = scaleCentreY + ((p.y - scaleCentreY) * scale);
                l.lines[currentLineIndex].points[i] = new Point(x, y);
            }
        }
    }
    
    public var rotateCentreX : Float;
    public var rotateCentreY : Float;
    public var rotatePositions : Array<Dynamic>;
    
    public function Lines_StartRotate(x : Float, y : Float)
    {
        var line : EdLine = GetCurrentLevel().GetLineByIndex(currentLineIndex);
        if (line == null)
        {
            return;
        }
        
        rotateCentreX = x;
        rotateCentreY = y;
        rotatePositions = [];
        
        for (p/* AS3HX WARNING could not determine type for var: p exp: EField(EIdent(line),points) type: null */ in line.points)
        {
            rotatePositions.push(p.clone());
        }
    }
    public function Lines_Rotate(rot : Float)
    {
        var line : EdLine = GetCurrentLevel().GetLineByIndex(currentLineIndex);
        if (line == null)
        {
            return;
        }
        
        var m : Matrix = new Matrix();
        m.translate(-rotateCentreX, -rotateCentreY);
        m.rotate(rot);
        m.translate(rotateCentreX, rotateCentreY);
        
        for (i in 0...line.points.length)
        {
            var p : Point = m.transformPoint(rotatePositions[i]);
            line.points[i] = p.clone();
        }
    }
    
    
    
    public function Lines_SplitPoly(lineIndex : Int, p0Index : Int, p1Index : Int)
    {
        if (lineIndex == -1)
        {
            return;
        }
        if (p0Index == -1)
        {
            return;
        }
        if (p1Index == -1)
        {
            return;
        }
        
        var l : Level = GetCurrentLevel();
        
        var line : EdLine = l.lines[lineIndex];
        
        var newLine0 : EdLine = new EdLine();
        var newLine1 : EdLine = new EdLine();
        
        
        
        var i : Int = p0Index;
        var doit : Bool = true;
        do
        {
            var p : Point = line.GetPoint(i).clone();
            newLine0.AddPoint(p.x, p.y);
            if (i == p1Index)
            {
                doit = false;
            }
            i++;
            if (i >= line.GetNumPoints())
            {
                i = 0;
            }
        }
        while ((doit));
        
        i = p1Index;
        doit = true;
        do
        {
            var p : Point = line.GetPoint(i).clone();
            newLine1.AddPoint(p.x, p.y);
            if (i == p0Index)
            {
                doit = false;
            }
            i++;
            if (i >= line.GetNumPoints())
            {
                i = 0;
            }
        }
        while ((doit));
        
        
        newLine0.objParameters = line.objParameters.Clone();
        newLine1.objParameters = line.objParameters.Clone();
        newLine0.type = 0;
        newLine1.type = 0;
        
        Lines_DeleteSelectedLine();
        l.lines.push(newLine0);
        l.lines.push(newLine1);
        currentLineIndex = -1;
        currentPointIndex = -1;
    }
    
    
    public function Lines_SelectPoint(x : Float, y : Float)
    {
        var l : Level = GetCurrentLevel();
        var lineIndex : Int = 0;
        
        currentPointIndex = -1;
        for (line/* AS3HX WARNING could not determine type for var: line exp: EField(EIdent(l),lines) type: null */ in l.lines)
        {
            var pointIndex : Int = 0;
            if (line.primitiveType == EdLine.PRIMITIVE_LINE)
            {
                for (p/* AS3HX WARNING could not determine type for var: p exp: EField(EIdent(line),points) type: null */ in line.points)
                {
                    if (Utils.DistBetweenPoints(p.x, p.y, x, y) < (3 * (1 / PhysEditor.zoom)))
                    {
                        currentLineIndex = lineIndex;
                        currentPointIndex = pointIndex;
                        return;
                    }
                    pointIndex++;
                }
            }
            if (line.primitiveType == EdLine.PRIMITIVE_RECTANGLE)
            {
                var i : Int = 0;
                while (i <= 2)
                {
                    var p : Point = line.points[i];
                    if (Utils.DistBetweenPoints(p.x, p.y, x, y) < 3)
                    {
                        currentLineIndex = lineIndex;
                        currentPointIndex = pointIndex;
                        return;
                    }
                    pointIndex += 2;
                    i += 2;
                }
            }
            
            lineIndex++;
        }
    }
    
    public function FreeLine_Start()
    {
        PhysEditor.UndoTakeSnapshot();
        addlineActive = false;
        Lines_AddPoint(mxs, mys);
    }
    public function FreeLine_Move()
    {
        Lines_AddPoint(mxs, mys);
    }
    public function FreeLine_End()
    {
        Lines_MinDistanceBetweenPoints(freeLine_MinDist);
        SetSubMode("addpoint");
        addlineActive = true;
    }
}


