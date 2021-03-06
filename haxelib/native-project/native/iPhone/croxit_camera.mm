#ifndef STATIC_LINK
	#define IMPLEMENT_API
#endif
#include <hx/CFFI.h>

#import <UIKit/UIKit.h>
#import <UIKit/UIImage.h>
#import <Foundation/Foundation.h>

DECLARE_KIND(k_image)
DEFINE_KIND(k_image)

#define radians( degrees ) ( degrees * M_PI / 180 )

//Image handling

UIImage *img_of_value(value v)
{
	val_check_kind(v,k_image);
	return (UIImage *) val_data(v);
}

void imageFinalizer(void* abstract_object)
{ 
	NSLog(@"image finalizer");
	UIImage* img = img_of_value((value) abstract_object);
	[img release];
} 

value value_of_img(UIImage *img)
{
	value abstract_object = alloc_abstract(k_image, img);
	[img retain];
	val_gc(abstract_object, (hxFinalizer) &imageFinalizer);
	
	return abstract_object;
}

value cdis_iwidth(value aimg)
{
	UIImage *img = img_of_value(aimg);
	CGSize size = [img size];
	return alloc_float(size.width);
}

DEFINE_PRIM(cdis_iwidth, 1);

value cdis_iheight(value aimg)
{
	UIImage *img = img_of_value(aimg);
	CGSize size = [img size];
	return alloc_float(size.height);
}

DEFINE_PRIM(cdis_iheight, 1);

value cdis_i_of_file(value path)
{
	val_check(path, string);
	UIImage *img = [[UIImage alloc] initWithContentsOfFile: [NSString stringWithUTF8String:val_string(path)]];
	value ret = value_of_img(img);
	[img release];
	
	return ret;
}

DEFINE_PRIM(cdis_i_of_file, 1);

value cdis_normalize(value aimg)
{
	//modified code from PhoneGap
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	UIImage *sourceImage = img_of_value(aimg);
	float rotation_radians = 0;
	  bool perpendicular = false;
	  switch ([sourceImage imageOrientation]) {
	   case UIImageOrientationUp:
	     rotation_radians = 0.0;
	     break;
	   case UIImageOrientationDown:   
	     rotation_radians = M_PI;
	     break;
	   case UIImageOrientationRight:
	     rotation_radians = M_PI_2;
	     perpendicular = true;
	     break;
	   case UIImageOrientationLeft:
	     rotation_radians = -M_PI_2;
	     perpendicular = true;
	     break;
	   default:
	     break;
	  }

	  UIGraphicsBeginImageContext(CGSizeMake(sourceImage.size.width, sourceImage.size.height));
	  CGContextRef context = UIGraphicsGetCurrentContext();

	  //Rotate around the center point
	  CGContextTranslateCTM(context, sourceImage.size.width/2, sourceImage.size.height/2);
	  CGContextRotateCTM(context, rotation_radians);

	  CGContextScaleCTM(context, 1.0, -1.0);
	  float width = perpendicular ? sourceImage.size.height : sourceImage.size.width;
	  float height = perpendicular ? sourceImage.size.width : sourceImage.size.height;
	  CGContextDrawImage(context, CGRectMake(-width / 2, -height / 2, width, height), [sourceImage CGImage]);

	  // Move the origin back since the rotation might've change it (if its 90 degrees)
	  if (perpendicular) {
		CGContextTranslateCTM(context, -sourceImage.size.height/2, -sourceImage.size.width/2);
	  }
	  
	  UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	  UIGraphicsEndImageContext();
	  value ret = value_of_img(newImage);

	  [pool release];
	  return ret;
}

DEFINE_PRIM(cdis_normalize, 1)

