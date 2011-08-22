//
// UIImage+Editor.m
// Originally created for MyFile
//
// UIImage+Editor is licensed under a Creative Commons Attribution-NonCommercial 3.0 Unported License.
// As attribution, I just require that you mention my name in conjunction
// with this library, and that your application can reproduce this legal notice.
// For details, see: http://creativecommons.org/licenses/
//
// Although this library was written in the hope that it will be useful,
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR 'AS IS', THUS
// THERE IS NO WARRANTY AT ALL, NEITHER EXPRESSED OR IMPLIED, NOT EVEN
// FOR MERCHANTABILITY OR FITTNESS FOR A PARTICUALR PURPOSE. I (THE AUTHOR) AM NOT RESPONSIBLE
// FOR ANY DAMAGE, DATA LOSS OR ANY OTHER TYPES OF UNEXPECTED AND/OR BAD RESULTS
// IN CONNECTION OF THIS SOFTWARE.
//
// Created by Árpád Goretity, 2011.
//

#import "UIImage+Editor.h"

// convert degrees to radians
CGFloat degreesToRadians (CGFloat degrees) {
	return (degrees / 180.0) * M_PI;
}

// convert radians to degrees
CGFloat radiansToDegrees (CGFloat radians) {
	return (radians / M_PI) * 180.0;
}

@implementation UIImage (Editor)

- (UIImage *) resizedToSize: (CGSize) size {
	return [self resizedImage: size interpolationQuality: kCGInterpolationHigh];
}

- (UIImage *) resizedByRatio: (CGFloat) ratio {
	CGSize newSize = CGSizeMake (self.size.width * ratio, self.size.height * ratio);
	return [self resizedToSize: newSize];
}

- (UIImage *) croppedToRect: (CGRect) rect {
	return [self croppedImage: rect];
}

- (UIImage *) withBorderRadius: (CGFloat) radius {
	return [self roundedCornerImage: round (radius) borderSize: 0];
}

- (UIImage *) addText: (NSString *) str atPoint: (CGPoint) point withFont: (UIFont *) font ofColor: (UIColor *) color {

	int w = self.size.width;
	int h = self.size.height;

	// create empty bitmap context
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB ();
	CGContextRef ctx = CGBitmapContextCreate (NULL, w, h, 8, w * 4, colorSpace, kCGImageAlphaPremultipliedFirst);
	CGContextSetInterpolationQuality (ctx, kCGInterpolationHigh);
	CGAffineTransform transform = [self transformForOrientation: self.size];
	CGContextConcatCTM (ctx, transform);
	CGContextSetTextMatrix (ctx, CGAffineTransformInvert (transform));
	BOOL transposed;
	switch (self.imageOrientation) {

		case UIImageOrientationLeft:
		case UIImageOrientationLeftMirrored:
		case UIImageOrientationRight:
		case UIImageOrientationRightMirrored:
			transposed = YES;
			break;

		default:
			transposed = NO;
			break;

	}

	// draw the image and the text on the bitmap context
	CGContextDrawImage (ctx, transposed ? CGRectMake (0, 0, h, w) : CGRectMake (0, 0, w, h), [self CGImage]);
	char *text = (char *)[str cStringUsingEncoding: NSASCIIStringEncoding];
	CGContextSetTextDrawingMode (ctx, kCGTextFill);
	CGFloat *comp = CGColorGetComponents ([color CGColor]);
	CGContextSetRGBFillColor (ctx, comp[0], comp[1], comp[2], comp[3]);
	CGContextSelectFont (ctx, [[font fontName] UTF8String], [font pointSize], kCGEncodingMacRoman);
	CGContextShowTextAtPoint (ctx, point.x, h - point.y, text, strlen (text));

	// get the image as a UIImage and clean up
	CGImageRef imageMasked = CGBitmapContextCreateImage (ctx);
	UIImage *img = [UIImage imageWithCGImage: imageMasked];
	CGContextRelease (ctx);
	CGImageRelease (imageMasked);
	CGColorSpaceRelease (colorSpace);

	return img;
	
}

