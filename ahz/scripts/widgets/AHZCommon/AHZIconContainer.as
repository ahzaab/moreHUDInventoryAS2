import flash.utils.*;
import gfx.events.EventDispatcher;
import flash.display.BitmapData;

class ahz.scripts.widgets.AHZCommon.AHZIconContainer extends MovieClip
{
  /* CONSTANTS */
  	private static var MAX_CONCURRENT_ICONS:Number = 32;
	private static var ICON_WIDTH:Number = 20;
	private static var ICON_HEIGHT:Number = 20;
	private static var ICON_XOFFSET:Number = -7;
	private static var ICON_YOFFSET:Number = -7;

	/* Static */
	private static var eventObject: Object;
  	private static var managerSetup:Boolean = false;		
		
  /* INITIALIATZION */
  
  	public var IconContainer_mc:MovieClip;
    public var Icon_tf:TextField;
  	private var iconLoader:MovieClipLoader;
  	private var loadedIcons:Array;
    private var _imageSubs:Array;
	private var _currentImageIndex:Number;
  	private var _tf:TextField;
  	private var _lastX:Number;
	
	function onLoad():Void 
	{
		super.onLoad();
	}	
	
	public function set text(textValue:String):Void
	{
		_global.skse.plugins.AHZmoreHUDInventory.AHZLog("set: " + text, false);
		Icon_tf.text = textValue;
		updatePosition();
	}
	
	public function get text():String
	{
		_global.skse.plugins.AHZmoreHUDInventory.AHZLog("get: " + Icon_tf.text, false);
		return Icon_tf.text;
	}	
	
	public function set htmlText(textValue:String):Void
	{
		Icon_tf.htmlText = textValue;
		updatePosition();
	}
	
	public function get htmlText():String
	{
		return Icon_tf.htmlText;
	}	
	
	public function set html(htmlValue:Boolean):Void
	{
		Icon_tf.html = htmlValue;
		updatePosition();
	}
	
	public function get html():Boolean
	{
		return Icon_tf.html;
	}	
	
  	public function AHZIconContainer()
	{
		super();
		IconContainer_mc = this;
		_tf = Icon_tf;
		_tf.textAutoSize = "shrink";
		_tf.verticalAlign = "center";
		_lastX = -9999999;
		_global.skse.plugins.AHZmoreHUDInventory.AHZLog("_tf: " + _tf, false);
		_currentImageIndex = 0;
		_imageSubs = new Array();
		loadedIcons = new Array();		
	}
	
	function updatePosition ():Void {
		
		if (!loadedIcons.length)
		{
			return;
		}
		
		if (_lastX <= -9999990)
		{
			_lastX = _tf.getLineMetrics(0).x;
		}
		
		var newLineMetrics = _tf.getLineMetrics(0);
		var xDelta = _lastX - newLineMetrics.x;
		for (var i = 0; i < _currentImageIndex; i++)
		{
			_global.skse.plugins.AHZmoreHUDInventory.AHZLog("old loadedIcons["+i+"]._x: " + loadedIcons[i]._x, false);
			loadedIcons[i]._x = loadedIcons[i]._x - (xDelta);
			_global.skse.plugins.AHZmoreHUDInventory.AHZLog("new loadedIcons["+i+"]._x: " + loadedIcons[i]._x, false);
		}		
		_lastX = newLineMetrics.x;
	}
	
	public function Load(s_filePath:String, a_scope: Object, a_loadedCallBack: String, a_errorCallBack: String):Void
	{		
		_global.skse.plugins.AHZmoreHUDInventory.AHZLog("loadIcons start for '" + s_filePath + "'" , false);
				
		if (managerSetup){
			return;
		}
		managerSetup = true;
		eventObject = {};
		EventDispatcher.initialize(eventObject);
		eventObject.addEventListener("iconsLoaded", a_scope, a_loadedCallBack);
		eventObject.addEventListener("iconLoadError", a_scope, a_errorCallBack);		
		
		for (var i:Number = 0; i < MAX_CONCURRENT_ICONS; i++)
		{
			var clip = this.createEmptyMovieClip("clip" + i, this.getNextHighestDepth());
			clip._y = _tf._y;
			clip._x = _tf._x;
			iconLoader = new MovieClipLoader();
			iconLoader.addListener(this);
			iconLoader.loadClip(s_filePath, clip);
		}
		_global.skse.plugins.AHZmoreHUDInventory.AHZLog("loadIcons end", false);
	}
								
