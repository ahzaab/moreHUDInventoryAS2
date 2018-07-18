import flash.display.BitmapData;
import gfx.io.GameDelegate;
import Shared.GlobalFunc;
import skyui.util.Debug;
import flash.geom.Transform;
import flash.geom.ColorTransform;
import flash.geom.Matrix;


class ahz.scripts.widgets.AHZmoreHUDInventory extends MovieClip
{
	//Widgets
	public var iconHolder: TextField
	public var itemCard: Object;

	// Public vars
	public static var ICT_BOOK: Number				= 4;
	public static var BOOKFLAG_READ: Number			= 0x08;
	public static var ICT_ARMOR: Number				= 1;
	public static var ICT_WEAPON: Number			= 2;
	static var SHOW_PANEL = 1;
	
	// Options
		
	// private variables
	private var isSkyui:Boolean = false;
	private var _platform: Number;
	private var _currentMenu: String;

	// Statics
	private static var hooksInstalled:Boolean = false;

	/* INITIALIZATION */
		
	public function AHZmoreHUDInventory()
	{
		super();	
		
		_currentMenu = _global.skse.plugins.AHZmoreHUDInventory.GetCurrentMenu();
		
		// Snieak in the main menu and enable extended data before any inventory menu can load
		if (_currentMenu == "Main Menu")
		{
			_global.skse.plugins.AHZmoreHUDInventory.AHZLog(
					"AHZmoreHUDInventory turning on extended data.", true);			
			_global.skse.ExtendData(true);
			return;
		}
		
		// if the item card has this property name then this is SKYUI
		if (_root.Menu_mc.itemCard)
		{
			iconHolder = _root.Menu_mc.itemCard.createTextField("iconHolder", _root.Menu_mc.itemCard.getNextHighestDepth(), 0, 20, _root.Menu_mc.itemCard._width, 22);
			itemCard = _root.Menu_mc.itemCard;
			isSkyui = true;
		}
		// if the item card has this property name then this is Vanilla
		else if (_root.Menu_mc.ItemCard_mc)
		{
			iconHolder = _root.Menu_mc.ItemCard_mc.createTextField("iconHolder", _root.Menu_mc.ItemCard_mc.getNextHighestDepth(), 0, 20, _root.Menu_mc.ItemCard_mc._width, 22);
			itemCard = _root.Menu_mc.ItemCard_mc;
			isSkyui = false;
		}
		else
		{
			_global.skse.plugins.AHZmoreHUDInventory.AHZLog(
					"Could not obtain a refernce to the item card.", true)
			return;
		}

		if (! hooksInstalled)
		{
			// Apply hooks to hook events
			hookFunction(_root.Menu_mc, "UpdateItemCardInfo", this, "UpdateItemCardInfo");
			
			// Only need to hook these functions for the inventory and container menus
			// because they are the only menus that a book can be read from
			if (_currentMenu == "InventoryMenu" || _currentMenu == "ContainerMenu")
			{
				hookFunction(_root.Menu_mc, "onItemSelect", this, "onItemSelect");
				hookFunction(_root.Menu_mc, "AttemptEquip", this, "AttemptEquip");
				hookFunction(_root.Menu_mc, "SetPlatform", this, "SetPlatform");
			}
						 
			_global.skse.plugins.AHZmoreHUDInventory.InstallHooks();
			hooksInstalled = true;
		}
				
		iconHolder.verticalAlign = "center";
		iconHolder.textAutoSize = "fit";
		iconHolder.multiLine = false;

		var tf: TextFormat = new TextFormat();
		tf.align = "center";
		tf.color = 0x999999;
		tf.indent = 20;
		tf.font = "$EverywhereMediumFont";
		iconHolder.setNewTextFormat(tf);

		iconHolder.text = "No IconSource";					
	}

	function appendImageToEnd(textField:TextField, imageName:String, width:Number, height:Number)
	{
		if (textField.text.indexOf("[" + imageName + "]") < 0)
		{
			var b1 = BitmapData.loadBitmap(imageName); 
			if (b1)
			{
				var a = new Array; 
				a[0] = { subString:"[" + imageName + "]", image:b1, width:width, height:height, id:"id" + imageName };  //baseLineY:0, 
				textField.setImageSubstitutions(a);
				textField.text = textField.text + " " + "[" + imageName + "]";
			}
		}
	}

	// SkyUI Made this private, so I had to recreate it
	private function SKYUI_shouldProcessItemsListInput(abCheckIfOverRect: Boolean): Boolean
	{
		var process = _root.Menu_mc.bFadedIn == true && _root.Menu_mc.inventoryLists.currentState == SHOW_PANEL && _root.Menu_mc.inventoryLists.itemList.itemCount > 0 && !_root.Menu_mc.inventoryLists.itemList.disableSelection && !_root.Menu_mc.inventoryLists.itemList.disableInput;

		if (process && _platform == 0 && abCheckIfOverRect) {
			var e = Mouse.getTopMostEntity();
			var found = false;
			
			while (!found && e != undefined) {
				if (e == _root.Menu_mc.inventoryLists.itemList)
					found = true;
					
				e = e._parent;
			}
			
			process = process && found;
		}
		return process;
	}

	// SkyUI Made this private, so I had to recreate it
	private function SKYUI_confirmSelectedEntry(): Boolean
	{
		// only confirm when using mouse
		if (_platform != 0)
			return true;
		
		for (var e = Mouse.getTopMostEntity(); e != undefined; e = e._parent)
			if (e.itemIndex == _root.Menu_mc.inventoryLists.itemList.selectedIndex)
				return true;
				
		return false;
	}
	
