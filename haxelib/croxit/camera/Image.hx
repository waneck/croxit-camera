package croxit.camera;
import croxit.camera.CameraSource;
import croxit.camera.EncodingType;
import croxit.core.Loader;
import haxe.io.Bytes;

/**
 *  Abstraction of a native Image object.
 **/
class Image
{
	public var width(get_width, null):Float;
	public var height(get_height, null):Float;
	
	private var handle:Dynamic;
	
	/**
	 *  Creates a new Image object from a path
	 **/
	public static function ofFile(path:String):Image
	{
		return new Image(_of_file(path));
	}
	
	/**
	 *  Creates a new resized Image object.
	 **/
	public function resize(newWidth:Float, newHeight:Float):Image
	{
		if (handle == null) throw "Disposed";
		return new Image(_resize(handle, newWidth, newHeight));
	}
	
	/**
	 *  Disposes image handle
	 **/
	public function dispose():Void
	{
		handle = null;
	}
	
	/**
	 *  Compresses the image using the selected encoding type
	 **/
	public function getCompressed(encoding:EncodingType):Bytes
	{
		if (handle == null) throw "Disposed";
		var type = 0;
		var quality:Null<Float> = null;
		switch(encoding)
		{
			case JPEG(qual): quality = qual;
			case PNG: type = 1;
		}
		
		var ret = _compressed(handle, type, quality);
		return Bytes.ofData(ret);
	}
	
	/**
	 *  Gets the image orientation, if specified by the host platform. 
	 *  By default, the orientation is "Up", which means that the image is in the correct orientation to be displayed.
	 **/
	public function getOrientation():ImageOrientation
	{
		if (handle == null) throw "Disposed";
		return Type.createEnumIndex(ImageOrientation, _get_orientation(handle));
	}
	
	/**
	 *  If the current orientation is different from "Up", returns a new rotated Image object.
	 *  If it is already "Up", it returns itself.
	 **/
	public function normalizeRotation():Image
	{
		return switch(getOrientation())
		{
		case OUp: new Image(this.handle);
		default: new Image(_normalize(handle));
		}
	}
	
	public static function ofHandle(handle):Image
	{
		if (handle == null) throw "Disposed";
		if (handle == null)
			return null;
		return new Image(handle);
	}
	
	private function new(handle)
	{
		this.handle = handle;
	}
	
	private function get_width() : Float
	{
		if (handle == null) throw "Disposed";
		return _get_width(handle);
	}
	
	private function get_height():Float
	{
		if (handle == null) throw "Disposed";
		return _get_height(handle);
	}
	
	private static var _get_orientation = Loader.loadExt("croxit_display", "cdis_iget_orientation", 1);
	private static var _get_width = Loader.loadExt("croxit_display", "cdis_iwidth", 1);
	private static var _get_height = Loader.loadExt("croxit_display", "cdis_iheight", 1);
	private static var _of_file = Loader.loadExt("croxit_display", "cdis_i_of_file", 1);
	private static var _resize = Loader.loadExt("croxit_display", "cdis_iresize", 3);
	private static var _compressed = Loader.loadExt("croxit_display", "cdis_icompressed", 3);
	private static var _normalize = Loader.loadExt("croxit_display", "cdis_normalize", 1);
}