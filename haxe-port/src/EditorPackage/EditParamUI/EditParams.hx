package editorPackage.editParamUI;

import haxe.Constraints.Function;
import editorPackage.EdLine;
import editorPackage.EdObj;
import editorPackage.ObjParameter;
import editorPackage.ObjParameters;
import editorPackage.PhysEditor;
import fl.controls.ComboBox;
import fl.controls.List;
import fl.controls.listClasses.CellRenderer;
import fl.controls.listClasses.ListData;
import fl.events.ListEvent;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFieldType;
import flash.text.TextFormat;

/**
	 * ...
	 * @author LongAnimals
	 */
class EditParams
{
    
    public function new()
    {
    }
    
    
    private static var objParameters : ObjParameters;
    private static var currentParamIndex : Int = 0;
    
    
    private static var listBox : List = null;
    private static var listBoxContainer : MovieClip = null;
    
    public static function ClearParameterListBox()
    {
        if (listBoxContainer != null)
        {
            listBoxContainer.parent.removeChild(listBoxContainer);
            listBoxContainer = null;
            PhysEditor.isEntering = false;
        }
    }
    
    public static function PreventPropogationHandler(e : MouseEvent)
    {
        e.stopImmediatePropagation();
    }
    
    public static function AddParameterListBoxOrClear(_objParameters : ObjParameters)
    {
        if (_objParameters != null)
        {
            cast((_objParameters), AddParameterListBox);
        }
        else
        {
            ClearParameterListBox();
        }
    }
    
    public static function OpenCurrentParameterEdit()
    {
        CurrentAdjustObject_EnterParameter();
    }
    
    
    public static function DoChangedCallback(op : ObjParameter)
    {
        if (parameterChangedCallback != null)
        {
            parameterChangedCallback(op);
        }
    }
    
    private static var parameterChangedCallback : Function = null;
    
    public static function AddParameterListBox(_objParameters : ObjParameters, callback : Function = null)
    {
        parameterChangedCallback = callback;
        objParameters = _objParameters;
        
        currentParamIndex = 0;
        
        ClearParameterListBox();
        
        listBoxContainer = new EditParamListBox();
        listBoxContainer.closed_function = ListBoxClosed;
        
        PhysEditor.editorMC.addChild(listBoxContainer);
        
        listBoxContainer.x = Defs.editor_x;
        
        listBoxContainer.SetParameters(objParameters);
    }
    
    public static function ListBoxClosed()
    {
        Utils.print("Closed2");
        ClearParameterListBox();
    }
    
    public static function UpdateListBoxItem(index : Int)
    {
        listBox.removeAll();
        
        for (op/* AS3HX WARNING could not determine type for var: op exp: EField(EIdent(objParameters),list) type: null */ in objParameters.list)
        {
            var o : Dynamic = {};
            var s : String = op.name + " : " + op.value;
            o.label = s;
            o.data = s;
            listBox.addItem(o);
        }
    }
    
    
    public static function AddParameterListBox_changeHandler(event : ListEvent) : Void
    {
        event.stopImmediatePropagation();
        var list : List = cast((event.target), List);
        if (list == null)
        {
            return;
        }
        var cr : CellRenderer = try cast(list.itemToCellRenderer(event.item), CellRenderer) catch(e:Dynamic) null;
        var listData : ListData = cr.listData;
        
        currentParamIndex = listData.row;
        CurrentAdjustObject_EnterParameter();
    }
    
    public static function PickLineReturnFunction(_EdLine : EdLine)
    {
        var id : String = "";
        if (_EdLine != null)
        {
            id = PhysEditor.GetOrCreateUniqueLineID(_EdLine);
            cast((currentParamIndex), UpdateListBoxItem);
        }
        Utils.print("here " + id);
        cast((id), CurrentAdjustObject_UpdateCurrentParameter);
        cast((currentParamIndex), UpdateListBoxItem);
        
        PhysEditor.SetEditMode(PhysEditor.oldEditMode, false);
        PhysEditor.CursorText_Set("");
    }
    
