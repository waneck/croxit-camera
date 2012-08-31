package croxit.camera;
import croxit.camera.Image;
//http://stackoverflow.com/questions/1282830/uiimagepickercontroller-uiimage-memory-and-more

/**
 *  Native Camera UI controller
 **/
class Camera
{
	/**
	 *  Shows the native UI to either take a picture, or select one from the library.
	 *  
	 *  @param	source		determines the source of the picture
	 *  @param	onResult	callback when a result is available
	 **/
	public static function getPicture(source:CameraSource, onResult:CameraResult->Void):Void
	{
		if (cameraInterface == null)
			onResult(Error("Camera interface not found"));
		else
			cameraInterface._getPicture(source, onResult);
	}
	
	/**
	 *  Queries the system if a specific source is available.
	 **/
	public static function isSourceAvailable(source:CameraSource):Bool
	{
		if (cameraInterface == null)
			//if no interface is available, no source is available
			return false;
		else
			return cameraInterface._isSourceAvailable(source);
	}
	
	/**
	 *  Sets an alternate camera interface (e.g. for mocking purposes)
	 **/
	public static function setCameraInterface(ciface:Camera):Void
	{
		cameraInterface = ciface;
	}
	
	private static var cameraInterface:Camera
#if iphone
		= new croxit.camera.targets.base.Camera()
#end;
	
	private function _getPicture(source:CameraSource, onResult:CameraResult->Void):Void
	{
		onResult(Error("Camera interface not available"));
	}
	
	private function _isSourceAvailable(source:CameraSource):Bool
	{
		return false;
	}
}

/**
 *  Enum representing the result status of the picture taken.
 **/
enum CameraResult
{
	/**
	 *  Successfully retrieved an image
	 **/
	Success(img:Image);
	/**
	 *  User cancelled the dialogue
	 **/
	UserCancelled;
	/**
	 *  Another confliting dialogue is currently being displayed
	 **/
	DeviceBusy;
	/**
	 *  CameraSource type is not available
	 **/
	UnavailableSource;
	/**
	 *  Custom error
	 **/
	Error(msg:String);
}