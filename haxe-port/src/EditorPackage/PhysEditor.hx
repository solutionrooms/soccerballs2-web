package editorPackage;

import haxe.Constraints.Function;
import editorPackage.editParamUI.EditParams;
import fl.controls.List;
import fl.controls.listClasses.CellRenderer;
import fl.controls.listClasses.ListData;
import fl.events.ListEvent;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.Graphics;
import flash.display.MovieClip;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TextEvent;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.system.System;
import flash.text.AntiAliasType;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFieldType;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.ui.*;
import fl.events.ComponentEvent;
import fl.controls.ComboBox;
import licPackage.LicDef;

/**
	 * ...
	 * @author ...
	 */
class PhysEditor
{
    
    public function new()
    {
    }
    
    
    public static inline var editMode_Placement : Int = 0;
    public static inline var editMode_Library : Int = 1;
    public static inline var editMode_Commands1 : Int = 4;
    public static inline var editMode_Adjust : Int = 5;
    public static inline var editMode_Lines : Int = 6;
    public static inline var editMode_Joints : Int = 7;
    public static inline var editMode_GridCommands : Int = 8;
    public static inline var editMode_ObjCol : Int = 9;
    public static inline var editMode_Map : Int = 10;
    public static inline var editMode_PickPieceForLink : Int = 11;
    public static inline var editMode_PickLineForLink : Int = 12;
    public static inline var editMode_Multi : Int = 13;
    
    
    public static var currentLevel : Int = 0;
    public static var updateTimer : Int = 0;
    public static var oldEditMode : Int = 0;
    public static var editMode : Int = 0;
    public static var editSubMode : Int = 0;
    public static var prevEditMode : Int = 0;
    public static var scrollX : Float = 0;
    public static var scrollY : Float = 0;
    
    public static var renderMiniMap : Bool = false;
    public static var renderObjects : Bool = true;
    
    public static var gridsnap : Int = 20;
    public static var gridMode_active : Bool = false;
    public static var gridMode_renderGrid : Bool = false;
    
    public static var objectZSortMode : Bool = false;
    
    public static var infoTextFormat : TextFormat;
    public static var infoTextFormat_Cursor : TextFormat;
    public static var infoMC : MovieClip;
    public static var screenBD : BitmapData;
    public static var screenB : Bitmap;
    public static var editorMC : MovieClip;
    public static var linesScreen : MovieClip;
    
    public static var currentPieceList : Array<Dynamic>;
    
    
    public static var hoverLineIndex : Int;
    public static var hoverPointIndex : Int;
    
    public static var zoom : Float;
    public static var linZoom : Float;
    
    public static var undoList : Array<Dynamic>;
    
    public static var currentModeObject : EditModeBase = new EditModeBase();
    public static var editModeObj_Library : EditModeBase;
    public static var editModeObj_Placement : EditModeBase;
    public static var editModeObj_Adjust : EditModeBase;
    public static var editModeObj_Lines : EditModeBase;
    public static var editModeObj_Map : EditModeBase;
    public static var editModeObj_Joints : EditModeBase;
    public static var editModeObj_ObjCol : EditModeBase;
    public static var editModeObj_PickPieceForLink : EditModeBase;
    public static var editModeObj_PickLineForLink : EditModeBase;
    public static var editModeObj_Multi : EditModeBase;
    
    
    public static inline var LM_FILL : Int = 1;
    public static inline var LM_LINK : Int = 2;
    public static inline var LM_NORMALS : Int = 4;
    
    
    
    
    public static function SetEditMode(_mode : Int, clearParams : Bool = true)
    {
        KeyReader.Reset();
        editMode = _mode;
        editSubMode = 0;
        currentModeObject = new EditModeBase();
        if (editMode == editMode_Library)
        {
            currentModeObject = editModeObj_Library;
        }
        if (editMode == editMode_Placement)
        {
            currentModeObject = editModeObj_Placement;
        }
        if (editMode == editMode_Adjust)
        {
            currentModeObject = editModeObj_Adjust;
        }
        if (editMode == editMode_Lines)
        {
            currentModeObject = editModeObj_Lines;
        }
        if (editMode == editMode_Map)
        {
            currentModeObject = editModeObj_Map;
        }
        if (editMode == editMode_ObjCol)
        {
            currentModeObject = editModeObj_ObjCol;
        }
        if (editMode == editMode_Multi)
        {
            currentModeObject = editModeObj_Multi;
        }
        if (editMode == editMode_PickPieceForLink)
        {
            currentModeObject = editModeObj_PickPieceForLink;
        }
        if (editMode == editMode_PickLineForLink)
        {
            currentModeObject = editModeObj_PickLineForLink;
        }
        if (editMode == editMode_Joints)
        {
            currentModeObject = editModeObj_Joints;
        }
        
        if (clearParams)
        {
            EditParams.ClearParameterListBox();
        }
        currentModeObject.EnterMode();
    }
    
    public static function InitEditor(_sx : Float, _sy : Float) : Void
    {
        if (firstTime)
        {
            InitEditorOnce();
        }
        
        Mouse.show();
        PhysicsBase.Init();
        GameObjects.ClearAll();
        updateTimer = 0;
        currentPieceList = [];
        
        AddCurrentPiece(0, 0, 0, 0, 0, 0);
        
        currentLevel = Levels.currentIndex;
        
        zoom = linZoom = 1;
        
        MouseControl.SetWheelHandler(EditorWheelHandler);
        
        undoList = [];
        
        linesScreen = new MovieClip();
        linesScreen.graphics.clear();
        hoverLineIndex = -1;
        hoverPointIndex = -1;
        
        scrollX = _sx;
        scrollY = _sy;
        
        AddDataGrid(0, 300);
        
        editorMC = new MovieClip();
        
        editorMC.addEventListener(MouseEvent.MOUSE_DOWN, Editor_OnMouseDown);
        editorMC.addEventListener(MouseEvent.MOUSE_UP, Editor_OnMouseUp);
        editorMC.addEventListener(MouseEvent.MOUSE_MOVE, Editor_OnMouseMove);
        editorMC.addEventListener(Event.ENTER_FRAME, OnEnterFrame);
        
        screenBD = new BitmapData(Defs.displayarea_w, Defs.displayarea_h, false, 0xff2233);
        screenB = new Bitmap(screenBD);
        
        
        infoMC = new MovieClip();
        ClearInfoMC();
        
        editorMC.addChild(screenB);
        editorMC.addChild(infoMC);
        
        layersMC = EditorLayers.GetContainer();
        layersMC.scaleX = 0.6;
        layersMC.scaleY = 0.6;
        layersMC.x = Defs.editor_area_w - layersMC.width;
        layersMC.y = 15;
        editorMC.addChild(layersMC);
        
        LicDef.GetStage().addChild(editorMC);
        InitInfoTextFormat();
        
        CursorText_Init();
        CursorText_Hide();
        
        SetEditMode(editMode);
    }
    
    public static var layersMC : MovieClip;
    
    public static var firstTime : Bool = true;
    public static function InitEditorOnce() : Void
    {
        firstTime = false;
        Mouse.show();
        PhysicsBase.Init();
        GameObjects.ClearAll();
        updateTimer = 0;
        currentPieceList = [];
        
        AddCurrentPiece(0, 0, 0, 0, 0, 0);
        
        currentLevel = Levels.currentIndex;
        
        EditorLayers.InitOnce();
        
        MouseControl.SetWheelHandler(EditorWheelHandler);
        
        EdConsole.InitOnce();
        
        editModeObj_Library = new EditModeBase();
        editModeObj_Library.InitOnce();
        editModeObj_Placement = new EditModeBase();
        editModeObj_Placement.InitOnce();
        editModeObj_Adjust = new EditModeBase();
        editModeObj_Adjust.InitOnce();
        editModeObj_Lines = new EditModeBase();
        editModeObj_Lines.InitOnce();
        editModeObj_Map = new EditModeBase();
        editModeObj_Map.InitOnce();
        editModeObj_Joints = new EditModeBase();
        editModeObj_Joints.InitOnce();
        editModeObj_ObjCol = new EditModeBase();
        editModeObj_ObjCol.InitOnce();
        editModeObj_PickPieceForLink = new EditModeBase();
        editModeObj_PickPieceForLink.InitOnce();
        editModeObj_PickLineForLink = new EditModeBase();
        editModeObj_PickLineForLink.InitOnce();
        editModeObj_Multi = new EditModeBase();
        editModeObj_Multi.InitOnce();
        
        
        
        undoList = [];
        
        linesScreen = new MovieClip();
        linesScreen.graphics.clear();
        
        
        hoverLineIndex = -1;
        hoverPointIndex = -1;
        
        scrollX = 0;
        scrollY = 0;
        editMode = editMode_Adjust;
    }
    
    
    public static function CloseEditor()
    {
        editorMC.removeEventListener(Event.ENTER_FRAME, OnEnterFrame);
        editorMC.removeEventListener(MouseEvent.MOUSE_DOWN, Editor_OnMouseDown);
        editorMC.removeEventListener(MouseEvent.MOUSE_UP, Editor_OnMouseUp);
        editorMC.removeEventListener(MouseEvent.MOUSE_MOVE, Editor_OnMouseMove);
        
        
        editorMC.removeChild(screenB);
        editorMC.removeChild(infoMC);
        editorMC.removeChild(layersMC);
        
        LicDef.GetStage().removeChild(editorMC);
        screenBD = null;
        screenB = null;
        infoMC = null;
        editorMC = null;
    }
    
    
    public static function ClearInfoMC()
    {
        var i : Int;
        i = as3hx.Compat.parseInt(infoMC.numChildren - 1);
        while (i >= 0)
        {
            infoMC.removeChildAt(i);
            i--;
        }
    }
    
