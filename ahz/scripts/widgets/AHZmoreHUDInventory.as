﻿import ahz.scripts.widgets.AHZDefines.AHZCCSkyUIFrames;
import ahz.scripts.widgets.AHZDefines.AHZCCSurvFrames;
import ahz.scripts.widgets.AHZDefines.AHZVanillaFrames;
import flash.display.BitmapData;

class ahz.scripts.widgets.AHZmoreHUDInventory extends MovieClip
{
    //Widgets
    public var iconHolder: TextField;
    public var itemCard: MovieClip;
    public var rootMenuInstance:MovieClip;
    public var cardBackground:MovieClip;
    public var additionDescriptionHolder:MovieClip;
    var iconTextFormat:TextFormat;
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
    private var _isCCSurvCard:Boolean = false;
    private var _frameDefines:Object;
    private var _entryList:Object;
    private var _lastSelectedIndex:Number;
    private var _selectedIndex:Number;
    private var _selectedItem:Object;
    private var _lastItemCardVisibility:Boolean;
    private var _readyToUpdate:Boolean = false;

    // Statics
    private static var hooksInstalled:Boolean = false;
    private static var AHZ_XMargin:Number           = 15;
    private static var AHZ_YMargin:Number           = 0;
    private static var AHZ_YMargin_WithItems:Number = 35;
    private static var AHZ_YMargin_Crafting:Number  = 20;
    private static var AHZ_FontScale:Number         = 0.90;
    private static var AHZ_CraftingMenuYShift:Number = -25;
    private static var AHZ_NormalALPHA:Number = 60;

    // Types from ItemCard
    private static var ICT_ARMOR: Number            = 1;
    private static var ICT_WEAPON: Number           = 2;
    private static var ICT_BOOK: Number             = 4;
    private static var ICT_POTION: Number           = 6;        // Used for Spell Tomes (shrug)
    private static var ICT_FOOD: Number = 5;

    private static var BOOKFLAG_READ: Number        = 0x08;
    private static var SHOW_PANEL                   = 1;

    /* INITIALIZATION */

    // Get all unnamed movie clips.  Items that were not named in the fla file.
    // The property name for "unnamed" elements is in the format "instance<nnn>"
    function getUnnamedInstances(target:MovieClip, getOnlyMovieClips:Boolean) :Array
    {
        var arr:Array = new Array();
        for (var i in target)
        {
            var proName = i.toString();
            if (proName.indexOf("instance") == 0)
            {
                var unnamedIndex: String = proName.substring("instance".length);
                // If the value following the name "Instance" in the property name is a number
                if (int(unnamedIndex))
                {
                    if (getOnlyMovieClips)
                    {
                        if (target[i] instanceof MovieClip)
                        {
                            arr.push(target[i]);
                        }
                    }
                    else
                    {
                        arr.push(target[i]);
                    }
                }
            }
        }
        return arr;
    }

