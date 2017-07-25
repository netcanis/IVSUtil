//
//  IVSUtil.h
//  Pods
//
//  Created by netcanis on 25/07/2017.
//
//

#import <Foundation/Foundation.h>

// angles in drawing are in radians, where pi radians = 180 degrees
#define DEG2RAD(x)      (M_PI * (x) / 180.0)
#define RAD2DEG(x)      ((x) * 180.0 / M_PI)


@interface IVSUtil : NSObject


+ (NSString *)uniqueId:(NSString *)accessGroup;

+ (NSString *)cutFileName:(NSString *)url;

+ (NSString *)cutFileName2:(NSString *)url;

+ (NSString *)cutFileExt:(NSString *)url;

+ (NSString *)urlEncode:(NSString *)str;

+ (NSString *)urlDecode:(NSString *)str;

+ (NSURL*)makeURL:(NSString *)url parameters:(NSDictionary *)parameters;

+ (NSMutableDictionary *)parseURL:(NSURL *)url;

+ (NSMutableDictionary *)parseURLStr:(NSString *)urlStr;

+ (NSURL *)utf8URL:(NSString *)url;

+ (NSMutableDictionary *)parseAction:(NSString *)actionStr;

+ (void)writeDataToFile:(NSString *)path withData:(NSData *)data;

+ (void)writeJsonDataToFile:(NSString *)path withData:(NSData*)data;

+ (void)writeStringToFile:(NSString *)path withString:(NSString *)aString;

+ (NSString *)readStringFromFile:(NSString *)path;

+ (NSString *)data2JsonString:(NSData *)data;

+ (NSTimeInterval)getElapsedTime:(NSDate *)startTime;

+ (NSString *)utf8toNString:(NSString *)str;

+ (NSString *)contentTypeForImageData:(NSData *)data;

+ (NSString *)dic2Json:(NSMutableDictionary *)dic;

+ (NSMutableDictionary *)json2Dic:(NSString *)jsonString;

+ (NSString *)arr2Json:(NSMutableArray *)arr;

+ (NSMutableArray *)json2Arr:(NSString *)jsonString;

+ (NSString *)subStringFrom:(NSString *)str sep:(NSString *)sep;

+ (NSString *)subStringTo:(NSString *)str sep:(NSString *)sep;

+ (NSMutableArray *)splitString:(NSString *)str index:(NSInteger)index isBackward:(BOOL)isBackward;

+ (CGSize)statusBarSize;

+ (CGSize)screenSize;

+ (CGSize)screenPercentage:(CGFloat)p;

+ (CGFloat)fontPixelToPoint:(int)pixelSize;

+ (UIImage *)roundCornersOfImageOptimized:(UIImage *)image;

+ (UIImage *)roundCornersOfImage:(UIImage *)image radius:(CGFloat)radius size:(CGSize)size;

+ (UIImage *)resizeImagePercentage:(UIImage *)image percentage:(int)percentage;

+ (UIImage *)resizeImage:(UIImage *)image size:(CGSize)size mode:(UIViewContentMode)contentMode;

+ (UIImage *)imageToGrayScale:(UIImage *)image;

+ (void)beginCurveAnimation:(float)duration;

+ (void)commitCurveAnimation;

+ (NSString *)stringFromRect:(CGRect)r;

+ (BOOL)isRetina;

+ (UIImage *)rotateImageByDegrees:(UIImage *)image degrees:(CGFloat)degrees;

+ (UIImage *)rotateImageByRadians:(UIImage *)image radians:(CGFloat)radians;

+ (NSString *)getFolderPath:(NSString *)fullPath;

+ (BOOL) checkingURLExists:(NSString *)url;

+ (void)removeWebChche;

+ (void)shareData:(id)vc title:(NSString *)strTitle param:(NSMutableArray *)items;

+ (void)saveImagesToAlbum:(NSMutableArray *)images;

+ (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;


@end