value cdis_iresize(value aimg, value targetWidthv, value targetHeightv)
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	val_check(targetWidthv, float);
	val_check(targetHeightv, float);
	UIImage *sourceImage = img_of_value(aimg);
	CGFloat targetWidth = val_float(targetWidthv);
    CGFloat targetHeight = val_float(targetHeightv);
	
	CGSize targetSize = CGSizeMake(targetWidth, targetHeight);
	
    UIImage *newImage = nil;        
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);

    if (CGSizeEqualToSize(imageSize, targetSize) == NO) 
    {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;

        if (widthFactor > heightFactor) 
            scaleFactor = widthFactor; // scale to fit height
        else
            scaleFactor = heightFactor; // scale to fit width
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;

        // center the image
        if (widthFactor > heightFactor)
        {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5; 
        }
        else 
            if (widthFactor < heightFactor)
            {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
            }
    }       

    UIGraphicsBeginImageContext(targetSize); // this will crop

    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;

    [sourceImage drawInRect:thumbnailRect];

    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if(newImage == nil) 
	{
        NSLog(@"could not scale image");
	}

    //pop the context to get back to the default
    UIGraphicsEndImageContext();
	value ret = value_of_img(newImage);
	
	[pool release];
    return ret;
}

DEFINE_PRIM(cdis_iresize, 3);

value cdis_icompressed(value aimg, value type, value quality)
{
	val_check(type, int);
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	UIImage *img = img_of_value(aimg);
	NSData *data = nil;
	if (type == 0)
	{
		double qual = 100.0;
		if (val_is_float(quality))
		{
			qual = val_float(quality);
		}
		
		data = UIImageJPEGRepresentation(img, (float) qual);
	} else {
		data = UIImagePNGRepresentation(img);
	}
	
	int len = [data length];
	buffer buf = alloc_buffer_len(len / sizeof(unsigned char));
	
	char *bufdata = buffer_data(buf);
	memcpy(bufdata, (char *)[data bytes], len);
	
	[pool release];
	return buffer_val(buf);
}

DEFINE_PRIM(cdis_icompressed, 3);

value cdis_iget_orientation(value aimg)
{
	UIImage *img = img_of_value(aimg);
	switch([img imageOrientation]) {
		case UIImageOrientationUp:
			return alloc_int(0);
	    case UIImageOrientationDown:   
	      return alloc_int(1);
	    case UIImageOrientationRight:
	      return alloc_int(2);
	    case UIImageOrientationLeft:
	      return alloc_int(3);
	    default:
	      return alloc_int(-1);
	}
}

DEFINE_PRIM(cdis_iget_orientation, 1);


/////////////////// Camera //////////////////////

@interface CameraPicker : UIImagePickerController
{
@public
	AutoGCRoot *result;
	int target;
}

@property (retain) UIPopoverController* popoverController; 

- (void) dealloc;

@end

@interface CameraRequest : NSObject
	<UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate>
{
@public
	CameraPicker* pickerController;
}

@property (retain) CameraPicker* pickerController;

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker;

@end

@implementation CameraPicker

@synthesize popoverController;


- (void) dealloc
{
	if (result && result->get())
	{
		val_call2(result->get(), alloc_int(4), alloc_string("Camera Picker is being deallocated before result is ready"));
		delete result;
		result = NULL;
	}
	
	[super dealloc];
}

@end


@implementation CameraRequest

@synthesize pickerController;

