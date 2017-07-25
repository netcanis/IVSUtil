//
//  IVSUtil.m
//  Pods
//
//  Created by Sung Hwan Cho on 25/07/2017.
//
//

#import "IVSUtil.h"
#import "KeychainItemWrapper.h"
#import <WebKit/WebKit.h>
#include <sys/types.h>
#include <sys/sysctl.h>

@implementation IVSUtil


#pragma mark -
#pragma mark - Device Infomation

+ (NSString *)appName {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
}

+ (NSString *)bundleVersion
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

+ (NSString *)shortVersion
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

+ (float)iosVersion {
    return [[[UIDevice currentDevice] systemVersion] floatValue];
}

+ (NSString *)deviceModel {
    return [[UIDevice currentDevice] model];
}

+ (NSString *)bundleId
{
    return [[NSBundle mainBundle] bundleIdentifier];
}

+ (NSString *)platform {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    free(machine);
    return platform;
}

+ (NSString *)docDir {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

+ (NSString *)docPath:(NSString *)fname {
    return [[IVSUtil docDir] stringByAppendingPathComponent:fname];
}

+ (NSString *)resDir {
    return [[NSBundle mainBundle] resourcePath];
}

+ (NSString *)resPath:(NSString *)fname {
    return [[IVSUtil resDir] stringByAppendingPathComponent:fname];
}

+ (NSString *)cachesDir {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}




#pragma mark -
#pragma mark - Checking

+ (BOOL)IsEmpty:(id)obj
{
    return (nil == obj)
    || ([obj isKindOfClass:[NSNull class]])
    || ([obj respondsToSelector:@selector(length)] && ![obj respondsToSelector:@selector(count)] && [(NSData *)obj length] == 0)
    || ([obj respondsToSelector:@selector(count)]  &&  [obj count] == 0);
}

+ (BOOL)isEnabledPush
{
    UIUserNotificationSettings *ns = [[UIApplication sharedApplication] currentUserNotificationSettings];
    if (UIUserNotificationTypeNone == [ns types]){
        return NO;
    } else {
        return YES;
    }
}

+ (BOOL)needUpdate:(NSString *)version
{
    if (nil == version || YES == [version isEqualToString:@""]){
        return NO;
    }
    
    NSArray *serverVerArr = [version componentsSeparatedByString: @"."];
    NSArray *nativeVerArr  = [[self shortVersion] componentsSeparatedByString: @"."];
    
    NSInteger count = MAX([serverVerArr count], [nativeVerArr count]);
    for (int index = 0; index < count; ++index){
        NSInteger sn = 0;
        NSInteger nn = 0;
        
        if (index >= [serverVerArr count]){
            sn = 0;
        } else {
            NSString *snStr = [serverVerArr objectAtIndex:index];
            sn = [snStr integerValue];
        }
        if (index >= [nativeVerArr count]){
            nn = 0;
        } else {
            NSString *nnStr = [nativeVerArr objectAtIndex:index];
            nn = [nnStr integerValue];
        }
        
        if (sn == nn){
            continue;
        } else if (sn > nn){
            return YES;
        } else {
            break;
        }
    }
    
    return NO;
}




#pragma mark -
#pragma mark - Converting

+ (NSString *)uniqueId:(NSString *)accessGroup
{
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:[IVSUtil bundleId]
                                                                       accessGroup:accessGroup];
    
    NSString *uuid = [wrapper objectForKey:(__bridge id)(kSecAttrAccount)];
    if (nil == uuid || 0 == uuid.length) {
        CFUUIDRef uuidRef = CFUUIDCreate(NULL);
        CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
        CFRelease(uuidRef);
        uuid = [NSString stringWithString:(__bridge NSString *)uuidStringRef];
        CFRelease(uuidStringRef);
        [wrapper setObject:uuid forKey:(__bridge id)(kSecAttrAccount)];
    }
    return uuid;
}

+ (NSString *)cutFileName:(NSString *)url {
    return [[url lastPathComponent] stringByDeletingPathExtension];
}

+ (NSString *)cutFileName2:(NSString *)url {
    NSArray *parts = [url componentsSeparatedByString:@"/"];
    return [parts lastObject];
}

+ (NSString *)cutFileExt:(NSString *)url {
    return [[url lastPathComponent] pathExtension];
}

