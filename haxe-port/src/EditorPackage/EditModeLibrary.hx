package editorPackage;

import flash.display.BitmapData;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.geom.Rectangle;

/**
	 * ...
	 * @author LongAnimals
	 */
class EditModeLibrary extends EditModeBase
{
    
    public function new()
    {
        super();
    }
    
    override public function EnterMode() : Void
    {
        PhysEditor.CursorText_Show();
        PhysEditor.CursorText_Set("");
    }
    override public function InitOnce() : Void
    {
        InitLibraryFilter();
    }
    
    
    override public function OnMouseDown(e : MouseEvent) : Void
    {
        PhysEditor.SetEditMode(PhysEditor.editMode_Adjust);
        Library_PickPiece();
    }
    override public function OnMouseUp(e : MouseEvent) : Void
    {
    }
    override public function OnMouseMove(e : MouseEvent) : Void
    {
        Library_GetHoverPieceName();
    }
    override public function OnMouseWheel(delta : Int) : Void
    {
        if (delta > 0)
        {
            library_page++;
            if (library_page >= GetNumLibraryPages())
            {
                library_page = 0;
            }
        }
        if (delta < 0)
        {
            library_page--;
            if (library_page < 0)
            {
                library_page = GetNumLibraryPages() - 1;
            }
        }
    }
    override public function Update() : Void
    {
        if (KeyReader.Pressed(KeyReader.KEY_DOWN))
        {
            library_page++;
            if (library_page >= GetNumLibraryPages())
            {
                library_page = 0;
            }
        }
        if (KeyReader.Pressed(KeyReader.KEY_UP))
        {
            library_page--;
            if (library_page < 0)
            {
                library_page = GetNumLibraryPages() - 1;
            }
        }
        
        if (KeyReader.Pressed(KeyReader.KEY_1))
        {
            NextLibraryFilter();
        }
        if (KeyReader.Pressed(KeyReader.KEY_2))
        {
            NextLibrarySize();
        }
    }
    override public function Render(bd : BitmapData) : Void
    {
        super.Render(bd);
        
        var s : String;
        bd.fillRect(Defs.screenRect, 0xff6040c0);
        var x : Int = 0;
        var y : Int = 0;
        x = Std.int(pickerRectangle.x);
        while (x <= pickerRectangle.right)
        {
            PhysEditor.RenderLine(x, pickerRectangle.y, x, pickerRectangle.bottom, 0xff40c040);
            x = Std.int(x + boxSizeW);
        }
        x = Std.int(pickerRectangle.y);
        while (x <= pickerRectangle.bottom)
        {
            PhysEditor.RenderLine(pickerRectangle.x, x, pickerRectangle.right, x, 0xff40c040);
            x = Std.int(x + boxSizeH);
        }
        
        
        var numPerPage : Int = as3hx.Compat.parseInt(boxNumW * boxNumH);
        
        var min : Int = as3hx.Compat.parseInt(library_page * numPerPage);
        var max : Int = as3hx.Compat.parseInt(min + (numPerPage - 1));
        
        
        x = Std.int(pickerRectangle.left);
        y = Std.int(pickerRectangle.top);
        var num : Int = Game.objectDefs.GetNum();
        var index : Int = 0;
        var xp : Int = 0;
        var yp : Int = 0;
        
        for (po/* AS3HX WARNING could not determine type for var: po exp: EIdent(libraryPieces) type: null */ in libraryPieces)
        {
            if (index >= min && index <= max)
            {
                var maxDestRect : Rectangle = new Rectangle(x + 8, y + 8, boxSizeW - 16, boxSizeH - 16);
                PhysObj.RenderAt(po, x + (boxSizeW / 2), y + (boxSizeH / 2), 0, 1, bd, PhysEditor.linesScreen.graphics, true, null, maxDestRect);
                x = Std.int(x + boxSizeW);
                xp++;
                if (xp >= boxNumW)
                {
                    x = 0;
                    y = Std.int(y + boxSizeH);
                    xp = 0;
                }
            }
            index++;
        }
    }
    override public function RenderHud(x : Int, y : Int) : Int
    {
        var s : String;
        s = "1: Filter [" + libraryFilter + "] " + as3hx.Compat.parseInt(libraryFilterIndex + 1) + "/" + libraryFilters.length;
        y += PhysEditor.AddInfoText("a", x, y, s);
        s = "2: Scale " + as3hx.Compat.parseInt(librarySizeIndex + 1) + "/" + numLibrarySizes;
        y += PhysEditor.AddInfoText("a", x, y, s);
        
        var savedy : Int;
        
        var numPerPage : Int = as3hx.Compat.parseInt(boxNumW * boxNumH);
        
        var min : Int = as3hx.Compat.parseInt(library_page * numPerPage);
        var max : Int = as3hx.Compat.parseInt(min + (numPerPage - 1));
        
        
        x = Std.int(pickerRectangle.left);
        y = Std.int(pickerRectangle.top);
        var num : Int = Game.objectDefs.GetNum();
        var index : Int = 0;
        var xp : Int = 0;
        var yp : Int = 0;
        
        for (po/* AS3HX WARNING could not determine type for var: po exp: EIdent(libraryPieces) type: null */ in libraryPieces)
        {
            if (index >= min && index <= max)
            {
                s = po.name;
                PhysEditor.AddInfoText("a", x + 8, Std.int(y + boxSizeH - 16), s);
                
                x = Std.int(x + boxSizeW);
                xp++;
                if (xp >= boxNumW)
                {
                    x = 0;
                    y = Std.int(y + boxSizeH);
                    xp = 0;
                }
            }
            index++;
        }
        
        
        return savedy;
    }
    
    
    public var pickerRectangle : Rectangle = new Rectangle(0, 0, Defs.displayarea_w, Defs.displayarea_h);
    public var boxNumW : Float = 5;
    public var boxNumH : Float = 4;
    public var boxSizeW : Float = Defs.displayarea_w / 5;
    public var boxSizeH : Float = Defs.displayarea_h / 4;
    