    public static function PickObjectReturnFunction(poi : EdObj)
    {
        var id : String = "";
        if (poi != null)
        {
            id = PhysEditor.GetOrCreateUniqueObjectID(poi);
            cast((currentParamIndex), UpdateListBoxItem);
        }
        Utils.print("here1 " + id);
        cast((id), CurrentAdjustObject_UpdateCurrentParameter);
        cast((currentParamIndex), UpdateListBoxItem);
        
        PhysEditor.SetEditMode(PhysEditor.oldEditMode, false);
        PhysEditor.CursorText_Set("");
    }
    
    public static function CurrentAdjustObject_EnterParameter()
    {
        var param : ObjParameter = objParameters.GetByIndex(currentParamIndex);
        var paramName : String = param.name;
        var ob : ObjParam = ObjectParameters.GetObjectParamByName(paramName);
        if (ob == null)
        {
            return;
        }
        if (ob.type == "list")
        {
            AddComboBoxEntry(cast((currentParamIndex), GetParamXpos), cast((currentParamIndex), GetParamYpos), ob.name, CurrentAdjustObject_GetSelectedParameterValue(), ob.valueList, CurrentAdjustObject_EnterParameter_Done);
        }
        else if (ob.type == "linelink" && KeyReader.Down(KeyReader.KEY_SHIFT))
        {
            PhysEditor.oldEditMode = PhysEditor.editMode;
            PhysEditor.editModeObj_PickLineForLink.returnFunction = PickLineReturnFunction;
            PhysEditor.SetEditMode(PhysEditor.editMode_PickLineForLink, false);
            PhysEditor.CursorText_Set("Pick Line");
        }
        else if (ob.type == "objlink" && KeyReader.Down(KeyReader.KEY_SHIFT))
        {
            PhysEditor.oldEditMode = PhysEditor.editMode;
            PhysEditor.editModeObj_PickPieceForLink.returnFunction = PickObjectReturnFunction;
            PhysEditor.SetEditMode(PhysEditor.editMode_PickPieceForLink, false);
            PhysEditor.CursorText_Set("Pick Object");
        }
        else
        {
            AddTextEntry(cast((PhysEditor.editModeObj_Adjust.currentAdjustObjectParam), GetParamXpos), cast((PhysEditor.editModeObj_Adjust.currentAdjustObjectParam), GetParamYpos), ob.name, CurrentAdjustObject_GetSelectedParameterValue(), CurrentAdjustObject_EnterParameter_Done);
        }
    }
    
    public static function CurrentAdjustObject_EnterParameter_Done(text : String)
    {
        cast((text), CurrentAdjustObject_UpdateCurrentParameter);
        cast((currentParamIndex), UpdateListBoxItem);
    }
    
    public static function ParameterListBox_SetSelectedIndex()
    {
        if (listBoxContainer != null)
        {
            listBox.selectedIndex = currentParamIndex;
        }
    }
    private static function CurrentAdjustObject_UpdateCurrentParameter(newValue : String) : Void
    {
        var param : ObjParameter = objParameters.GetByIndex(currentParamIndex);
        param.value = newValue;
    }
    private static function CurrentAdjustObject_GetSelectedParameterName() : String
    {
        var param : ObjParameter = objParameters.GetByIndex(currentParamIndex);
        return param.name;
    }
    private static function CurrentAdjustObject_GetSelectedParameterValue() : String
    {
        var param : ObjParameter = objParameters.GetByIndex(currentParamIndex);
        return param.value;
    }
    private static function CurrentAdjustObject_SelectNextParameter()
    {
        currentParamIndex++;
        if (currentParamIndex >= objParameters.list.length)
        {
            currentParamIndex = 0;
        }
        ParameterListBox_SetSelectedIndex();
    }
    
    public static function GetParamXpos(index : Int) : Int
    {
        return 230;
    }
    public static function GetParamYpos(index : Int) : Int
    {
        return as3hx.Compat.parseInt(Defs.displayarea_h - 100);
    }
    