+ (NSString *)urlEncode:(NSString *)str {
    return [str stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

+ (NSString *)urlDecode:(NSString *)str {
    return [str stringByRemovingPercentEncoding];
}

+ (NSURL*)makeURL:(NSString *)url parameters:(NSDictionary *)parameters {
    NSURLComponents *components = [NSURLComponents componentsWithString:url];
    NSMutableArray *queryItems = [NSMutableArray array];
    for (NSString *key in parameters){
        [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:parameters[key]]];
    }
    components.queryItems = queryItems;
    return components.URL;
}

+ (NSMutableDictionary *)parseURL:(NSURL *)url {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:false];
    for (NSURLQueryItem *item in urlComponents.queryItems){
        if (nil != item.value) {
            [dict setObject:item.value forKey:item.name];
        }
    }
    return dict;
}

+ (NSMutableDictionary *)parseURLStr:(NSString *)urlStr {
    return [IVSUtil parseURL:[NSURL URLWithString:urlStr]];
}

+ (NSURL *)utf8URL:(NSString *)url {
    NSCharacterSet *allowedCharacterSet = [NSCharacterSet URLQueryAllowedCharacterSet];
    return [NSURL URLWithString:[url stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet]];
}

+ (NSMutableDictionary *)parseAction:(NSString *)actionStr {
    NSString *urlStr = [actionStr stringByReplacingOccurrencesOfString:@"app_cmd>action"
                                                            withString:@"app_cmd?app_cmd_action"];
    NSMutableDictionary *dict = [IVSUtil parseURL:[NSURL URLWithString:urlStr]];
    NSString *value = [[NSString alloc] initWithString:[dict objectForKey:@"app_cmd_action"]];
    [dict setObject:value forKey:@"app_cmd>action"];
    [dict removeObjectForKey:@"app_cmd_action"];
    return dict;
}

+ (void)writeDataToFile:(NSString *)path withData:(NSData *)data
{
    NSString *folderPath = [IVSUtil getFolderPath:path];
    if (NO == [[NSFileManager defaultManager] fileExistsAtPath:folderPath]) {
        NSError *error = nil;
        NSDictionary *attr = [NSDictionary dictionaryWithObject:NSFileProtectionComplete
                                                         forKey:NSFileProtectionKey];
        [[NSFileManager defaultManager] createDirectoryAtPath:folderPath
                                  withIntermediateDirectories:YES
                                                   attributes:attr
                                                        error:&error];
        if (error) {
            NSLog(@"Error creating directory path: %@", [error localizedDescription]);
        }
    }
    
    [data writeToFile:path atomically:YES];
}

+ (void)writeJsonDataToFile:(NSString *)path withData:(NSData*)data
{
    NSString *resultString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:data
                                                                                            options:NSJSONWritingPrettyPrinted
                                                                                              error:nil]
                                                   encoding:NSUTF8StringEncoding];
    [IVSUtil writeStringToFile:path withString:resultString];
}

+ (void)writeStringToFile:(NSString *)path withString:(NSString *)aString
{
    NSString *folderPath = [IVSUtil getFolderPath:path];
    if (NO == [[NSFileManager defaultManager] fileExistsAtPath:folderPath]) {
        NSError *error = nil;
        NSDictionary *attr = [NSDictionary dictionaryWithObject:NSFileProtectionComplete
                                                         forKey:NSFileProtectionKey];
        [[NSFileManager defaultManager] createDirectoryAtPath:folderPath
                                  withIntermediateDirectories:YES
                                                   attributes:attr
                                                        error:&error];
        if (error) {
            NSLog(@"Error creating directory path: %@", [error localizedDescription]);
        }
    }
    
    [[aString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:path atomically:NO];
}

+ (NSString *)readStringFromFile:(NSString *)path
{
    NSData *data = [NSData dataWithContentsOfFile:path];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (NSString *)data2JsonString:(NSData *)data {
    NSString *resultString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:data
                                                                                            options:NSJSONWritingPrettyPrinted
                                                                                              error:nil]
                                                   encoding:NSUTF8StringEncoding];
    return resultString;
}

+ (NSTimeInterval)getElapsedTime:(NSDate *)startTime
{
    NSTimeInterval seconds = -[startTime timeIntervalSinceNow];
    return seconds;
}

