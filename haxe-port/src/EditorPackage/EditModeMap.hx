package editorPackage;

import flash.display.BitmapData;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.geom.Rectangle;

/**
	 * ...
	 * @author LongAnimals
	 */
class EditModeMap extends EditModeBase
{
    public var mapper_transparency : Int = 5;
    public var mapper_currentCell : Int = 1;
    public var mapper_brushType : Int = 0;
    public var brushes : Array<Dynamic>;
    public var mapCols : Array<Dynamic>;
    public var mapColNames : Array<Dynamic>;
    
    public function new()
    {
        super();
    }
    override public function InitOnce() : Void
    {
        mapCols = [];
        mapColNames = [];
        mapCols.push(0);
        
        mapColNames.push("blank");
        mapCols.push(0xffff00);
        mapColNames.push("rough01");
        mapCols.push(0xff00ff);
        mapColNames.push("water");
        mapCols.push(0x00ffff);
        mapColNames.push("cliff");
        mapCols.push(0x0000ff);
        mapColNames.push("undefined");
        mapCols.push(0xffff00);
        mapColNames.push("undefined");
        mapCols.push(0xff00ff);
        mapColNames.push("undefined");
        mapCols.push(0xffffff);
        mapColNames.push("undefined");
        mapCols.push(0xff0000);
        mapColNames.push("undefined");
        
        var brush : Array<Dynamic> = null;        brushes = [];
        
        brush = [];
        brush.push(new Point(0, 0));
        brushes.push(brush);
        
        brush = [];
        brush.push(new Point(0, 0));
        brush.push(new Point(1, 0));
        brush.push(new Point(0, 1));
        brush.push(new Point(1, 1));
        brushes.push(brush);
        
        brush = [];
        brush.push(new Point(0, 0));
        brush.push(new Point(-1, 0));
        brush.push(new Point(1, 0));
        brush.push(new Point(0, 1));
        brush.push(new Point(0, -1));
        brushes.push(brush);
        
        brush = [];
        brush.push(new Point(-1, 0));
        brush.push(new Point(0, 0));
        brush.push(new Point(1, 0));
        brush.push(new Point(-1, 1));
        brush.push(new Point(0, 1));
        brush.push(new Point(1, 1));
        brush.push(new Point(-1, -1));
        brush.push(new Point(0, -1));
        brush.push(new Point(1, -1));
        brushes.push(brush);
        
        mapper_currentCell = 1;
        mapper_brushType = 0;
        
        mapper_transparency = 2;
    }
    override public function OnMouseDown(e : MouseEvent) : Void
    {
        super.OnMouseDown(e);
        Mapper_PlotCell(mapper_currentCell);
    }
    override public function OnMouseUp(e : MouseEvent) : Void
    {
    }
    override public function OnMouseMove(e : MouseEvent) : Void
    {
    }
    override public function OnMouseWheel(delta : Int) : Void
    {
        if (delta > 0)
        {
            Mapper_IncCurrentCell();
        }
        if (delta < 0)
        {
            Mapper_DecCurrentCell();
        }
    }
    override public function Update() : Void
    {
        super.Update();
        if (KeyReader.Down(KeyReader.KEY_1) == true)
        {
            Mapper_PlotCell(0);
        }
        if (KeyReader.Pressed(KeyReader.KEY_2) == true)
        {
            Mapper_DecCurrentCell();
        }
        if (KeyReader.Pressed(KeyReader.KEY_3) == true)
        {
            Mapper_IncCurrentCell();
        }
        if (KeyReader.Pressed(KeyReader.KEY_4) == true)
        {
            Mapper_Fill(mapper_currentCell);
        }
        if (KeyReader.Pressed(KeyReader.KEY_5) == true)
        {
            Mapper_CycleBrush();
        }
        if (KeyReader.Pressed(KeyReader.KEY_6) == true)
        {
            Mapper_CycleTransparency();
        }
    }
    override public function Render(bd : BitmapData) : Void
    {
        super.Render(bd);
        
        bd.fillRect(Defs.screenRect, 0xff445566);
        PhysEditor.RenderBackground(bd);
        PhysEditor.Editor_RenderObjects();
        PhysEditor.Editor_RenderMiniMap();
        PhysEditor.Editor_RenderLines1();
        Mapper_RenderMap();
        Mapper_RenderCursor();
    }
    override public function RenderHud(x : Int, y : Int) : Int
    {
        var s : String = null;        var l : Level = GetCurrentLevel();
        s = "ScrollPos: " + Math.round(PhysEditor.scrollX) + " " + Math.round(PhysEditor.scrollY);
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "CursorPos: " + as3hx.Compat.parseInt(MouseControl.x + PhysEditor.scrollX) + " " + as3hx.Compat.parseInt(MouseControl.y + PhysEditor.scrollY);
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "Offset / Size: " + l.mapMinX + "," + l.mapMinY + "   " + ((l.mapMaxX - l.mapMinX) + 1) + "," + ((l.mapMaxY - l.mapMinY) + 1);
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "1: Erase cell(s)";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "2/3: Current Piece: " + as3hx.Compat.parseInt(mapper_currentCell + 1) + " / " + mapCols.length + "  (" + mapColNames[mapper_currentCell] + ")   ";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "4: Fill ";
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "5: Brush: " + as3hx.Compat.parseInt(mapper_brushType + 1) + " / " + brushes.length;
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "6: Display : " + mapper_transparency + " / 5";
        y += PhysEditor.AddInfoText("a", x, y, s);
        return y;
    }
    
    
    
    
    
    
    
    
    public function mapper_ExpandMap(mx : Int, my : Int)
    {
        var newMap : Array<Dynamic> = null;        var l : Level = GetCurrentLevel();
        
        
        var newMinX : Int = l.mapMinX;
        var newMaxX : Int = l.mapMaxX;
        var newMinY : Int = l.mapMinY;
        var newMaxY : Int = l.mapMaxY;
        
        var offsetX : Int = 0;
        var offsetY : Int = 0;
        
        if (mx < l.mapMinX)
        {
            newMinX = mx;
        }
        if (my < l.mapMinY)
        {
            newMinY = my;
        }
        
        if (mx > l.mapMaxX)
        {
            newMaxX = mx;
        }
        if (my > l.mapMaxY)
        {
            newMaxY = my;
        }
        
        offsetX = as3hx.Compat.parseInt(newMinX - l.mapMinX);
        offsetY = as3hx.Compat.parseInt(newMinY - l.mapMinY);
        
        
        
        
        
        var i : Int = 0;        
        var newW : Int = as3hx.Compat.parseInt((newMaxX - newMinX) + 1);
        var newH : Int = as3hx.Compat.parseInt((newMaxY - newMinY) + 1);
        var oldW : Int = as3hx.Compat.parseInt((l.mapMaxX - l.mapMinX) + 1);
        var oldH : Int = as3hx.Compat.parseInt((l.mapMaxY - l.mapMinY) + 1);
        
        newMap = [];
        for (i in 0...newW * newH)
        {
            newMap[i] = 0;
        }
        
        
        var y : Int = 0;        var x : Int = 0;        for (y in 0...oldH)
        {
            for (x in 0...oldW)
            {
                var c : Int = l.map[x + (y * oldW)];
                newMap[x - offsetX + ((y - offsetY) * newW)] = c;
            }
        }
        
        
        l.mapMinX = newMinX;
        l.mapMaxX = newMaxX;
        l.mapMinY = newMinY;
        l.mapMaxY = newMaxY;
        l.map = newMap;
    }
    
    
    public function Mapper_IncCurrentCell()
    {
        mapper_currentCell++;
        if (mapper_currentCell >= mapCols.length)
        {
            mapper_currentCell = 0;
        }
    }
    public function Mapper_CycleTransparency()
    {
        mapper_transparency++;
        if (mapper_transparency >= 6)
        {
            mapper_transparency = 0;
        }
    }
    public function Mapper_CycleBrush()
    {
        mapper_brushType++;
        if (mapper_brushType >= brushes.length)
        {
            mapper_brushType = 0;
        }
    }
    public function Mapper_DecCurrentCell()
    {
        mapper_currentCell--;
        if (mapper_currentCell < 0)
        {
            mapper_currentCell = as3hx.Compat.parseInt(mapCols.length - 1);
        }
    }
    
    
    public var fillList : Array<Dynamic>;
    public var fillList1 : Array<Dynamic>;
    