    public var library_page : Int = 0;
    public function Library_PickPiece()
    {
        var mx : Int = Std.int(MouseControl.x);
        var my : Int = Std.int(MouseControl.y);
        mx = Std.int(mx - pickerRectangle.left);
        my = Std.int(my - pickerRectangle.top);
        var x : Int = as3hx.Compat.parseInt(mx / boxSizeW);
        var y : Int = as3hx.Compat.parseInt(my / boxSizeH);
        var pos : Int = as3hx.Compat.parseInt(x + (y * boxNumW));
        
        
        var numPerPage : Int = as3hx.Compat.parseInt(boxNumW * boxNumH);
        
        pos += as3hx.Compat.parseInt(library_page * numPerPage);
        
        var num : Int = as3hx.Compat.parseInt(libraryPieces.length - 1);
        if (pos > num)
        {
            pos = num;
        }
        
        
        var po : PhysObj = libraryPieces[pos];
        
        
        
        
        
        PhysEditor.editModeObj_Adjust.PickSinglePlacementObject(new EdPlacementObj(po.name));
        PhysEditor.editModeObj_Adjust.SetSubMode("place");
    }
    
    
    public var library_hoverPieceName : String = "";
    public function Library_GetHoverPieceName()
    {
        library_hoverPieceName = "";
        var mx : Int = Std.int(MouseControl.x);
        var my : Int = Std.int(MouseControl.y);
        mx = Std.int(mx - pickerRectangle.left);
        my = Std.int(my - pickerRectangle.top);
        var x : Int = as3hx.Compat.parseInt(mx / boxSizeW);
        var y : Int = as3hx.Compat.parseInt(my / boxSizeH);
        var pos : Int = as3hx.Compat.parseInt(x + (y * boxNumW));
        
        
        var numPerPage : Int = as3hx.Compat.parseInt(boxNumW * boxNumH);
        
        pos += as3hx.Compat.parseInt(library_page * numPerPage);
        
        var num : Int = as3hx.Compat.parseInt(libraryPieces.length - 1);
        if (pos > num)
        {
            pos = num;
        }
        
        
        var po : PhysObj = libraryPieces[pos];
        
        library_hoverPieceName = po.name;
    }
    
