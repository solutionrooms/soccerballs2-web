package editorPackage;

import flash.display.BitmapData;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.system.System;

/**
	 * ...
	 * @author LongAnimals
	 */
class EditModeObjCol extends EditModeBase
{
    private var addlineActive : Bool;
    private var newLineType : Int;
    
    private var objLines : Array<Dynamic>;
    
    public function new()
    {
        super();
    }
    
    override public function EnterMode() : Void
    {
        PhysEditor.CursorText_Show();
        PhysEditor.CursorText_Set("");
        cast(("null"), SetSubMode);
        objLines = new Array<Dynamic>();
        PhysEditor.scrollX = 0;
        PhysEditor.scrollY = 0;
    }
    override public function InitOnce() : Void
    {
        currentLineIndex = -1;
        currentPointIndex = -1;
        addlineActive = false;
        newLineType = 0;
        var l : Level = GetCurrentLevel();
        currentLineIndex = 0;
        objLines = new Array<Dynamic>();
    }
    
    
    override public function OnMouseDown(e : MouseEvent) : Void
    {
        super.OnMouseDown(e);
        
        if (subMode == "pick")
        {
            Lines_SelectLine(mxs, mys);
        }
        else if (subMode == "scaleline")
        {
            PhysEditor.UndoTakeSnapshot();
            Lines_StartScale(mxs, mys);
        }
        else if (subMode == "newline")
        {
            PhysEditor.UndoTakeSnapshot();
            addlineActive = true;
            currentPointIndex = -1;
            Lines_NewLine();
            Lines_AddPoint(mxs, mys);
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
            Lines_SelectPoint(mxs, mys);
        }
        else if (subMode == "selectpoint")
        {
            PhysEditor.UndoTakeSnapshot();
            Lines_SelectPoint(mxs, mys);
        }
        else if (subMode == "deleteline")
        {
            PhysEditor.UndoTakeSnapshot();
            Lines_SelectLine(mxs, mys);
            Lines_DeleteSelectedLine();
        }
        else if (subMode == "deletepoint")
        {
            PhysEditor.UndoTakeSnapshot();
            Lines_DeletePoint(mxs, mys);
        }
        else if (subMode == "insertpoint")
        {
            PhysEditor.UndoTakeSnapshot();
            Lines_InsertPointAtMousePos(mxs, mys);
        }
        else if (subMode == "insertafter")
        {
            PhysEditor.UndoTakeSnapshot();
            Lines_InsertPoint(mxs, mys);
        }
        else if (addlineActive)
        {
            PhysEditor.UndoTakeSnapshot();
            Lines_AddPoint(mxs, mys);
        }
    }
    
    override public function OnMouseUp(e : MouseEvent) : Void
    {
        super.OnMouseUp(e);
        
        if (subMode == "scaleline")
        {
            var scale : Float = 1 + ((mxs - scaleCentreX) * 0.001);
            cast((scale), Lines_Scale);
        }
    }
    
    
    override public function OnMouseMove(e : MouseEvent) : Void
    {
        super.OnMouseMove(e);
        var l : Level = GetCurrentLevel();
        
        if (e.buttonDown == false)
        {
            return;
        }
        
        if (subMode == "dragpoint")
        {
            if (currentPointIndex != -1)
            {
                var p : Point = objLines[currentLineIndex].points[currentPointIndex];
                p.x = mxs;
                p.y = mys;
            }
        }
        if (subMode == "dragline")
        {
            if (currentPointIndex != -1)
            {
                var p : Point = objLines[currentLineIndex].points[currentPointIndex];
                var dx : Float = mxs - p.x;
                var dy : Float = mys - p.y;
                for (p/* AS3HX WARNING could not determine type for var: p exp: EField(EArray(EIdent(objLines),EIdent(currentLineIndex)),points) type: null */ in objLines[currentLineIndex].points)
                {
                    p.x += dx;
                    p.y += dy;
                }
            }
        }
        else if (subMode == "scaleline")
        {
            var scale : Float = 1 + ((mxs - scaleCentreX) * 0.001);
            cast((scale), Lines_Scale);
        }
    }
    override public function OnMouseWheel(delta : Int) : Void
    {
    }
    