    public static function OnEnterFrame(e : Event)
    {
        var g : Graphics = Game.fillScreenMC.graphics;
        g.clear();
        RenderEditor();
    }
    
    
    
    
    
    
    
    
    
    
    public static function GetInstanceById(id : String) : EdObj
    {
        var level_instances : Array<Dynamic> = GetCurrentLevelInstances();
        for (inst in level_instances)
        {
            if (inst.id == id)
            {
                return inst;
            }
        }
        return null;
    }
    
    public static function GetAnyObjectById(id : String) : EditableObjectBase
    {
        var objs : Array<Dynamic> = GetAllObjectsList();
        for (inst in objs)
        {
            if (inst.id == id)
            {
                return inst;
            }
        }
        return null;
    }
    public static function GetAnyObjectByPreviousId(id : String) : EditableObjectBase
    {
        var objs : Array<Dynamic> = GetAllObjectsList();
        for (inst in objs)
        {
            if (inst.prev_id == id)
            {
                return inst;
            }
        }
        return null;
    }
    public static function ClearAllPreviousIDs()
    {
        var objs : Array<Dynamic> = GetAllObjectsList();
        for (inst in objs)
        {
            inst.prev_id == "";
        }
    }
    
    
    
    public static function Editor_OnMouseDown(e : MouseEvent) : Void
    {
        currentModeObject.OnMouseDown(e);
    }
    public static function Editor_OnMouseUp(e : MouseEvent) : Void
    {
        currentModeObject.OnMouseUp(e);
    }
    public static function Editor_OnMouseMove(e : MouseEvent) : Void
    {
        currentModeObject.OnMouseMove(e);
    }
    
    
    public static function ClearCurrentPieces() : Void
    {
        currentPieceList = [];
    }
    public static function AddCurrentPiece(id : Int, rot : Float, xoff : Float, yoff : Float, _origX : Float = 0, _origY : Float = 0, _initParams : String = "")
    {
        var piece : Dynamic = {};
        piece.id = id;
        piece.rot = as3hx.Compat.parseFloat(rot);
        piece.xoff = as3hx.Compat.parseFloat(xoff);
        piece.yoff = as3hx.Compat.parseFloat(yoff);
        piece.origx = as3hx.Compat.parseFloat(_origX);
        piece.origy = as3hx.Compat.parseFloat(_origY);
        piece.scale = 1;
        piece.initParams = _initParams;
        currentPieceList.push(piece);
    }
    
    public static function GetCurrentPieceInitialPos() : Point
    {
        if (currentPieceList.length == 0)
        {
            return new Point(0, 0);
        }
        var piece : Dynamic = currentPieceList[0];
        return new Point(piece.origx, piece.origy);
    }
    
    
    public static function ClearEditorMode() : Void
    {
        EditParams.ClearParameterListBox();
        KeyReader.Reset();
    }
    public static function UpdateEditor() : Void
    {
        if (isEntering)
        {
            return;
        }
        
        EdConsole.UpdateOncePerFrame();
        
        updateTimer++;
        var mx : Int = Std.int(MouseControl.x);
        var my : Int = Std.int(MouseControl.y);
        
        CursorText_SetPos(mx, my);
        
        if (gridMode_active)
        {
            mx = Math.floor(mx);
            my = Math.floor(my);
            mx = as3hx.Compat.parseInt(as3hx.Compat.parseInt(mx / gridsnap) * as3hx.Compat.parseInt(gridsnap));
            my = as3hx.Compat.parseInt(as3hx.Compat.parseInt(my / gridsnap) * as3hx.Compat.parseInt(gridsnap));
        }
        
        var sx : Float = scrollX;
        var sy : Float = scrollY;
        if (gridMode_active)
        {
            sx = Math.floor(sx);
            sy = Math.floor(sy);
            sx = as3hx.Compat.parseInt(sx / gridsnap) * as3hx.Compat.parseInt(gridsnap);
            sy = as3hx.Compat.parseInt(sy / gridsnap) * as3hx.Compat.parseInt(gridsnap);
        }
        
        var mxs : Int = as3hx.Compat.parseInt(mx + sx);
        var mys : Int = as3hx.Compat.parseInt(my + sy);
        
        
        var physObj : PhysObj;
        var l : Level = GetCurrentLevel();
        
        Lines_GetCurrentPointUnderCursor(mxs, mys);
        
        if (KeyReader.Pressed(KeyReader.KEY_1))
        {
            EditorLayers.ToggleUIVisibility();
        }
        
        if (KeyReader.Pressed(KeyReader.KEY_G))
        {
            gridMode_active = (gridMode_active == false);
        }
        
        if (KeyReader.Pressed(KeyReader.KEY_BACKSPACE))
        {
            scrollX = 0;
            scrollY = 0;
            zoom = linZoom = 1;
        }
        
        
        if (KeyReader.Pressed(KeyReader.KEY_F1))
        {
            SetEditMode(editMode_Multi);
        }
        if (KeyReader.Pressed(KeyReader.KEY_F2))
        {
            SetEditMode(editMode_Library);
        }
        
        
        if (KeyReader.Pressed(KeyReader.KEY_F5))
        {
            SetEditMode(editMode_Adjust);
        }
        if (KeyReader.Pressed(KeyReader.KEY_F6))
        {
            SetEditMode(editMode_Lines);
        }
        if (KeyReader.Pressed(KeyReader.KEY_F7))
        {
            SetEditMode(editMode_Joints);
        }
        
        if (KeyReader.Pressed(KeyReader.KEY_F8))
        {
            ClearEditorMode();
            ExportAllLevelsAsXml();
            return;
        }
        if (KeyReader.Pressed(KeyReader.KEY_F9))
        {
            ClearEditorMode();
            var sss : String = ExportLevelAsXml();
            ExternalData.OutputString(sss);
            
            CloseEditor();
            Game.StartLevel();
            return;
        }
        if (KeyReader.Pressed(KeyReader.KEY_SPACE))
        {
            ClearEditorMode();
            CloseEditor();
            Game.StartLevel();
            return;
        }
        
        var zadd : Float = 0;
        if (KeyReader.Down(KeyReader.KEY_EQUALS))
        {
            zadd = -0.1;
            if (KeyReader.Down(KeyReader.KEY_SHIFT))
            {
                zadd = -1;
            }
        }
        if (KeyReader.Down(KeyReader.KEY_MINUS))
        {
            zadd = 0.1;
            if (KeyReader.Down(KeyReader.KEY_SHIFT))
            {
                zadd = 1;
            }
        }
        
        if (zadd != 0)
        {
            var z : Float = 1 / zoom;
            var n : Float = MouseControl.x;
            var n1 : Float = MouseControl.y;
            scrollX += (n * z);
            scrollY += (n1 * z);
            
            linZoom += zadd;
            linZoom = Utils.LimitNumber(0.1, 1000, linZoom);
            
            
            zoom = 1 / linZoom;
            var z : Float = 1 / zoom;
            scrollX -= (n * z);
            scrollY -= (n1 * z);
        }
        
        
        if (editMode == editMode_Commands1)
        {
            if (KeyReader.Pressed(KeyReader.KEY_9))
            {
                var sss : String = ExportLevelAsXml();
                ExternalData.OutputString(sss);
                
                CloseEditor();
                Game.StartLevel();
                return;
            }
            if (KeyReader.Pressed(KeyReader.KEY_4))
            {
                KeyReader.ClearKey(KeyReader.KEY_4);
                var sss : String = ExportLevelAsXml();
                ExternalData.OutputString(sss);
                
                SetEditMode(prevEditMode);
                return;
            }
            if (KeyReader.Pressed(KeyReader.KEY_5))
            {
                KeyReader.ClearKey(KeyReader.KEY_5);
                ExportAllLevelsAsXml();
                SetEditMode(prevEditMode);
                return;
            }
            
            return;
        }
        if (editMode == editMode_GridCommands)
        {
            if (KeyReader.Pressed(KeyReader.KEY_1))
            {
                gridMode_active = gridMode_active == false;
            }
            if (KeyReader.Pressed(KeyReader.KEY_2))
            {
                gridMode_renderGrid = gridMode_renderGrid == false;
            }
            if (KeyReader.Pressed(KeyReader.KEY_3))
            {
                objectZSortMode = objectZSortMode == false;
            }
            if (KeyReader.Pressed(KeyReader.KEY_4))
            {
                renderMiniMap = (renderMiniMap == false);
            }
            if (KeyReader.Pressed(KeyReader.KEY_5))
            {
                renderObjects = (renderObjects == false);
            }
            
            if (KeyReader.Pressed(KeyReader.KEY_SPACE))
            {
                SetEditMode(prevEditMode);
            }
            
            
            return;
        }
        
        if (KeyReader.Pressed(KeyReader.KEY_U))
        {
            DoUndo();
        }
        
        
        currentModeObject.Update();
        UpdateScroll();
    }
    
    
    
    
    
    
    
    public static function EditorWheelHandler(delta : Int)
    {
        currentModeObject.OnMouseWheel(delta);
    }
    
    
    public static function Lines_GetCurrentPointUnderCursor(x : Float, y : Float)
    {
        var l : Level = GetCurrentLevel();
        var lineIndex : Int = 0;
        hoverLineIndex = -1;
        hoverPointIndex = -1;
        for (line/* AS3HX WARNING could not determine type for var: line exp: EField(EIdent(l),lines) type: null */ in l.lines)
        {
            var pointIndex : Int = 0;
            for (p/* AS3HX WARNING could not determine type for var: p exp: EField(EIdent(line),points) type: null */ in (line.points : Array<Dynamic>))
            {
                if (Utils.DistBetweenPoints(p.x, p.y, x, y) < 3)
                {
                    hoverLineIndex = lineIndex;
                    hoverPointIndex = pointIndex;
                    return;
                }
                pointIndex++;
            }
            lineIndex++;
        }
    }
    