    function GetBackgroundMovie():MovieClip
    {
        if (itemCard["background"])
        {
            return MovieClip(itemCard["background"]);
        }
        else
        {
            // Vanilla does not name the background clip.  So we must
            // enumerate for a movie clip without children.  It "Should" be the background
            // Unnamed instances will have a name in the form of "instance<nnn>"
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
                        return MovieClip(arry[i]);
                    }
                }
            }
        }
        return undefined;
    }

    // This function is used to shift every item in the item card that is below the description
    // text field.  Since we are increasing the height of the text field we need to make sure the
    // items below do not overlap
    function GetItemsBelowDescription(targetMovie:MovieClip, targetTextField: TextField):Array
    {
        var arr:Array = new Array();
        for (var i in targetMovie)
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

        // if the item card has this property name then this is SKYUI
        if (rootMenuInstance.itemCard)
        {
            itemCard = rootMenuInstance.itemCard;
            iconHolder = itemCard.createTextField("iconHolder", itemCard.getNextHighestDepth(), 0, 10, itemCard._width, 32);
            _entryList = rootMenuInstance.inventoryLists.itemList._entryList;
            isSkyui = true;
        }
        // if the item card has this property name then this is Vanilla
        else if (rootMenuInstance.ItemCard_mc)
        {
            itemCard = rootMenuInstance.ItemCard_mc;
            iconHolder = itemCard.createTextField("iconHolder", itemCard.getNextHighestDepth(), 0, 20, itemCard._width, 22);
            _entryList = rootMenuInstance.InventoryLists_mc._ItemsList.EntriesA;
            isSkyui = false;
        }
        else if (_currentMenu == "Crafting Menu" && rootMenuInstance.ItemInfoHolder.ItemInfo)
        {
            itemCard = rootMenuInstance.ItemInfoHolder.ItemInfo;
            iconHolder = itemCard.createTextField("iconHolder", itemCard.getNextHighestDepth(), 0, 20, itemCard._width, 22);
            additionDescriptionHolder = rootMenuInstance.ItemInfoHolder.AdditionalDescriptionHolder;
            if (rootMenuInstance.InventoryLists.ItemsListHolder.List_mc.EntriesA)
            {
                _entryList = rootMenuInstance.InventoryLists.ItemsListHolder.List_mc.EntriesA;
                isSkyui = false;
            }
            else if (rootMenuInstance.InventoryLists.panelContainer.itemList._entryList)
            {
                _entryList = rootMenuInstance.InventoryLists.panelContainer.itemList._entryList;
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

        _global.skse.plugins.AHZmoreHUDInventory.AHZLog("Frame Count: " + itemCard._totalframes, false);

        if (itemCard._totalframes >= AHZCCSurvFrames.MAX_FRAMES)
        {
            _global.skse.plugins.AHZmoreHUDInventory.AHZLog("Survival Card Detected", true);
            _isCCSurvCard = true;
            _frameDefines = AHZCCSurvFrames;
        }
        else if (itemCard._totalframes >= AHZCCSkyUIFrames.MAX_FRAMES)
        {
            _global.skse.plugins.AHZmoreHUDInventory.AHZLog("SkyUI Survival Integration Card Detected", true);
            _isCCSurvCard = true;
            _frameDefines = AHZCCSkyUIFrames;
        }
        else
        {
            _global.skse.plugins.AHZmoreHUDInventory.AHZLog("Vanilla Card Detected", true);
            _isCCSurvCard = false;
            _frameDefines = AHZVanillaFrames;
        }

        if (! hooksInstalled)
        {
            _global.skse.plugins.AHZmoreHUDInventory.InstallHooks();
            hooksInstalled = true;
        }

        // Creation the text field that holds the extra data
        iconHolder.verticalAlign = "center";
        iconHolder.textAutoSize = "shrink";
        iconHolder.multiLine = false;

        iconTextFormat = new TextFormat();
        iconTextFormat.align = "center";
        iconTextFormat.color = 0x999999;
        iconTextFormat.indent = 20;
        iconTextFormat.size = 24;
        iconTextFormat.font = "$EverywhereMediumFont";
        iconHolder.setNewTextFormat(iconTextFormat);
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
        }

        // Start monitoring the frames
        this.onEnterFrame = ItemCardOnEnterFrame;
    }

    function GetSelectedIndex():Number
    {
        var selectedItemIndex:Number;
        if (isSkyui)
        {
            if (_currentMenu == "Crafting Menu")
            {
                selectedItemIndex = rootMenuInstance.InventoryLists.panelContainer.itemList._selectedIndex;
            }
            else
            {
                selectedItemIndex = rootMenuInstance.inventoryLists.itemList._selectedIndex;
            }
        }
        else //Vanilla
        {
            if (_currentMenu == "Crafting Menu")
            {
                selectedItemIndex = rootMenuInstance.InventoryLists.ItemsListHolder.List_mc.iSelectedIndex;
            }
            else
            {
                selectedItemIndex = rootMenuInstance.InventoryLists_mc._ItemsList.iSelectedIndex;
            }
        }
        return selectedItemIndex;
    }

    function ItemCardOnEnterFrame(): Void
    {
        var itemCardVisible:Boolean = (itemCard._alpha > 0 && rootMenuInstance._alpha == 100);

        if (itemCardVisible)
        {
            _readyToUpdate = true;
        }

        if (!_readyToUpdate)
        {
            return;
        }

        if (_enableItemCardResize)
        {
            if (itemCard._currentframe != _lastFrame)
            {
                cardBackground = GetBackgroundMovie();
                _lastFrame = itemCard._currentframe;
                AdjustItemCard(_lastFrame);
            }

            if (_itemCardOverride)
            {
                this._alpha = itemCard._alpha - (100 - AHZ_NormalALPHA);
                cardBackground._alpha = 0;
            }
            else
            {
                this._alpha = 0;
                cardBackground._alpha = AHZ_NormalALPHA;
            }
        }

        _selectedIndex = GetSelectedIndex();

        if (_lastSelectedIndex != _selectedIndex ||
                _selectedItem.formId != _entryList[_selectedIndex].formId ||
                _selectedItem.text != _entryList[_selectedIndex].text)
        {
            _lastSelectedIndex = _selectedIndex;
            _selectedItem = _entryList[_selectedIndex];
            UpdateItemCardInfo();
        }
        else
        {
            // Books are unique, they can be updated while in the menu and there is no way of
            // knowing if we are in the book menu without doing a bunch of hooks
            if (itemCard.itemInfo.type == ICT_BOOK &&
            (iconHolder.text == "" || iconHolder.text.indexOf("eyeImage.png") < 0) && 			// Not showing the book read icon
            _global.skse.plugins.AHZmoreHUDInventory.ShowBookRead() &&
            _global.skse.plugins.AHZmoreHUDInventory.GetWasBookRead(_selectedItem.formId))
            {
                iconHolder.text = "";
                appendImageToEnd(iconHolder, "eyeImage.png", 20,20);
            }
        }
    }

    function ResetIconText()
    {
        iconHolder.html = false;
        iconHolder.verticalAlign = "center";
        iconHolder.textAutoSize = "shrink";
        iconHolder.multiLine = false;
        iconHolder.setNewTextFormat(iconTextFormat);
        iconHolder.text = "";
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
        var marginRequired:Boolean = false;

        itemCardX = itemCard._parent._x + itemCard._x;
        itemCardY = itemCard._parent._y + itemCard._y;
        this._y = itemCardY;
        this._x = itemCardX - ((this._width - itemCardWidth) / 2);
        itemCardBottom = this._height;
        var oldDescrptionHeight:Number;

        _global.skse.plugins.AHZmoreHUDInventory.AHZLog("<<<FRAME>>>: " + itemCardFrame, false);

        // If we advance to somethine like the confirmation frame, then make sure the icons are not visible
        // Dont wipe the value because we need to restore it when returning to the same item card
        if (itemCardFrame >= _frameDefines.EMPTY_LOW && itemCardFrame <= _frameDefines.EMPTY_HIGH)
        {
            iconHolder._alpha = 0;
        }
        else
        {
            iconHolder._alpha = 100;
        }

        switch (itemCardFrame)
        {
            case _frameDefines.WEAPONS_ENCH:
                {
                    processedTextField = itemCard.WeaponEnchantedLabel;
                }
                break;
            case _frameDefines.ARMOR_ENCH:
            case _frameDefines.ARMOR_SURV_ENCH:
                {
                    processedTextField = itemCard.ApparelEnchantedLabel;
                }
                break;
            case _frameDefines.POTION_REF:
                {
                    processedTextField = itemCard.PotionsLabel;
                }
                break;
            case _frameDefines.BOOKS_DESCRIPTION:
                {
                    processedTextField = itemCard.BookDescriptionLabel;
                }
                break;

            case _frameDefines.MAGIC_REG:
            case _frameDefines.POW_REG:
            case _frameDefines.MAGIC_TIME_LABEL:
            case _frameDefines.POWER_TIME_LABEL:
            case _frameDefines.ACTIVEEFFECTS:
                {
                    processedTextField = itemCard.MagicEffectsLabel;
                    marginRequired = true;
                }
                break;
            case _frameDefines.MAG_SHORT:
                {
                    processedTextField = itemCard.MagicEffectsLabel;
                }
                break;

            /*case _frameDefines.CFT_ENCHANTING:
            {
                processedTextField = itemCard.EnchantmentLabel;
            }
            break; 	*/

            // All other frames are not going to be resized
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
            //this._alpha = AHZ_NormalALPHA;
            cardBackground._alpha = 0;
            processedTextField._width = this._width - (AHZ_XMargin * 2);
            processedTextField._x = newX + AHZ_XMargin;
            oldDescrptionHeight = processedTextField._height;

            if (marginRequired)
            {
                processedTextField._height = (itemCardBottom - processedTextField._y) - AHZ_YMargin_WithItems;
            }
            else
            {
                processedTextField._height = (itemCardBottom - processedTextField._y) - AHZ_YMargin;
            }

            ShrinkToFit(processedTextField);

            // Need to shift up to make room for the requied crafting materials
            if (_currentMenu == "Crafting Menu" && !_craftingMenuCardShifted)
            {
                itemCard._parent._y = itemCard._parent._y + AHZ_CraftingMenuYShift;
                this._y = this._y + AHZ_CraftingMenuYShift;
                additionDescriptionHolder._y = additionDescriptionHolder._y - AHZ_CraftingMenuYShift;
                _craftingMenuCardShifted = true;
            }
        }
        else
        {
            _itemCardOverride = false;

            // Shift back to normal
            if (_currentMenu == "Crafting Menu" && _craftingMenuCardShifted)
            {
                itemCard._parent._y = itemCard._parent._y - AHZ_CraftingMenuYShift;
                this._y = this._y - AHZ_CraftingMenuYShift;
                additionDescriptionHolder._y = additionDescriptionHolder._y + AHZ_CraftingMenuYShift;
                _craftingMenuCardShifted = false;
            }
        }

        // Shift any control the is below the processedTextField, down to the new
        // Width
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

    // A hook to update the item card with extended items
    // Note this function does not get called by the crafting menus.  If we need to extend
    // the crafting menu, I need to find another way.  I found no publically accessable hooks
    // in the crafting menu.
    function UpdateItemCardInfo(): Void
    {
        _global.skse.plugins.AHZmoreHUDInventory.AHZLog("-->UpdateItemCardInfo", false);
        var type:Number;
        var itemCardFrame:Number = itemCard._currentframe;

        type = itemCard.itemInfo.type;
        ResetIconText();

        if (_enableItemCardResize)
        {
            AdjustItemCard(_lastFrame);
        }

        // No extended data to process for the magic menu at this time
        if (_currentMenu == "MagicMenu")
        {
            return;
        }

        // Keep icons off of frames like the confirmation frame etc.
        if (itemCardFrame >= _frameDefines.EMPTY_LOW && itemCardFrame <= _frameDefines.EMPTY_HIGH)
        {
            return;
        }

        if (type != ICT_BOOK && type != ICT_ARMOR && type != ICT_WEAPON && type != ICT_POTION && type != ICT_FOOD)
        {
            return;
        }

        if (_selectedItem.AHZItemCardObj.enchantmentKnown)
        {
            appendImageToEnd(iconHolder, "ahzknown.png", 20,20);
        }
        // Fortunately, extraData is not required for getting the Book Read Status.  This allows us to check
        // it in real time and make sure the read status is accurate
        else if (_global.skse.plugins.AHZmoreHUDInventory.GetWasBookRead(_selectedItem.formId))
        {
            if (_global.skse.plugins.AHZmoreHUDInventory.ShowBookRead())
            {
                appendImageToEnd(iconHolder, "eyeImage.png", 20,20);
            }
        }
        else if (_selectedItem.AHZItemCardObj.bookSkill &&
                 String(_selectedItem.AHZItemCardObj.bookSkill).length )
        {
            iconHolder.text = String(_selectedItem.AHZItemCardObj.bookSkill.toUpperCase());
        }
        else if (_selectedItem.AHZItemCardObj.PosEffects > 0||
                 _selectedItem.AHZItemCardObj.NegEffects > 0)
        {
            var strEffects:String;
            strEffects = "<TEXTFORMAT><P ALIGN=\'center\' >"
                         strEffects += " </P></TEXTFORMAT>";
            iconHolder.textAutoSize = "shrink";
            iconHolder.html = true;

            if (_selectedItem.AHZItemCardObj.PosEffects > 0)
            {
                strEffects = appendHtmlToEnd(strEffects, "<font face=\'$EverywhereBoldFont\' size=\'6\' color=\'#189515\'> [Health.png]</font>");
                strEffects = appendHtmlToEnd(strEffects, "<font face=\'$EverywhereBoldFont\' size=\'18\' color=\'#189515\'> " + _selectedItem.AHZItemCardObj.PosEffects + "</font>");

            }
            if (_selectedItem.AHZItemCardObj.NegEffects > 0)
            {
                if (_selectedItem.AHZItemCardObj.PosEffects > 0)
                {
                    strEffects = appendHtmlToEnd(strEffects, "<font face=\'$EverywhereBoldFont\' size=\'10\' color=\'#FF0000\'>      </font>");
                }
                strEffects = appendHtmlToEnd(strEffects, "<font face=\'$EverywhereBoldFont\' size=\'6\' color=\'#FF0000\'> [Poison.png]</font>");
                strEffects = appendHtmlToEnd(strEffects, "<font face=\'$EverywhereBoldFont\' size=\'18\' color=\'#FF0000\'> " + _selectedItem.AHZItemCardObj.NegEffects + "</font>");

            }

            var b1 = BitmapData.loadBitmap("Health.png");
            var b2 = BitmapData.loadBitmap("Poison.png");

            var a = new Array;
            var imageName:String = "Health.png";
            a.push({ subString:"[" + imageName + "]", image:b1, width:16, height:16, id:"id" + imageName });  //baseLineY:0,
            imageName = "Poison.png";
            a.push({ subString:"[" + imageName + "]", image:b2, width:16, height:16, id:"id" + imageName });  //baseLineY:0,
            iconHolder.setImageSubstitutions(a);
            iconHolder.htmlText = strEffects;
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

    function interpolate(pBegin:Number, pEnd:Number, pMax:Number, pStep:Number):Number
    {
        return pBegin + Math.floor((pEnd - pBegin) * pStep / pMax);
    }

    // @override WidgetBase
    public function onLoad():Void
    {
        super.onLoad();
    }

    public static function hookFunction(a_scope:Object, a_memberFn:String, a_hookScope:Object, a_hookFn:String):Boolean
    {
        var memberFn:Function = a_scope[a_memberFn];
        if (memberFn == null || a_scope[a_memberFn] == null)
        {
            return false;
        }

        a_scope[a_memberFn] = function ()
        {
            memberFn.apply(a_scope,arguments);
            a_hookScope[a_hookFn].apply(a_hookScope,arguments);
        };
        return true;
    }
}