+ (NSString *)utf8toNString:(NSString *)str {
    NSString* strT= [str stringByReplacingOccurrencesOfString:@"\\U" withString:@"\\u"];
    CFStringRef transform = CFSTR("Any-Hex/Java");
    CFStringTransform((__bridge CFMutableStringRef)strT, NULL, transform, YES);
    return strT;
}

+ (NSString *)contentTypeForImageData:(NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];
    
    switch (c) {
        case 0xFF:
            return @"image/jpeg";
        case 0x89:
            return @"image/png";
        case 0x47:
            return @"image/gif";
        case 0x49:
        case 0x4D:
            return @"image/tiff";
    }
    return nil;
}

+ (NSString *)dic2Json:(NSMutableDictionary *)dic
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}

+ (NSMutableDictionary *)json2Dic:(NSString *)jsonString
{
    NSError *error;
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&error];
    return dic;
}

+ (NSString *)arr2Json:(NSMutableArray *)arr
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:arr options:0 error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}

+ (NSMutableArray *)json2Arr:(NSString *)jsonString
{
    NSError *error;
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableArray *arr = [NSJSONSerialization JSONObjectWithData:jsonData
                                                          options:NSJSONReadingMutableContainers
                                                            error:&error];
    return arr;
}

+ (NSString *)subStringFrom:(NSString *)str sep:(NSString *)sep
{
    NSRange range = [str rangeOfString:sep];
    if (NSNotFound != range.location)
    {
        return [str substringFromIndex:range.location+range.length];
    } else {
        return @"";
    }
    return nil;
}

+ (NSString *)subStringTo:(NSString *)str sep:(NSString *)sep
{
    NSRange range = [str rangeOfString:sep];
    if (NSNotFound != range.location)
    {
        return [str substringToIndex:range.location];
    } else {
        return str;
    }
    return nil;
}

+ (NSMutableArray *)splitString:(NSString *)str index:(NSInteger)index isBackward:(BOOL)isBackward
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSInteger pos = (YES == isBackward) ? ([str length]-index) : index;
    
    [array addObject:[str substringToIndex:pos]];
    [array addObject:[str substringFromIndex:pos]];
    return array;
}



#pragma mark -
#pragma mark Graphics Utility
+ (CGSize)statusBarSize {
    return [[UIApplication sharedApplication] statusBarFrame].size;
}

+ (CGSize)screenSize {
    return [UIScreen mainScreen].bounds.size;
}

+ (CGSize)screenPercentage:(CGFloat)p {
    CGSize ss = [IVSUtil screenSize];
    ss.width = nearbyint(ss.width * p);
    ss.height = nearbyint(ss.height * p);
    
    return ss;
}

+ (CGFloat)fontPixelToPoint:(int)pixelSize
{
    return pixelSize / 2.2639;
}


#pragma mark -
#pragma mark - Image Processing

static BOOL optRoundedInit = NO;
static CGSize roundSize;
static CGFloat roundRadius, roundMinX, roundMinY, roundMaxX, roundMaxY;
static CGFloat angle0, angle90, angle180, angle270, angle360;
static CGRect roundDrawingRect, roundInteriorRect;
static CGMutablePathRef roundClippingPath;