    public var fillOrigCell : Int;
    
    public function Mapper_Fill(cellID : Int)
    {
        var l : Level = GetCurrentLevel();
        var mx : Int = MouseControl.x;
        var my : Int = MouseControl.y;
        mx += PhysEditor.scrollX;
        my += PhysEditor.scrollY;
        mx /= l.mapCellW;
        my /= l.mapCellH;
        
        fillList = [];
        
        fillOrigCell = Mapper_GetCell(mx, my);
        
        Mapper_PutCell(mx, my, cellID);
        Mapper_PutFillCell(mx - 1, my, cellID, fillList);
        Mapper_PutFillCell(mx + 1, my, cellID, fillList);
        Mapper_PutFillCell(mx, my - 1, cellID, fillList);
        Mapper_PutFillCell(mx, my + 1, cellID, fillList);
        
        var done : Bool = false;
        
        do
        {
            fillList1 = [];
            for (o in fillList)
            {
                Mapper_PutFillCell(o.x - 1, o.y, cellID, fillList1);
                Mapper_PutFillCell(o.x + 1, o.y, cellID, fillList1);
                Mapper_PutFillCell(o.x, o.y - 1, cellID, fillList1);
                Mapper_PutFillCell(o.x, o.y + 1, cellID, fillList1);
            }
            if (fillList1.length != 0)
            {
                fillList = fillList1;
            }
            else
            {
                done = true;
            }
        }
        while ((done == false));
    }
    