	public function onLoadInit(a_mc: MovieClip): Void
	{		
		a_mc._quality = "BEST";
		a_mc.gotoAndStop("ahzEmpty");		
		loadedIcons.push(a_mc);
		if (loadedIcons.length == MAX_CONCURRENT_ICONS)
		{
			eventObject.dispatchEvent({type: "iconsLoaded", tf: this});	
		}
	}
	
	public function onLoadError(a_mc:MovieClip, a_errorCode: String): Void
	{
		_global.skse.plugins.AHZmoreHUDInventory.AHZLog("Error Loading Icon: " + a_errorCode, false);
		eventObject.dispatchEvent({type: "iconLoadError", error: a_errorCode});	
	}
	
	private function getImageSub(a_imageName:String):Object
	{
		var i:Number;
        for (i = 0; i < _imageSubs.length; i++)
		{
			if (_imageSubs[i].subString && _imageSubs[i].subString == "[" + a_imageName + "]")
			{
				return _imageSubs[i];
			}
		}
		
		return null;
	}

	private function appendHtmlToEnd(htmlText:String, appendedHtml:String):String
    {
        var stringIndex:Number;
        stringIndex = htmlText.lastIndexOf("</P></TEXTFORMAT>");
        var firstText:String = htmlText.substr(0,stringIndex);
        var secondText:String = htmlText.substr(stringIndex,htmlText.length - stringIndex);
        return firstText + appendedHtml + secondText;
    }

	function AppendImage(a_imageName:String):Void
	{		
		var loadedImage:BitmapData;
		if (loadedIcons.length)
		{
	 		loadedImage = BitmapData.loadBitmap("dummy.png");
		}
		else
		{		
			_global.skse.plugins.AHZmoreHUDInventory.AHZLog("OLD LOADING", false);
			loadedImage = BitmapData.loadBitmap(a_imageName);
		}
		
		_global.skse.plugins.AHZmoreHUDInventory.AHZLog("loadedImage: " + loadedImage, false);
		if (loadedImage)
		{
			if (loadedIcons.length || !getImageSub(a_imageName))   // Already exists
			{
				_imageSubs.push({ subString:"[" + a_imageName + "]", image:loadedImage, width:ICON_WIDTH, height:ICON_WIDTH, id:"id" + a_imageName });
			}	
		}
				
		if (_imageSubs.length)
		{
			_global.skse.plugins.AHZmoreHUDInventory.AHZLog("_tf.html: " + _tf.html, false);
			
			// get the line metrics before addeding the next image
			var currentLineMetrics = _tf.getLineMetrics(0);
			if (_tf.html) 
			{
				_tf.htmlText = appendHtmlToEnd(_tf.htmlText, "[" + a_imageName + "]");
			}
			else
			{
				_tf.text += "[" + a_imageName + "]";
			}			
			
			_tf.setImageSubstitutions(_imageSubs);
			
			if (loadedIcons.length){	
				loadedIcons[_currentImageIndex].gotoAndStop(a_imageName);
				loadedIcons[_currentImageIndex]._quality = "BEST";
				loadedIcons[_currentImageIndex]._x = (currentLineMetrics.x + currentLineMetrics.width) + ICON_XOFFSET;
				loadedIcons[_currentImageIndex]._y = _tf._Y + (_tf._height - ICON_HEIGHT) - currentLineMetrics.descent;
				loadedIcons[_currentImageIndex]._height = ICON_HEIGHT;
				loadedIcons[_currentImageIndex]._width = ICON_WIDTH;
				updatePosition();
				
				if (_currentImageIndex < loadedIcons.length - 1)
				{
					_currentImageIndex++;			
				}
			}
		}	
	}	
	
    public function Clear()
    {
		for (var i:Number = 0; i < loadedIcons.length; i++)
		{
			loadedIcons[i].gotoAndStop("ahzEmpty");
		}			
		_tf.setImageSubstitutions(null);
        _tf.html = false;
		_tf.text = ""	
		for (var i:Number = 0; i < loadedIcons.length; i++)
		{
			loadedIcons[i]._x = 0;
			loadedIcons[i]._y = 0;
		}			
		_currentImageIndex = 0;
		_imageSubs = new Array();
    }
}