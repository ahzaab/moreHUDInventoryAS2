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
    public var iconHolder: TextField;
    public var itemCard: MovieClip;
	public var rootMenuInstance:MovieClip;
	public var cardBackground:MovieClip;
	public var additionDescriptionHolder:MovieClip;
	
    // Public vars

    // Options
        
    // private variables
    private var isSkyui:Boolean = false;
    private var _platform: Number;
    private var _currentMenu: String;
    private var _equipHand: Number;
    private var iSelectedCategory: Number;
    private var originalWidth:Number;
    private var originalX:Number;
    private var newWidth:Number;
    private var newX:Number;
    private var prevHeight:Number;
    private var itemCardWidth:Number;
    private var _lastFrame:Number = -1;
    private var _itemCardOverride:Boolean = false;
    private var _enableItemCardResize:Boolean = false;
	private var _craftingMenuCardShifted:Boolean = false;

    // Statics
    private static var hooksInstalled:Boolean = false;
    private static var AHZ_XMargin:Number 			= 15;
    private static var AHZ_YMargin:Number 			= 0;
	private static var AHZ_YMargin_WithItems:Number = 35;
	private static var AHZ_YMargin_Crafting:Number = 20;
    private static var AHZ_FontScale:Number 		= 0.90;
	private static var AHZ_CraftingMenuYShift:Number = -25;
	private static var AHZ_NormalALPHA:Number = 60;

    // Types from ItemCard
    private static var ICT_ARMOR: Number            = 1;
    private static var ICT_WEAPON: Number           = 2;
    private static var ICT_BOOK: Number             = 4;
    private static var ICT_POTION: Number           = 6;        // Used for Spell Tomes (shrug)
    
    private static var BOOKFLAG_READ: Number        = 0x08; 
    private static var SHOW_PANEL                   = 1;

	// For all non-magic menus
    private static var AHZ_ICF_WEAPONS_ENCH:Number 	= 10;
    private static var AHZ_ICF_ARMOR_ENCH:Number 	= 30;
    private static var AHZ_ICF_POTION:Number 		= 40;
    private static var AHZ_ICF_POTION_SURVIVAL:Number = 60;
	private static var AHZ_ICF_POTION_SURVIVAL2:Number = 61;
    private static var AHZ_ICF_INGR:Number 			= 50;
    private static var AHZ_ICF_BOOKS:Number 		= 80;
    private static var AHZ_ICF_MAGIC:Number 		= 90;
	
	// For magic menu
	private static var AHZ_ICF_POWERS:Number 		= 95;
	private static var AHZ_ICF_ACTIVEEFFECTS:Number = 171;
	private static var AHZ_ICF_MM_MAGIC:Number = 100;
	
	// Anything above this frame does not get icons (For Now)
	private static var AHZ_ICF_EMPTY:Number = 130;

    /* INITIALIZATION */
        
	function getUnnamedInstances(target:MovieClip, getOnlyMovieClips:Boolean) :Array
	{
		var arr:Array = new Array();
		for(var i in target)
		{
			
			var proName = i.toString();
			if (proName.indexOf("instance") == 0){
				var unnamedIndex: String = proName.substring("instance".length);	
				if (int(unnamedIndex))
				{
					if (getOnlyMovieClips){
						if (target[i] instanceof MovieClip)
						{
							arr.push(target[i]);
						}
					}
					else{
						arr.push(target[i]);	
					}
				}
			}
		}	
		return arr;
	}

	function GetBackgroundMovie():MovieClip
	{
		//_global.skse.plugins.AHZmoreHUDInventory.AHZLog("GetBackgroundMovie", false);	
		if (itemCard["background"])
		{
			//_global.skse.plugins.AHZmoreHUDInventory.AHZLog(MovieClip(itemCard["background"]).toString(), false);	
			return MovieClip(itemCard["background"]);
		}
		else
		{
			// Vanilla does not name the background
			var arry:Array = getUnnamedInstances(itemCard, true);
			if (arry && arry.length > 0)
			{
				var i:Number;
				for (i = 0; i < arry.length; i++)
				{
					var children:Array = getUnnamedInstances(arry[i], false);
					
					// Skip movie clips that have unnamed children.  The background will not have any
					if (children && children.length > 0)
					{
						// Skip
					}
					else
					{
						//_global.skse.plugins.AHZmoreHUDInventory.AHZLog(arry[i].toString(), false);
						return MovieClip(arry[i]);
					}
				}				
			}
		}
		//_global.skse.plugins.AHZmoreHUDInventory.AHZLog("undefined", false);
		return undefined;
	}		
		
	function GetItemsBelowDescription(targetMovie:MovieClip, targetTextField: TextField):Array
	{
		var arr:Array = new Array();
		for(var i in targetMovie)
		{
			if (targetMovie[i] instanceof TextField)
			{
				if (TextField(targetMovie[i])._y > targetTextField._y)
				{
					arr.push(TextField(targetMovie[i]));
				}
			}
			else if (targetMovie[i] instanceof MovieClip)
			{
				if (MovieClip(targetMovie[i])._y > targetTextField._y)
				{
					arr.push(MovieClip(targetMovie[i]));
				}
			}
		}	
		return arr;
	}				
		
    public function AHZmoreHUDInventory()
    {
        super();    
        this._alpha = 0;    
        _currentMenu = _global.skse.plugins.AHZmoreHUDInventory.GetCurrentMenu();
        
        // Sneak in the main menu and enable extended data before any inventory menu can load
        if (_currentMenu == "Main Menu")
        {
            _global.skse.plugins.AHZmoreHUDInventory.AHZLog(
                    "AHZmoreHUDInventory turning on extended data.", true);         
            _global.skse.ExtendData(true);
            return;
        }
		
		rootMenuInstance = _root.Menu_mc;
		
		if (_currentMenu == "Crafting Menu")
		{
			rootMenuInstance = _root["Menu"];
		}
		
		/*for (var i in rootMenuInstance)
		 {
			_global.skse.plugins.AHZmoreHUDInventory.AHZLog(i + " = " + rootMenuInstance[i], false) ;
		 }*/
			
		/*for (var i in _root)
		 {
			_global.skse.plugins.AHZmoreHUDInventory.AHZLog(i + " = " + _root[i], false) ;
		 }*/
        /*_global.skse.plugins.AHZmoreHUDInventory.AHZLog("----------------", false) ;
		for (var i in rootMenuInstance)
		 {
			 if (rootMenuInstance[i]._alpha > 0 && rootMenuInstance[i]._alpha < 100)
			 {
				_global.skse.plugins.AHZmoreHUDInventory.AHZLog(i + " = " + rootMenuInstance[i], false) ;
				_global.skse.plugins.AHZmoreHUDInventory.AHZLog(i + "._alpha = " + rootMenuInstance[i]._alpha, false) ;
			 }
			//rootMenuInstance[i].border = true;
			  for (var p in rootMenuInstance[i])
			 {
				 if (rootMenuInstance[i][p]._alpha > 0 && rootMenuInstance[i][p]._alpha < 100)
				 {
					_global.skse.plugins.AHZmoreHUDInventory.AHZLog("      " + p + " = " + rootMenuInstance[i][p], false) ;
					_global.skse.plugins.AHZmoreHUDInventory.AHZLog("      " + p + "._alpha = " + rootMenuInstance[i][p]._alpha, false) ;
				 }
				  for (var q in rootMenuInstance[i][p])
				 {
					 if (rootMenuInstance[i][p][q]._alpha > 0 && rootMenuInstance[i][p][q]._alpha < 100)
					 {
						_global.skse.plugins.AHZmoreHUDInventory.AHZLog("             " + q + " = " + rootMenuInstance[i][p][q], false) ;
						_global.skse.plugins.AHZmoreHUDInventory.AHZLog("             " + q + "._alpha = " + rootMenuInstance[i][p][q]._alpha, false) ;
					 }
					  for (var s in rootMenuInstance[i][p][q])
					 {
						 if (rootMenuInstance[i][p][q][s]._alpha > 0 && rootMenuInstance[i][p][q][s]._alpha < 100)
						 {
							_global.skse.plugins.AHZmoreHUDInventory.AHZLog("             " + s + " = " + rootMenuInstance[i][p][q][s], false) ;
							_global.skse.plugins.AHZmoreHUDInventory.AHZLog("             " + s + "._alpha = " + rootMenuInstance[i][p][q][s]._alpha, false) ;
						 }
					 }		
				 }				
			 }
		 }*/
		
        // if the item card has this property name then this is SKYUI
        if (rootMenuInstance.itemCard)
        {
			itemCard = rootMenuInstance.itemCard;
            iconHolder = itemCard.createTextField("iconHolder", itemCard.getNextHighestDepth(), 0, 20, itemCard._width, 22);
            isSkyui = true;
        }
        // if the item card has this property name then this is Vanilla
        else if (rootMenuInstance.ItemCard_mc)
        {
			itemCard = rootMenuInstance.ItemCard_mc;
            iconHolder = itemCard.createTextField("iconHolder", itemCard.getNextHighestDepth(), 0, 20, itemCard._width, 22);
            isSkyui = false;
        }
		else if (_currentMenu == "Crafting Menu" && rootMenuInstance.ItemInfoHolder.ItemInfo)
		{
			itemCard = rootMenuInstance.ItemInfoHolder.ItemInfo;
			iconHolder = itemCard.createTextField("iconHolder", itemCard.getNextHighestDepth(), 0, 20, itemCard._width, 22);
			additionDescriptionHolder = rootMenuInstance.ItemInfoHolder.AdditionalDescriptionHolder;
			if (rootMenuInstance.BottomBarInfo.PlayerInfoCard_mc)
			{
            	isSkyui = false;
			}
			else if (rootMenuInstance.BottomBarInfo.playerInfoCard)
			{
				isSkyui = true;
			}
			else  // Cannot tell if its skyui or vanilla
			{
				_global.skse.plugins.AHZmoreHUDInventory.AHZLog(
                    "Could not obtain a reference to the item card.", true)
            	return;
			}
		}
        else
        {
            _global.skse.plugins.AHZmoreHUDInventory.AHZLog(
                    "Could not obtain a reference to the item card.", true)
            return;
        }

        if (! hooksInstalled)
        {
			// The Crafting menus have no publically accessable update functions to hook
			if (_currentMenu != "Crafting Menu")
			{
				hookFunction(rootMenuInstance, "UpdateItemCardInfo", this, "UpdateItemCardInfo");
	
				// For SkuUI the startItemEquip is called when the shift button is held down
				// This is the only time a book can be read in the container menu for SkyUI
				if (_currentMenu == "ContainerMenu" && isSkyui)
				{
					hookFunction(rootMenuInstance, "startItemEquip", this, "startItemEquip");  
				}
				
				// For Inventory Menu needed to invalidate "Book Read"
				if (_currentMenu == "InventoryMenu" && isSkyui)
				{
					hookFunction(rootMenuInstance, "onItemSelect", this, "onItemSelect");
					hookFunction(rootMenuInstance, "AttemptEquip", this, "AttemptEquip");
					hookFunction(rootMenuInstance, "SetPlatform", this, "SetPlatform");
				}                   
						
				// For Used for Vanilla to check the book read status       
				if (_currentMenu == "InventoryMenu" || _currentMenu == "ContainerMenu" && !isSkyui)
				{
					hookFunction(rootMenuInstance, "onItemSelect", this, "onItemSelect");
					hookFunction(rootMenuInstance, "AttemptEquip", this, "AttemptEquip");
					hookFunction(rootMenuInstance, "SetPlatform", this, "SetPlatform");
					hookFunction(rootMenuInstance, "onShowItemsList", this, "onShowItemsList");
				}                       
			}
            _global.skse.plugins.AHZmoreHUDInventory.InstallHooks();    
            hooksInstalled = true;
            
        }
 
        // Creation the text field that holds the extra data
        iconHolder.verticalAlign = "center";
        iconHolder.textAutoSize = "fit";
        iconHolder.multiLine = false;

        var tf: TextFormat = new TextFormat();
        tf.align = "center";
        tf.color = 0x999999;
        tf.indent = 20;
        tf.font = "$EverywhereMediumFont";
        iconHolder.setNewTextFormat(tf);

        iconHolder.text = "";      
                
        _enableItemCardResize = _global.skse.plugins.AHZmoreHUDInventory.EnableItemCardResize();

        if (_enableItemCardResize)
        {
			cardBackground = GetBackgroundMovie();
            newWidth = this._width;
            originalX = cardBackground._x;  
            originalWidth = cardBackground._width;
            newX = (originalX - (newWidth - originalWidth)) / 2;                
            itemCardWidth = itemCard._width;
                
            // Start monitoring the frames
            this.onEnterFrame = ItemCardOnEnterFrame;
        }
    }

    function ItemCardOnEnterFrame(): Void 
    {       	
        if (itemCard._alpha == 0 || rootMenuInstance._alpha < 100)
        {
            this._alpha = 0;
        }
        else
        {
			if (itemCard._currentframe != _lastFrame)
			{
				cardBackground = GetBackgroundMovie();
				_lastFrame = itemCard._currentframe;    
				AdjustItemCard(_lastFrame);
				
				if (_itemCardOverride)
				{
					this._alpha = AHZ_NormalALPHA;
					cardBackground._alpha = 0;     
				}
				else
				{
					this._alpha = 0;
					cardBackground._alpha = AHZ_NormalALPHA;    
				} 	
				
        /*_global.skse.plugins.AHZmoreHUDInventory.AHZLog("++++++++++++++", false) ;
		for (var i in rootMenuInstance)
		 {
			 if (rootMenuInstance[i]._alpha > 0 && rootMenuInstance[i]._alpha < 100)
			 {
				_global.skse.plugins.AHZmoreHUDInventory.AHZLog(i + " = " + rootMenuInstance[i], false) ;
				_global.skse.plugins.AHZmoreHUDInventory.AHZLog(i + "._alpha = " + rootMenuInstance[i]._alpha, false) ;
			 }
			//rootMenuInstance[i].border = true;
			  for (var p in rootMenuInstance[i])
			 {
				 if (rootMenuInstance[i][p]._alpha > 0 && rootMenuInstance[i][p]._alpha < 100)
				 {
					_global.skse.plugins.AHZmoreHUDInventory.AHZLog("      " + p + " = " + rootMenuInstance[i][p], false) ;
					_global.skse.plugins.AHZmoreHUDInventory.AHZLog("      " + p + "._alpha = " + rootMenuInstance[i][p]._alpha, false) ;
				 }
				  for (var q in rootMenuInstance[i][p])
				 {
					 if (rootMenuInstance[i][p][q]._alpha > 0 && rootMenuInstance[i][p][q]._alpha < 100)
					 {
						_global.skse.plugins.AHZmoreHUDInventory.AHZLog("           " + q + " = " + rootMenuInstance[i][p][q], false) ;
						_global.skse.plugins.AHZmoreHUDInventory.AHZLog("           " + q + "._alpha = " + rootMenuInstance[i][p][q]._alpha, false) ;
					 }
					  for (var s in rootMenuInstance[i][p][q])
					 {
						 if (rootMenuInstance[i][p][q][s]._alpha > 0 && rootMenuInstance[i][p][q][s]._alpha < 100)
						 {
							_global.skse.plugins.AHZmoreHUDInventory.AHZLog("                " + s + " = " + rootMenuInstance[i][p][q][s], false) ;
							_global.skse.plugins.AHZmoreHUDInventory.AHZLog("                " + s + "._alpha = " + rootMenuInstance[i][p][q][s]._alpha, false) ;
						 }
					 }		
				 }				
			 }
		 }	
		 _global.skse.plugins.AHZmoreHUDInventory.AHZLog("----------------", false) ;*/
				
				// Vanilla does somthing weird where the item card gets stuck at around an apha of 23.  This was noticed for the crafting menu
				// If resizing is running.  This will force the item card to go to its expected alpha
				if (itemCard._alpha > 0 && itemCard._alpha < AHZ_NormalALPHA)
				{
					itemCard._alpha = AHZ_NormalALPHA;
				}
				
			}			          
        } 
    }

    function stringReplace(block:String, findStr:String, replaceStr:String):String
    {
        return block.split(findStr).join(replaceStr);
    }

	// The Scaleform Extension is broken for center justify for Shrink so I rolled my own
    function ShrinkToFit(tf:TextField):Void
    {
        tf.multiline = true;
        tf.wordWrap = true  
        var tfText:String = tf.htmlText;
        var fontSize:Number = 20;
        var htmlSize = "SIZE=\"" + fontSize.toString() + "\""
        tf.textAutoSize = "none";
        tf.SetText(tfText, true);
        tf.textAutoSize = "none";
        var tfHeight:Number = tf.getLineMetrics(0).height * tf.numLines;        
        while (tfHeight > tf._height && fontSize > 5)
        {
            var beforeHtmlSize = "SIZE=\"" + fontSize.toString() + "\"";
            fontSize -= 1;
            htmlSize = "SIZE=\"" + fontSize.toString() + "\"";
            tfText = stringReplace(tfText, beforeHtmlSize, htmlSize);
            tf.textAutoSize = "none";
            tf.SetText(tfText, true);
            tf.textAutoSize = "none";
            tfHeight = tf.getLineMetrics(0).height * tf.numLines;           
        }   
    }

    function AdjustItemCard(itemCardFrame:Number):Void
    {           
        var processedTextField:TextField = undefined;
                    
        var itemCardX:Number;
        var itemCardY:Number;
        var itemCardBottom:Number;
        
		_global.skse.plugins.AHZmoreHUDInventory.AHZLog("itemCard._parent._x: " + itemCard._parent._x, false);  
		_global.skse.plugins.AHZmoreHUDInventory.AHZLog("itemCard._x: " + itemCard._x, false); 
        itemCardX = itemCard._parent._x + itemCard._x;
        itemCardY = itemCard._parent._y + itemCard._y;  
        this._y = itemCardY;
        this._x = itemCardX - ((this._width - itemCardWidth) / 2);
        itemCardBottom = this._height;
        var oldDescrptionHeight:Number;
		
        _global.skse.plugins.AHZmoreHUDInventory.AHZLog("<<<FRAME>>>: " + itemCardFrame, false);    
        	
		if (_currentMenu == "MagicMenu")
		{
			switch (itemCardFrame)
			{       
				case AHZ_ICF_MAGIC:
				case AHZ_ICF_MM_MAGIC:
				{
					processedTextField = itemCard.MagicEffectsLabel;    
				}
				break;  
				case AHZ_ICF_POWERS:
				{
					processedTextField = itemCard.MagicEffectsLabel;
				}
				break;
				case AHZ_ICF_ACTIVEEFFECTS:
				{
					processedTextField = itemCard.MagicEffectsLabel;
				}
				break;			
				default:
				{
					processedTextField = undefined;
					cardBackground._alpha = AHZ_NormalALPHA;
					this._alpha = 0;
				}
				break;
			}
			
			if (processedTextField)
			{
				_itemCardOverride = true;
				this._alpha = AHZ_NormalALPHA;
				cardBackground._alpha = 0;
				processedTextField._width = this._width - (AHZ_XMargin * 2);
				processedTextField._x = newX + AHZ_XMargin;
				oldDescrptionHeight = processedTextField._height;
				processedTextField._height = (itemCardBottom - processedTextField._y) - (AHZ_YMargin_WithItems); 
				ShrinkToFit(processedTextField); 
				additionDescriptionHolder
			}
			else
			{
				_itemCardOverride = false;
			}		
		}
		else
		{
			// If we advance to somethine like the confirmation frame, then make sure the icons are wiped
			if (itemCardFrame >= AHZ_ICF_EMPTY)
			{
				iconHolder._alpha = 0;
			}
			else
			{
				iconHolder._alpha = 100;
			}
			
			switch (itemCardFrame)
			{
				case AHZ_ICF_WEAPONS_ENCH:
				{
					processedTextField = itemCard.WeaponEnchantedLabel;         
				}
				break;
				case AHZ_ICF_ARMOR_ENCH:
				{
					processedTextField = itemCard.ApparelEnchantedLabel;
				}
				break;
				case AHZ_ICF_POTION:
				case AHZ_ICF_POTION_SURVIVAL:
				case AHZ_ICF_POTION_SURVIVAL2:
				{
					processedTextField = itemCard.PotionsLabel;         
				}
				break;
				case AHZ_ICF_BOOKS:
				{
					processedTextField = itemCard.BookDescriptionLabel;
				}
				break;          
				case AHZ_ICF_MAGIC:
				{
					processedTextField = itemCard.MagicEffectsLabel;    
				}
				break;  		
				default:
				{
					processedTextField = undefined;
					cardBackground._alpha = AHZ_NormalALPHA;
					this._alpha = 0;
				}
				break;
			}
			
			if (processedTextField)
			{
				_itemCardOverride = true;
				this._alpha = AHZ_NormalALPHA;
				cardBackground._alpha = 0;
				processedTextField._width = this._width - (AHZ_XMargin * 2);
				processedTextField._x = newX + AHZ_XMargin;
				oldDescrptionHeight = processedTextField._height;
				processedTextField._height = (itemCardBottom - processedTextField._y) - AHZ_YMargin;		
				ShrinkToFit(processedTextField);    
				
				// Need to shift up to make room for the requied crafting materials
				if (_currentMenu == "Crafting Menu" && !_craftingMenuCardShifted){
					itemCard._y = itemCard._y + AHZ_CraftingMenuYShift;
					this._y = this._y + AHZ_CraftingMenuYShift;
					_craftingMenuCardShifted = true;
				}
			}
			else
			{
				_itemCardOverride = false;
				
				// Shift back to normal
				if (_currentMenu == "Crafting Menu" && _craftingMenuCardShifted){
					itemCard._y = itemCard._y - AHZ_CraftingMenuYShift;
					this._y = this._y - AHZ_CraftingMenuYShift;
					_craftingMenuCardShifted = false;
				}				
			}
		}
		
		if (_itemCardOverride)
		{
			var itemsBelow:Array = GetItemsBelowDescription(itemCard, processedTextField);
			
			var itemBelow:Number;
			
			for (itemBelow = 0; itemBelow < itemsBelow.length; itemBelow++)
			{
				itemsBelow[itemBelow]._y = itemsBelow[itemBelow]._y + (processedTextField._height - oldDescrptionHeight);
			}	
		}
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
        var process = rootMenuInstance.bFadedIn == true && rootMenuInstance.inventoryLists.currentState == SHOW_PANEL && rootMenuInstance.inventoryLists.itemList.itemCount > 0 && !rootMenuInstance.inventoryLists.itemList.disableSelection && !rootMenuInstance.inventoryLists.itemList.disableInput;

        if (process && _platform == 0 && abCheckIfOverRect) {
            var e = Mouse.getTopMostEntity();
            var found = false;
            
            while (!found && e != undefined) {
                if (e == rootMenuInstance.inventoryLists.itemList)
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
            if (e.itemIndex == rootMenuInstance.inventoryLists.itemList.selectedIndex)
                return true;
                
        return false;
    }
    
    // Had to hook because the _platform variable is private
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
       
        var entryList:Object;
        var selectedIndex:Number;
        var type:Number;
        
        if (isSkyui)
        {
            entryList = rootMenuInstance.inventoryLists.itemList._entryList;
            selectedIndex = rootMenuInstance.inventoryLists.itemList._selectedIndex;
        }
        else //Vanilla
        {
            entryList = rootMenuInstance.InventoryLists_mc._ItemsList.EntriesA;
            selectedIndex = rootMenuInstance.InventoryLists_mc._ItemsList.iSelectedIndex;      
        }   
        
        type = itemCard.itemInfo.type;
        
        if ((type != ICT_BOOK && type != ICT_POTION) || _global.skse == null)
            return;
            
        _global.skse.plugins.AHZmoreHUDInventory.AHZLog("--.CheckBook", false);                 
            
        //entryList[selectedIndex].flags |= BOOKFLAG_READ;
        UpdateItemCardInfo(itemCard.itemInfo);  
    }

    // Occurs when an item is selected with the activate/gamepad key
    private function onItemSelect(event: Object): Void
    {
        if (_currentMenu != "InventoryMenu" && _currentMenu != "ContainerMenu")
            return;
        
        if (!isSkyui)
        {
            // If a transfer is occurring in the vanilla menu
            if (isViewingContainer() && rootMenuInstance.bShowEquipButtonHelp == false)
            {
                return;
            }
        }
        
        if (!event.entry.enabled && event.keyboardOrMouse == 0)
        {
            return;
        }
        _global.skse.plugins.AHZmoreHUDInventory.AHZLog("-->onItemSelect", false);  
        CheckBook();
    }

    // Occurs when an item is selected with the mouse
    private function AttemptEquip(a_slot: Number, a_bCheckOverList: Boolean): Void
    {
        if (_currentMenu != "InventoryMenu" && _currentMenu != "ContainerMenu")
            return;
                                                        
        if (!isSkyui)
        {
            // If a transfer is occurring in the vanilla menu
            if (isViewingContainer() && rootMenuInstance.bShowEquipButtonHelp == false)
            {
                return;
            }
        }                               
                                
        _global.skse.plugins.AHZmoreHUDInventory.AHZLog("-->AttemptEquip", false);          
        var processInput: Boolean = a_bCheckOverList == undefined ? true : a_bCheckOverList;
        
        if (isSkyui)
        {
            if (!SKYUI_shouldProcessItemsListInput(a_bCheckOverList) || SKYUI_confirmSelectedEntry()) {
                return;
            }
        }
        else
        {
            if (!rootMenuInstance.ShouldProcessItemsListInput(processInput)) {
                return;
            }
        }
        CheckBook();
    }
    
    // Extra hook needed to set the iSelectedCategory in vanilla
    function onShowItemsList(event: Object): Void
    {
        if (!isSkyui)
        {
            iSelectedCategory = rootMenuInstance.InventoryLists_mc.CategoriesList.selectedIndex;
        }
    }   
    
    // Returns true if in the non-player side of the container menu
    private function isViewingContainer(): Boolean
    {
        var isInViewContainer:Boolean;
        if (_currentMenu != "ContainerMenu") 
        {
            _global.skse.plugins.AHZmoreHUDInventory.AHZLog("NOT IN VIEWING MENU", false);      
            return false;
        }
        
        // Vanilla and SKYUI have different methods for detecting whether in the player menu or the container menu
        if (isSkyui)
        {
            isInViewContainer =  (rootMenuInstance.inventoryLists.categoryList.activeSegment == 0);
        }
        else
        {
            var dividerIdx: Number = rootMenuInstance.InventoryLists_mc.CategoriesList.dividerIndex;
            isInViewContainer =  dividerIdx != undefined && iSelectedCategory < dividerIdx;
        }
        
        if (isInViewContainer)
        {
            _global.skse.plugins.AHZmoreHUDInventory.AHZLog("IN VIEWING MENU", false);      
        }
        else
        {
            _global.skse.plugins.AHZmoreHUDInventory.AHZLog("NOT IN VIEWING MENU", false);      
        }
        
        
        return  isInViewContainer;
    }   

    // On Quantity Menu select in container menu
    private function onQuantityMenuSelect(event: Object): Void
    {
        _global.skse.plugins.AHZmoreHUDInventory.AHZLog("-->onQuantityMenuSelect", false);  
        if (_equipHand != undefined) {
            CheckBook()
            _equipHand = undefined;
            return;
        }
    }
    
    // Start Item Equip in container menu
    private function startItemEquip(a_equipHand: Number): Void
    {
        _global.skse.plugins.AHZmoreHUDInventory.AHZLog("-->startItemEquip", false);    
        CheckBook();
    }

    // A hook to update the item card with extended items
    function UpdateItemCardInfo(aUpdateObj: Object): Void
    {       
        _global.skse.plugins.AHZmoreHUDInventory.AHZLog("-->UpdateItemCardInfo", false);
        var entryList:Object;
        var selectedIndex:Number;
        var type:Number;
        if (isSkyui)
        {
            entryList = rootMenuInstance.inventoryLists.itemList._entryList;
            selectedIndex = rootMenuInstance.inventoryLists.itemList._selectedIndex;
        }
        else //Vanilla
        {
            entryList = rootMenuInstance.InventoryLists_mc._ItemsList.EntriesA;
            selectedIndex = rootMenuInstance.InventoryLists_mc._ItemsList.iSelectedIndex;      
        }
        		
        type = itemCard.itemInfo.type;
        iconHolder.text = "";

        if (_enableItemCardResize)
        {
            AdjustItemCard(_lastFrame);
        }         

		// No extended data to process for the magic menu
		if (_currentMenu == "MagicMenu")
		{
			return;
		}

		// Keep icons off of frames like the confirmation frame etc.
		if (itemCard._currentframe >= AHZ_ICF_EMPTY)
		{
			return;
		}

        if (type != ICT_BOOK && type != ICT_ARMOR && type != ICT_WEAPON && type != ICT_POTION)
        {
            return;
        }

		for (var i in entryList[selectedIndex])
		{
			_global.skse.plugins.AHZmoreHUDInventory.AHZLog(i + " = " + entryList[selectedIndex][i], false);
		}

		if (entryList[selectedIndex].AHZItemCardObj.enchantmentKnown)
		{
			appendImageToEnd(iconHolder, "ahzknown.png", 20,20);
		}
		else if (_global.skse.plugins.AHZmoreHUDInventory.GetWasBookRead(entryList[selectedIndex].formId))
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