    public static function UpdateScroll()
    {
        if (KeyReader.Down(KeyReader.KEY_SHIFT) == false)
        {
            var dv : Float = 32;
            var xv : Float = 0;
            var yv : Float = 0;
            if (KeyReader.Down(KeyReader.KEY_CONTROL))
            {
                dv = 4;
            }
            
            dv *= 1 / zoom;
            
            if (KeyReader.Down(KeyReader.KEY_LEFT))
            {
                xv = -dv;
            }
            if (KeyReader.Down(KeyReader.KEY_RIGHT))
            {
                xv = dv;
            }
            if (KeyReader.Down(KeyReader.KEY_UP))
            {
                yv = -dv;
            }
            if (KeyReader.Down(KeyReader.KEY_DOWN))
            {
                yv = dv;
            }
            scrollX += xv;
            scrollY += yv;
        }
    }
    
    
    public static var cursorTF : TextField;
    public static function CursorText_Set(s : String)
    {
        cursorTF.text = s;
        cursorTF.setTextFormat(infoTextFormat_Cursor);
    }
    public static function CursorText_Show()
    {
        cursorTF.visible = true;
    }
    public static function CursorText_Hide()
    {
        cursorTF.visible = false;
    }
    public static function CursorText_SetPos(x : Int, y : Int)
    {
        cursorTF.x = x + 10;
        cursorTF.y = y - 10;
    }
    public static function CursorText_Init()
    {
        cursorTF = new TextField();
        cursorTF.type = TextFieldType.DYNAMIC;
        cursorTF.x = 300;
        cursorTF.y = 300;
        cursorTF.text = "cursor here";
        cursorTF.background = false;
        
        infoTextFormat_Cursor.align = TextFormatAlign.LEFT;
        cursorTF.autoSize = TextFieldAutoSize.LEFT;
        
        cursorTF.setTextFormat(infoTextFormat_Cursor);
        cursorTF.antiAliasType = AntiAliasType.ADVANCED;
        cursorTF.name = "cursorTF";
        cursorTF.selectable = false;
        cursorTF.mouseEnabled = false;
        
        editorMC.addChild(cursorTF);
    }
    
    public static function AddInfoText(fieldName : String, x : Int, y : Int, s : String, justify : String = "left", extra : String = null) : Int
    {
        tf = new TextField();
        tf.type = TextFieldType.DYNAMIC;
        tf.x = x;
        tf.y = y;
        tf.text = s;
        tf.background = false;
        
        if (justify == "left")
        {
            infoTextFormat.align = TextFormatAlign.LEFT;
            tf.autoSize = TextFieldAutoSize.LEFT;
        }
        if (justify == "right")
        {
            infoTextFormat.align = TextFormatAlign.RIGHT;
            tf.autoSize = TextFieldAutoSize.RIGHT;
        }
        
        tf.setTextFormat(infoTextFormat);
        tf.antiAliasType = AntiAliasType.ADVANCED;
        tf.name = fieldName;
        tf.selectable = false;
        tf.mouseEnabled = false;
        
        
        
        
        infoMC.addChild(tf);
        return as3hx.Compat.parseInt(tf.height - 6);
    }
    
    public static function InitInfoTextFormat()
    {
        infoTextFormat = new TextFormat();
        infoTextFormat.size = 10;
        (untyped infoTextFormat).color = 0xffffff;
        infoTextFormat.font = "Arial";
        
        infoTextFormat_Cursor = new TextFormat();
        infoTextFormat_Cursor.size = 10;
        (untyped infoTextFormat_Cursor).color = 0xffffff;
        infoTextFormat_Cursor.font = "Arial";
    }
    public static function RenderPanel_Editor()
    {
        ClearInfoMC();
        var x : Float;
        var y : Float;
        var s : String;
        var w : Float;
        
        x = Defs.editor_area_w - 100;
        y = Defs.displayarea_h - 20;
        var memused : Int = as3hx.Compat.parseInt(System.totalMemory / 1024);
        
        s = "FPS: " + Std.string(Utils.DP2(Game.main.fps)) + "  Mem: " + memused;
        AddInfoText("fps", Std.int(x), Std.int(y), s, "right");
        x = Defs.editor_x + 10;
        s = "Level: " + currentLevel + "   [ " + GetCurrentLevel().id + "  " + GetCurrentLevel().name + " ]";
        AddInfoText("level", Std.int(x), Std.int(y), s);
        
        
        x = Defs.editor_area_w - 150;
        y = 0;
        s = "F1:MultiAdjust | F2:Library | F5:Objects | F6:Lines | F7:Joints | F8:Save | F9:Save&Quit";
        AddInfoText("level", Std.int(x), Std.int(y), s, "right");
        
        
        
        s = "Editor: Mode = ";
        if (editMode == editMode_Placement)
        {
            s += "Placement";
        }
        if (editMode == editMode_Map)
        {
            s += "Mapper";
        }
        if (editMode == editMode_Library)
        {
            s += "Library Page " + Std.string(as3hx.Compat.parseInt(editModeObj_Library.library_page + 1)) + " / " + Std.string(as3hx.Compat.parseInt(editModeObj_Library.GetNumLibraryPages())) + "     " + editModeObj_Library.library_hoverPieceName;
        }
        if (editMode == editMode_ObjCol)
        {
            s += "Object Collision";
        }
        if (editMode == editMode_Adjust)
        {
            s += "Adjust";
        }
        if (editMode == editMode_Joints)
        {
            s += "Joints";
        }
        if (editMode == editMode_Lines)
        {
            s += "Lines";
        }
        if (editMode == editMode_PickPieceForLink)
        {
            s += "Pick A Piece For Linkage";
        }
        if (editMode == editMode_PickLineForLink)
        {
            s += "Pick A Line For Linkage";
        }
        if (editMode == editMode_Multi)
        {
            s += "Multi Adjust";
        }
        x = Defs.editor_x + 10;
        y = 10;
        y += AddInfoText("a", Std.int(x), Std.int(y), s);
        
        y = currentModeObject.RenderHud(Std.int(x), Std.int(y));
    }
    
    public static function CheckIDForUniqueness(_id : String) : Bool
    {
        var match : Bool = false;
        var l : Level = GetCurrentLevel();
        for (line/* AS3HX WARNING could not determine type for var: line exp: EField(EIdent(l),lines) type: null */ in l.lines)
        {
            if (line.id == _id)
            {
                match = true;
            }
        }
        for (poi/* AS3HX WARNING could not determine type for var: poi exp: EField(EIdent(l),instances) type: null */ in l.instances)
        {
            if (poi.id == _id)
            {
                match = true;
            }
        }
        if (match)
        {
            Utils.print("ERRRRROOORR: CheckIDForUniqueness");
            return false;
        }
        return true;
    }
    public static function CreateNewUniqueID() : String
    {
        var unique : Bool = false;
        do
        {
            var s : String = "uid_";
            for (i in 0...6)
            {
                s += Utils.RandBetweenInt(0, 9);
            }
            unique = CheckIDForUniqueness(s);
        }
        while ((unique == false));
        
        return s;
    }
    
    public static function GetOrCreateUniqueLineID(l : EdLine) : String
    {
        if (l.id == "")
        {
            l.id = CreateNewUniqueID();
        }
        return l.id;
    }
    
    public static function GetOrCreateUniqueObjectID(poi : EdObj) : String
    {
        if (poi.id == "")
        {
            poi.id = CreateNewUniqueID();
        }
        return poi.id;
    }
    
    public static function CurrentAdjustObject_ParameterPickObjectLink()
    {
        if (editModeObj_Adjust.currentAdjustObject == null)
        {
            return;
        }
        var po : PhysObj = Game.objectDefs.FindByName(editModeObj_Adjust.currentAdjustObject.typeName);
        var paramName : String = po.instanceParams[editModeObj_Adjust.currentAdjustObjectParam];
        var ob : ObjParam = ObjectParameters.GetObjectParamByName(paramName);
        if (ob == null)
        {
            return;
        }
        if (ob.type != "objlink")
        {
            return;
        }
        SetEditMode(editMode_PickPieceForLink);
    }
    public static function CurrentAdjustObject_ParameterPickLineLink()
    {
        if (editModeObj_Adjust.currentAdjustObject == null)
        {
            return;
        }
        var po : PhysObj = Game.objectDefs.FindByName(editModeObj_Adjust.currentAdjustObject.typeName);
        var paramName : String = po.instanceParams[editModeObj_Adjust.currentAdjustObjectParam];
        var ob : ObjParam = ObjectParameters.GetObjectParamByName(paramName);
        if (ob == null)
        {
            return;
        }
        if (ob.type != "linelink")
        {
            return;
        }
        SetEditMode(editMode_PickLineForLink);
    }
    
    
    
    
    
    public static var pickedPieceForLink : EdObj = null;
    public static var isEntering : Bool = false;
    public static var tf : TextField;
    public static var AddTextEntry_Callback : Function;
    public static function AddTextEntry(xpos : Int, ypos : Int, title : String, text : String, _cb : Function)
    {
        AddEntryMC();
        
        AddTextEntry_Callback = _cb;
        var f : TextFormat;
        
        f = new TextFormat();
        f.size = 20;
        (untyped f).color = 0x0;
        
        tf = new TextField();
        tf.name = "tf";
        tf.type = TextFieldType.INPUT;
        entryMC.addChild(tf);
        tf.x = xpos;
        tf.y = ypos;
        tf.text = text;
        tf.opaqueBackground = true;
        tf.background = true;
        tf.backgroundColor = 0xffffff;
        tf.multiline = false;
        tf.setTextFormat(f);
        tf.setSelection(0, tf.text.length);
        Game.main.stage.focus = tf;
        
        tf.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler, false, 0, true);
        