+ (UIImage *)roundCornersOfImageOptimized:(UIImage *)image {
    // Single time optimization, bool comparison is the fastest thing a CPU can do,
    // no worries about perf here
    if( !optRoundedInit ) {
        roundSize = CGSizeMake(90.f, 90.f);
        roundRadius = MIN(12.f, .5f * MIN(roundSize.width, roundSize.height) );
        
        // it's not that the "interior rect" makes any sense by itself; it's just used
        // to determine the coordinates of the straight parts of the rounded rect
        //
        roundDrawingRect = CGRectMake( 0.0f, 0.0f, roundSize.width, roundSize.height );
        roundInteriorRect = CGRectInset( roundDrawingRect, roundRadius, roundRadius );
        
        roundMinX = CGRectGetMinX( roundInteriorRect );
        roundMinY = CGRectGetMinY( roundInteriorRect );
        roundMaxX = CGRectGetMaxX( roundInteriorRect );
        roundMaxY = CGRectGetMaxY( roundInteriorRect );
        
        angle0   = DEG2RAD( 0.0 );
        angle90  = DEG2RAD( 90.0 );
        angle180 = DEG2RAD( 180.0 );
        angle270 = DEG2RAD( 270.0 );
        angle360 = DEG2RAD( 360.0 );
        
        // we're not using a transformation of the coordinate system
        const CGAffineTransform * noTransform = NULL;
        
        // drawing will be counterclockwise
        const bool counterclockwise = NO;  //NO means counterclockwise; YES means clockwise
        
        // if the button size and rounded-corner radius are going to be constant,
        // this block (and its setup) could conceivably be moved to -viewDidLoad,
        // with clippingPath being an instance variable.
        //
        roundClippingPath = CGPathCreateMutable();
        CGPathAddArc( roundClippingPath, noTransform, roundMaxX, roundMaxY, roundRadius, angle0,   angle90,  counterclockwise );
        CGPathAddArc( roundClippingPath, noTransform, roundMinX, roundMaxY, roundRadius, angle90,  angle180, counterclockwise );
        CGPathAddArc( roundClippingPath, noTransform, roundMinX, roundMinY, roundRadius, angle180, angle270, counterclockwise );
        CGPathAddArc( roundClippingPath, noTransform, roundMaxX, roundMinY, roundRadius, angle270, angle360, counterclockwise );
        
        // Warning! clippingPath is never dealloced!
        
        optRoundedInit = YES;
    }
    
    // all actual drawing takes place in a drawing context.
    // Since have haven't gone through -drawRect: at this stage, we have to create a context ourselves.
    UIGraphicsBeginImageContext( roundSize );
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // all the setup is done; now define the clipping path
    CGContextBeginPath( context );
    CGContextAddPath( context, roundClippingPath );
    CGContextClosePath( context );
    CGContextClip( context );
    
    // ...and draw our image, clipping the corners
    [image drawInRect: roundDrawingRect];
    
    // get the result as an autoreleased image
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // we're done with our image context
    UIGraphicsEndImageContext();
    
    // and return the autoreleased image to the caller
    return resultImage;
}

+ (UIImage *)roundCornersOfImage:(UIImage *)image radius:(CGFloat)radius size:(CGSize)size {
    // account for a passed-in radius that is too large to work with the size
    radius = MIN(radius, .5 * MIN(size.width, size.height) );
    
    // it's not that the "interior rect" makes any sense by itself; it's just used
    // to determine the coordinates of the straight parts of the rounded rect
    //
    CGRect drawingRect = CGRectMake( 0.0f, 0.0f, size.width, size.height );
    CGRect interiorRect = CGRectInset( drawingRect, radius, radius );
    
    CGFloat minX = CGRectGetMinX( interiorRect );
    CGFloat minY = CGRectGetMinY( interiorRect );
    CGFloat maxX = CGRectGetMaxX( interiorRect );
    CGFloat maxY = CGRectGetMaxY( interiorRect );
    
    CGFloat angle0   = DEG2RAD( 0.0 );
    CGFloat angle90  = DEG2RAD( 90.0 );
    CGFloat angle180 = DEG2RAD( 180.0 );
    CGFloat angle270 = DEG2RAD( 270.0 );
    CGFloat angle360 = DEG2RAD( 360.0 );
    
    // we're not using a transformation of the coordinate system
    const CGAffineTransform * noTransform = NULL;
    
    // drawing will be counterclockwise
    const bool counterclockwise = NO;  //NO means counterclockwise; YES means clockwise
    
    // if the button size and rounded-corner radius are going to be constant,
    // this block (and its setup) could conceivably be moved to -viewDidLoad,
    // with clippingPath being an instance variable.
    //
    CGMutablePathRef clippingPath = CGPathCreateMutable();
    CGPathAddArc( clippingPath, noTransform, maxX, maxY, radius, angle0,   angle90,  counterclockwise );
    CGPathAddArc( clippingPath, noTransform, minX, maxY, radius, angle90,  angle180, counterclockwise );
    CGPathAddArc( clippingPath, noTransform, minX, minY, radius, angle180, angle270, counterclockwise );
    CGPathAddArc( clippingPath, noTransform, maxX, minY, radius, angle270, angle360, counterclockwise );
    
    // all actual drawing takes place in a drawing context.
    // Since have haven't gone through -drawRect: at this stage, we have to create a context ourselves.
    UIGraphicsBeginImageContext( size );
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // all the setup is done; now define the clipping path
    CGContextBeginPath( context );
    CGContextAddPath( context, clippingPath );
    CGContextClosePath( context );
    CGContextClip( context );
    
    // ...and draw our image, clipping the corners
    [image drawInRect: drawingRect];
    
    // get the result as an autoreleased image
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // release the memory for our clipping path (but move to -dealloc if clippingPath
    // is changed to be an instance variable and its definition is moved to -viewDidLoad)
    CFRelease( clippingPath );
    
    // we're done with our image context
    UIGraphicsEndImageContext();
    
    // and return the autoreleased image to the caller
    return resultImage;
}