- (UIImage *) grayscaled {

	// ARGB byte index constants (within a pixel represented by 4 bytes)
	const uint8_t ALPHA = 0;
	const uint8_t BLUE = 1;
	const uint8_t GREEN = 2;
	const uint8_t RED = 3;

	// create an empty ARGB image
	CGSize size = self.size;
	int width = size.width;
	int height = size.height;
	uint32_t *pixels = (uint32_t *) malloc (width * height * sizeof (uint32_t));
	// memset all pixels to (0, 0, 0, 0) to preserve transparency if existed
	memset (pixels, 0, width * height * sizeof (uint32_t));
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB ();
	CGContextRef context = CGBitmapContextCreate (pixels, width, height, 8, width * sizeof (uint32_t), colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
	// draw the image on the bitmap context
	CGContextDrawImage (context, CGRectMake (0, 0, width, height), [self CGImage]);
	
	for (int y = 0; y < height; y++) {
		for (int x = 0; x < width; x++) {
			uint8_t *rgbaPixel = (uint8_t *) &pixels[y * width + x];
			// convert to grayscale using recommended weighting method: http://en.wikipedia.org/wiki/Grayscale#Converting_color_to_grayscale
			uint32_t gray = 0.3 * rgbaPixel[RED] + 0.59 * rgbaPixel[GREEN] + 0.11 * rgbaPixel[BLUE];
			rgbaPixel[RED] = gray;
			rgbaPixel[GREEN] = gray;
			rgbaPixel[BLUE] = gray;
		}
	}
	
	// get image and clean up
	CGImageRef image = CGBitmapContextCreateImage (context);
	CGContextRelease (context);
	CGColorSpaceRelease (colorSpace);
	free (pixels);
	UIImage *resultUIImage = [UIImage imageWithCGImage: image];
	CGImageRelease (image);

	return resultUIImage;
	
}

- (UIImage *) withAlpha: (CGFloat) alpha {

	int w = self.size.width;
	int h = self.size.height;

	// create empty ARGB image
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB ();
	CGContextRef ctx = CGBitmapContextCreate (NULL, w, h, 8, w * 4, colorSpace, kCGImageAlphaPremultipliedFirst);
	// leave the image in its original quality
	CGContextSetInterpolationQuality (ctx, kCGInterpolationHigh);
	CGAffineTransform transform = [self transformForOrientation: self.size];
	CGContextConcatCTM (ctx, transform);
	// actually adjust transparency factor
	CGContextSetAlpha (ctx, alpha);

	BOOL transposed;

	// adjust stretch ratio according to orientation
	switch (self.imageOrientation) {

		case UIImageOrientationLeft:
		case UIImageOrientationLeftMirrored:
		case UIImageOrientationRight:
		case UIImageOrientationRightMirrored:
			transposed = YES;
			break;

		default:
			transposed = NO;
			break;

	}

	// draw the modified image on the bitmap context
	CGContextDrawImage (ctx, transposed ? CGRectMake (0, 0, h, w) : CGRectMake (0, 0, w, h), [self CGImage]);
	CGImageRef imageMasked = CGBitmapContextCreateImage (ctx);
	// get it as a UIImage from the context
	UIImage *img = [UIImage imageWithCGImage: imageMasked];
	// clean up
	CGContextRelease (ctx);
	CGImageRelease (imageMasked);
	CGColorSpaceRelease (colorSpace);

	return img;

}

- (UIImage *) rotatedByDegrees: (CGFloat) degrees {   

	// calculate the size of the rotated view's containing box for our drawing space
	UIView *rotatedViewBox = [[UIView alloc] initWithFrame: CGRectMake (0, 0, self.size.width, self.size.height)];
	CGAffineTransform t = CGAffineTransformMakeRotation (degreesToRadians (degrees));
	rotatedViewBox.transform = t;
	CGSize rotatedSize = rotatedViewBox.frame.size;
	[rotatedViewBox release];
	// Create the bitmap context
	UIGraphicsBeginImageContext (rotatedSize);
	CGContextRef bitmap = UIGraphicsGetCurrentContext ();
	// Move the origin to the middle of the image so we will rotate and scale around the center.
	CGContextTranslateCTM (bitmap, rotatedSize.width / 2, rotatedSize.height / 2);
	// Rotate the image context
	CGContextRotateCTM (bitmap, degreesToRadians (degrees));
	// Now, draw the rotated/scaled image into the context
	CGContextScaleCTM (bitmap, 1.0, -1.0);
	CGContextDrawImage (bitmap, CGRectMake (-self.size.width / 2, -self.size.height / 2, self.size.width, self.size.height), [self CGImage]);
   	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	return newImage;
   
}

@end

