import flash.utils.*;
import gfx.events.EventDispatcher;
import flash.display.BitmapData;

class AHZIconContainer
{
  /* CONSTANTS */
  	private static var MAX_CONCURRENT_ICONS:Number = 32;
	private static var ICON_WIDTH:Number = 20;
	private static var ICON_HEIGHT:Number = 20;

	private static var eventObject: Object;
		
  /* INITIALIATZION */
  
  	private var iconLoader:MovieClipLoader;
	private var iconContainer:MovieClip;
  	private var loadedIcons:Array;
    private var loadedItemCount:Number;
  	private static var managerSetup:Boolean = false;
  
	public function loadIcons(s_filePath:String, a_scope: Object, a_loadedCallBack: String, a_errorCallBack: String):Void
	{		
		_global.skse.plugins.AHZmoreHUDInventory.AHZLog("loadIcons start for '" + s_filePath + "'" , false);
				
		if (managerSetup){
			return;
		}
		loadedItemCount = 0;
		loadedIcons = new Array();
		managerSetup = true;
		eventObject = {};
		EventDispatcher.initialize(eventObject);
		eventObject.addEventListener("configLoad", a_scope, a_loadedCallBack);
		eventObject.addEventListener("configError", a_scope, a_errorCallBack);		
		
		for (var i:Number = 0; i < MAX_CONCURRENT_ICONS; i++)
		{
			var clip = a_scope.createEmptyMovieClip("clip" + i, a_scope.getNextHighestDepth() + i);
			iconLoader = new MovieClipLoader();
			iconLoader.addListener(this);
			iconLoader.loadClip(s_filePath, clip);
		}
		

		
		_global.skse.plugins.AHZmoreHUDInventory.AHZLog("loadIcons end", false);
		
		
		
		//eventObject.dispatchEvent({type: "configLoad", config: configObject});
	}
			
	function applySmoothing(target:MovieClip):MovieClip {
		var mcParent:MovieClip = target._parent;
		var mcName:String = target._name;
		var myBitmap:BitmapData = new BitmapData(target._width, target._height);
		myBitmap.draw(target);
		target.removeMovieClip();
		target.attachBitmap(myBitmap, 1, "auto", true);
		return target;
	}			
			
	public function onLoadInit(a_mc: MovieClip): Void
	{

		a_mc._quality = "BEST";
		a_mc.gotoAndStop(loadedItemCount+1);
		
		//a_mc._xscale = (ICON_WIDTH / a_mc._width) *100; 
		//a_mc._yscale = (ICON_HEIGHT / a_mc._height) *100;
		a_mc._width = ICON_WIDTH;
		a_mc._height = ICON_HEIGHT;
		
		loadedIcons.push(a_mc);
		a_mc._x = ICON_WIDTH * loadedItemCount;
		loadedItemCount++;
		
//		mc.forceSmoothing
		//var bitmap:BitmapData = new BitmapData(a_mc._width, a_mc._height, true);
		//a_mc.attachBitmap(bitmap, a_mc.getNextHighestDepth(),"auto", true);
		//bitmap.draw(a_mc);		
		
		
	}
	
	public function onLoadError(a_mc:MovieClip, a_errorCode: String): Void
	{
	}
}