+ (UIImage *)resizeImagePercentage:(UIImage *)image percentage:(int)percentage {
    CGSize s = [image size];
    float p = (float)percentage / 100.f;
    s.width *= p;
    s.height *= p;
    
    return [IVSUtil resizeImage:image size:s mode:UIViewContentModeScaleToFill];
}

+ (UIImage *)resizeImage:(UIImage *)image size:(CGSize)size mode:(UIViewContentMode)contentMode {
    if( contentMode == UIViewContentModeScaleToFill ) {
        // Do nothing
    } else if( contentMode == UIViewContentModeScaleAspectFit )	{
        CGFloat relationWidth = size.width / [image size].width;
        CGFloat relationHeight = size.height / [image size].height;
        CGFloat relation = ( relationWidth < relationHeight ) ? relationWidth : relationHeight;
        size = CGSizeMake([image size].width * relation, [image size].height * relation);
    } else {
        NSLog(@"resizeImage: UIViewContentMode not supported.");
    }
    
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *scaledImage = [UIImage imageWithCGImage:[UIGraphicsGetImageFromCurrentImageContext() CGImage]];	// Hope this is not the slowest thing in the world... :)
    //UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext(); // Autoreleased
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

+ (UIImage *)imageToGrayScale:(UIImage *)image {
    uint8_t kBlue = 1, kGreen = 2, kRed = 3;
    
    CGSize size = image.size;
    int width = size.width;
    int height = size.height;
    
    // the pixels will be painted to this array
    uint32_t *pixels = (uint32_t *)malloc(width * height * sizeof(uint32_t));
    
    // clear the pixels so any transparency is preserved
    memset(pixels, 0, width * height * sizeof(uint32_t));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // create a context with RGBA pixels
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * sizeof(uint32_t), colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
    
    // paint the bitmap to our context which will fill in the pixels array
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [image CGImage]);
    
    for( int y = 0; y < height; y++ )
    {
        for( int x = 0; x < width; x++ )
        {
            uint8_t *rgbaPixel = (uint8_t *)&pixels[y * width + x];
            
            // convert to grayscale using recommended method: http://en.wikipedia.org/wiki/Grayscale#Converting_color_to_grayscale
            uint32_t gray = 0.3 * rgbaPixel[kRed] + 0.59 * rgbaPixel[kGreen] + 0.11 * rgbaPixel[kBlue];
            
            // set the pixels to gray
            rgbaPixel[kRed] = gray;
            rgbaPixel[kGreen] = gray;
            rgbaPixel[kBlue] = gray;
        }
    }
    
    // create a new CGImageRef from our context with the modified pixels
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    
    // we're done with the context, color space, and pixels
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(pixels);
    
    // make a new UIImage to return
    UIImage *resultUIImage = [UIImage imageWithCGImage:imageRef];
    
    // we're done with image now too
    CGImageRelease(imageRef);
    
    return resultUIImage;
}

+ (void)beginCurveAnimation:(float)duration {
    [UIView beginAnimations:nil context:UIGraphicsGetCurrentContext()];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:duration];
}

+ (void)commitCurveAnimation {
    [UIView commitAnimations];
}

+ (NSString *)stringFromRect:(CGRect)r {
    return [NSString stringWithFormat:@"%f, %f, %f, %f", r.origin.x, r.origin.y, r.size.width, r.size.height];
}

+ (BOOL)isRetina {
    return [[UIScreen mainScreen] respondsToSelector:@selector(scale)] && ([[UIScreen mainScreen] scale] > 1.f);
}

