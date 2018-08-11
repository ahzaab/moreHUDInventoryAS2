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
    public var itemCard: MovieClip;

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

    // Statics
    private static var hooksInstalled:Boolean = false;
    private static var AHZ_XMargin:Number 			= 15;
    private static var AHZ_YMargin:Number 			= 0;
    private static var AHZ_FontScale:Number 		= 0.90;

    // Types from ItemCard
    private static var ICT_ARMOR: Number            = 1;
    private static var ICT_WEAPON: Number           = 2;
    private static var ICT_BOOK: Number             = 4;
    private static var ICT_POTION: Number           = 6;        // Used for Spell Tomes (shrug)
    
    private static var BOOKFLAG_READ: Number        = 0x08; 
    private static var SHOW_PANEL                   = 1;

    private static var AHZ_ICF_WEAPONS_ENCH:Number 	= 10;
    private static var AHZ_ICF_ARMOR_ENCH:Number 	= 30;
    private static var AHZ_ICF_POTION:Number 		= 40;
    private static var AHZ_ICF_POTION_SURVIVAL:Number = 60;
    private static var AHZ_ICF_INGR:Number 			= 50;
    private static var AHZ_ICF_BOOKS:Number 		= 80;
    private static var AHZ_ICF_MAGIC:Number 		= 90;


    /* INITIALIZATION */
        
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
                    "Could not obtain a reference to the item card.", true)
            return;
        }

        if (! hooksInstalled)
        {
            // Apply hooks to hook events
            hookFunction(_root.Menu_mc, "UpdateItemCardInfo", this, "UpdateItemCardInfo");
            // For SkuUI the startItemEquip is called when the shift button is held down
            // This is the only time a book can be read in the container menu for SkyUI
            if (_currentMenu == "ContainerMenu" && isSkyui)
            {
                hookFunction(_root.Menu_mc, "startItemEquip", this, "startItemEquip");  
            }
            
            // For Inventory Menu needed to invalidate "Rook Read"
            if (_currentMenu == "InventoryMenu" && isSkyui)
            {
                hookFunction(_root.Menu_mc, "onItemSelect", this, "onItemSelect");
                hookFunction(_root.Menu_mc, "AttemptEquip", this, "AttemptEquip");
                hookFunction(_root.Menu_mc, "SetPlatform", this, "SetPlatform");
            }                   
                    
            // For Used for Vanilla to check the book read status       
            if (_currentMenu == "InventoryMenu" || _currentMenu == "ContainerMenu" && !isSkyui)
            {
                hookFunction(_root.Menu_mc, "onItemSelect", this, "onItemSelect");
                hookFunction(_root.Menu_mc, "AttemptEquip", this, "AttemptEquip");
                hookFunction(_root.Menu_mc, "SetPlatform", this, "SetPlatform");
                hookFunction(_root.Menu_mc, "onShowItemsList", this, "onShowItemsList");
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

        iconHolder.text = "No IconSource";      
                
        _enableItemCardResize = isSkyui && _global.skse.plugins.AHZmoreHUDInventory.EnableItemCardResize();
                
        if (_enableItemCardResize)
        {
            newWidth = this._width;
            originalX = itemCard["background"]._x;  
            originalWidth = itemCard["background"]._width;
            newX = (originalX - (newWidth - originalWidth)) / 2;                
            itemCardWidth = itemCard._width;
                
            // Start monitoring the frames
            this.onEnterFrame = ItemCardOnEnterFrame;
        }
    }

    function ItemCardOnEnterFrame(): Void 
    {       
        if (itemCard._currentframe != _lastFrame)
        {
            _lastFrame = itemCard._currentframe;    
            AdjustItemCard(_lastFrame);
        }       
    
        if (itemCard._alpha == 0 || _root.Menu_mc._alpha < 100)
        {
            this._alpha = 0;
        }
        else
        {
            if (_itemCardOverride)
            {
                this._alpha = 60;
                itemCard["background"]._alpha = 0;                  
            }
            else
            {
                this._alpha = 0;
				itemCard["background"]._alpha = 60;    
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
        
        itemCardX = itemCard._parent._x + itemCard._x;
        itemCardY = itemCard._parent._y + itemCard._y;  
        this._y = itemCardY;
        this._x = itemCardX - ((this._width - itemCardWidth) / 2);
        itemCardBottom = this._height;
        
        _global.skse.plugins.AHZmoreHUDInventory.AHZLog("<<<FRAME>>>: " + itemCardFrame, false);    
        
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
				itemCard["background"]._alpha = 60;  
                this._alpha = 0;
            }
            break;
        }
        
        if (processedTextField)
        {
            _itemCardOverride = true;
            this._alpha = 60;
            itemCard["background"]._alpha = 0;  
            processedTextField._width = this._width - (AHZ_XMargin * 2);
            processedTextField._x = newX + AHZ_XMargin;
            processedTextField._height = (itemCardBottom - processedTextField._y) - AHZ_YMargin;                
            ShrinkToFit(processedTextField);    
        }
        else
        {
            _itemCardOverride = false;
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
            entryList = _root.Menu_mc.inventoryLists.itemList._entryList;
            selectedIndex = _root.Menu_mc.inventoryLists.itemList._selectedIndex;
        }
        else //Vanilla
        {
            entryList = _root.Menu_mc.InventoryLists_mc._ItemsList.EntriesA;
            selectedIndex = _root.Menu_mc.InventoryLists_mc._ItemsList.iSelectedIndex;      
        }   
        
        type = itemCard.itemInfo.type;
        
        if ((type != ICT_BOOK && type != ICT_POTION) || _global.skse == null)
            return;
            
        _global.skse.plugins.AHZmoreHUDInventory.AHZLog("--.CheckBook", false);                 
            
        entryList[selectedIndex].flags |= BOOKFLAG_READ;
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
            if (isViewingContainer() && _root.Menu_mc.bShowEquipButtonHelp == false)
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
            if (isViewingContainer() && _root.Menu_mc.bShowEquipButtonHelp == false)
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
            if (!_root.Menu_mc.ShouldProcessItemsListInput(processInput)) {
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
            iSelectedCategory = _root.Menu_mc.InventoryLists_mc.CategoriesList.selectedIndex;
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
            isInViewContainer =  (_root.Menu_mc.inventoryLists.categoryList.activeSegment == 0);
        }
        else
        {
            var dividerIdx: Number = _root.Menu_mc.InventoryLists_mc.CategoriesList.dividerIndex;
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
            entryList = _root.Menu_mc.inventoryLists.itemList._entryList;
            selectedIndex = _root.Menu_mc.inventoryLists.itemList._selectedIndex;
        }
        else //Vanilla
        {
            entryList = _root.Menu_mc.InventoryLists_mc._ItemsList.EntriesA;
            selectedIndex = _root.Menu_mc.InventoryLists_mc._ItemsList.iSelectedIndex;      
        }
        
        type = itemCard.itemInfo.type;
        iconHolder.text = "";

        if (_enableItemCardResize)
        {
            AdjustItemCard(_lastFrame);
        }         

        if (type != ICT_BOOK && type != ICT_ARMOR && type != ICT_WEAPON && type != ICT_POTION)
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