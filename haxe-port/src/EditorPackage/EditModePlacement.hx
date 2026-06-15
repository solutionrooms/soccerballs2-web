package editorPackage;

import flash.display.BitmapData;
import flash.events.MouseEvent;
import flash.geom.Point;

/**
	 * ...
	 * @author LongAnimals
	 */
class EditModePlacement extends EditModeBase
{
    
    public function new()
    {
        super();
    }
    override public function EnterMode() : Void
    {
    }
    override public function InitOnce() : Void
    {
    }
    override public function OnMouseDown(e : MouseEvent) : Void
    {
        super.OnMouseDown(e);
        
        PhysEditor.UndoTakeSnapshot();
        
        var level_instances : Array<Dynamic> = PhysEditor.GetCurrentLevelInstances();
        
        var posx : Float = mxs;
        var posy : Float = mys;
        var physObj : PhysObj;
        
        for (ob/* AS3HX WARNING could not determine type for var: ob exp: EField(EIdent(PhysEditor),currentPieceList) type: null */ in PhysEditor.currentPieceList)
        {
            physObj = Game.objectDefs.GetByIndex(ob.id);
            var pieceName : String = physObj.name;
            
            if (KeyReader.Down(KeyReader.KEY_1))
            {
                var ppp : Point = PhysEditor.SnapToObjects(mxs, mys);
                if (ppp != null)
                {
                    Utils.print("snapped to point :" + mxs + " " + mys + "   ->   " + ppp.x + " " + ppp.y);
                    posx = ppp.x;
                    posy = ppp.y;
                }
            }
            
            var pi : EdObj = Levels.CreateLevelObjInstanceAt(pieceName, posx + ob.xoff, posy + ob.yoff, ob.rot, ob.scale, "", ob.initParams);
            
            var physobj : PhysObj = Game.objectDefs.FindByName(pieceName);
            if (physobj != null)
            {
                pi.objParameters.ClearAll();
                for (i in 0...physObj.instanceParams.length)
                {
                    pi.objParameters.AddOrSet(physObj.instanceParams[i], physObj.instanceParamsDefaults[i]);
                }
            }
            
            level_instances.push(pi);
            PhysEditor.SetCurrentLevelInstances(level_instances);
        }
    }
    override public function OnMouseUp(e : MouseEvent) : Void
    {
    }
    override public function OnMouseMove(e : MouseEvent) : Void
    {
    }
    override public function OnMouseWheel(delta : Int) : Void
    {
        if (KeyReader.Down(KeyReader.KEY_SHIFT))
        {
            var rv : Float = 1;
            if (KeyReader.Down(KeyReader.KEY_CONTROL) == false)
            {
                rv *= 10;
            }
            var rotvel = 0;
            if (delta > 0)
            {
                rotvel = rv;
            }
            if (delta < 0)
            {
                rotvel = -rv;
            }
            
            PhysEditor.UndoTakeSnapshot();
            CurrenPiece_AddRot(rotvel);
        }
        else if (KeyReader.Down(KeyReader.KEY_CONTROL))
        {
            var rv : Float = 0.1;
            var rotvel = 0;
            if (delta > 0)
            {
                rotvel = rv;
            }
            if (delta < 0)
            {
                rotvel = -rv;
            }
            
            PhysEditor.UndoTakeSnapshot();
            CurrenPiece_AddScale(rotvel);
        }
        else
        {
            if (delta > 0)
            {
                IncCurrentPiece();
            }
            if (delta < 0)
            {
                DecCurrentPiece();
            }
        }
    }
    override public function Update() : Void
    {
        if (KeyReader.Down(KeyReader.KEY_P) == true)
        {
            var poi : EdObj = PhysEditor.HitTestPhysObjGraphics(mx, my);
            if (poi != null)
            {
                PhysEditor.ClearCurrentPieces();
                PhysEditor.AddCurrentPiece(Game.objectDefs.FindIndexByName(poi.typeName), 0, 0, 0, poi.x, poi.y, poi.objParameters.ToString());
            }
        }
        
        
        if (KeyReader.Down(KeyReader.KEY_SHIFT) == true)
        {
            if (KeyReader.Pressed(KeyReader.KEY_UP))
            {
                PhysEditor.UndoTakeSnapshot();
                IncCurrentPiece();
            }
            if (KeyReader.Pressed(KeyReader.KEY_DOWN))
            {
                PhysEditor.UndoTakeSnapshot();
                DecCurrentPiece();
            }
            
            var rv : Float = 1;
            if (KeyReader.Down(KeyReader.KEY_CONTROL) == false)
            {
                rv *= 10;
            }
            if (KeyReader.Down(KeyReader.KEY_LEFT))
            {
                PhysEditor.UndoTakeSnapshot();
                CurrenPiece_AddRot(-rv);
            }
            if (KeyReader.Down(KeyReader.KEY_RIGHT))
            {
                PhysEditor.UndoTakeSnapshot();
                CurrenPiece_AddRot(rv);
            }
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
        
        var physObj : PhysObj;
        
        for (ob/* AS3HX WARNING could not determine type for var: ob exp: EField(EIdent(PhysEditor),currentPieceList) type: null */ in PhysEditor.currentPieceList)
        {
            physObj = Game.objectDefs.GetByIndex(ob.id);
            var p : Point = PhysEditor.GetMapPos(mxs + ob.xoff, mys + ob.yoff);
            PhysObj.RenderAt(physObj, p.x, p.y, ob.rot, ob.scale * PhysEditor.zoom, bd, PhysEditor.linesScreen.graphics, true);
        }
        
        PhysEditor.Editor_RenderGrid(bd);
    }
    override public function RenderHud(x : Int, y : Int) : Int
    {
        var s : String = "";
        for (ob/* AS3HX WARNING could not determine type for var: ob exp: EField(EIdent(PhysEditor),currentPieceList) type: null */ in PhysEditor.currentPieceList)
        {
            var physObj : PhysObj = Game.objectDefs.GetByIndex(ob.id);
            s += physObj.name + " ";
        }
        y += PhysEditor.AddInfoText("a", x, y, s);
        
        s = "ScrollPos: " + Math.round(PhysEditor.scrollX) + " " + Math.round(PhysEditor.scrollY);
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "CursorPos: " + as3hx.Compat.parseInt(MouseControl.x + PhysEditor.scrollX) + " " + as3hx.Compat.parseInt(MouseControl.y + PhysEditor.scrollY);
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "P: Pick a piece";
        y += PhysEditor.AddInfoText("a", x, y, s);
        return y;
    }
    
    
    
    public function CurrenPiece_AddScale(rv : Float)
    {
        for (ob/* AS3HX WARNING could not determine type for var: ob exp: EField(EIdent(PhysEditor),currentPieceList) type: null */ in PhysEditor.currentPieceList)
        {
            ob.scale += as3hx.Compat.parseFloat(rv);
        }
    }
    public function CurrenPiece_AddRot(rv : Float)
    {
        for (ob/* AS3HX WARNING could not determine type for var: ob exp: EField(EIdent(PhysEditor),currentPieceList) type: null */ in PhysEditor.currentPieceList)
        {
            ob.rot += as3hx.Compat.parseFloat(rv);
        }
    }
    
    public function DecCurrentPiece()
    {
        for (ob/* AS3HX WARNING could not determine type for var: ob exp: EField(EIdent(PhysEditor),currentPieceList) type: null */ in PhysEditor.currentPieceList)
        {
            ob.id--;
            if (ob.id < 0)
            {
                ob.id = Game.objectDefs.GetNum() - 1;
            }
        }
    }
    
    public function IncCurrentPiece()
    {
        for (ob/* AS3HX WARNING could not determine type for var: ob exp: EField(EIdent(PhysEditor),currentPieceList) type: null */ in PhysEditor.currentPieceList)
        {
            ob.id++;
            if (ob.id > Game.objectDefs.GetNum() - 1)
            {
                ob.id = 0;
            }
        }
    }
}


