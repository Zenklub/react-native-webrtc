
#import <Foundation/Foundation.h>
#import <WebRTC/ZENCameraVideoCapturer.h>

@interface VideoCaptureController : NSObject

-(instancetype)initWithCapturer:(ZENCameraVideoCapturer *)capturer
                 andConstraints:(NSDictionary *)constraints;
-(void)startCapture;
-(void)stopCapture;
-(void)switchCamera;

@end