    private static var instanceParamsStartY : Int;
    private static var instanceParamsStartX : Int;
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
        PhysEditor.editorMC.addChild(entryMC);
        entryMC.addEventListener(MouseEvent.CLICK, PreventPropogationHandler);
        entryMC.addEventListener(MouseEvent.MOUSE_DOWN, PreventPropogationHandler);
        entryMC.addEventListener(MouseEvent.MOUSE_UP, PreventPropogationHandler);
    }
    
    private static var entryMC : MovieClip = null;
    private static var comboBox : ComboBox;
    public static function AddComboBoxEntry(xpos : Int, ypos : Int, title : String, text : String, inputList : Array<Dynamic>, _cb : Function)
    {
        AddEntryMC();
        
        
        AddTextEntry_Callback = _cb;
        comboBox = new fl.controls.ComboBox();
        comboBox.x = xpos;
        comboBox.y = ypos;
        comboBox.alpha = 1;
        comboBox.width = 300;
        
        entryMC.addChild(comboBox);
        
        var selectedIndex : Int = 0;
        var count : Int = 0;
        for (s in inputList)
        {
            var o : Dynamic = {};
            o.label = s;
            o.data = s;
            if (s == text)
            {
                comboBox.selectedItem = o;
                selectedIndex = count;
            }
            comboBox.addItem(o);
            count++;
        }
        
        comboBox.selectedIndex = selectedIndex;
        
        comboBox.prompt = text;
        comboBox.addEventListener(Event.CHANGE, AddComboBoxEntry_changeHandler, false, 0, true);
        
        Game.main.stage.focus = comboBox;
    }
    private static function ComboBox_Close()
    {
        Game.main.stage.focus = null;
        PhysEditor.isEntering = false;
        ComboBox_RemoveHandlers();
        comboBox.close();
        RemoveEntryMC();
    }
    private static function ComboBox_RemoveHandlers()
    {
        comboBox.removeEventListener(Event.CHANGE, AddComboBoxEntry_changeHandler);
    }
    
    private static function ComboBox_keyDownHandler(e : KeyboardEvent)
    {
        if (PhysEditor.isEntering == false)
        {
            return;
        }
        if (e.charCode == KeyReader.KEY_ESCAPE)
        {
            Utils.print("cancelled");
            ComboBox_Close();
        }
    }
    
    private static function AddComboBoxEntry_changeHandler(event : Event) : Void
    {
        var selection : String = cast((event.target), ComboBox).selectedItem.data;
        
        ComboBox_Close();
        
        if (AddTextEntry_Callback != null)
        {
            cast((selection), AddTextEntry_Callback);
        }
    }
    
    private static var pickedPieceForLink : EdObj = null;
    private static var tf : TextField;
    private static var AddTextEntry_Callback : Function;
    private static function AddTextEntry(xpos : Int, ypos : Int, title : String, text : String, _cb : Function)
    {
        AddEntryMC();
        
        AddTextEntry_Callback = _cb;
        var f : TextFormat;
        
        f = new TextFormat();
        f.size = 20;
        f.color = 0x0;
        
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
        
        PhysEditor.isEntering = true;
    }
    
    /*
		listBoxContainer.addEventListener(KeyboardEvent.KEY_DOWN, ListBoxKeyHandler); 
		static function ListBoxKeyHandler(e:KeyboardEvent)
		{
			if (e.keyCode == KeyReader.KEY_ESCAPE)
			{
				PhysEditor.SetEditMode(PhysEditor.oldEditMode,false);
				PhysEditor.CursorText_Set("");
				
			}
		}
		*/
    
    private static function keyDownHandler(e : KeyboardEvent)
    {
        if (PhysEditor.isEntering == false)
        {
            return;
        }
        var tf : TextField = try cast(e.currentTarget, TextField) catch(e:Dynamic) null;
        if (e.charCode == KeyReader.KEY_ENTER)
        {
            KeyReader.ClearKey(KeyReader.KEY_ENTER);
            
            if (AddTextEntry_Callback != null)
            {
                cast((tf.text), AddTextEntry_Callback);
            }
            PhysEditor.isEntering = false;
            
            Game.main.stage.focus = null;
            tf.parent.removeChild(tf);
            tf = null;
            RemoveEntryMC();
        }
        if (e.charCode == KeyReader.KEY_ESCAPE)
        {
            Utils.print("cancelled");
            PhysEditor.isEntering = false;
            Game.main.stage.focus = null;
            tf.parent.removeChild(tf);
            tf = null;
            RemoveEntryMC();
        }
    }
}

