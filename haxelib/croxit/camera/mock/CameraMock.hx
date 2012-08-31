package croxit.camera.mock;
import croxit.camera.Camera;
import croxit.camera.CameraSource;
import croxit.camera.Image;

/**
 *  In order to make application and functionality testing easier, specially for testing on the web,
 *  you can create your own mock interface to replace the default camera behaviour
 **/
class CameraMock extends Camera
{
	public function new()
	{
		
	}
	
	public function getPicture(source:CameraSource, onResult:Null<Image>->Void):Void
	{
		//default mocking behaviour is that user fails every time
		onResult(null);
	}
	
	public function isSourceAvailable(source:CameraSource):Bool
	{
		return false;
	}
}