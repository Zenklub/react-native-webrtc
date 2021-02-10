#import "WebRTCModule.h"
#import <WebRTC/ZENDataChannel.h>

@interface ZENDataChannel (React)

@property (nonatomic, strong) NSNumber *peerConnectionId;

@end

@interface WebRTCModule (ZENDataChannel) <ZENDataChannelDelegate>

@end