    public var libraryFilter : String = "";
    public var libraryFilterIndex : Int = 0;
    public var libraryFilters : Array<Dynamic>;
    public var librarySizeIndex : Int;
    public var numLibrarySizes : Int;
    public var librarySizes : Array<Dynamic>;
    
    public function DoesLibraryFilterListContain(filter : String) : Bool
    {
        for (s in libraryFilters)
        {
            if (s == filter)
            {
                return true;
            }
        }
        return false;
    }
    public function InitLibraryFilter()
    {
        pickerRectangle = new Rectangle(0, 60, Defs.displayarea_w, Defs.displayarea_h - 80);
        
        libraryFilterIndex = -1;
        libraryFilter = "";
        libraryFilters = [];
        libraryFilters.push("");
        librarySizeIndex = -1;
        
        librarySizes = [];
        librarySizes.push(new Point(4, 3));
        librarySizes.push(new Point(5, 4));
        librarySizes.push(new Point(7, 5));
        librarySizes.push(new Point(9, 7));
        librarySizes.push(new Point(12, 10));
        
        numLibrarySizes = librarySizes.length;
        
        
        for (po/* AS3HX WARNING could not determine type for var: po exp: EField(EField(EIdent(Game),objectDefs),list) type: null */ in Game.objectDefs.list)
        {
            if (po.displayInLibrary)
            {
                if (DoesLibraryFilterListContain(po.libraryClass) == false)
                {
                    libraryFilters.push(po.libraryClass);
                }
            }
        }
        
        for (ss in libraryFilters)
        {
            Utils.print("filter: " + ss);
        }
        
        NextLibraryFilter();
        NextLibrarySize();
    }
    
    public function TestLibraryFilter(filter : String) : Bool
    {
        if (libraryFilter == "")
        {
            return true;
        }
        if (libraryFilter == filter)
        {
            return true;
        }
        return false;
    }
    
    public function NextLibrarySize()
    {
        librarySizeIndex++;
        if (librarySizeIndex >= numLibrarySizes)
        {
            librarySizeIndex = 0;
        }
        var p : Point = librarySizes[librarySizeIndex];
        
        boxNumW = p.x;
        boxNumH = p.y;
        boxSizeW = pickerRectangle.width / boxNumW;
        boxSizeH = pickerRectangle.height / boxNumH;
        
        if (library_page > GetNumLibraryPages())
        {
            library_page = as3hx.Compat.parseInt(GetNumLibraryPages() - 1);
        }
        
        
        GetLibraryPieces();
    }
    public function NextLibraryFilter()
    {
        libraryFilterIndex++;
        if (libraryFilterIndex >= libraryFilters.length)
        {
            libraryFilterIndex = 0;
        }
        libraryFilter = libraryFilters[libraryFilterIndex];
        library_page = 0;
        GetLibraryPieces();
    }
    
    
    public var libraryPieces : Array<Dynamic>;
    public function GetLibraryPieces()
    {
        libraryPieces = [];
        for (po/* AS3HX WARNING could not determine type for var: po exp: EField(EField(EIdent(Game),objectDefs),list) type: null */ in Game.objectDefs.list)
        {
            if (po.displayInLibrary && TestLibraryFilter(po.libraryClass))
            {
                libraryPieces.push(po);
            }
        }
    }
    
    public function CountLibraryPieces() : Int
    {
        var count : Int = 0;
        for (po/* AS3HX WARNING could not determine type for var: po exp: EField(EField(EIdent(Game),objectDefs),list) type: null */ in Game.objectDefs.list)
        {
            if (po.displayInLibrary && TestLibraryFilter(po.libraryClass))
            {
                count++;
            }
        }
        return count;
    }
    
    public function GetNumLibraryPages() : Int
    {
        var numPerPage : Int = as3hx.Compat.parseInt(boxNumW * boxNumH);
        
        var num : Int = CountLibraryPieces();
        
        var p : Int = as3hx.Compat.parseInt(num / numPerPage);
        var pr : Int = as3hx.Compat.parseInt(num % numPerPage);
        if (pr != 0)
        {
            p++;
        }
        return p;
    }
}


