package croxit.camera.targets.base;
import croxit.camera.Camera.CameraResult;
import croxit.camera.CameraSource;
import croxit.camera.Image;
import croxit.core.Loader;

class Camera extends croxit.camera.Camera
{
	public function new()
	{
		
	}
	
	override private function _getPicture(source:CameraSource, onResult:CameraResult->Void):Void
	{
		_get_picture(Type.enumIndex(source), 0, function(res:Int, hnd:Dynamic) {
			var res = switch(res)
			{
			case 0: if (hnd == null) Error("hnd == null"); else Success(Image.ofHandle(hnd));
			case 1: UserCancelled;
			case 2: DeviceBusy;
			case 3: UnavailableSource;
			case 4: Error(hnd);
			default: Error("Invalid result number " + res);
			};
			
			onResult(res);
		});
	}
	
	override private function _isSourceAvailable(source:CameraSource):Bool
	{
		return _source_avail(Type.enumIndex(source));
	}
	
	static var _get_picture:Dynamic = Loader.loadExt("croxit_display", "cdis_get_picture", 3);
	static var _source_avail:Dynamic = Loader.loadExt("croxit_display", "cdis_source_avail", 1);
}