    private var subMode : String;
    private function SetSubMode(s : String)
    {
        subMode = s;
        
        if (s == "null")
        {
            PhysEditor.CursorText_Set("");
        }
        if (s == "pick")
        {
            PhysEditor.CursorText_Set("pick line");
        }
        if (s == "addpoint")
        {
            PhysEditor.CursorText_Set("add point");
        }
        if (s == "newline")
        {
            PhysEditor.CursorText_Set("new line");
        }
        if (s == "dragpoint")
        {
            PhysEditor.CursorText_Set("drag point");
        }
        if (s == "dragline")
        {
            PhysEditor.CursorText_Set("drag line");
        }
        if (s == "deleteline")
        {
            PhysEditor.CursorText_Set("delete line");
        }
        if (s == "deletepoint")
        {
            PhysEditor.CursorText_Set("delete point");
        }
        if (s == "insertpoint")
        {
            PhysEditor.CursorText_Set("insert on line");
        }
        if (s == "selectpoint")
        {
            PhysEditor.CursorText_Set("select point");
        }
        if (s == "scaleline")
        {
            PhysEditor.CursorText_Set("scale line");
        }
        if (s == "insertafter")
        {
            PhysEditor.CursorText_Set("insert after selected");
        }
    }
    
    override public function Update() : Void
    {
        super.Update();
        
        
        if (KeyReader.Down(KeyReader.KEY_T))
        {
            cast(("scaleline"), SetSubMode);
        }
        else if (KeyReader.Down(KeyReader.KEY_L))
        {
            cast(("pick"), SetSubMode);
        }
        else if (KeyReader.Down(KeyReader.KEY_N))
        {
            cast(("newline"), SetSubMode);
        }
        else if (KeyReader.Down(KeyReader.KEY_SHIFT))
        {
            cast(("dragpoint"), SetSubMode);
        }
        else if (KeyReader.Down(KeyReader.KEY_CONTROL))
        {
            cast(("dragline"), SetSubMode);
        }
        else if (KeyReader.Down(KeyReader.KEY_DELETE) || KeyReader.Down(KeyReader.KEY_SQUIGGLE))
        {
            cast(("deleteline"), SetSubMode);
        }
        else if (KeyReader.Down(KeyReader.KEY_D))
        {
            cast(("deletepoint"), SetSubMode);
        }
        else if (KeyReader.Down(KeyReader.KEY_S))
        {
            cast(("insertpoint"), SetSubMode);
        }
        else if (KeyReader.Down(KeyReader.KEY_Q))
        {
            cast(("selectpoint"), SetSubMode);
        }
        else if (KeyReader.Down(KeyReader.KEY_A))
        {
            cast(("insertafter"), SetSubMode);
        }
        else if (addlineActive)
        {
            cast(("addpoint"), SetSubMode);
        }
        else
        {
            cast(("null"), SetSubMode);
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
        
        if (KeyReader.Pressed(KeyReader.KEY_1))
        {
            DecCurrentPiece();
        }
        if (KeyReader.Pressed(KeyReader.KEY_2))
        {
            IncCurrentPiece();
        }
        
        if (KeyReader.Pressed(KeyReader.KEY_P))
        {
            PrintOut();
        }
    }
    
    private function PrintOut()
    {
        var centre : Point = ObjCol_GetCentrePos();
        
        var point : Point = new Point();
        var s : String;
        var ss : String = "";
        
        
        if (objLines.length == 0)
        {
            return;
        }
        
        var line : PhysLine = objLines[0];
        {
            var i : Int;
            var j : Int;
            
            var points : Array<Dynamic> = line.points;
            
            var numPoints : Int = points.length;
            var numPerLine : Int = 100000;
            var numGroups : Int = as3hx.Compat.parseInt(numPoints / numPerLine);
            var numRemainder : Int = as3hx.Compat.parseInt(numPoints % numPerLine);
            var count : Int = 0;
            
            
            for (i in 0...numGroups)
            {
                var s1 : String = "vertices =\"";
                for (j in 0...numPerLine)
                {
                    point = points[count++];
                    s1 += as3hx.Compat.parseInt(point.x - centre.x) + "," + as3hx.Compat.parseInt(point.y - centre.y);
                    if (j != numPerLine - 1)
                    {
                        s1 += ", ";
                    }
                }
                s1 += "\"";
                s = s1;
                ss += s;  // + "\n";  
                Utils.print(s);
            }
            if (numRemainder != 0)
            {
                var s1 : String = "vertices =\"";
                for (j in 0...numRemainder)
                {
                    point = points[count++];
                    s1 += as3hx.Compat.parseInt(point.x - centre.x) + "," + as3hx.Compat.parseInt(point.y - centre.y);
                    if (j != numRemainder - 1)
                    {
                        s1 += ", ";
                    }
                }
                s1 += "\"";
                s = s1;
                ss += s;  // + "\n";  
                Utils.print(s);
            }
        }
        
        System.setClipboard(ss);
    }
    
    private function DecCurrentPiece()
    {
        for (ob/* AS3HX WARNING could not determine type for var: ob exp: EField(EIdent(PhysEditor),currentPieceList) type: null */ in PhysEditor.currentPieceList)
        {
            ob.id--;
            if (ob.id < 0)
            {
                ob.id = Game.objectDefs.GetNum() - 1;
            }
        }
        GetObjectLines();
    }
    
    private function IncCurrentPiece()
    {
        for (ob/* AS3HX WARNING could not determine type for var: ob exp: EField(EIdent(PhysEditor),currentPieceList) type: null */ in PhysEditor.currentPieceList)
        {
            ob.id++;
            if (ob.id > Game.objectDefs.GetNum() - 1)
            {
                ob.id = 0;
            }
        }
        GetObjectLines();
    }
    
    
    private function GetObjectLines()
    {
        objLines = new Array<Dynamic>();
    }
    
    private function PreviousPiece()
    {
        Utils.print("PreviousPiece not implemented yet");
    }
    private function NextPiece()
    {
        Utils.print("NextPiece not implemented yet");
    }
    
    
    override public function Render(bd : BitmapData) : Void
    {
        super.Render(bd);
        bd.fillRect(Defs.screenRect, 0xff445566);
        cast((bd), RenderCurrentPiece);
        cast((false), Editor_RenderObjectCollisionLines);
        PhysEditor.Editor_RenderLineToCursor();
    }
    override public function RenderHud(x : Int, y : Int) : Int
    {
        var s : String;
        s = "I: Line ID: ";
        if (currentLineIndex != -1)
        {
            var line : PhysLine = GetCurrentLevel().lines[currentLineIndex];
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
        s = "D: Delete Point";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "SHIFT Drag Point";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "CTRL Drag Line";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "N: New line";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "S: Insert Point On Line";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "Q: Select Point";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "A: Insert Point After";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "T: Scale Line (drag)";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "8: Change Type";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "R: Reverse Line Direction";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "[ and ]: Move to first / last point of selected line";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "ScrollPos: " + Math.round(PhysEditor.scrollX) + " " + Math.round(PhysEditor.scrollY);
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "CursorPos: " + as3hx.Compat.parseInt((MouseControl.x + PhysEditor.scrollX) - ObjCol_GetCentrePos().x) + " " + as3hx.Compat.parseInt((MouseControl.y + PhysEditor.scrollY) - ObjCol_GetCentrePos().y);
        y += PhysEditor.AddInfoText("a", x, y, s);
        
        if (currentLineIndex != -1)
        {
            var line : PhysLine = GetCurrentLevel().lines[currentLineIndex];
        }
        return y;
    }
    
    
    
    private var currentLineIndex : Int;
    private var currentPointIndex : Int;
    
    
    private function Lines_EnterID()
    {
        if (currentLineIndex == -1)
        {
            return;
        }
        var l : Level = GetCurrentLevel();
        var line : PhysLine = objLines[currentLineIndex];
        PhysEditor.AddTextEntry(100, 100, "line id ", line.id, Lines_EnterID_Done);
    }
    private function Lines_EnterID_Done(text : String)
    {
        var l : Level = GetCurrentLevel();
        var line : PhysLine = objLines[currentLineIndex];
        line.id = text;
    }
    
    
    private function Lines_Reverse()
    {
        if (currentLineIndex == -1)
        {
            return;
        }
        var l : Level = GetCurrentLevel();
        
        var pts : Array<Dynamic> = objLines[currentLineIndex].points;
        
        var newpts : Array<Dynamic> = pts.reverse();
        
        objLines[currentLineIndex].points = newpts;
    }
    private function Lines_AddPoint(x : Float, y : Float)
    {
        if (currentLineIndex == -1)
        {
            return;
        }
        var l : Level = GetCurrentLevel();
        var p : Point = new Point(x, y);
        var pts : Array<Dynamic> = objLines[currentLineIndex].points;
        pts.push(p);
        objLines[currentLineIndex].points = pts;
    }
    
    private function Lines_InsertPointAtMousePos(x : Float, y : Float)
    {
        var l : Level = GetCurrentLevel();
        if (currentLineIndex == -1)
        {
            return;
        }
        
        var numPoints = objLines[currentLineIndex].points.length;
        var a0 : Array<Dynamic> = objLines[currentLineIndex].points;
        
        var i : Int;
        for (i in 0...numPoints - 1)
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
    
    private function Lines_InsertPointOnCurrentLine(x : Float, y : Float)
    {
        var l : Level = GetCurrentLevel();
        
        
        if (currentLineIndex != -1 && currentPointIndex != -1)
        {
            var a0 : Array<Dynamic> = objLines[currentLineIndex].points;
            
            if (currentPointIndex == a0.length - 1)
            {
                return;
            }
            
            var newPoint : Point = new Point(x, y);
            
            as3hx.Compat.arraySplice(a0, currentPointIndex + 1, 0, [newPoint]);
            
            currentPointIndex = as3hx.Compat.parseInt(currentPointIndex + 1);
        }
    }
    
    
    private function Lines_InsertPoint(x : Float, y : Float)
    {
        var l : Level = GetCurrentLevel();
        
        var lineIndex : Int = 0;
        var selectedLineIndex : Int = currentLineIndex;
        var selectedPointIndex : Int = currentPointIndex;
        if (selectedLineIndex == -1 || selectedPointIndex == -1)
        {
            return;
        }
        
        
        var a0 : Array<Dynamic> = objLines[selectedLineIndex].points;
        
        if (selectedPointIndex == a0.length - 1)
        {
            return;
        }
        var p0 : Point = a0[selectedPointIndex].clone();
        var p1 : Point = a0[selectedPointIndex + 1].clone();
        
        var newPoint : Point = new Point(x, y);
        
        as3hx.Compat.arraySplice(a0, selectedPointIndex + 1, 0, [newPoint]);
        
        objLines[selectedLineIndex].points = a0;
        currentPointIndex++;
    }
    
    
    private function Lines_DeleteSelectedLine()
    {
        var l : Level = GetCurrentLevel();
        if (currentLineIndex != -1)
        {
            var a2 : Array<Dynamic> = new Array<Dynamic>();
            var index : Int = 0;
            for (line in objLines)
            {
                if (index != currentLineIndex)
                {
                    a2.push(line.Clone());
                }
                index++;
            }
            objLines = a2;
            currentPointIndex = -1;
            currentLineIndex = -1;
        }
    }
    private function Lines_DeletePoint(x : Float, y : Float)
    {
        var l : Level = GetCurrentLevel();
        var lineIndex : Int = 0;
        var selectedLineIndex : Int = -1;
        var selectedPointIndex : Int = -1;
        
        for (line in objLines)
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
            var a0 : Array<Dynamic> = objLines[selectedLineIndex].points;
            var a1 : Array<Dynamic> = new Array<Dynamic>();
            var i : Int;
            for (i in 0...a0.length)
            {
                if (i != selectedPointIndex)
                {
                    a1.push(a0[i].clone());
                }
            }
            objLines[selectedLineIndex].points = a1;
            
            var a2 : Array<Dynamic> = new Array<Dynamic>();
            for (line in objLines)
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
            objLines = a2;
            currentPointIndex = -1;
        }
    }
    private function Lines_ScrollToFirstPointOfSelectedLine()
    {
        if (currentLineIndex == -1)
        {
            return;
        }
        var l : Level = GetCurrentLevel();
        var a : Array<Dynamic> = objLines[currentLineIndex].points;
        var p : Point = a[0];
        PhysEditor.scrollX = p.x - (Defs.displayarea_w * 0.5);
        PhysEditor.scrollY = p.y - (Defs.displayarea_h * 0.5);
    }
    
    private function Lines_ScrollToLastPointOfSelectedLine()
    {
        if (currentLineIndex == -1)
        {
            return;
        }
        var l : Level = GetCurrentLevel();
        var a : Array<Dynamic> = objLines[currentLineIndex].points;
        var p : Point = a[a.length - 1];
        PhysEditor.scrollX = p.x - (Defs.displayarea_w * 0.5);
        PhysEditor.scrollY = p.y - (Defs.displayarea_h * 0.5);
    }
    
    
    private function Lines_NewLine()
    {
        var line : PhysLine = new PhysLine();
        line.type = newLineType;
        var l : Level = GetCurrentLevel();
        objLines.push(line);
        currentLineIndex = as3hx.Compat.parseInt(objLines.length - 1);
        Utils.print("New line " + currentLineIndex);
    }
    
    private function Lines_SelectLine(x : Float, y : Float)
    {
        var l : Level = GetCurrentLevel();
        var lineIndex : Int = 0;
        currentLineIndex = -1;
        for (line in objLines)
        {
            var i : Int;
            var a0 : Array<Dynamic> = line.points;
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
    
    private function Lines_SelectLineByPoint(x : Float, y : Float)
    {
        var l : Level = GetCurrentLevel();
        var lineIndex : Int = 0;
        currentLineIndex = -1;
        for (line in objLines)
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
    
    
    private function Lines_MovePoints(x : Float, y : Float)
    {
        if (currentLineIndex == -1)
        {
            return;
        }
        var l : Level = GetCurrentLevel();
        var points : Array<Dynamic> = objLines[currentLineIndex].points;
        
        var maxd : Float = 100;
        var d : Float;
        
        
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
    
    private function Lines_Subdivide(x : Float, y : Float)
    {
        if (currentLineIndex == -1 || currentPointIndex == -1)
        {
            return;
        }
        
        var l : Level = GetCurrentLevel();
        var lineIndex : Int = 0;
        var selectedLineIndex : Int = -1;
        var selectedPointIndex : Int = -1;
        
        for (line in objLines)
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
            
            var newpoints : Array<Dynamic> = new Array<Dynamic>();
            
            var i : Int;
            var points : Array<Dynamic> = objLines[selectedLineIndex].points;
            for (i in p0...p1)
            {
                var pt0 : Point = points[i].clone();
                var pt1 : Point = points[i + 1].clone();
                var pt2 : Point = new Point((pt0.x + pt1.x) / 2, (pt0.y + pt1.y) / 2);
                newpoints.push(pt2);
                newpoints.push(pt1);
            }
            
            var ps : Array<Dynamic> = new Array<Dynamic>();
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
            objLines[selectedLineIndex].points = ps;
        }
    }
    
    
    private var scaleCentreX : Float;
    private var scaleCentreY : Float;
    private var scalePositions : Array<Dynamic>;
    
    private function Lines_StartScale(x : Float, y : Float)
    {
        scaleCentreX = x;
        scaleCentreY = y;
        scalePositions = new Array<Dynamic>();
        
        var l : Level = GetCurrentLevel();
        if (currentLineIndex != -1)
        {
            for (p/* AS3HX WARNING could not determine type for var: p exp: EField(EArray(EIdent(objLines),EIdent(currentLineIndex)),points) type: null */ in objLines[currentLineIndex].points)
            {
                scalePositions.push(p.clone());
            }
        }
    }
    private function Lines_Scale(scale : Float)
    {
        var l : Level = GetCurrentLevel();
        if (currentLineIndex != -1)
        {
            for (i in 0...objLines[currentLineIndex].points.length)
            {
                var p : Point = scalePositions[i];
                var x : Float = scaleCentreX + ((p.x - scaleCentreX) * scale);
                var y : Float = scaleCentreY + ((p.y - scaleCentreY) * scale);
                objLines[currentLineIndex].points[i] = new Point(x, y);
            }
        }
    }
    
    private function Lines_SelectPoint(x : Float, y : Float)
    {
        var l : Level = GetCurrentLevel();
        var lineIndex : Int = 0;
        currentPointIndex = -1;
        for (line in objLines)
        {
            var pointIndex : Int = 0;
            for (p/* AS3HX WARNING could not determine type for var: p exp: EField(EIdent(line),points) type: null */ in line.points)
            {
                if (Utils.DistBetweenPoints(p.x, p.y, x, y) < 3)
                {
                    currentLineIndex = lineIndex;
                    currentPointIndex = pointIndex;
                    return;
                }
                pointIndex++;
            }
            lineIndex++;
        }
    }
    
    private function Editor_RenderObjectCollisionLines(_useCursor : Bool = false)
    {
        var p0 : Point = new Point();
        var p1 : Point = new Point();
        var r : Rectangle = new Rectangle();
        
        var l : Level = GetCurrentLevel();
        var bd : BitmapData = Game.main.screenBD;
        var lineIndex : Int = 0;
        for (line in objLines)
        {
            var points : Array<Dynamic> = line.points;
            if (lineIndex == currentLineIndex && _useCursor)
            {
                var mx : Int = MouseControl.x;
                var my : Int = MouseControl.y;
                points = new Array<Dynamic>();
                for (p0/* AS3HX WARNING could not determine type for var: p0 exp: EField(EIdent(line),points) type: null */ in line.points)
                {
                    points.push(p0.clone());
                }
                points.push(new Point(mx + PhysEditor.scrollX, my + PhysEditor.scrollY));
            }
            
            var lineMode : Int = 0;
            var doNormals : Bool = false;
            if ((lineMode & PhysEditor.LM_LINK) != 0)
            {
                doNormals = true;
            }
            var col : Int = 0xffffff;
            var thickness : Int = 1;
            if (lineIndex == currentLineIndex)
            {
                thickness = 2;
            }
            if (points.length >= 2)
            {
                var i : Int;
                for (i in 0...points.length - 1)
                {
                    p0 = points[i];
                    p1 = points[i + 1];
                    PhysEditor.RenderLine(p0.x - PhysEditor.scrollX, p0.y - PhysEditor.scrollY, p1.x - PhysEditor.scrollX, p1.y - PhysEditor.scrollY, col, thickness, 1, doNormals);
                }
                if ((lineMode & PhysEditor.LM_LINK) != 0)
                {
                    p0 = points[points.length - 1];
                    p1 = points[0];
                    PhysEditor.RenderLine(p0.x - PhysEditor.scrollX, p0.y - PhysEditor.scrollY, p1.x - PhysEditor.scrollX, p1.y - PhysEditor.scrollY, col, thickness, 1, doNormals);
                }
            }
            if ((lineMode & PhysEditor.LM_FILL) != 0)
            {
                PhysEditor.FillPoly(points, col, 0.1);
            }
            for (i in 0...points.length)
            {
                col = 0xffff0000;
                if (lineIndex == currentLineIndex && currentPointIndex == i)
                {
                    col = 0xffffff00;
                }
                var off1 : Int = 2;
                var off2 : Int = 4;
                if (lineIndex == PhysEditor.hoverLineIndex && PhysEditor.hoverPointIndex == i)
                {
                    off1 = 3;
                    off2 = 6;
                }
                
                
                r.x = points[i].x - off1 - PhysEditor.scrollX;
                r.y = points[i].y - off1 - PhysEditor.scrollY;
                r.width = off2;
                r.height = off2;
                PhysEditor.RenderRectangle(r, col);
            }
            lineIndex++;
        }
    }
    
    
    private function ObjCol_GetCentrePos() : Point
    {
        var x : Float = Defs.displayarea_w / 2;
        var y : Float = Defs.displayarea_h / 2;
        return new Point(x, y);
    }
    
    public function RenderCurrentPiece(bd : BitmapData) : Void
    {
        var physObj : PhysObj;
        var cp : Point = ObjCol_GetCentrePos().clone();
        cp.x -= PhysEditor.scrollX;
        cp.y -= PhysEditor.scrollY;
        if (PhysEditor.currentPieceList.length == 1)
        {
            bd.fillRect(Defs.screenRect, 0xff445566);
            var ob : Dynamic = PhysEditor.currentPieceList[0];
            physObj = Game.objectDefs.GetByIndex(ob.id);
            
            
            
            PhysObj.RenderAt(physObj, cp.x, cp.y, 0, 1, bd, PhysEditor.linesScreen.graphics, false);
        }
        
        Utils.RenderDotLine(bd, cp.x - 10, cp.y, cp.x + 10, cp.y, 100, 0xff0000);
        Utils.RenderDotLine(bd, cp.x, cp.y - 10, cp.x, cp.y + 10, 100, 0xff0000);
    }
}