    public function Mapper_PutFillCell(mx : Int, my : Int, cellID : Int, fl : Array<Dynamic>)
    {
        var l : Level = GetCurrentLevel();
        if (mx < l.mapMinX)
        {
            return;
        }
        if (my < l.mapMinY)
        {
            return;
        }
        if (mx > l.mapMaxX)
        {
            return;
        }
        if (my > l.mapMaxY)
        {
            return;
        }
        
        
        var oldW : Int = as3hx.Compat.parseInt((l.mapMaxX - l.mapMinX) + 1);
        mx -= l.mapMinX;
        my -= l.mapMinY;
        var cell : Int = l.map[mx + (my * oldW)];
        
        
        
        if (cell != fillOrigCell)
        {
            return;
        }
        
        l.map[mx + (my * oldW)] = cellID;
        
        mx += l.mapMinX;
        my += l.mapMinY;
        
        
        var o : Dynamic = {};
        o.x = mx;
        o.y = my;
        fl.push(o);
    }
    
    public function Mapper_GetCell(mx : Int, my : Int) : Int
    {
        var l : Level = GetCurrentLevel();
        var oldW : Int = as3hx.Compat.parseInt((l.mapMaxX - l.mapMinX) + 1);
        mx -= l.mapMinX;
        my -= l.mapMinY;
        return l.map[mx + (my * oldW)];
    }
    public function Mapper_PutCell(mx : Int, my : Int, cellID : Int)
    {
        var l : Level = GetCurrentLevel();
        var oldW : Int = as3hx.Compat.parseInt((l.mapMaxX - l.mapMinX) + 1);
        mx -= l.mapMinX;
        my -= l.mapMinY;
        l.map[mx + (my * oldW)] = cellID;
    }
    
    
    
    public function Mapper_PlotCell(cellID : Int)
    {
        var brush : Array<Dynamic> = brushes[mapper_brushType];
        
        var l : Level = GetCurrentLevel();
        
        for (p in brush)
        {
            var mx : Int = MouseControl.x;
            var my : Int = MouseControl.y;
            mx += PhysEditor.scrollX;
            my += PhysEditor.scrollY;
            mx /= l.mapCellW;
            my /= l.mapCellH;
            
            mx += p.x;
            my += p.y;
            
            if (mx < l.mapMinX || mx > l.mapMaxX || my < l.mapMinY || my > l.mapMaxY)
            {
                mapper_ExpandMap(mx, my);
            }
            
            var oldW : Int = as3hx.Compat.parseInt((l.mapMaxX - l.mapMinX) + 1);
            
            mx -= l.mapMinX;
            my -= l.mapMinY;
            
            
            l.map[mx + (my * oldW)] = cellID;
        }
    }
    
    public function Mapper_RenderMap()
    {
        if (mapper_transparency == 0)
        {
            return;
        }
        var trans : Float = Utils.ScaleTo(0, 1, 0, 5, mapper_transparency);
        
        var l : Level = GetCurrentLevel();
        var cy : Int = 0;        var cx : Int = 0;        
        var r : Rectangle = new Rectangle(0, 0, l.mapCellW - 1, l.mapCellH - 1);
        
        var oldW : Int = as3hx.Compat.parseInt((l.mapMaxX - l.mapMinX) + 1);
        var oldH : Int = as3hx.Compat.parseInt((l.mapMaxY - l.mapMinY) + 1);
        
        
        for (cy in 0...oldH)
        {
            for (cx in 0...oldW)
            {
                var c : Int = l.map[(cy * oldW) + cx];
                if (c != 0)
                {
                    r.x = ((cx + l.mapMinX) * l.mapCellW) - PhysEditor.scrollX;
                    r.y = ((cy + l.mapMinY) * l.mapCellH) - PhysEditor.scrollY;
                    
                    
                    PhysEditor.FillRectangle(r, mapCols[c], 0, trans);
                }
            }
        }
    }
    
    
    public function Mapper_RenderCursor()
    {
        var l : Level = GetCurrentLevel();
        var brush : Array<Dynamic> = brushes[mapper_brushType];
        
        for (p in brush)
        {
            var mx : Int = MouseControl.x;
            var my : Int = MouseControl.y;
            
            mx += PhysEditor.scrollX;
            my += PhysEditor.scrollY;
            
            mx /= l.mapCellW;
            my /= l.mapCellH;
            mx += p.x;
            my += p.y;
            mx *= l.mapCellW;
            my *= l.mapCellH;
            
            mx -= PhysEditor.scrollX;
            my -= PhysEditor.scrollY;
            
            
            PhysEditor.RenderRectangle(new Rectangle(mx, my, l.mapCellW - 1, l.mapCellH - 1), 0xffff8080, 2);
        }
    }
}