-(BOOL)popoverSupported
{
	return ( NSClassFromString(@"UIPopoverController") != nil) && 
	(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	NSLog(@"didFinishPicking!");
	NSDictionary *resultInfo = info;
	if([self popoverSupported] && self.pickerController.popoverController != nil)
	{
		[self.pickerController.popoverController dismissPopoverAnimated:YES]; 
		self.pickerController.popoverController.delegate = nil;
		self.pickerController.popoverController = nil;
	}
	else 
	{
		[self.pickerController dismissModalViewControllerAnimated:YES]; 
	}
	
	value ret;
	if (!resultInfo) {
		NSLog(@"no resultInfo");
		ret = val_null;
	} else if (pickerController->target == 1) {
		NSString *path = [resultInfo objectForKey:UIImagePickerControllerMediaURL];
		NSLog(@"media url %@", path);
		
		if (!path)
			ret = val_null;
		else
			ret = alloc_string([path UTF8String]);
	} else {
		UIImage* image = [resultInfo objectForKey:UIImagePickerControllerOriginalImage];
		NSLog(@"image data is null? %d", !image);
		
		if (!image)
			ret = val_null;
		else
			ret = value_of_img(image);
	}
	
	if (pickerController->result && pickerController->result->get())
	{
		if (val_null == ret)
		{
			//user cancelled
			val_call2(pickerController->result->get(), alloc_int(1), val_null);
		} else {
			val_call2(pickerController->result->get(), alloc_int(0), ret);
		}
		delete pickerController->result;
		pickerController->result = NULL;
	}
}

- (void) dealloc
{
	if (self.pickerController) 
	{
		self.pickerController.delegate = nil;
	}
	self.pickerController = nil;
	[super dealloc];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	NSLog(@"cancelled :(");
	
	if (pickerController->result && pickerController->result->get())
	{
		val_call2(pickerController->result->get(), alloc_int(1), alloc_null());
		delete pickerController->result;
		pickerController->result = NULL;
	}
	
	[picker dismissModalViewControllerAnimated:YES];
	
	if([self popoverSupported] && self.pickerController.popoverController != nil)
	{
		self.pickerController.popoverController.delegate = nil;
		self.pickerController.popoverController = nil;
	}

	self.pickerController.delegate = nil;
	self.pickerController = nil;
}

@end

UIImagePickerControllerSourceType source_type_of_int(int v)
{
	switch(v)
	{
		case 0:
			return UIImagePickerControllerSourceTypeCamera;
		case 1:
			return UIImagePickerControllerSourceTypePhotoLibrary;
		default:
			return UIImagePickerControllerSourceTypeSavedPhotosAlbum;
	}
}

extern UIViewController *web_view_controller;
CameraRequest *global_camera_request;

value cdis_get_picture(value source, value target, value cback)
{
	val_check(source, int);
	val_check(target, int);
	val_check_function(cback, 2);
	
	UIImagePickerControllerSourceType stype = source_type_of_int(val_int(source));
	
	if (![UIImagePickerController isSourceTypeAvailable:stype])
	{
		val_call2(cback, alloc_int(3), val_null);
		return val_null;
	}
	
	if (!global_camera_request)
	{
		global_camera_request = [[CameraRequest alloc] init];
	}
	
	if (global_camera_request.pickerController == nil) 
    {
        global_camera_request.pickerController = [[[CameraPicker alloc] init] autorelease];
		global_camera_request.pickerController.delegate = global_camera_request;
    }
	
	global_camera_request.pickerController.sourceType = stype;
	if (global_camera_request.pickerController->result && global_camera_request.pickerController->result->get())
	{
		value fn = global_camera_request.pickerController->result->get();
		if (val_is_function(fn))
		{
			val_call2(fn, alloc_int(4), alloc_string("Action cancelled by new camera pick call"));
		}
		
		delete global_camera_request.pickerController->result;
		global_camera_request.pickerController->result = nil;
	}
	
	global_camera_request.pickerController->result = new AutoGCRoot(cback);
	global_camera_request.pickerController->target = val_int(target);
	
	UIWindow *window = [[UIApplication sharedApplication] keyWindow];
	UIViewController *rootViewController = window.rootViewController;
	
	if([global_camera_request popoverSupported] && stype != UIImagePickerControllerSourceTypeCamera)
	{
		if (global_camera_request.pickerController.popoverController == nil) 
		{ 
		    global_camera_request.pickerController.popoverController = [[[NSClassFromString(@"UIPopoverController") alloc] 
		                                               initWithContentViewController:global_camera_request.pickerController] autorelease];
		} 
		global_camera_request.pickerController.popoverController.delegate = global_camera_request;
		[ global_camera_request.pickerController.popoverController presentPopoverFromRect:CGRectMake(0,32,320,480)
																	inView:[rootViewController view]
																	permittedArrowDirections:UIPopoverArrowDirectionAny 
																	animated:YES]; 
	} else { 
	    [rootViewController presentModalViewController:global_camera_request.pickerController animated:YES]; 
	}
	
	return val_null;
}

DEFINE_PRIM(cdis_get_picture, 3);

value cdis_source_avail(value source)
{
	val_check(source, int);
	return alloc_bool([UIImagePickerController isSourceTypeAvailable:source_type_of_int(val_int(source))]);
}

DEFINE_PRIM(cdis_source_avail, 1);

extern "C" 
{
	
	
	int croxit_camera_register_prims() { return 0; }
	
}