//
// UIImage+Editor.h
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

#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import "UIImage+Resize.h"
#import "UIImage+RoundedCorner.h"
#import "UIImage+Alpha.h"

CGFloat degreesToRadians (CGFloat degrees);
CGFloat radiansToDegrees (CGFloat radians);

@interface UIImage (Editor)

// resize to a specified (width, height) size. Can be used for stretching.
- (UIImage *) resizedToSize: (CGSize) size;
// resize to a specified ratio (ratio must not be 0)
- (UIImage *) resizedByRatio: (CGFloat) ratio;
// crop a specified rect from the middle of the image
- (UIImage *) croppedToRect: (CGRect) rect;
// generate a rounded corner image by adjusting the corner arcs' alpha
- (UIImage *) withBorderRadius: (CGFloat) radius;
// draw a string to the specified string at a given point, with a given font and color
- (UIImage *) addText: (NSString *) str atPoint: (CGPoint) point withFont: (UIFont *) font ofColor: (UIColor *) color;
// return a grayscale copy of the image
- (UIImage *) grayscaled;
// return a transparent copy of the image
- (UIImage *) withAlpha: (CGFloat) alpha;
// return a rotated copy of the image. Specify rotation angle in degrees. Use radiansToDegrees() to convert radians to degrees.
- (UIImage *) rotatedByDegrees: (CGFloat) degrees;
@end