	// Had to hook because the _platform variable is provate
	public function SetPlatform(a_platform: Number, a_bPS3Switch: Boolean): Void
	{
		_platform = a_platform;
	}

	// Only used for "InventoryMenu" and "ContainerMenu" for updating hte
	// book read status if the book was read when in these menus
	private function CheckBook():Void
	{
		if (_currentMenu != "InventoryMenu" && _currentMenu != "ContainerMenu")
			return;	
		
		_global.skse.plugins.AHZmoreHUDInventory.AHZLog("CheckBook", false);		
		var entryList:Object;
		var selectedIndex:Number;
		var type:Number;
		
		if (isSkyui)
		{
			entryList = _root.Menu_mc.inventoryLists.itemList._entryList;
			selectedIndex = _root.Menu_mc.inventoryLists.itemList._selectedIndex;
		}
		else //Vanilla
		{
			entryList = _root.Menu_mc.InventoryLists_mc._ItemsList.EntriesA;
			selectedIndex = _root.Menu_mc.InventoryLists_mc._ItemsList.iSelectedIndex;		
		}	
		
		type = itemCard.itemInfo.type;
		
		if (type != ICT_BOOK || _global.skse == null)
			return;
			
		entryList[selectedIndex].flags |= BOOKFLAG_READ;
		UpdateItemCardInfo(itemCard.itemInfo);	
	}

	// Occurs when an item is selected with the activate/gamepad key
	private function onItemSelect(event: Object): Void
	{
		if (_currentMenu != "InventoryMenu" && _currentMenu != "ContainerMenu")
			return;
			
		if (!event.entry.enabled)
		{
			return;
		}
		_global.skse.plugins.AHZmoreHUDInventory.AHZLog("onItemSelect", false);	
		CheckBook();
	}

	// Occurs when an item is selected with the mouse
	private function AttemptEquip(a_slot: Number, a_bCheckOverList: Boolean): Void
	{
		if (_currentMenu != "InventoryMenu" && _currentMenu != "ContainerMenu")
			return;
		
		_global.skse.plugins.AHZmoreHUDInventory.AHZLog("AttemptEquip", false);			
		var processInput: Boolean = a_bCheckOverList == undefined ? true : a_bCheckOverList;
		
		if (isSkyui)
		{
			if (!SKYUI_shouldProcessItemsListInput(a_bCheckOverList) || SKYUI_confirmSelectedEntry()) {
				return;
			}
		}
		else
		{
			if (!_root.Menu_mc.ShouldProcessItemsListInput(processInput)) {
				return;
			}
		}
		CheckBook();
	}

	function UpdateItemCardInfo(aUpdateObj: Object): Void
	{
		_global.skse.plugins.AHZmoreHUDInventory.AHZLog("UpdateItemCardInfo", false);
		var entryList:Object;
		var selectedIndex:Number;
		var type:Number;
		if (isSkyui)
		{
			entryList = _root.Menu_mc.inventoryLists.itemList._entryList;
			selectedIndex = _root.Menu_mc.inventoryLists.itemList._selectedIndex;
		}
		else //Vanilla
		{
			entryList = _root.Menu_mc.InventoryLists_mc._ItemsList.EntriesA;
			selectedIndex = _root.Menu_mc.InventoryLists_mc._ItemsList.iSelectedIndex;		
		}
		
		type = itemCard.itemInfo.type;

		_global.skse.plugins.AHZmoreHUDInventory.AHZLog("Type: " + type.toString(), false);

		iconHolder.text = "";
		
		if (type != ICT_BOOK && type != ICT_ARMOR && type != ICT_WEAPON)
		{
			return;
		}

		if (entryList[selectedIndex].AHZItemCardObj)
		{
			if (entryList[selectedIndex].AHZItemCardObj.enchantmentKnown)
			{
				appendImageToEnd(iconHolder, "ahzknown.png", 20,20);
			}
			else if ((entryList[selectedIndex].flags & BOOKFLAG_READ) == BOOKFLAG_READ)
			{
				if (_global.skse.plugins.AHZmoreHUDInventory.ShowBookRead())
				{
					appendImageToEnd(iconHolder, "eyeImage.png", 20,20);
				}
			}
			else if (entryList[selectedIndex].AHZItemCardObj.bookSkill &&
					 String(entryList[selectedIndex].AHZItemCardObj.bookSkill).length )
			{
				iconHolder.text = String(entryList[selectedIndex].AHZItemCardObj.bookSkill.toUpperCase());
			}
		}
	}

	function appendHtmlToEnd(htmlText:String, appendedHtml:String):String
	{
		var stringIndex:Number;
		stringIndex = htmlText.lastIndexOf("</P></TEXTFORMAT>");
		var firstText:String = htmlText.substr(0,stringIndex);
		var secondText:String = htmlText.substr(stringIndex,htmlText.length - stringIndex);						
        return firstText + appendedHtml + secondText;
	}

	function interpolate(pBegin:Number, pEnd:Number, pMax:Number, pStep:Number):Number {
		return pBegin + Math.floor((pEnd - pBegin) * pStep / pMax);
	}

	// @override WidgetBase
	public function onLoad():Void
	{
		super.onLoad();
	}
	
	public static function hookFunction(a_scope:Object, a_memberFn:String, a_hookScope:Object, a_hookFn:String):Boolean {
		var memberFn:Function = a_scope[a_memberFn];
		if (memberFn == null || a_scope[a_memberFn] == null) {
			return false;
		}

		a_scope[a_memberFn] = function () {
			memberFn.apply(a_scope,arguments);
			a_hookScope[a_hookFn].apply(a_hookScope,arguments);
		};
		return true;
	}
}