+ (UIImage *)rotateImageByDegrees:(UIImage *)image degrees:(CGFloat)degrees {
    // Create the bitmap context
    CGSize size = CGSizeMake(image.size.width *image.scale, image.size.height *image.scale);
    UIGraphicsBeginImageContext(size);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, size.width/2, size.height/2);
    
    // Rotate the image context
    CGContextRotateCTM(bitmap, DEG2RAD(degrees));
    
    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-size.width / 2, -size.height / 2, size.width, size.height), [image CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (UIImage *)rotateImageByRadians:(UIImage *)image radians:(CGFloat)radians {
    return [IVSUtil rotateImageByDegrees:image degrees:RAD2DEG(radians)];
}

+ (NSString *)getFolderPath:(NSString *)fullPath {
    NSRange range = [fullPath rangeOfString:@"/" options:NSBackwardsSearch];
    if (NSNotFound != range.location) {
        return [fullPath substringToIndex:range.location];
    } else {
        return fullPath;
    }
}




#pragma mark -
#pragma mark - Network
+ (BOOL) checkingURLExists:(NSString *)url {
    __block BOOL result = YES;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]
                                             cachePolicy:NSURLRequestReloadIgnoringCacheData
                                         timeoutInterval:30.0f];
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request
                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                         if (nil != error) {// Error
                                             NSLog(@"Error (%zd) : %@", [error code], [error userInfo]);
                                             result = NO;
                                         } else {// Success
                                             NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
                                             if([resp statusCode] == 404) {
                                                 result = NO;
                                             } else {
                                                 result = YES;
                                             }
                                         }
                                         dispatch_semaphore_signal(sem);
                                     }] resume];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return result;
}

+ (void)removeWebChche
{
    // for WKWebView
    NSSet *websiteDataTypes = [NSSet setWithArray:@[
                                                    WKWebsiteDataTypeDiskCache,
                                                    //WKWebsiteDataTypeOfflineWebApplicationCache,
                                                    WKWebsiteDataTypeMemoryCache,
                                                    //WKWebsiteDataTypeLocalStorage,
                                                    //WKWebsiteDataTypeCookies,
                                                    //WKWebsiteDataTypeSessionStorage,
                                                    //WKWebsiteDataTypeIndexedDBDatabases,
                                                    //WKWebsiteDataTypeWebSQLDatabases
                                                    ]];
    //// All kinds of data
    //NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
    //// Date from
    NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
    //// Execute
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
        // Done
    }];
    
    // for UIWebView
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

+ (void)shareData:(id)vc title:(NSString *)strTitle param:(NSMutableArray *)items
{
    @try {
        [items insertObject:strTitle atIndex:0];
        
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
        [vc presentViewController:activityViewController animated:YES completion:nil];
    } @catch (NSException *e) {
        NSLog(@"exceptionName %@, reason %@", [e name], [e reason]);
    } @finally {
        NSLog(@"shareAction");
    }
}

// 이미지 저장 및 업로드
+ (void)saveImagesToAlbum:(NSMutableArray *)images
{
    for (UIImage *image in images) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }
}

+ (void)downloadImageAndSave:(NSString *)imgUrl
                     message:(NSString *)message
{
//    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:imgUrl]
//                                                          options:SDWebImageDownloaderUseNSURLCache
//                                                         progress:nil
//                                                        completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
//                                                            
//                                                            if (image && finished) {
//                                                                UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), (__bridge void*)imgUrl);
//                                                                
//                                                                if (NO == [IVSUtil IsEmpty:message]) {
//                                                                    [Toast toastWithMessage:message
//                                                                                   duration:2.0f
//                                                                                      align:ToastAlignBottom
//                                                                                   fontSize:12.0f
//                                                                            backgroundColor:[UIColor blackColor]];
//                                                                }
//                                                            }
//                                                        }];
}

+ (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (nil == image) {
        return;
    }
    
    if (nil != error) {
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), contextInfo);
    }
}

+ (void)downloadImagesAndShare:(NSString *)imgUrl
                      shareurl:(NSString *)shareurl
{
//    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:imgUrl]
//                                                          options:SDWebImageDownloaderUseNSURLCache
//                                                         progress:nil
//                                                        completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
//                                                            NSMutableArray *urlArray = [[NSMutableArray alloc] init];
//                                                            
//                                                            NSCharacterSet *allowedCharacterSet = [NSCharacterSet URLQueryAllowedCharacterSet];
//                                                            NSURL *URL = [NSURL URLWithString:[shareurl stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet]];
//                                                            [urlArray addObject:URL];
//                                                            [urlArray addObject:image];
//                                                            
//                                                            [IVSUtil shareData:[AppDelegate Instance].window.rootViewController
//                                                                         title:@""
//                                                                         param:urlArray];
//                                                        }];
}


@end