        isEntering = true;
    }
    
    public static function AddDataGrid(xpos : Int, ypos : Int)
    {
    }
    
    public static var listBox : List = null;
    public static var listBoxContainer : MovieClip = null;
    
    
    public static function PreventPropogationHandler(e : MouseEvent)
    {
        e.stopImmediatePropagation();
    }
    
    public static function ParameterListBox_SetSelectedIndex()
    {
        if (listBoxContainer != null)
        {
            listBox.selectedIndex = editModeObj_Adjust.currentAdjustObjectParam;
        }
    }
    
    
    
    public static var entryMC : MovieClip;
    public static function RemoveEntryMC()
    {
        if (entryMC != null)
        {
            entryMC.parent.removeChild(entryMC);
            entryMC = null;
        }
    }
    public static function AddEntryMC()
    {
        RemoveEntryMC();
        entryMC = new MovieClip();
        entryMC.x = 0;
        entryMC.y = 0;
        entryMC.graphics.clear();
        entryMC.graphics.beginFill(0xffffff, 0.5);
        entryMC.graphics.drawRect(entryMC.x, entryMC.y, Defs.displayarea_w, Defs.displayarea_h);
        entryMC.graphics.endFill();
        editorMC.addChild(entryMC);
        entryMC.addEventListener(MouseEvent.CLICK, PreventPropogationHandler);
        entryMC.addEventListener(MouseEvent.MOUSE_DOWN, PreventPropogationHandler);
        entryMC.addEventListener(MouseEvent.MOUSE_UP, PreventPropogationHandler);
    }
    
    
    
    public static function keyDownHandler(e : KeyboardEvent)
    {
        if (isEntering == false)
        {
            return;
        }
        var tf : TextField = try cast(e.currentTarget, TextField) catch(e:Dynamic) null;
        if (e.charCode == KeyReader.KEY_ENTER)
        {
            if (AddTextEntry_Callback != null)
            {
                AddTextEntry_Callback(tf.text);
            }
            isEntering = false;
            
            
            Game.main.stage.focus = null;
            tf.parent.removeChild(tf);
            tf = null;
            RemoveEntryMC();
        }
        if (e.charCode == KeyReader.KEY_ESCAPE)
        {
            Utils.print("cancelled");
            isEntering = false;
            
            Game.main.stage.focus = null;
            tf.parent.removeChild(tf);
            tf = null;
            RemoveEntryMC();
        }
    }
    
    
    
    
    
    public static function RenderEditor()
    {
        linesScreen.graphics.clear();
        
        var gfxid : Int;
        var numf : Int;
        var px : Float;
        var s : String;
        
        var bd : BitmapData = screenBD;
        
        var mx : Int = Std.int(MouseControl.x);
        var my : Int = Std.int(MouseControl.y);
        
        if (gridMode_active)
        {
            mx = Math.floor(mx);
            my = Math.floor(my);
            mx = as3hx.Compat.parseInt(as3hx.Compat.parseInt(mx / gridsnap) * as3hx.Compat.parseInt(gridsnap));
            my = as3hx.Compat.parseInt(as3hx.Compat.parseInt(my / gridsnap) * as3hx.Compat.parseInt(gridsnap));
        }
        
        var sx : Float = scrollX;
        var sy : Float = scrollY;
        if (gridMode_active)
        {
            sx = Math.floor(sx);
            sy = Math.floor(sy);
            sx = as3hx.Compat.parseInt(sx / gridsnap) * as3hx.Compat.parseInt(gridsnap);
            sy = as3hx.Compat.parseInt(sy / gridsnap) * as3hx.Compat.parseInt(gridsnap);
        }
        
        var mxs : Int = as3hx.Compat.parseInt(mx + sx);
        var mys : Int = as3hx.Compat.parseInt(my + sy);
        
        
        
        if (editMode == editMode_Commands1)
        {
            bd.fillRect(Defs.screenRect, 0xff7030c0);
        }
        if (editMode == editMode_GridCommands)
        {
            bd.fillRect(Defs.screenRect, 0xff7030c0);
        }
        
        currentModeObject.Render(bd);
        
        
        
        RenderPanel_Editor();
    }
    
    
    
    
    
    
    
    
    
    public static function RenderBackground(bd : BitmapData)
    {
        var p0 : Point = GetMapPos(0, 0);
        var w : Float = Defs.displayarea_w * zoom;
        var h : Float = Defs.displayarea_h * zoom;
        
        bd.fillRect(new Rectangle(p0.x, p0.y, w, h), 0);
    }
    
    
    public static function Editor_RenderGrid(bd : BitmapData)
    {
        if (gridMode_active == false)
        {
            return;
        }
        if (gridMode_renderGrid == false)
        {
            return;
        }
        
        
        var mx : Int = as3hx.Compat.parseInt(scrollX);
        var my : Int = as3hx.Compat.parseInt(scrollY);
        
        mx = Math.floor(mx);
        my = Math.floor(my);
        mx = as3hx.Compat.parseInt(as3hx.Compat.parseInt(mx / gridsnap) * as3hx.Compat.parseInt(gridsnap));
        my = as3hx.Compat.parseInt(as3hx.Compat.parseInt(my / gridsnap) * as3hx.Compat.parseInt(gridsnap));
        
        var x0 : Float = 0;
        var x1 : Float = Defs.displayarea_w;
        var y0 : Float = 0;
        var y1 : Float = Defs.displayarea_h;
        
        
        var g : Graphics = linesScreen.graphics;
        g.lineStyle(1, 0xff808080, 1);
        
        var x : Int;
        var y : Int;
        
        var sx : Float = scrollX;
        var sy : Float = scrollY;
        
        x = mx;
        while (x < mx + Defs.displayarea_w)
        {
            g.moveTo(x - sx, y0);
            g.lineTo(x - sx, y1);
            x += gridsnap;
        }
        y = my;
        while (y < my + Defs.displayarea_h)
        {
            g.moveTo(x0, y - sy);
            g.lineTo(x1, y - sy);
            y += gridsnap;
        }
    }
    
    public static function SnapToObjects(x : Float, y : Float) : Point
    {
        var physObj : PhysObj;
        
        if (currentPieceList.length != 1)
        {
            return null;
        }
        var ob : Dynamic = currentPieceList[0];
        
        physObj = Game.objectDefs.GetByIndex(ob.id);
        
        if (physObj == null)
        {
            return null;
        }
        
        var pi : EdObj = Levels.CreateLevelObjInstanceAt(physObj.name, x + ob.xoff, y + ob.yoff, ob.rot, ob.scale, "");
        Editor_GetNearbyGuidelines(null, x, y, 20);
        
        
        var bd : BitmapData = screenBD;
        
        
        var madnumber : Int = 99999999;
        
        var nearestX : Float = madnumber;
        var nearestY : Float = madnumber;
        
        for (gl/* AS3HX WARNING could not determine type for var: gl exp: EIdent(guideLines) type: null */ in guideLines)
        {
            if (gl.type == 1)
            {
                if (Math.abs(gl.x0 - x) < nearestX)
                {
                    nearestX = gl.x0;
                }
            }
            else if (Math.abs(gl.y0 - y) < nearestY)
            {
                nearestY = gl.y0;
            }
        }
        
        if (nearestX != madnumber && nearestY != madnumber)
        {
            var p : Point = new Point(nearestX, nearestY);
            return p;
        }
        return null;
    }
    
    public static var guideLines : Array<Dynamic>;
    public static function Editor_GetNearbyGuidelines(origObject : EdObj, x : Float, y : Float, maxd1 : Float = 50)
    {
        var maxd2 : Float = 3;
        var body : PhysObjBody;
        var shape : PhysObjShape;
        var p : Point;
        var p1 : Point;
        
        var level_instances : Array<Dynamic> = GetCurrentLevelInstances();
        var m : Matrix = new Matrix();
        
        var origPoints : Array<Dynamic> = [];
        
        if (origObject != null)
        {
            var origPO : PhysObj = Game.objectDefs.FindByName(origObject.typeName);
            if (origPO != null)
            {
                for (body/* AS3HX WARNING could not determine type for var: body exp: EField(EIdent(origPO),bodies) type: null */ in origPO.bodies)
                {
                    for (shape/* AS3HX WARNING could not determine type for var: shape exp: EField(EIdent(body),shapes) type: null */ in body.shapes)
                    {
                        if (shape.type == PhysObjShape.Type_Poly)
                        {
                            for (p/* AS3HX WARNING could not determine type for var: p exp: EField(EIdent(shape),poly_points) type: null */ in shape.poly_points)
                            {
                                m.identity();
                                m.rotate(Utils.DegToRad(origObject.rot));
                                var pr : Point = new Point(p.x, p.y);
                                pr = m.transformPoint(pr);
                                
                                var pp : Point = new Point(pr.x + origObject.x + body.pos.x, pr.y + origObject.y + body.pos.y);
                                origPoints.push(pp);
                            }
                        }
                    }
                }
            }
        }
        else
        {
            origPoints.push(new Point(x, y));
        }
        
        guideLines = [];
        for (poi in level_instances)
        {
            if (poi != origObject)
            {
                var po : PhysObj = Game.objectDefs.FindByName(poi.typeName);
                if (po != null)
                {
                    for (body/* AS3HX WARNING could not determine type for var: body exp: EField(EIdent(po),bodies) type: null */ in po.bodies)
                    {
                        for (shape/* AS3HX WARNING could not determine type for var: shape exp: EField(EIdent(body),shapes) type: null */ in body.shapes)
                        {
                            if (shape.type == PhysObjShape.Type_Poly)
                            {
                                for (p/* AS3HX WARNING could not determine type for var: p exp: EField(EIdent(shape),poly_points) type: null */ in shape.poly_points)
                                {
                                    m.identity();
                                    m.rotate(Utils.DegToRad(poi.rot));
                                    var pr : Point = new Point(p.x, p.y);
                                    pr = m.transformPoint(pr);
                                    
                                    var ppp : Point = new Point(pr.x + poi.x + body.pos.x, pr.y + poi.y + body.pos.y);
                                    for (p1 in origPoints)
                                    {
                                        var dx : Float = Math.abs(ppp.x - p1.x);
                                        var dy : Float = Math.abs(ppp.y - p1.y);
                                        
                                        var level : Bool = false;
                                        if (dy < maxd2 && dx < maxd1)
                                        {
                                            level = false;
                                            if (Math.floor(ppp.y) == Math.floor(p1.y))
                                            {
                                                level = true;
                                            }
                                            
                                            var gl : PhysEdGuideLine = new PhysEdGuideLine(ppp.x - 100, ppp.x + 100, ppp.y, 0, level);
                                            guideLines.push(gl);
                                        }
                                        if (dx < maxd2 && dy < maxd1)
                                        {
                                            level = false;
                                            if (Math.floor(ppp.x) == Math.floor(p1.x))
                                            {
                                                level = true;
                                            }
                                            var gl : PhysEdGuideLine = new PhysEdGuideLine(ppp.y - 100, ppp.y + 100, ppp.x, 1, level);
                                            guideLines.push(gl);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    public static function Editor_RenderNearbyGuidelines()
    {
        var bd : BitmapData = screenBD;
        for (gl in guideLines)
        {
            var col : Int = 0xffff0000;
            if (gl.level)
            {
                col = 0xff00ffff;
            }
            RenderLine(gl.x0 - scrollX, gl.y0 - scrollY, gl.x1 - scrollX, gl.y1 - scrollY, col);
        }
    }
    
    
    
    public static function Editor_RenderMiniMap()
    {
        if (renderMiniMap == false)
        {
            return;
        }
        var scale : Float = 1 / 20;
        var level_instances : Array<Dynamic> = GetCurrentLevelInstances();
        var bd : BitmapData = screenBD;
        for (poi in level_instances)
        {
            var po : PhysObj = Game.objectDefs.FindByName(poi.typeName);
            if (po != null)
            {
                PhysObj.RenderAt(po, poi.x - scrollX, (poi.y - scrollY) + (240 / scale), poi.rot, poi.scale, bd, linesScreen.graphics, false);
            }
        }
    }
    public static function FillPoly(poly : Array<Dynamic>, col : Int, alpha : Float)
    {
        if (poly.length <= 2)
        {
            return;
        }
        var g : Graphics = linesScreen.graphics;
        g.lineStyle(null, null, null);
        g.beginFill(col, alpha);
        for (i in 0...poly.length + 1)
        {
            var j : Int = as3hx.Compat.parseInt(i % poly.length);
            var p : Point = poly[j];
            if (i == 0)
            {
                g.moveTo(p.x, p.y);
            }
            else
            {
                g.lineTo(p.x, p.y);
            }
        }
        g.endFill();
    }
    
    
    public static function FillPolyBitmap(bd : BitmapData, poly : Array<Dynamic>)
    {
        if (poly.length <= 2)
        {
            return;
        }
        var g : Graphics = linesScreen.graphics;
        g.lineStyle(null, null, null);
        g.beginBitmapFill(bd, null, true, false);
        for (i in 0...poly.length + 1)
        {
            var j : Int = as3hx.Compat.parseInt(i % poly.length);
            var p : Point = poly[j];
            if (i == 0)
            {
                g.moveTo(p.x, p.y);
            }
            else
            {
                g.lineTo(p.x, p.y);
            }
        }
        g.endFill();
    }
    
    
    public static function RenderLine(x0 : Float, y0 : Float, x1 : Float, y1 : Float, col : Int, thickness : Float = 1, alpha : Float = 1, normal : Bool = false, directionArrow : Bool = false)
    {
        var sx0 : Float = 0;
        var sx1 : Float = sx0 + Defs.displayarea_w;
        if (x0 > sx1 && x1 > sx1)
        {
            return;
        }
        if (x0 < sx0 && x1 < sx0)
        {
            return;
        }
        var sy0 : Float = 0;
        var sy1 : Float = sy0 + Defs.displayarea_h;
        if (y0 > sy1 && y1 > sy1)
        {
            return;
        }
        if (y0 < sy0 && y1 < sy0)
        {
            return;
        }
        
        var g : Graphics = linesScreen.graphics;
        g.lineStyle(thickness, col, alpha);
        g.moveTo(x0, y0);
        g.lineTo(x1, y1);
        
        if (normal)
        {
            var mx : Float = (x0 + x1) * 0.5;
            var my : Float = (y0 + y1) * 0.5;
            var dir : Float = Math.atan2(y1 - y0, x1 - x0) - (Math.PI * 0.5);
            var mx1 : Float = mx + (Math.cos(dir) * 5);
            var my1 : Float = my + (Math.sin(dir) * 5);
            g.moveTo(mx, my);
            g.lineTo(mx1, my1);
        }
        if (directionArrow)
        {
            var dir : Float = Math.atan2(y1 - y0, x1 - x0);
            dir += Utils.DegToRad(180);
            var x2 : Float = x1 + (Math.cos(dir - Utils.DegToRad(15)) * 20);
            var y2 : Float = y1 + (Math.sin(dir - Utils.DegToRad(15)) * 20);
            g.moveTo(x1, y1);
            g.lineTo(x2, y2);
            var x2 : Float = x1 + (Math.cos(dir + Utils.DegToRad(15)) * 20);
            var y2 : Float = y1 + (Math.sin(dir + Utils.DegToRad(15)) * 20);
            g.moveTo(x1, y1);
            g.lineTo(x2, y2);
        }
    }
    public static function RenderCircle(x : Float, y : Float, r : Float, col : Int, thickness : Float = 1, alpha : Float = 1)
    {
        var g : Graphics = linesScreen.graphics;
        g.lineStyle(thickness, col, alpha);
        g.drawCircle(x, y, r);
    }
    
    public static function FillCircle(x : Float, y : Float, r : Float, col : Int, thickness : Float = 1, alpha : Float = 1)
    {
        var g : Graphics = linesScreen.graphics;
        g.lineStyle(null, 0, 0);
        g.beginFill(col, alpha);
        g.drawCircle(x, y, r);
        g.endFill();
    }
    
    public static function RenderRectangle(r : Rectangle, col : Int, thickness : Float = 1, alpha : Float = 1)
    {
        var sx0 : Float = 0;
        var sx1 : Float = sx0 + Defs.displayarea_w;
        if (r.left > sx1)
        {
            return;
        }
        if (r.right < sx0)
        {
            return;
        }
        var sy0 : Float = 0;
        var sy1 : Float = sy0 + Defs.displayarea_h;
        if (r.top > sy1)
        {
            return;
        }
        if (r.bottom < sy0)
        {
            return;
        }
        
        
        RenderLine(r.left, r.top, r.right, r.top, col, thickness, alpha);
        RenderLine(r.left, r.bottom, r.right, r.bottom, col, thickness, alpha);
        RenderLine(r.left, r.top, r.left, r.bottom, col, thickness, alpha);
        RenderLine(r.right, r.top, r.right, r.bottom, col, thickness, alpha);
    }
    
    public static function FillRectangle(r : Rectangle, col : Int, thickness : Float = 1, alpha : Float = 1)
    {
        var sx0 : Float = 0;
        var sx1 : Float = sx0 + Defs.displayarea_w;
        if (r.left > sx1)
        {
            return;
        }
        if (r.right < sx0)
        {
            return;
        }
        var sy0 : Float = 0;
        var sy1 : Float = sy0 + Defs.displayarea_h;
        if (r.top > sy1)
        {
            return;
        }
        if (r.bottom < sy0)
        {
            return;
        }
        
        
        var g : Graphics = linesScreen.graphics;
        g.lineStyle(null, 0, 0);
        g.beginFill(col, alpha);
        g.moveTo(r.left, r.top);
        g.lineTo(r.right, r.top);
        g.lineTo(r.right, r.bottom);
        g.lineTo(r.left, r.bottom);
        g.endFill();
    }
    
    public static function SortInstancesByZ(list : Array<Dynamic>) : Array<Dynamic>
    {
        var poi : EdObj;
        for (poi in list)
        {
            poi.sortZ = 0;
            var po : PhysObj = Game.objectDefs.FindByName(poi.typeName);
            
            
            for (graphic/* AS3HX WARNING could not determine type for var: graphic exp: EField(EIdent(po),graphics) type: null */ in po.graphics)
            {
                poi.sortZ = graphic.zoffset;
            }
            
            for (body/* AS3HX WARNING could not determine type for var: body exp: EField(EIdent(po),bodies) type: null */ in po.bodies)
            {
                for (graphic/* AS3HX WARNING could not determine type for var: graphic exp: EField(EIdent(body),graphics) type: null */ in body.graphics)
                {
                    poi.sortZ = graphic.zoffset;
                }
            }
        }
        Sort.numericDesc(list, "sortZ");
        return list;
    }
    
    
    
    public static function Editor_RenderPickedObjectsHilight() : Void
    {
        if (renderObjects == false)
        {
            return;
        }
        var bd : BitmapData = screenBD;
        var pos : Point = GetCurrentPieceInitialPos();
        for (ob in currentPieceList)
        {
            var po : PhysObj = Game.objectDefs.GetByIndex(ob.id);
            if (po != null)
            {
                var x : Float = ob.origx;
                var y : Float = ob.origy;
                PhysObj.RenderOutline(po, x - scrollX, y - scrollY, 9, linesScreen.graphics);
            }
        }
    }
    
    public static function Editor_RenderJoints1(bd : BitmapData)
    {
        var jointList : Array<Dynamic> = Levels.GetCurrentLevelJoints();
        
        for (joint in jointList)
        {
            var doit : Bool = true;
            if (editModeObj_Joints.selectedJoint == joint)
            {
                if ((PhysEditor.updateTimer & 1) != 0)
                {
                    doit = false;
                }
            }
            if (doit == true)
            {
                if (joint.type == EdJoint.Type_Rev)
                {
                    RenderRevJoint(bd, joint);
                }
                if (joint.type == EdJoint.Type_Distance)
                {
                    RenderDistanceJoint(bd, joint);
                }
                if (joint.type == EdJoint.Type_Prismatic)
                {
                    RenderPrismaticJoint(bd, joint);
                }
            }
        }
    }
    
    public static function Editor_RenderJoints(bd : BitmapData)
    {
        PhysEditor.linesScreen.graphics.clear();
        var jointList : Array<Dynamic> = Levels.GetCurrentLevelJoints();
        
        for (joint in jointList)
        {
            joint.Render();
        }
        PhysEditor.screenBD.draw(PhysEditor.linesScreen);
    }
    
    public static function RemoveEverything()
    {
        editModeObj_Joints.RemoveAllJoints();
        PhysEditor.GetCurrentLevel().instances = [];
        
        PhysEditor.GetCurrentLevel().lines = [];
        editModeObj_Lines.currentLineIndex = -1;
        editModeObj_Lines.currentPointIndex = -1;
    }
    
    public static function RenderRevJoint(bd : BitmapData, joint : EdJoint)
    {
        var zp : Point;
        var zp1 : Point;
        
        zp = GetMapPos(Std.int(joint.rev_pos.x), Std.int(joint.rev_pos.y));
        
        Utils.RenderCircle(bd, zp.x, zp.y, 10, 0xffffffff);
        if (joint.obj0Name != "")
        {
            var inst : EdObj = PhysEditor.GetInstanceById(joint.obj0Name);
            if (inst != null)
            {
                zp1 = GetMapPos(Std.int(inst.x), Std.int(inst.y));
                
                Utils.RenderDotLine(bd, zp.x, zp.y, zp1.x, zp1.y, 100, 0xffff0000);
                Utils.RenderCircle(bd, zp1.x, zp1.y, 5 * zoom, 0xffffffff);
            }
        }
        if (joint.obj1Name != "")
        {
            var inst : EdObj = PhysEditor.GetInstanceById(joint.obj1Name);
            if (inst != null)
            {
                zp1 = GetMapPos(Std.int(inst.x), Std.int(inst.y));
                zp = GetMapPos(Std.int(joint.rev_pos.x), Std.int(joint.rev_pos.y));
                
                Utils.RenderDotLine(bd, zp.x, zp.y, zp1.x, zp1.y, 100, 0xffff8000);
                Utils.RenderCircle(bd, zp1.x, zp1.y, 5, 0xffffffff);
            }
        }
    }
    public static function RenderPrismaticJoint(bd : BitmapData, joint : EdJoint)
    {
        var sx : Float = scrollX;
        var sy : Float = scrollY;
        var v0 : Point = joint.prism_pos.clone();
        var v1 : Point = joint.prism_pos1.clone();
        Utils.RenderDotLine(bd, v0.x - sx, v0.y - sy, v1.x - sx, v1.y - sy, 100, 0xffffffff);
    }
    public static function RenderDistanceJoint(bd : BitmapData, joint : EdJoint)
    {
        var zp : Point;
        var zp1 : Point;
        
        zp = GetMapPos(Std.int(joint.dist_pos0.x), Std.int(joint.dist_pos0.y));
        zp1 = GetMapPos(Std.int(joint.dist_pos1.x), Std.int(joint.dist_pos1.y));
        
        
        Utils.RenderDotLine(bd, zp.x, zp.y, zp1.x, zp1.y, 100, 0xff00ffff);
        Utils.RenderCircle(bd, zp.x, zp.y, 5, 0xff00cccc);
        Utils.RenderCircle(bd, zp1.x, zp1.y, 5, 0xff00cccc);
    }
    
    
    
    public static function RenderSortedEdObjs()
    {
        var sortList : Array<Dynamic> = [];
        var l : Level = GetCurrentLevel();
        var level_instances : Array<Dynamic> = GetCurrentLevelInstances();
        
        for (poi in level_instances)
        {
            poi.SetSortPosFromGameLayer();
            sortList.push(poi);
        }
        var i : Int = 0;
        for (line/* AS3HX WARNING could not determine type for var: line exp: EField(EIdent(l),lines) type: null */ in l.lines)
        {
            line.SetSortPosFromGameLayer();
            sortList.push(line);
            line.index = i;
            i++;
        }
        
        Sort.numericDesc(sortList, "sort_zpos");
        
        for (base in sortList)
        {
            if (Std.is(base, EdObj))
            {
                poi = try cast(base, EdObj) catch(e:Dynamic) null;
                poi.Render();
            }
            if (Std.is(base, EdLine))
            {
                line = try cast(base, EdLine) catch(e:Dynamic) null;
                line.RenderInner();
            }
        }
    }
    
    
    public static function Editor_RenderObjects()
    {
        if (renderObjects == false)
        {
            return;
        }
        var level_instances : Array<Dynamic> = GetCurrentLevelInstances();
        
        if (objectZSortMode)
        {
            level_instances = SortInstancesByZ(level_instances);
        }
        
        
        var bd : BitmapData = screenBD;
        for (poi in level_instances)
        {
            poi.Render();
        }
    }
    public static function ExportAllLevelsAsXml()
    {
        var sss : String = "";
        var i : Int;
        var cl : Int = currentLevel;
        for (i in 0...Levels.list.length)
        {
            currentLevel = i;
            sss += ExportLevelAsXml();
            sss += "\n\n";
        }
        currentLevel = cl;
        ExternalData.OutputString(sss);
    }
    
    
    
    
    public static function UndoTakeSnapshot()
    {
        var l : Level = GetCurrentLevel();
        
        var undo : Dynamic = {};
        var lines : Array<Dynamic> = [];
        var objs : Array<Dynamic> = [];
        var joints : Array<Dynamic> = [];
        
        for (line/* AS3HX WARNING could not determine type for var: line exp: EField(EIdent(l),lines) type: null */ in l.lines)
        {
            var newline : EdLine = line.Clone();
            lines.push(newline);
        }
        undo.lines = lines;
        
        
        var level_instances : Array<Dynamic> = GetCurrentLevelInstances();
        for (poi in level_instances)
        {
            var newpoi : EdObj = poi.Clone();
            objs.push(newpoi);
        }
        undo.objects = objs;
        
        for (joint/* AS3HX WARNING could not determine type for var: joint exp: EField(EIdent(l),joints) type: null */ in l.joints)
        {
            var newjoint : EdJoint = joint.Clone();
            joints.push(newjoint);
        }
        undo.joints = joints;
        
        undoList.push(undo);
    }
    
    public static function DoUndo()
    {
        var l : Level = GetCurrentLevel();
        
        if (undoList.length == 0)
        {
            return;
        }
        
        var undo : Dynamic = undoList.pop();
        
        var joints : Array<Dynamic> = undo.joints;
        var lines : Array<Dynamic> = undo.lines;
        var objects : Array<Dynamic> = undo.objects;
        
        l.lines = [];
        
        for (line in lines)
        {
            var newline : EdLine = line.Clone();
            l.lines.push(newline);
        }
        
        if (objects.length != 0)
        {
            var level_instances : Array<Dynamic> = [];
            for (poi in objects)
            {
                var newpoi : EdObj = poi.Clone();
                level_instances.push(newpoi);
            }
            Levels.list[currentLevel].instances = level_instances;
        }
        
        l.joints = [];
        for (joint in joints)
        {
            var newjoint : EdJoint = joint.Clone();
            l.joints.push(newjoint);
        }
        
        editModeObj_Multi.AfterUndo();
        editModeObj_Lines.currentLineIndex = -1;
        editModeObj_Lines.currentPointIndex = -1;
    }
    
    
    
    public static function ExportLevelAsXml() : String
    {
        var l : Level = GetCurrentLevel();
        
        var s : String = "";
        var ss : String = "";
        
        s = "<level id=\"" + l.id + "\"";
        s += " name=\"" + l.name + "\"";
        s += " displayname=\"" + l.displayName + "\"";
        s += " category=\"" + Std.string(l.category) + "\"";
        s += " desc=\"" + l.description + "\"";
        s += " bg=\"" + l.bgFrame + "\"";
        s += " >";
        ss += s + "\n";
        Utils.print(s);
        
        
        s = Levels.GetGameSpecificLevelDataXML(currentLevel);
        ss += s + "\n";
        Utils.print(s);
        
        
        for (frameID/* AS3HX WARNING could not determine type for var: frameID exp: EField(EIdent(l),helpscreenFrames) type: null */ in l.helpscreenFrames)
        {
            s = "\t<helpscreen frame=\"" + frameID + "\" />";
            ss += s + "\n";
            Utils.print(s);
        }
        
        var level_instances : Array<Dynamic> = GetCurrentLevelInstances();
        
        for (libfilter/* AS3HX WARNING could not determine type for var: libfilter exp: EField(EIdent(editModeObj_Library),libraryFilters) type: null */ in editModeObj_Library.libraryFilters)
        {
            var active : Bool = false;
            for (poi in level_instances)
            {
                var po : PhysObj = Game.objectDefs.FindByName(poi.typeName);
                if (po != null && po.libraryClass == libfilter)
                {
                    active = true;
                }
            }
            if (active)
            {
                s = "\t<objgroup name=\"" + libfilter + "\">";
                ss += s + "\n";
                Utils.print(s);
                for (poi in level_instances)
                {
                    var po : PhysObj = Game.objectDefs.FindByName(poi.typeName);
                    
                    
                    if (po != null && po.libraryClass == libfilter)
                    {
                        var paramString : String = poi.GetParameterListForExport();
                        
                        s = "\t\t<obj id=\"" + poi.id + "\" type=\"" + poi.typeName + "\" x=\"" + poi.x + "\" y=\"" + poi.y + "\" rot=\"" + poi.rot + "\" scale=\"" + poi.scale + "\" params=\"" + paramString + "\" />";
                        ss += s + "\n";
                        Utils.print(s);
                    }
                }
                s = "\t</objgroup>";
                ss += s + "\n";
                Utils.print(s);
            }
        }
        
        s = "\t<joints>";
        ss += s + "\n";
        Utils.print(s);
        for (joint/* AS3HX WARNING could not determine type for var: joint exp: EField(EIdent(l),joints) type: null */ in l.joints)
        {
            s = joint.GetExportXMLString();
            
            ss += s + "\n";
            Utils.print(s);
        }
        s = "\t</joints>";
        ss += s + "\n";
        Utils.print(s);
        
        var i : Int;
        var j : Int;
        
        
        var point : Point;
        
        for (line/* AS3HX WARNING could not determine type for var: line exp: EField(EIdent(l),lines) type: null */ in l.lines)
        {
            var paramString : String = line.GetParameterListForExport();
            
            s = "<line type=\"" + line.type + "\" id=\"" + line.id + "\"";
            s += " params=\"" + paramString + "\"" + " >";
            ss += s + "\n";
            Utils.print(s);
            
            var i : Int;
            var j : Int;
            
            var points : Array<Dynamic> = line.points;
            
            var numPoints : Int = points.length;
            var numPerLine : Int = 10;
            var numGroups : Int = as3hx.Compat.parseInt(numPoints / numPerLine);
            var numRemainder : Int = as3hx.Compat.parseInt(numPoints % numPerLine);
            var count : Int = 0;
            
            
            for (i in 0...numGroups)
            {
                var s1 : String = "<points a=\"";
                for (j in 0...numPerLine)
                {
                    point = points[count++];
                    s1 += point.x + "," + point.y;
                    if (j != numPerLine - 1)
                    {
                        s1 += ", ";
                    }
                }
                s1 += "\" />";
                s = s1;
                ss += s + "\n";
                Utils.print(s);
            }
            if (numRemainder != 0)
            {
                var s1 : String = "<points a=\"";
                for (j in 0...numRemainder)
                {
                    point = points[count++];
                    s1 += point.x + "," + point.y;
                    if (j != numRemainder - 1)
                    {
                        s1 += ", ";
                    }
                }
                s1 += "\" />";
                s = s1;
                ss += s + "\n";
                Utils.print(s);
            }
            
            s = "</line>";
            ss += s + "\n";
            Utils.print(s);
        }
        
        
        
        s = "<map";
        s += " minx=\"" + l.mapMinX + "\"";
        s += " maxx=\"" + l.mapMaxX + "\"";
        s += " miny=\"" + l.mapMinY + "\"";
        s += " maxy=\"" + l.mapMaxY + "\"";
        s += " cellw=\"" + l.mapCellW + "\"";
        s += " cellh=\"" + l.mapCellH + "\"";
        s += " >";
        ss += s + "\n";
        Utils.print(s);
        
        var len : Int = l.map.length;
        var start : Int = 0;
        var doneit : Bool = false;
        var numPerLine : Int = 600;
        
        do
        {
            if (len >= numPerLine)
            {
                s = "<mapdata a=\"";
                for (i in start...start + numPerLine)
                {
                    s += Std.string(l.map[i]);
                }
                s += "\"/>";
                ss += s + "\n";
                start += numPerLine;
                len -= numPerLine;
            }
            else
            {
                s = "<mapdata a=\"";
                for (i in start...start + len)
                {
                    s += Std.string(l.map[i]);
                }
                s += "\"/>";
                ss += s + "\n";
                doneit = true;
            }
        }
        while ((doneit == false));
        
        s = "</map>";
        ss += s + "\n";
        Utils.print(s);
        
        
        s = "</level>";
        ss += s + "\n";
        Utils.print(s);
        
        return ss;
    }
    
    
    public static function GetAllObjectsList() : Array<Dynamic>
    {
        var a0 : Array<Dynamic> = GetCurrentLevel().joints;
        var a1 : Array<Dynamic> = GetCurrentLevel().lines;
        var a2 : Array<Dynamic> = GetCurrentLevel().instances;
        var a : Array<Dynamic> = (a0 + a1);
        a = (a + a2);
        return a;
    }
    
    
    public static function DragBoxAnyObject(r : Rectangle) : Array<Dynamic>
    {
        var obj : EditableObjectBase = null;
        
        var a0 : Array<Dynamic> = editModeObj_Joints.HitTestRectangle(r);
        var a1 : Array<Dynamic> = editModeObj_Lines.HitTestRectangle(r);
        var a2 : Array<Dynamic> = ObjectsHitTestRectangle(r);
        
        var a : Array<Dynamic> = (a0 + a1);
        a = (a + a2);
        
        return a;
    }
    
    public static function ObjectsHitTestRectangle(r : Rectangle) : Array<Dynamic>
    {
        var a : Array<Dynamic> = [];
        var level_instances : Array<Dynamic> = GetCurrentLevelInstances();
        for (obj in level_instances)
        {
            if (obj.HitTestRectangle(r))
            {
                a.push(obj);
            }
        }
        return a;
    }
    
    public static function HitTestAnyObjectNoJoints(x : Float, y : Float, screenX : Float, screenY : Float) : EditableObjectBase
    {
        var obj : EditableObjectBase = null;
        obj = try cast(HitTestPhysObjGraphics(screenX, screenY), EditableObjectBase) catch(e:Dynamic) null;
        if (obj == null)
        {
            obj = try cast(HitTestLineArea(x, y), EditableObjectBase) catch(e:Dynamic) null;
        }
        return obj;
    }
    
    public static function HitTestAnyObject(x : Float, y : Float, screenX : Float, screenY : Float) : EditableObjectBase
    {
        var obj : EditableObjectBase = null;
        obj = try cast(HitTestJoint(x, y), EditableObjectBase) catch(e:Dynamic) null;
        if (obj == null)
        {
            obj = try cast(HitTestPhysObjGraphics(screenX, screenY), EditableObjectBase) catch(e:Dynamic) null;
        }
        if (obj == null)
        {
            obj = try cast(HitTestLineArea(x, y), EditableObjectBase) catch(e:Dynamic) null;
        }
        return obj;
    }
    
    public static function HitTestJoint(x : Float, y : Float) : EdJoint
    {
        var j : EdJoint = editModeObj_Joints.GetJointAtPosition(x, y);
        return j;
    }
    
    public static function HitTestLineArea(x : Float, y : Float) : EdLine
    {
        editModeObj_Lines.Lines_SelectLineByArea(x, y);
        if (editModeObj_Lines.currentLineIndex != -1)
        {
            var level : Level = GetCurrentLevel();
            return level.lines[editModeObj_Lines.currentLineIndex];
        }
        return null;
    }
    
    
    public static function HitTestLinePoints(x : Float, y : Float) : EdLine
    {
        editModeObj_Lines.Lines_SelectLineByPoint(x, y);
        if (editModeObj_Lines.currentLineIndex != -1)
        {
            var level : Level = GetCurrentLevel();
            return level.lines[editModeObj_Lines.currentLineIndex];
        }
        return null;
    }
    public static function HitTestPhysObjGraphics(x : Float, y : Float, onlyPhysObjs : Bool = false) : EdObj
    {
        var level_instances : Array<Dynamic> = GetCurrentLevelInstances();
        
        var i : Int;
        i = as3hx.Compat.parseInt(level_instances.length - 1);
        while (i >= 0)
        {
            var poi : EdObj = level_instances[i];
            
            
            var po : PhysObj = Game.objectDefs.FindByName(poi.typeName);
            
            var doit : Bool = true;
            if (onlyPhysObjs)
            {
                doit = false;
                if (po.hasPhysics)
                {
                    doit = true;
                }
            }
            if (doit)
            {
                var bd : BitmapData = screenBD;
                bd.fillRect(Defs.screenRect, 0);
                
                var p : Point = GetMapPos(Std.int(poi.x), Std.int(poi.y));
                
                PhysObj.RenderAt(po, p.x, p.y, poi.rot, poi.scale * zoom, bd);
                
                var col : Int = bd.getPixel(Std.int(x), Std.int(y));
                if (col != 0)
                {
                    return poi;
                }
            }
            i--;
        }
        return null;
    }
    
    
    
    public static function GetCurrentLevelLines() : Array<Dynamic>
    {
        return Levels.list[currentLevel].lines;
    }
    public static function GetCurrentLevelJoints() : Array<Dynamic>
    {
        return Levels.list[currentLevel].joints;
    }
    public static function GetCurrentLevelInstances() : Array<Dynamic>
    {
        return Levels.list[currentLevel].instances;
    }
    public static function SetCurrentLevelInstances(instances : Array<Dynamic>) : Void
    {
        Levels.list[currentLevel].instances = instances;
    }
    public static function GetCurrentLevel() : Level
    {
        return Levels.GetLevel(currentLevel);
    }
    
    public static function DeleteObject(obj : EditableObjectBase)
    {
        if (obj.classType == "obj")
        {
            RemoveFromLevelInstances(try cast(obj, EdObj) catch(e:Dynamic) null);
        }
        if (obj.classType == "line")
        {
            DeleteLine(try cast(obj, EdLine) catch(e:Dynamic) null);
        }
        if (obj.classType == "joint")
        {
            DeleteJoint(try cast(obj, EdJoint) catch(e:Dynamic) null);
        }
    }
    
    public static function DeleteLine(obj : EdLine)
    {
        var lineList : Array<Dynamic> = GetCurrentLevelLines();
        if (Lambda.indexOf(lineList, obj) != -1)
        {
            lineList.splice(Lambda.indexOf(lineList, obj), 1);
        }
    }
    public static function DeleteJoint(obj : EdJoint)
    {
        var jointList : Array<Dynamic> = GetCurrentLevelJoints();
        if (Lambda.indexOf(jointList, obj) != -1)
        {
            jointList.splice(Lambda.indexOf(jointList, obj), 1);
        }
    }
    public static function RemoveFromLevelInstances(poi : EdObj)
    {
        var level_instances : Array<Dynamic> = GetCurrentLevelInstances();
        var list1 : Array<Dynamic> = [];
        for (p in level_instances)
        {
            if (p == poi)
            {
            }
            else
            {
                list1.push(p);
            }
        }
        level_instances = list1;
        Levels.list[currentLevel].instances = level_instances;
    }
    
    public static function Editor_RenderLineToCursor()
    {
        linesScreen.graphics.clear();
        if (editModeObj_Lines.addlineActive == false)
        {
            return;
        }
        if (editModeObj_Lines.subMode != "addpoint")
        {
            return;
        }
        var l : Level = GetCurrentLevel();
        if (editModeObj_Lines.currentLineIndex == -1)
        {
            return;
        }
        var line : EdLine = l.lines[editModeObj_Lines.currentLineIndex];
        
        if (line.primitiveType == EdLine.PRIMITIVE_LINE)
        {
            GetMousePositions();
            
            var i : Int = as3hx.Compat.parseInt(line.points.length - 1);
            var p0 : Point = GetMapPos(line.points[i].x, line.points[i].y);
            var p1 : Point = GetMapPos(mxs, mys);
            var bd : BitmapData = screenBD;
            RenderLine(p1.x, p1.y, p0.x, p0.y, 0xff00ffff);
        }
        screenBD.draw(linesScreen);
    }
    
    
    public static function GetMapPosRect(r : Rectangle) : Rectangle
    {
        var r1 : Rectangle = r.clone();
        var p : Point;
        p = GetMapPos(Std.int(r.x), Std.int(r.y));
        r1.x = p.x;
        r1.y = p.y;
        p = GetPos(Std.int(r.width), Std.int(r.height));
        r1.width = p.x;
        r1.height = p.y;
        return r1;
    }
    public static function GetMapPosPoints(a : Array<Dynamic>) : Array<Dynamic>
    {
        var b : Array<Dynamic> = [];
        for (p in a)
        {
            var p1 : Point = GetMapPos(p.x, p.y);
            b.push(p1);
        }
        return b;
    }
    public static function GetMapPos(x : Int, y : Int) : Point
    {
        return GetMapPosPoint(new Point(x, y));
    }
    public static function GetMapPosPoint(p : Point) : Point
    {
        return new Point((p.x - PhysEditor.scrollX) * zoom, (p.y - PhysEditor.scrollY) * zoom);
    }
    public static function GetPos(x : Int, y : Int) : Point
    {
        var p : Point = new Point((x) * zoom, (y) * zoom);
        return p;
    }
    
    public static var mx : Int;
    public static var my : Int;
    public static var sx : Float;
    public static var sy : Float;
    public static var mxs : Int;
    public static var mys : Int;
    
    public static function GetMousePositions()
    {
        mx = Std.int(MouseControl.x);
        my = Std.int(MouseControl.y);
        
        if (PhysEditor.gridMode_active)
        {
            mx = Math.floor(mx);
            my = Math.floor(my);
            mx = as3hx.Compat.parseInt(as3hx.Compat.parseInt(mx / PhysEditor.gridsnap) * as3hx.Compat.parseInt(PhysEditor.gridsnap));
            my = as3hx.Compat.parseInt(as3hx.Compat.parseInt(my / PhysEditor.gridsnap) * as3hx.Compat.parseInt(PhysEditor.gridsnap));
        }
        
        sx = PhysEditor.scrollX;
        sy = PhysEditor.scrollY;
        if (PhysEditor.gridMode_active)
        {
            sx = Math.floor(sx);
            sy = Math.floor(sy);
            sx = as3hx.Compat.parseInt(sx / PhysEditor.gridsnap) * as3hx.Compat.parseInt(PhysEditor.gridsnap);
            sy = as3hx.Compat.parseInt(sy / PhysEditor.gridsnap) * as3hx.Compat.parseInt(PhysEditor.gridsnap);
        }
        mxs = as3hx.Compat.parseInt((mx * (1 / PhysEditor.zoom)) + sx);
        mys = as3hx.Compat.parseInt((my * (1 / PhysEditor.zoom)) + sy);
    }
    
    
    public static function Editor_RenderLines1(_useCursor : Bool = false)
    {
        var l : Level = GetCurrentLevel();
        var i : Int = 0;
        for (line/* AS3HX WARNING could not determine type for var: line exp: EField(EIdent(l),lines) type: null */ in l.lines)
        {
            line.index = i;
            line.RenderInner();
            i++;
        }
    }
    
    /*
		static function Editor_RenderLines(_useCursor:Boolean = false)
		{
			if (editModeObj_Lines.addlineActive == false) _useCursor = false;
			if (editModeObj_Lines.subMode != "addpoint") _useCursor = false;



			var p0:Point = new Point();
			var p1:Point = new Point();
			var r:Rectangle = new Rectangle();

			var l:Level = GetCurrentLevel();
			var bd:BitmapData = screenBD;
			var lineIndex:int = 0;
			for each(var line:EdLine in l.lines)
			{
				var layer:int = 0;
				if (line.objParameters.GetParam("editor_layer") != "")
				{
					layer = line.objParameters.GetValueInt("editor_layer")-1;
				}

				if (IsLayerVisible(layer) == true)
				{

					var points:Array = line.points;
					if (lineIndex == editModeObj_Lines.currentLineIndex && _useCursor && line.primitiveType==EdLine.PRIMITIVE_LINE)
					{
						GetMousePositions();
						points = new Array();
						for each(var p0:Point in (line.points : Array<Dynamic>))
						{
							points.push(p0.clone());
						}
						points.push(new Point(mxs, mys));
					}
					var points1:Array = new Array;
					for each(var p:Point in points)
					{
						var zp:Point = GetMapPos( p.x, p.y);
						points1.push(zp);
					}
					points = points1;

					var lineMode:int = GetLineTypeMode(line.type);
					var doNormals:Boolean = false;
					if ( (lineMode & LM_LINK) != 0) doNormals = true;
					var col:uint = GetLineTypeColor(line.type);
					var thickness:int = 1;
					if (lineIndex == editModeObj_Lines.currentLineIndex)
					{

						thickness = 2;
					}
					if (points.length >= 2)
					{
						var i:int;
						for (i = 0; i < points.length - 1; i++)
						{
							p0 = points[i];
							p1 = points[i + 1];
							RenderLine(p0.x,p0.y, p1.x,p1.y,col,thickness,1,doNormals);
						}
						if ( (lineMode & LM_LINK) != 0)
						{
							p0 = points[points.length-1];
							p1 = points[0];
							RenderLine(p0.x,p0.y, p1.x,p1.y,col,thickness,1,doNormals);
						}
					}
					if ( (lineMode & LM_FILL) != 0)
					{
						FillPoly(points, col, 0.1);
					}

					if (line.primitiveType == EdLine.PRIMITIVE_LINE)
					{
						for (i = 0; i < points.length; i++)
						{
							col = 0xffff0000;
							if (lineIndex == editModeObj_Lines.currentLineIndex && editModeObj_Lines.currentPointIndex == i) col = 0xffffff00;
							var off1:int = 2;
							var off2:int = 4;
							if (lineIndex == hoverLineIndex && hoverPointIndex == i)
							{
								off1 = 3;
								off2 = 6;
							}
							r.x = points[i].x - off1;
							r.y = points[i].y - off1;
							r.width = off2;
							r.height = off2;

							RenderRectangle(r, col);
						}
					}

					if (line.primitiveType == EdLine.PRIMITIVE_RECTANGLE)
					{
						for (i = 0; i <= 2; i+=2)
						{
							col = 0xffff0000;
							if (lineIndex == editModeObj_Lines.currentLineIndex && editModeObj_Lines.currentPointIndex == i) col = 0xffffff00;
							var off1:int = 2;
							var off2:int = 4;
							if (lineIndex == hoverLineIndex && hoverPointIndex == i)
							{
								off1 = 3;
								off2 = 6;
							}
							r.x = points[i].x - off1;
							r.y = points[i].y - off1;
							r.width = off2;
							r.height = off2;

							RenderRectangle(r, col);
						}

					}
				}
				lineIndex++;
			}
		}
		*/
    
    public static function HighlightLinePoly(line : EdLine)
    {
        if (line == null)
        {
            return;
        }
        
        var points : Array<Dynamic> = GetMapPosPoints(line.points);
        
        FillPoly(points, 0xffffff, 0.5);
    }
}





